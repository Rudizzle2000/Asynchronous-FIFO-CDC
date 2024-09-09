


module Asynchronous_FIFO_CDC #(parameter DATA_WIDTH = 4, ADDR_WIDTH = 3)
(
   input logic w_clk_in,                    // Write clock input
   input logic w_reset_in,                  // Write reset input
   input logic w_request_in,                // Write request input
   input logic [DATA_WIDTH - 1:0] w_data_in,// Write data input

   input logic r_clk_in,                    // Read clock input
   input logic r_reset_in,                  // Read reset input
   input logic r_request_in,                // Read request input

   output logic full_out,                   // FIFO full output
   output logic empty_out,                  // FIFO empty output
   output logic [DATA_WIDTH - 1:0] r_data_out // Read data output
);

   // Internal signals for address pointers
   logic [ADDR_WIDTH - 1:0] w_addr;         // Write address
   logic [ADDR_WIDTH - 1:0] w_addr_to_r;    // Write address in read domain
   logic [ADDR_WIDTH - 1:0] r_addr;         // Read address
   logic [ADDR_WIDTH - 1:0] r_addr_to_w;    // Read address in write domain

   // Connecting reset signals
   logic w_sync_reset_out; // write reset signal 
   logic r_sync_reset_out; // read reset signal
	
   // Asynchrouns reset for write modules
   async_reset WRITE_RESET 
   ( 
	.clk(clk),
	.async_reset_in(w_reset_in),
	.sync_reset_out(w_sync_reset_out)
   );
	
   // Asynchrouns reset for read modules
   async_reset READ_RESET 
   ( 
	.clk(clk),
	.async_reset_in(r_reset_in),
	.sync_reset_out(r_sync_reset_out)
   );	

   // FIFO memory instantiation
   fifo_mem #(DATA_WIDTH, ADDR_WIDTH) FIFO_MEM 
   ( 
      .w_clk_in(w_clk_in),
      .w_full_in(full_out),
      .w_request_in(w_request_in),
      .w_data_in(w_data_in),
      .w_addr_in(w_addr),
      .r_addr_in(r_addr),
      .r_data_out(r_data_out)
   );

   // Write side top module instantiation
   write_fifo_top #(ADDR_WIDTH) W_TOP
   ( 
      .w_clk_in(w_clk_in),
      .w_reset_in(w_reset_in),
      .w_request_in(w_request_in),
      .r_ptr_in(r_addr_to_w),
      .w_full_out(full_out),
      .w_addr_out(w_addr)
   );

   // Synchronizer for write address to read domain
   binaryToGrey_sync_greyToBinary_top #(ADDR_WIDTH) CONVERT_W_TO_R
   (
      .clk_in(r_clk_in),
      .reset_in(r_reset_in),
      .binary_ptr_in(w_addr),
      .binary_ptr_out(w_addr_to_r) 
   );

   // Synchronizer for read address to write domain
   binaryToGrey_sync_greyToBinary_top #(ADDR_WIDTH) CONVERT_R_TO_W
   (
      .clk_in(w_clk_in),
      .reset_in(w_reset_in),
      .binary_ptr_in(r_addr),
      .binary_ptr_out(r_addr_to_w) 
   );

   // Read side top module instantiation
   read_fifo_top #(ADDR_WIDTH) R_TOP
   (
      .r_clk_in(r_clk_in),
      .r_reset_in(r_reset_in),
      .r_request_in(r_request_in),
      .w_ptr_in(w_addr_to_r), 
      .r_empty_out(empty_out),
      .r_addr_out(r_addr)
   );

endmodule 




module Asynchronous_FIFO_CDC_tb();

  parameter DATA_WIDTH = 4;
  parameter ADDR_WIDTH = 3;

  // Testbench signals
  logic w_clk_in;
  logic w_reset_in;
  logic w_request_in;
  logic [DATA_WIDTH - 1:0] w_data_in;
  
  logic r_clk_in;
  logic r_reset_in;
  logic r_request_in;

  logic full_out;
  logic empty_out;
  logic [DATA_WIDTH - 1:0] r_data_out;

  // Device Under Test (DUT) instantiation
  Asynchronous_FIFO_CDC #(DATA_WIDTH, ADDR_WIDTH) DUT (
    .w_clk_in(w_clk_in),
    .w_reset_in(w_reset_in),
    .w_request_in(w_request_in),
    .w_data_in(w_data_in),
    
    .r_clk_in(r_clk_in),
    .r_reset_in(r_reset_in),
    .r_request_in(r_request_in),

    .full_out(full_out),
    .empty_out(empty_out),
    .r_data_out(r_data_out)
  );

  // Clock generation parameters
  parameter w_period = 100;
  parameter r_period = 150;

  // Write clock generation
  initial begin
    w_clk_in = 0;
    forever #(w_period / 2) w_clk_in = ~w_clk_in;
  end

  // Read clock generation
  initial begin
    r_clk_in = 0;
    forever #(r_period / 2) r_clk_in = ~r_clk_in;
  end

  initial begin
    // System Initialization
    w_reset_in = 1;
    r_reset_in = 1;
    w_request_in = 0;
    r_request_in = 0;
    w_data_in = 0;

    @(posedge w_clk_in);
    @(posedge r_clk_in);
    
    // Release reset signals
    w_reset_in = 0;
    r_reset_in = 0;
    
    // Wait for a few cycles for stabilization
    repeat(2) @(posedge w_clk_in);
    repeat(2) @(posedge r_clk_in);

    // ================================ //
    /* Test Write FIFO Operations/Logic */
    // ================================ //
	 
    // Fill all but one spot in FIFO (Tests edge case)
    for (int i = 0; i < 2**ADDR_WIDTH - 1; i++) begin
      w_request_in = 1;
      w_data_in = i;
      @(posedge w_clk_in);
      w_request_in = 0;
      @(posedge w_clk_in);
    end
    
    // Remain almost full for 2 more clock cycles (for viewing response on output)
    w_request_in = 0;
    repeat(2) @(posedge w_clk_in);
	 
    // Fill FIFO, but continue to enter write requests (Tests write enable logic)
    w_request_in = 1;
    repeat(4) @(posedge w_clk_in);
	 
    // End write request operations
    w_request_in = 0;
    @(posedge w_clk_in);
	 
    // Wait for a few cycles
    repeat(2) @(posedge w_clk_in);
    repeat(2) @(posedge r_clk_in);

    // =============================== //
    /* Test Read FIFO Operations/Logic */
    // =============================== //
    
    // Read all but one entry in FIFO (Tests edge case)
    for (int i = 0; i < 2**ADDR_WIDTH - 1; i++) begin
      r_request_in = 1;
      @(posedge r_clk_in);
      r_request_in = 0;
      @(posedge r_clk_in);
      $display("Read Data: %0d, Empty: %0d", r_data_out, empty_out);
    end
    
    // Remain almost empty for 2 more clock cycles (for viewing response on output)
    r_request_in = 0;
    repeat(2) @(posedge r_clk_in);
	 
    // Empty FIFO, but continue to enter read requests (Tests read enable logic)
    r_request_in = 1;
    repeat(4) @(posedge r_clk_in);
	 
    // End read request operations
    r_request_in = 0;
    @(posedge r_clk_in);
	 
    // Wait a few cycles
    repeat(2) @(posedge w_clk_in);
    repeat(2) @(posedge r_clk_in);


    // ======================================================== //
    /* Test Write & Read FIFO Operations/Logic At The Same Time */
    // ======================================================== //
    
    fork
      // Write to FIFO
      begin
        for (int i = 0; i < 20; i++) begin
          w_request_in = 1;
	  if (~full_out) begin
	     w_data_in = incr_w_data_in; // Write data as increasing numbers
	     incr_w_data_in++;
	  end
          @(posedge w_clk_in);
          w_request_in = 0;
          @(posedge w_clk_in);
        end
      end

      // Read from FIFO
      begin
        for (int i = 0; i < 20; i++) begin
          r_request_in = 1;
          @(posedge r_clk_in);
          r_request_in = 0;
          @(posedge r_clk_in);
          $display("Read Data: %0d, Empty: %0d", r_data_out, empty_out);
        end
      end
    join

    // Wait a few cycles after the operation
    repeat(2) @(posedge w_clk_in);
    repeat(2) @(posedge r_clk_in);     

    $stop;
  end

endmodule


