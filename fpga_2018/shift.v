`define STATE_IDLE 2'b00
`define STATE_INIT 2'b11
`define STATE_COMMAND 2'b01
`define STATE_DATA 2'b10
`define DATA_SIZE 8192
`define CMD_READ 8'h03

module spi_shift(
	input clk,
	input [7:0] counter,
	output spi_cs, 
	output spi_sck,
	output spi_si, 
	input spi_so,
	output [`DATA_SIZE-1:0] data,
	output [12:0] dram_address,
	inout [15:0] dram_data,
	output dram_cke,
	output dram_clk,
	output dram_wren,
	output dram_cs,
	output dram_cas,
	output dram_ras,
	output [1:0] dram_bdm,
	output [1:0] dram_ba
	);

reg [30:0] Q;
reg [31:0] cmd;
wire trig;
reg oneframe;

spi_shift_mem ss(clk, trig, data, cmd, spi_sck, spi_cs, spi_si, spi_so);

//assign trig = (counter==0)? Q[20:0] == 21'hFFFFFFFF : Q[27:0] == 28'hFFFFFFFF;
assign trig = Q[20:0] == 21'hFFFFFFFF;

initial begin
cmd = 32'b0;
Q = 21'b0;
oneframe = 1'b0;
end

always@(negedge Q[20]) begin
cmd[31:24] <= `CMD_READ;
if (counter > 0) begin
	cmd[18:0] <= (`DATA_SIZE/8) * (counter - 1);
end else begin
	if (cmd[18:0] >= 19'h4ac00) cmd[18:0] <= 0;
	else cmd[18:0] <= cmd[18:0] + `DATA_SIZE/8;
end

end

always@(cmd) begin
	oneframe <= 1'b1;
end


always@(posedge clk) begin
	Q <= Q + 1'b1;
	end
endmodule

module spi_shift_mem(
	input clk,
	input trig,
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
	data = 8'h00;
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
		end
	end

	`STATE_COMMAND: begin
		counter <= counter + 1'b1;
		if (counter >= 32 - 1) begin
			state <= `STATE_DATA;
			counter <= 0;
		end
	end

	`STATE_DATA: begin
		counter <= counter + 1'b1;
		if (counter >= `DATA_SIZE - 0) begin
			state <= `STATE_IDLE;
			spi_cs <= 1'b1;
		end
	end
	endcase
	end

	always@(posedge clk) begin
		if (state == `STATE_DATA) begin
			data <= { data[`DATA_SIZE-2:0], so};
		end
	end
	
endmodule


//module spi_shift_testbench;
//	reg clk, trig;
//	wire [`DATA_SIZE-2:0] data;
//	
//	wire spi_sck;
//	wire spi_cs;
//	wire spi_si;
//	reg spi_so;
//	wire [7:0] byte;
//	reg [31:0] cmd;
//	wire [7:0] leds;
//	
//	spi_shift_mem ssm (clk, trig, data, cmd, spi_sck, spi_cs, spi_si, spi_so);
//
//	//spi_shift ss(clk, spi_cs, spi_sck, spi_si, spi_so, leds);
//	always@(posedge clk) begin
//	spi_so <= 1'b1; ///~spi_so;
//	end
//	
//	//assign byte = data[63:56];
//	
//	initial begin
//	cmd[31:24] <= `CMD_READ;
//	cmd[23:0] <= 0;
//	spi_so = 1'b0;
//	clk = 1'b0;
//	trig = 1'b0;
//	trig <= #5 1'b1;
//	trig <= #10 1'b0;
//	
//	repeat(2000) #1 clk = ~clk;
//	$stop;
//	end
//	
//endmodule