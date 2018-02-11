`define STATE_IDLE 2'b00
`define STATE_COMMAND 2'b01
`define STATE_DATA 2'b10
`define DATA_SIZE 8192
//`define DATA_SIZE 32
`define CMD_READ 8'h03
`define NUM_FRAMES 3

/* spi_shift
	Interface to memory moduyle. 
	Translates frame number to read command. */
module spi_shift(
	input clk,
	input [31:0] frames,
	input bell,
	output spi_cs, 
	output spi_sck,
	output spi_si, 
	input spi_so,
	output [`DATA_SIZE-1:0] data
	);

reg [30:0] Q;
wire [31:0] cmd;
wire trig;
wire [3:0] frame;
reg [13:0] bellcounter;
reg reset_bell;

spi_shift_mem ss(clk, trig, frame, data, cmd, spi_sck, spi_cs, spi_si, spi_so);

assign trig = ((bellcounter < 300) ? Q[20:0] == 21'hFFFFFFFF : Q[24:0] == 25'hFFFFFFFF;

initial begin
Q = 21'b0;
end

assign cmd[31:24] = `CMD_READ;
assign cmd[18:0] = (`DATA_SIZE/8) * ((bellcounter < 300) ? (bellcounter + frames[24+:8]) : (frames[(frame*8)+:8]));

//always@(posedge bell) begin
//	bellcounter <= 0;
//end

always@(negedge Q[20]) begin
	if (bellcounter < 300) begin
		bellcounter <= bellcounter + 1'b1;
	end else if (bell) begin
		bellcounter <= 0;
	end
end

//always@(negedge Q[22]) begin
//cmd[31:24] <= `CMD_READ;
//if (counter > 0) begin
	//cmd[18:0] <= (`DATA_SIZE/8) * frames[(frame*8)+:8];
	//cmd[18:0] <= (`DATA_SIZE/8) * frames[23:16];

//end else begin
	//if (cmd[18:0] >= 19'h4ac00) cmd[18:0] <= 0;
	//else cmd[18:0] <= cmd[18:0] + `DATA_SIZE/8;
//end
//end


always@(posedge clk) begin
	Q <= Q + 1'b1;
	end
endmodule

/* spi_shift_mem
	Communicates with the external spi memory.
	Reads data to register. */
module spi_shift_mem(
	input clk,
	input trig,
	output reg [3:0] frame,
	output reg [`DATA_SIZE-1:0] data,
	input [31:0] cmd,
	output spi_sck,
	output reg spi_cs,
	output spi_si,
	input spi_so);

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
	reg [31:0] cmd;
	wire [3:0] frame;
	reg [31:0] frames;

	spi_shift_mem ssm (clk, trig, frame, data, cmd, spi_sck, spi_cs, spi_si, spi_so);

	always@(posedge clk) begin
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