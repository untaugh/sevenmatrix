`define STATE_IDLE 2'b00
`define STATE_INIT 2'b11
`define STATE_COMMAND 2'b01
`define STATE_DATA 2'b10
`define DATA_SIZE 8192
//`define DATA_SIZE 32
`define CMD_READ 8'h03
`define NUM_FRAMES 3

module spi_shift(
	input clk,
	input [7:0] counter,
	input [31:0] frames,
	output spi_cs, 
	output spi_sck,
	output spi_si, 
	input spi_so,
	output [`DATA_SIZE-1:0] data
	//output [12:0] dram_address,
	//inout [15:0] dram_data,
	//output dram_cke,
	//output dram_clk,
	//output dram_wren,
	//output dram_cs,
	//output dram_cas,
	//output dram_ras,
	//output [1:0] dram_bdm,
	//output [1:0] dram_ba
	);

wire accumulate;
reg [30:0] Q;
wire [31:0] cmd;
wire trig;
wire [3:0] frame;

reg [1:0] framecounter;

assign accumulate = framecounter > 0;

spi_shift_mem ss(clk, trig, accumulate, frame, data, cmd, spi_sck, spi_cs, spi_si, spi_so);

//assign trig = (counter==0)? Q[20:0] == 21'hFFFFFFFF : Q[27:0] == 28'hFFFFFFFF;
assign trig = Q[24:0] == 25'hFFFFFFFF;

initial begin
//cmd = 32'b0;
Q = 21'b0;
framecounter = 1'b0;
//cmd[31:24] <= `CMD_READ;

end

assign cmd[31:24] = `CMD_READ;
assign cmd[18:0] = (`DATA_SIZE/8) * frames[(frame*8)+:8];


//always@(*) cmd[18:0] <= (`DATA_SIZE/8) * frames[(frame*8)+:8];


//always@(negedge Q[22]) begin
//cmd[31:24] <= `CMD_READ;
//if (counter > 0) begin
	//cmd[18:0] <= (`DATA_SIZE/8) * frames[(frame*8)+:8];
	//cmd[18:0] <= (`DATA_SIZE/8) * frames[23:16];

//end else begin
	//if (cmd[18:0] >= 19'h4ac00) cmd[18:0] <= 0;
	//else cmd[18:0] <= cmd[18:0] + `DATA_SIZE/8;
//end

//if (framecounter >= 2) framecounter <= 0;
//else framecounter <= framecounter + 1'b1;

//end


always@(posedge clk) begin
	Q <= Q + 1'b1;
	end
endmodule

module spi_shift_mem(
	input clk,
	input trig,
	input accumulate,
	output reg [3:0] frame,
	output reg [`DATA_SIZE-1:0] data,
	input [31:0] cmd,
	output spi_sck,
	output reg spi_cs,
	output spi_si,
	input spi_so
);
	assign spi_sck = clk & ! spi_cs;
	reg [1:0] state;
	reg [15:0] counter;
	wire so;

	assign spi_si = cmd[31-counter];
	assign so = spi_so;

	initial begin
	frame = 4'h0;
	data = 8'h05;
	state = 2'b00;
	counter = 16'h0000;
	spi_cs = 1'b1;
	end

	always@(negedge clk) begin
	case (state)
	`STATE_IDLE: begin
		if (trig == 1) begin
			spi_cs <= 1'b0;
			state <= `STATE_COMMAND;
			counter <= 0;
			frame <= 0;
		end else if (0 < frame && frame < `NUM_FRAMES) begin
			spi_cs <= 1'b0;
			state <= `STATE_COMMAND;
			counter <= 0;
		end
	end

	`STATE_COMMAND: begin
		counter <= counter + 1'b1;
		if (counter >= 32 - 0) begin
			state <= `STATE_DATA;
			counter <= 0;
		end
	end

	`STATE_DATA: begin
		counter <= counter + 1'b1;
		if (counter >= `DATA_SIZE - 1) begin
			state <= `STATE_IDLE;
			spi_cs <= 1'b1;
			frame <= frame + 1'b1;
		end
	end
	endcase
	end

	always@(posedge clk) begin
		if (state == `STATE_DATA) begin
			//if (accumulate)
			if (frame > 0)
				data <= { data[`DATA_SIZE-2:0], (so | data[`DATA_SIZE-1])};
			else
				data <= { data[`DATA_SIZE-2:0], so };
		end
	end

endmodule


module spi_shift_testbench;
	reg clk, trig;
	wire [`DATA_SIZE-2:0] data;

	wire spi_sck;
	wire spi_cs;
	wire spi_si;
	reg spi_so;
	wire [7:0] byte;
	reg [31:0] cmd;
	wire [7:0] leds;
	reg accumulate;
	wire [3:0] frame;
	reg [31:0] frames;

	spi_shift_mem ssm (clk, trig, accumulate, frame, data, cmd, spi_sck, spi_cs, spi_si, spi_so);

	always@(posedge clk) begin
	//spi_so <= 1'b1; ///~spi_so;
	cmd[23:0] <= frames[frame*8 +: 8];
	end

	initial begin
	frames <= 32'hF00F5511;
	cmd[31:24] <= `CMD_READ;
	cmd[23:0] <= 0;

	spi_so = 1'b0;
	clk = 1'b0;
	trig = 1'b0;
	trig <= #5 1'b1;
	trig <= #10 1'b0;
	spi_so = 1'b1;
	
	repeat(100) #1 clk = ~clk;

	spi_so = 1'b0;

	repeat(100) #1 clk = ~clk;
	
	//trig <= #5 1'b1;
	//trig <= #10 1'b0;
	
	repeat(256) #1 clk = ~clk;


	$stop;
	end
	
endmodule