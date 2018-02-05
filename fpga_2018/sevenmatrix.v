//module sm_spimem(
	
//);

//endmodule


module sm_memory(clk, mem_waddr, mem_wdata, mem_raddr, mem_rdata);
	input clk;
	input [5:0] mem_waddr;
	input [3:0] mem_wdata;
	input [9:0] mem_raddr;
	output [3:0] mem_rdata;
	reg [3:0] mem [0:1023];
	reg [30:0] Q;
	reg [3:0] mem_data_out;
	integer i, j;

	assign mem_rdata = mem_data_out;

	initial
	begin
	Q = 31'h0;
	for (i=0; i<1024; i = i + 1'b1)
		begin
		j = (i%64 < 32) ? (i%32/2) : 15-(i%32/2);
		mem[i] = j;// + (i/64);
		end
	end

	always@(negedge clk)
	begin
		Q <= Q + 1'b1;
		mem_data_out <= mem[mem_raddr];
	end

	always@(posedge Q[16])
	begin
	for (i=0; i<1024; i = i + 1'b1)
		begin
		//mem[i] <= mem[i] + 1'b1;
		mem[(i+1)%1024] <= mem[i];
		
		end
	end
endmodule

//module sm_numbers(clk,clk_data,mem_waddr,mem_wdata);
//	input clk;
//	reg [23:0] Q;
//	output clk_data;
//	output reg [6:0] mem_waddr;
//	output reg [7:0] mem_wdata;
//	reg [63:0] counter;
//	reg dot;
//	wire [63:0] bcd;
//	reg [7:0] number;
//	wire [7:0] seg_number;
//	
//	assign clk_slow = Q[2];
//	assign clk_data = Q[1];
//	
//	bin_to_seg bts1 (
//	.seg (seg_number),
//	.bin (number),
//	.dot (dot)
//	);
//	
//	bin_to_bcd bb1(
//	.bcd (bcd),
//	.bin (counter),
//	);
		
	//assign clk_data = clk;
	
//	always@(posedge clk_data)
//	begin
//	mem_waddr = mem_waddr +1;
//	end
//	
//	always@(posedge clk)
//	begin
//	Q = Q + 1;
//	mem_wdata = seg_number;
//
//	case (mem_waddr)
//	0*8: number = bcd[63:60];
//	1*8: number = bcd[59:56];
//	2*8: number = bcd[55:52];
//	3*8: number = bcd[51:48];
//	4*8: number = bcd[47:44];
//	5*8: number = bcd[43:40];
//	6*8: number = bcd[39:36];
//	7*8: number = bcd[35:32];
//	8*8: number = bcd[31:28];
//	9*8: number = bcd[27:24];
//	10*8: number = bcd[23:20];
//	11*8: number = bcd[19:16];
//	12*8: number = bcd[15:12];
//	13*8: number = bcd[11:8];
//	14*8: number = bcd[7:4];
//	15*8: number = bcd[3:0];
//	default: mem_wdata = 0;
//	endcase
//	end
//	
//	always@(posedge clk_slow)
//	counter = counter + 1;
//	
//endmodule


module SevenMatrix(
		input button0, button1,
		//input knapp1, knapp2, 
		input clk_50,
		output [3:0] cols,
		output le,oe,clk,sdi,
	output spi_si,
	input spi_so,
	output spi_sck,
	output spi_cs); //,mem_addr,mem_data);

	reg [23:0] Q; // Counter divider. 

	reg button0_flag, button1_flag;
	reg [7:0] counter;
	//reg [5:0] colindex;
	//reg [3:0] index;
	//reg [7:0] pixel;
	//reg [511:0] column;

	//wire [5:0] ledc; // led module counter. 
	wire [7:0] brig; // brightness
	//wire [9:0] mem_addr;
	//wire [3:0] mem_data;
	//wire [5:0] mem_waddr;
	//wire [3:0] mem_wdata;
	//wire clk_data;
   //reg [7:0] framebuffer [0:1023];
	//integer frame;

	wire [8192-1:0] data;

	initial
	begin
	Q = 24'h0;
	button0_flag = 1'b0;
	button1_flag = 1'b0;
	counter = 1'b0;
	//frame = 0;
//	column = 512'b1;
//	column[8*(8*1+1)] = 1;
//	column[8*(8*2+2)] = 1;
//	column[8*(8*3+3)] = 1;
//	column[8*(8*4+4)] = 1;
//	column[8*(8*5+5)] = 1;
//	column[8*(8*6+6)] = 1;
//	column[8*(8*7+7)] = 1;

	//column[503] = 1;
	//column[495] = 1;
	//column[496] = 1;
	//column[511] = 1;
	//index = 5;
	end

	//assign spi_clk = clk_50;

	//assign sdi = data[{cols, Q[7:2], 3'h0}+:8] > (127 - 127/(brig+1) + brig/2); // (brig*brig)/255 + 192, //{brig[7:4], 4'h0},

	assign sdi = spi_cs && brightness(data[{cols, Q[6:1], 3'h0}+:8], brig);// : brightness(data2[{cols, Q[6:1], 3'h0}+:8], brig);

	assign 	oe = !spi_cs, //Q[20] && Q[19:0] < 16'hFFFF, // > 16'hFFFF, //1'b0, // Enable output.
				clk = Q[0], // Only output clock when shifting out data. 
				brig = Q[14:7],
				le = Q[6:0] == 7'hFE;  // Latch data just before chaning column. 

	assign cols = Q[18:15];
	//assign clk_prog = clk_50; // Q[20];

	//always@(posedge Q[1]) begin
	//	colindex <= colindex + 1;
	//end

	//always@(negedge Q[1]) begin
		//pixel <= data[cols*512+8*Q[7:2]+:8];
		//pixel <= column[{colindex, 3'h0}+:8];
		//pixel <= data[{cols, colindex, 3'h0}+:8];
	//end

	//always@(negedge le) begin
	//index <= Q[19:16];
	//column <= data[{cols, 9'h0}+:512];
	//end

	function brightness(
		input [7:0] pixel,
		input [7:0] level);
		//brightness = pixel > 100;
		if (level & (1<<7)) 			brightness = pixel > 128;
		else if (level & (1<<6))	brightness = pixel > 64;
		else if (level & (1<<5))	brightness = pixel > 32;
		else if (level & (1<<4))	brightness = pixel > 16;
		else if (level & (1<<3))	brightness = pixel > 8;
		else if (level & (1<<2))	brightness = pixel > 4;
		else if (level & (1<<1))	brightness = pixel > 2;
		else if (level & (1<<0))	brightness = pixel > 1;
		else brightness = 0;

		//brightness = isbitset(7, pixel);
		//if (level > 40)		brightness = isbitset(6, pixel);
		//if (level < 30)		brightness = isbitset(5, pixel);
		//if (level < 20)		brightness = isbitset(4, pixel);
		//if (level < 10)		brightness = isbitset(4, pixel);
		//if (level < 220)		brightness = isbitset(3, pixel);
		//if (level < 230)		brightness = isbitset(2, pixel);
		//if (level < 240)		brightness = isbitset(1, pixel);
		//brightness = isbitset(0, pixel);

	endfunction

//	function isbitset(
//		input [3:0] bit,
//		input [7:0] value
//		);
//		if (value & (1<<bit)) isbitset = 1'b1;
//		else isbitset = 1'b0;
//	endfunction
	
	spi_shift ss(
		.clk(clk_50),
		.counter(counter),
		.spi_cs(spi_cs), 
		.spi_sck(spi_sck),
		.spi_si(spi_si), 
		.spi_so(spi_so),
		.data(data),
	);
	
//	sm_memory sm1(
//	.clk (clk_data),
//	.mem_waddr (mem_waddr),
//	.mem_wdata (mem_wdata),
//	.mem_raddr (mem_addr),
//	.mem_rdata (mem_data)
//	);

	//sm_numbers sn1(
	//.clk (clk_prog),
	//.clk_data (clk_data),
	//.mem_waddr (mem_waddr),
	//.mem_wdata (mem_wdata),
	//);

	always@(posedge Q[0]) begin
		if (button0 && !button0_flag) button0_flag <= 1'b1;
		if (!button0 && button0_flag) begin
			button0_flag <= 1'b0;
			counter <= counter + 1'b1;
		end
		if (button1 && !button1_flag) button1_flag <= 1'b1;
		if (!button1 && button1_flag) begin
			button1_flag <= 1'b0;
			if (counter > 0) counter <= counter - 1'b1;
		end
	end

	always@(posedge clk_50) // Increment main counter. 
	Q <= Q + 1'b1;
endmodule

//module SevenMatrix_testbench;
//
//	reg knapp1, knapp2, clk;
//	wire shft_clk, le, oe, sdi;
//	//reg [3:0] cols;
//	wire [3:0] cols;
//	reg [5:0] mem_waddr;
//	reg [3:0] mem_wdata;
//	reg [5:0] mem_raddr;
//	wire [3:0] mem_rdata;
//	wire clk_50;
//
//	//testm tm(clk);
//   SevenMatrix sm (knapp1, knapp2, clk,cols,le,oe,shft_clk,sdi);
//	//sm_memory memory(clk, mem_waddr, mem_wdata, mem_raddr, mem_rdata);
//
//	assign clk_50 = clk;
// 
//	initial
//	begin
//	clk = 1'b0;
//
//	repeat(100000) #1 clk = ~clk;
//	$stop;
//	end
//endmodule


//module bin_to_bcd(bcd,bin);
//	parameter nums = 16;
//	output [nums*4-1:0] bcd;
//	input [31:0] bin;
//	
//	genvar i;
//	generate 
//	for(i=0; i<nums; i = i+1)
//	begin : b1
//	assign bcd[i*4+3:i*4] = (bin/(10**i))%10;
//	end
//	endgenerate
//	
//endmodule

///* Convert binary value to, segment value*/
//module bin_to_seg(output reg [7:0] seg, input[3:0] bin, input dot);
//
//	// SEGMENTS	
//	parameter SEGA = (1<<0);
//	parameter SEGB = (1<<2);
//	parameter SEGC = (1<<4);
//	parameter SEGD = (1<<7);
//	parameter SEGE = (1<<5);
//	parameter SEGF = (1<<1);
//	parameter SEGG = (1<<3);
//	parameter SEGP = (1<<6);
//
//	// NUMBERS
//	parameter NUM0 = (SEGA | SEGB | SEGC | SEGD | SEGE | SEGF);
//	parameter NUM1 = (SEGB | SEGC);
//	parameter NUM2 = (SEGA | SEGB | SEGD | SEGE | SEGG);
//	parameter NUM3 = (SEGA | SEGB | SEGC | SEGD | SEGG);
//	parameter NUM4 = (SEGB | SEGC | SEGF | SEGG);
//	parameter NUM5 = (SEGA | SEGF | SEGG | SEGC | SEGD);
//	parameter NUM6 = (SEGA | SEGC | SEGD | SEGE | SEGF | SEGG);
//	parameter NUM7 = (SEGA | SEGB | SEGC );
//	parameter NUM8 = (SEGA | SEGB | SEGC | SEGD | SEGE | SEGF | SEGG);
//	parameter NUM9 = (SEGA | SEGB | SEGC | SEGD | SEGF | SEGG);
//	parameter NUMA = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	parameter NUMB = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	parameter NUMC = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	parameter NUMD = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	parameter NUME = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	parameter NUMF = (SEGA | SEGB | SEGC | SEGE | SEGF |SEGG);
//	
//	always
//	begin
//	case (bin)
//	0: seg = NUM0;
//	1: seg = NUM1;
//	2: seg = NUM2;
//	3: seg = NUM3;
//	4: seg = NUM4;
//	5: seg = NUM5;
//	6: seg = NUM6;
//	7: seg = NUM7;
//	8: seg = NUM8;
//	9: seg = NUM9;
//	10: seg = NUMA;
//	11: seg = NUMB;
//	12: seg = NUMC;
//	13: seg = NUMD;
//	14: seg = NUME;
//	15: seg = NUMF;
//	endcase
//	if (dot) seg = seg | SEGP; 
//	end
//endmodule
