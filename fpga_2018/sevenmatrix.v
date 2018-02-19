`define HOUR_OFFSET 0
`define MINUTE_OFFSET 12
`define SECOND_OFFSET 72
`define FRAMES_OFFSET 132
`define FRAMES_NUM 4
`define FRAMES_PER_BELL 300

/* SevenMatrix 
	Drives columns and rows on display, with frames
	from memory module. */
module SevenMatrix(
	input button0, button1,
	input clk_50,
	output [3:0] cols,
	output le,oe,clk,sdi,
	output spi_si,
	input spi_so,
	output spi_sck,
	output spi_cs);

	reg [25:0] Q; // Counter divider. 
	reg [5:0] seconds;
	reg [5:0] minutes;
	reg [3:0] hours;

	reg button0_flag, button1_flag;
	reg [7:0] counter;
	wire [7:0] brig; // brightness
	wire [8192-1:0] data;

	wire [31:0] clockframes;
	wire bell;
	reg [7:0] bellnum;

	initial
	begin
	Q = 24'h0;
	button0_flag = 1'b0;
	button1_flag = 1'b0;
	counter = 1'b1;
	seconds = 0;
	minutes = 0;
	hours = 0;
	bellnum = 0;
	end

	assign clockframes[24+:8] = bellnum;
	assign clockframes[0+:8] = hourframe(hours);
	assign clockframes[8+:8] = minuteframe(minutes);
	assign clockframes[16+:8] = secondframe(seconds);
	assign bell = seconds == 6'h00;
	assign sdi = spi_cs && brightness(data[{cols, Q[6:1], 3'h0}+:8], brig); 
	assign oe = !spi_cs;
	assign clk = Q[0]; 
	assign brig = Q[14:7];
	assign le = Q[6:0] == 7'hFE;
	assign cols = Q[18:15];

	function [7:0] hourframe(input [7:0] hour);
		hourframe = hour + `HOUR_OFFSET;
	endfunction

	function [7:0] minuteframe(input [7:0] minute);
		minuteframe = minute + `MINUTE_OFFSET;
	endfunction

	function [7:0] secondframe(input [7:0] second);
		secondframe = second + `SECOND_OFFSET;
	endfunction

	function brightness(
		input [7:0] pixel,
		input [7:0] level);
		if (level & (1<<7)) 			brightness = pixel > 128;
		else if (level & (1<<6))	brightness = pixel > 64;
		else if (level & (1<<5))	brightness = pixel > 32;
		else if (level & (1<<4))	brightness = pixel > 16;
		else if (level & (1<<3))	brightness = pixel > 8;
		else if (level & (1<<2))	brightness = pixel > 4;
		else if (level & (1<<1))	brightness = pixel > 2;
		else if (level & (1<<0))	brightness = pixel > 1;
		else brightness = 0;
	endfunction

	spi_shift ss(
		.clk(clk_50),
		.frames(clockframes),
		.bell(bell),
		.spi_cs(spi_cs), 
		.spi_sck(spi_sck),
		.spi_si(spi_si), 
		.spi_so(spi_so),
		.data(data));

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

	always@(posedge Q[25]) begin // Increment seconds counter. 
	//clockframes[0+:8] <= hourframe(hours);
	//clockframes[8+:8] <= minuteframe(minutes);
	//clockframes[16+:8] <= secondframe(seconds);

		if (seconds >= 15) begin
			seconds <= 0;
			bellnum <= bellnum + 1'b1;
			if (bellnum >= (`FRAMES_NUM - 1)) bellnum <= 0;
			if (minutes >= 59) begin
				minutes <= 0;
				if (hours >= 11) hours <= 0;
				else hours = hours + 1'b1;
			end else minutes = minutes + 1'b1;
		end else seconds <= seconds + 1'b1;
	end

	always@(posedge clk_50) // Increment main counter. 
	Q <= Q + 1'b1;
endmodule

module SevenMatrix_testbench;
	reg button0, button1, clk;
	wire shft_clk, le, oe, sdi;
	wire [3:0] cols;
	reg [5:0] mem_waddr;
	reg [3:0] mem_wdata;
	reg [5:0] mem_raddr;
	wire [3:0] mem_rdata;
	wire clk_50;

   SevenMatrix sm (button0, button1, clk, cols, le, oe, shft_clk, sdi);

	assign clk_50 = clk;
 
	initial
	begin
	clk = 1'b0;
	repeat(100000) #1 clk = ~clk;
	$stop;
	end
endmodule

