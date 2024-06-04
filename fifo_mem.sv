

module fifo_mem #(parameter DATA_WIDTH = 4, ADDR_WIDTH = 4)

	(	input logic w_clk_in,
		input logic w_full_in,
		input logic w_request_in,
		input logic [DATA_WIDTH - 1:0] w_data_in,
		input logic [ADDR_WIDTH - 1:0] w_addr_in,
		input logic [ADDR_WIDTH - 1:0] r_addr_in,
		output logic [DATA_WIDTH - 1:0] r_data_out
	);
	
	logic w_en;
	
	// 2**ADDR_WIDTH allows grey code to fully be utalized/taken advantage of.
	// Mitagates the chance of metastability by having the address range be a power of two,
	// especially since the fifo is circular (pointer wraps back around).
	logic [DATA_WIDTH - 1:0] memory [0: (2**ADDR_WIDTH) - 1];
	
	// Write enbale logic
	assign w_en = ~w_full_in & w_request_in;
	
	// Write Operation (synchronous)
	always_ff @(posedge w_clk_in) begin
		if(w_en) begin
			memory[w_addr_in] <= w_data_in;
		end
	end
	
	// Read Operation (asynchronous)
	assign r_data_out = memory[r_addr_in];
	
endmodule 



module fifo_mem_tb();
    
   parameter DATA_WIDTH = 4;
   parameter ADDR_WIDTH = 3;

   logic w_clk_in;
   logic w_full_in;
   logic w_request_in;
   logic [DATA_WIDTH - 1:0] w_data_in;
   logic [ADDR_WIDTH - 1:0] w_addr_in;
   logic [ADDR_WIDTH - 1:0] r_addr_in;
   logic [DATA_WIDTH - 1:0] r_data_out;

    // Instantiate FIFO memory
   fifo_mem #(DATA_WIDTH, ADDR_WIDTH) FIFO_MEM 
   (   .w_clk_in(w_clk_in),
        .w_full_in(w_full_in),
        .w_request_in(w_request_in),
        .w_data_in(w_data_in),
        .w_addr_in(w_addr_in),
        .r_addr_in(r_addr_in),
        .r_data_out(r_data_out)
   );

    // Clock period
   parameter period = 100;

    // Generate clock signal
   initial begin
       w_clk_in = 0;
       forever #(period/2) w_clk_in = ~w_clk_in;
   end

    // Test sequence
   initial begin
        // Initialize signals
        w_full_in = 0;
        w_request_in = 0;
        w_data_in = 0;
        w_addr_in = 0;
        r_addr_in = 0;

        // Apply test vectors
        repeat(2) @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 0; w_data_in = 1;  @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 1; w_data_in = 2;  @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 2; w_data_in = 4;  @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 3; w_data_in = 6;  @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 4; w_data_in = 8;  @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 5; w_data_in = 10; @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 6; w_data_in = 12; @(posedge w_clk_in);
        w_full_in = 0; w_request_in = 1; w_addr_in = 7; w_data_in = 14; @(posedge w_clk_in);

        // Check memory reads
        w_full_in = 1; w_request_in = 0; @(posedge w_clk_in);
		  
		  for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
		  
				r_addr_in = i; $display("Read data @ addr %0d: %0d", r_addr_in, r_data_out); @(posedge w_clk_in);
				
		  end


       $stop;
   end

endmodule
