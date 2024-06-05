


module read_fifo_dpath #(parameter ADDR_WIDTH = 3)
(
  input logic r_clk_in,
  input logic r_reset_in,
  input logic r_request_in,
  input logic ctrl_empty_in,
  output logic [ADDR_WIDTH - 1:0] r_ptr_out
);

  logic r_enable;
  
  // Single hot bit for incrementing. Used to prevent manual truncating
  // to target size (reduces risk of system calulation error, and prevents warnings)
  logic [ADDR_WIDTH-1:0] one_hot = 1; 

  // Used to ensure the read pointer never leads the write pointer
  assign r_enable = ~ctrl_empty_in & r_request_in;

  // Sequential logic to control read pointer values
  always_ff @(posedge r_clk_in or posedge r_reset_in) begin
    if (r_reset_in) begin
      r_ptr_out <= 0; // Initialize the read pointer
    end
    else if (r_enable) begin
      r_ptr_out <= r_ptr_out + one_hot; // Increment the read pointer
    end
  end

endmodule




module read_fifo_dpath_tb();

  parameter ADDR_WIDTH = 3;

  // Testbench signals
  logic r_clk_in;
  logic r_reset_in;
  logic r_request_in;
  logic ctrl_empty_in;
  logic [ADDR_WIDTH - 1:0] r_ptr_out;

  // Device Under Test (DUT) instantiation
  read_fifo_dpath #(ADDR_WIDTH) R_DP (
    .r_clk_in(r_clk_in),
    .r_reset_in(r_reset_in),
    .r_request_in(r_request_in),
    .ctrl_empty_in(ctrl_empty_in),
    .r_ptr_out(r_ptr_out)
  );

  // Clock generation parameters
  parameter period = 100;

  // Clock generation
  initial begin
    r_clk_in = 0;
    forever #(period / 2) r_clk_in = ~r_clk_in;
  end

  // Test sequence
  initial begin
    // System initialization
    r_reset_in = 1;
    r_request_in = 0;
    ctrl_empty_in = 0; 
    @(posedge r_clk_in);
    
    // Deassert reset after two clock cycles
    repeat(2) @(posedge r_clk_in);
    r_reset_in = 0; 
    @(posedge r_clk_in);

    // ================================================================ //
    // Simulate the FIFO being full with 2**ADDR_WIDTH write operations
    // ================================================================ //

    // Enter read requests to read all contents within FIFO
    for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
      r_request_in = 1;
      ctrl_empty_in = 0;
      @(posedge r_clk_in);
      
      $display("r_request: %0d, r_ptr_out: %0d, ctrl_empty: %0d", 
                r_request_in, r_ptr_out, ctrl_empty_in);
    end

    // Testing r_enable signal when FIFO is empty
    for (int i = 0; i < 3; i++) begin
      r_request_in = 1;
      ctrl_empty_in = 1;
      @(posedge r_clk_in);
      
      $display("r_request: %0d, r_ptr_out: %0d, ctrl_empty: %0d", 
                r_request_in, r_ptr_out, ctrl_empty_in);
    end

    // Stop simulation
    $stop;
  end

endmodule

