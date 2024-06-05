


module write_fifo_dpath #(parameter ADDR_WIDTH = 3)
(
  input logic w_clk_in,                     // Write clock input
  input logic w_reset_in,                   // Write reset input
  input logic w_request_in,                 // Write request input
  input logic ctrl_full_in,                 // Control signal indicating FIFO is full
  output logic [ADDR_WIDTH - 1:0] w_ptr_out // Present write pointer output
);

  logic w_enable; // Write enable signal
  
  // Single hot bit for incrementing. Used to prevent manual truncating
  // to target size (reduces risk of system calulation error, and prevents warnings)
  logic [ADDR_WIDTH-1:0] one_hot = 1; 

  // Enable write operation only if FIFO is not full and write request is asserted
  assign w_enable = ~ctrl_full_in & w_request_in;

  // Sequential logic to control write pointer values
  always_ff @(posedge w_clk_in or posedge w_reset_in) begin
    if (w_reset_in) begin
      w_ptr_out <= 0; // Initialize write pointer on reset
    end
    else if (w_enable) begin
      w_ptr_out <= w_ptr_out + one_hot; // Increment write pointer

    end
  end

endmodule





module write_fifo_dpath_tb();

  parameter ADDR_WIDTH = 3;
  
  // Testbench signals
  logic w_clk_in;
  logic w_reset_in;
  logic w_request_in;
  logic ctrl_full_in;
  logic [ADDR_WIDTH - 1:0] w_ptr_next_out;
  logic [ADDR_WIDTH - 1:0] w_ptr_present_out;
  
  // Module instantiation
  write_fifo_dpath #(ADDR_WIDTH) W_DP (
    .w_clk_in(w_clk_in),
    .w_reset_in(w_reset_in),
    .w_request_in(w_request_in),
    .ctrl_full_in(ctrl_full_in),
    .w_ptr_next_out(w_ptr_next_out),
    .w_ptr_present_out(w_ptr_present_out)
  );

  // Clock period
  parameter period = 100;

  // Clock generation
  initial begin
    w_clk_in = 0;
    forever #(period / 2) w_clk_in = ~w_clk_in;
  end

  // Test sequence
  initial begin
    // System Initialization
    w_reset_in = 1;
    w_request_in = 0;
    ctrl_full_in = 0;
    
    @(posedge w_clk_in);
    repeat(2) @(posedge w_clk_in);
    w_reset_in = 0;
    @(posedge w_clk_in);

    // Enter 7 write requests
    for (int i = 0; i < 2**ADDR_WIDTH; i++) begin	
      w_request_in = 1; 
      ctrl_full_in = 0;
      @(posedge w_clk_in);
      $display("w_request: %0d, w_ptr_present: %0d, w_ptr_next: %0d, ctrl_full: %0d", 
                w_request_in, w_ptr_present_out, w_ptr_next_out, ctrl_full_in);     
    end

    // Testing w_enable signal (system is full, thus w_enable is disabled)
    w_request_in = 1; 
    ctrl_full_in = 1;
    @(posedge w_clk_in);
    $display("w_request: %0d, w_ptr_present: %0d, w_ptr_next: %0d, ctrl_full: %0d", 
              w_request_in, w_ptr_present_out, w_ptr_next_out, ctrl_full_in);

    // Simulate some read operations (system becomes empty)
    // For this simulation, we assume the pointers are reset externally
    w_reset_in = 1; @(posedge w_clk_in);
    w_reset_in = 0; @(posedge w_clk_in);

    // Enter 7 write requests again
    for (int i = 0; i < 2**ADDR_WIDTH; i++) begin	
      w_request_in = 1; 
      ctrl_full_in = 0;
      @(posedge w_clk_in);
      $display("w_request: %0d, w_ptr_present: %0d, w_ptr_next: %0d, ctrl_full: %0d", 
                w_request_in, w_ptr_present_out, w_ptr_next_out, ctrl_full_in);     
    end

    $stop; 
  end
  
endmodule





