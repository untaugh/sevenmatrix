#include <stdio.h>
#include <dirent.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <magick/MagickCore.h>

#define WIDTH 120
#define HEIGHT 112
#define NUM_SEGMENTS 1024

#define MODULES_X 16;
#define MODULES_Y 8;

#define MODULE_WIDTH 7.5f
#define MODULE_HEIGHT 14.0f

#define SETBRIGHT0 1.0f
#define SETBRIGHT1 0.2f
#define SETBRIGHT2 0.2f

#define displaywidth modulesx * modulewidth;
#define displayheight modulesy * moduleheight;

#define ratio displaywidth / displayheight;

#define segmentlength 4.5;

float segments[8][2] = {
  {3.75, 2.5},
  {1.5, 4.75},
  {6.0, 4.75},
  {3.75, 7.0},
  {6.0, 9.25},
  {1.5, 9.25},
  {6.25, 12.75},
  {3.75, 11.5}
};

typedef struct Segment {
  float brightness;
  float x;
  float y;
} Segment;

static void getPosition(uint16_t index, Segment *segment)
{
  int modulex = (index/8)/MODULES_Y;
  int moduley = (index/8)%MODULES_Y;
  int segi = index%8;

  segment->x = modulex * MODULE_WIDTH + segments[segi][0];
  segment->y = moduley * MODULE_HEIGHT + segments[segi][1];
}

static void setBrightness(float x, float y, uint32_t a, Segment *segment)
{
  float dx = segment->x - x;
  float dy = segment->y - y;
  float dist = sqrt(dx*dx + dy*dy);

  if (dist > 50.0) return;

  float bright = SETBRIGHT1/dist + (SETBRIGHT2/(dist*dist));
  bright = fminf(1.0, SETBRIGHT0 * bright);
  segment->brightness = fmaxf(segment->brightness, bright * (a / 196608.0f));
}

static void writeBinary(Segment *segments, uint8_t * data)
{
  for(int i=NUM_SEGMENTS-1; i>=0; i--)
  {
    *data++ = (uint8_t) (segments[i].brightness * 255.0f);
  }
}

static void getSegments(Image *image, Segment *segments)
{
  ExceptionInfo *exception;

  for (int y=0; y < image->rows; y++)
  {
    for (int x=0; x < image->columns; x++)
    {
      QuantumPixelPacket *q = GetAuthenticPixels(image, x, y, 1, 1, exception);

      uint32_t a = q->red + q->green + q->blue;

      for (int i=0; i<NUM_SEGMENTS; i++)
      {
        setBrightness(x,y,a, &segments[i]);
      }
    }
  }
}

static void convertFrame(Image *image, uint8_t * data)
{
  Segment segments[NUM_SEGMENTS];

  memset(segments, 0, sizeof(Segment) * NUM_SEGMENTS);

  for (int i=0; i<NUM_SEGMENTS; i++)
  {
    getPosition(i,&segments[i]);
  }

  getSegments(image, segments);

  writeBinary(segments, data);
}

static void convertImage(char * filename, uint8_t * data)
{
  Image *image;
  ImageInfo *image_info;
  ExceptionInfo *exception;

  printf("convertImage: %s\n", filename);

  MagickCoreGenesis(NULL, MagickTrue);

  exception = AcquireExceptionInfo();
  image_info = CloneImageInfo((ImageInfo *) NULL);

  strcpy(image_info->filename, filename);
  image = ReadImage(image_info, exception);

  if (exception->severity != UndefinedException)
  {
    CatchException(exception);
  }
  if (image == (Image *) NULL)
  {
    exit(1);
  }
  printf("w: %d, h: %d\n", image->columns, image->rows);

  convertFrame(image, data);
}

int filter (const struct dirent * entry)
{
  return !strncmp(entry->d_name, "screen-", 7);
}

enum mode
{
  DIRECTORY,
  IMAGE
};

int main(int argc, char ** argv)
{
  struct dirent * de;

  if (argc != 3)
  {
    printf("Usage: %s [mode] directory\n", argv[0]);
    exit(0);
  }

  enum mode mode;

  if (argv[1][0] == 'i') mode = IMAGE;
  else if (argv[1][0] == 'd') mode = DIRECTORY;
  else exit(0);

  char * filename = argv[2];

  uint8_t * data = (uint8_t*) malloc(NUM_SEGMENTS);

  FILE *dataout = fopen("frame.bin", "w");

  if (!dataout)
  {
    printf("Could not open out file.\n");
    exit(0);
  }

  struct dirent ** names;
  int n;

  if (mode == DIRECTORY)
  {
    n = scandir(filename, &names, filter, alphasort);
  }
  else
  {
    n = 1;
  }

  int framecount = 0;

  if (n<0)
  {
    printf("scandir: error\n");
  }
  else
  {
    for(int i=0; i<n; i++)
    {
      char path[100];
      if (mode == DIRECTORY)
      {
      strcpy(path, filename);
      strcat(path, "/");
      strcat(path, names[i]->d_name);
    }

  else
  {
    strcpy(path, filename);
  }
      convertImage(path, data);

      fwrite(data, 1, NUM_SEGMENTS, dataout);

      framecount++;
      if (mode == DIRECTORY) free(names[i]);
    }
  }

  if (mode == DIRECTORY) free(names);

  printf("Converted %d frames.\n", framecount);
  fclose(dataout);
}
