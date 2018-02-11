#!/usr/bin/python3

import writeserial

import argparse
from math import sqrt
from PIL import Image, ImageDraw, ImageColor
from pathlib import Path

modulesx = 16
modulesy = 8

modulewidth = 7.5
moduleheight = 14.0

displaywidth = modulesx * modulewidth
displayheight = modulesy * moduleheight

ratio = displaywidth / displayheight

segmentlength = 4.5

setbright0 = 1.0
setbright1 = 0.2
setbright2 = 0.2
setdist = 7.0

seg_0a = (3.75, 2.5)
seg_1f = (1.5, 4.75)
seg_2b = (6.0, 4.75)
seg_3g = (3.75, 7.0)
seg_5c = (6.0, 9.25)
seg_4e = (1.5, 9.25)
seg_7x = (6.25, 12.75)
seg_6d = (3.75, 11.5)

segments = [seg_0a, seg_1f, seg_2b, seg_3g, seg_5c, seg_4e, seg_7x, seg_6d];
segment_offs = [(segmentlength/2, 0),
                (0, segmentlength/2),
                (0, segmentlength/2),
                (segmentlength/2, 0),
                (0, segmentlength/2),
                (0, segmentlength/2),
                (0,0),
                (segmentlength/2, 0)];
segment_type = [0,
                1,
                1,
                0,
                1,
                1,
                2,
                0];

print('Display size: %d x %d' % (displaywidth, displayheight))
print('Ratio: %f' % (displaywidth / displayheight)) #15:14

parser = argparse.ArgumentParser(description='Convert and upload frames.')
parser.add_argument('-v', help='verify', action='store_true')
parser.add_argument('-p', help='program', action='store_true')
parser.add_argument('-g', help='generate frames', action='store_true')
parser.add_argument('-f', help='binary file to program or verify')
parser.add_argument('-d', help='directory for batch generate')
parser.add_argument('-i', help='display image')
parser.add_argument('-b', help='output binary file', action='store_true')
args = parser.parse_args()

datafile = args.f

class segment:

    brightness = 0.0
    count = 0

    def __init__(self, index):
        self.index = int(index)
        self.pos = self.getPos()
    def clear(self):
        self.brightness = 0
        self.count = 0
    def getBrightness(self):
        #return min(1.0, self.brightness/self.count)
        return min(1.0, self.brightness)
    def setPixelUV(self, u, v, a, ratio=1.0):
        self.setPixel(displaywidth * u, displayheight * v, a, ratio)
    def setPixel(self, x, y, a, ratio=1.0):
        dist = self.getDistance(x, y)
        if dist > 0.0:
            self.count += 1;
            #self.brightness += 1/(self.brightness+0.1) * ratio * (setbright/(dist*dist)) * a
            #self.brightness += (setbright/(dist*dist)) * a
            newbright = setbright1/dist + (setbright2/(dist*dist))
            newbright = min(1.0, setbright0 * newbright)
            self.brightness = max(self.brightness, newbright * a)
    def getDistance(self, x, y):
        #pos = self.getPos()
        dx = (self.pos[0] - x)
        dy = (self.pos[1] - y)
        return sqrt(dx*dx + dy*dy)
    def getModuleX(self):
        return int((self.index/8)/modulesy)
    def getModuleY(self):
        return int(self.index/8%modulesy)
    def getSegmentI(self):
        return int(self.index%8)
    def getType(self):
        return segment_type[self.getSegmentI()]
    def getPos(self):
        si = self.getSegmentI()
        posx = self.getModuleX()*modulewidth + segments[si][0]
        posy = self.getModuleY()*moduleheight + segments[si][1]
        return (posx, posy)
    def getStart(self):
        si = self.getSegmentI()
        posx = self.getModuleX()*modulewidth + segments[si][0] - segment_offs[si][0]
        posy = self.getModuleY()*moduleheight + segments[si][1] - segment_offs[si][1]
        return (posx, posy)
    def getEnd(self):
        si = self.getSegmentI()
        posx = self.getModuleX()*modulewidth + segments[si][0] + segment_offs[si][0]
        posy = self.getModuleY()*moduleheight + segments[si][1] + segment_offs[si][1]
        return (posx, posy)
    def info(self):
        print('Segment: (%d,%d,%d)' % (self.getModuleX(), self.getModuleY(), self.getSegmentI()), end='')
        #print(', Pos: (%f, %f) -> (%f, %f)' % (self.getStart() + self.getEnd()) )
        print(', Pos: (%f,%f)' % (self.getPos()['x'],self.getPos()['y']) )

class display:

    segments = []
    scale = 1.0

    def __init__(self, scale):
        for i in range(1024):
            self.segments.append(segment(i))
        self.scale = scale
        self.image = Image.new('RGB',(int(displaywidth*scale),int(displayheight*scale)))
        self.draw = ImageDraw.Draw(self.image)
    def clear(self):
        for seg in self.segments:
            seg.clear()
        del self.draw
        del self.image
        self.image = Image.new('RGB',(int(displaywidth*self.scale),int(displayheight*self.scale)))
        self.draw = ImageDraw.Draw(self.image)
    def setPixel(self, x,y,a):
        for seg in self.segments:
            seg.setPixel(x,y,a);
    def setPixelUV(self, u,v,a):
        for seg in self.segments:
            seg.setPixelUV(u,v,a);
    def setImage(self, img):
        new = img.resize((int(displaywidth/1),int(displayheight/1)))
        img = new
        #ratio = img.width/displaywidth
        for x in range(img.width):
            #print(x)
            for y in range(img.height):
                pixel = img.getpixel((x,y))
                #print(pixel)
                #a = pixel
                a = pixel[0]/3 + pixel[1]/3 + pixel[2]/3
                a /= 255.0
                #a /= ratio
                self.setPixelUV(x/img.width,y/img.height,a)
        for seg in self.segments:
            self.drawSegment(seg)
    def drawCircle(self,x,y,a):
        r = 0.5*self.scale
        x *= self.scale
        y *= self.scale
        self.draw.ellipse([x-r,y-r,x+r,y+r],fill='#%02x%02x%02x' % (int(255*a),0,0))
    def drawLine(self, start, end, a):
        start = (start[0] * self.scale, start[1] * self.scale)
        end = (end[0] * self.scale, end[1] * self.scale)
        self.draw.line((start, end),width=int(self.scale),fill='#%02x%02x%02x' % (int(255*a),0,0))
    def drawSegment(self, seg):
        if seg.getType() == 2:
            pos = seg.getPos()
            self.drawCircle(pos[0], pos[1], seg.getBrightness())
        else:
            start = seg.getStart()
            end = seg.getEnd()
            self.drawLine(start, end, seg.getBrightness())
    def show(self):
        self.image.show()
    def save(self, name):
        self.image.save(name + '.png','PNG')
    def initBinary(self, name):
        self.fileBinary = name
    def appendBinary(self):
        data = []
        for seg in self.segments:
            byte = int(seg.getBrightness()*255)
            data.append(byte)
        data.reverse()
        with Path(self.fileBinary).open('ab') as f:
            #print('seg: %d' % len(self.segments))
            print('Writing %d bytes to %s' % (len(data),self.fileBinary))
            f.write(bytes(data))

if args.d:
    count = 1
    infile = Path('%s/screen-%04d.tif' % (args.d, count))
    disp = display(10.0)
    disp.initBinary('batch.bin')
    while infile.exists():
        print('frame %d' % count)
        img = Image.open('%s/screen-%04d.tif' % (args.d, count))
        disp.setImage(img)
        #disp.show()
        disp.appendBinary()
        #d.save('out/%04d' % (outputfolder,i))
        disp.clear()
        del img
        count += 1
        infile = Path('%s/screen-%04d.tif' % (args.d, count))
    exit()
if args.i:
    disp = display(10.0)
    if args.b: disp.initBinary(args.i + '.bin')
    disp.setImage(Image.open(args.i))
    disp.show()
    if args.b: disp.appendBinary()
    del disp
    exit()
if args.v:
    if not datafile:
        print('Please select a file.')
        exit()
    ser = writeserial.initSerial(False)
    writeserial.Verify(ser, datafile)
    ser.close()
    exit()
elif args.p:
    if not datafile:
        print('Please select a file.')
        exit()
    ser = writeserial.initSerial(True)
    writeserial.Program(ser, datafile)
    ser.close()
    exit()
