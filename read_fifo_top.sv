


module read_fifo_top #(parameter ADDR_WIDTH = 3)
(
   input logic r_clk_in,                     // Read clock input
   input logic r_reset_in,                   // Read reset input
   input logic r_request_in,                 // Read request input
   input logic [ADDR_WIDTH - 1:0] w_ptr_in,  // Write pointer input from the other clock domain
   output logic r_empty_out,                 // Read empty flag output
   output logic [ADDR_WIDTH - 1:0] r_addr_out // Read address output
);

   // Internal signals
   logic r_empty_ctrl_to_dp;                 // Internal signal from controller to datapath for empty flag
   logic [ADDR_WIDTH - 1:0] r_ptr_dp_to_ctrl; // Internal signal for read pointer

   // Output assignments
   assign r_empty_out = r_empty_ctrl_to_dp;  // Connect internal empty flag to module output
   assign r_addr_out = r_ptr_dp_to_ctrl;     // Connect internal read pointer to module output

   // Instantiation of read FIFO controller
   read_fifo_ctrl #(ADDR_WIDTH) R_CTRL
   (
      .r_clk_in(r_clk_in),
      .r_reset_in(r_reset_in),
      .r_request_in(r_request_in),
      .w_ptr_in(w_ptr_in),
      .r_ptr_in(r_ptr_dp_to_ctrl),
      .ctrl_empty_out(r_empty_ctrl_to_dp)
   );

   // Instantiation of read FIFO datapath
   read_fifo_dpath #(ADDR_WIDTH) R_DP 
   (
      .r_clk_in(r_clk_in),
      .r_reset_in(r_reset_in),
      .r_request_in(r_request_in),
      .ctrl_empty_in(r_empty_ctrl_to_dp),
      .r_ptr_out(r_ptr_dp_to_ctrl)
   );  

endmodule 





module read_fifo_top_tb();

   parameter ADDR_WIDTH = 3;
   
   // Testbench signals
   logic r_clk_in;
   logic r_reset_in;
   logic r_request_in;
   logic [ADDR_WIDTH - 1:0] w_ptr_in;
   logic r_empty_out;
   logic [ADDR_WIDTH - 1:0] r_addr_out;

   // Device Under Test (DUT) instantiation
   read_fifo_top #(ADDR_WIDTH) R_TOP
   (
      .r_clk_in(r_clk_in),
      .r_reset_in(r_reset_in),
      .r_request_in(r_request_in),
      .w_ptr_in(w_ptr_in),
      .r_empty_out(r_empty_out),
      .r_addr_out(r_addr_out)
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
      // Initialize system
      r_reset_in = 1;
      r_request_in = 0;
      w_ptr_in = 0;
      @(posedge r_clk_in);
      
      // Reset sequence
      repeat(2) @(posedge r_clk_in);
      r_reset_in = 0; 
      @(posedge r_clk_in);
      
      // Simulate write operations until FIFO is full
      for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
         w_ptr_in = i;
         r_request_in = 0;
         @(posedge r_clk_in);
         $display("r_request: %0d, r_addr_out: %0d, w_ptr_in: %0d, r_empty: %0d",
                  r_request_in, r_addr_out, w_ptr_in, r_empty_out);
      end

      // Simulate read operations until FIFO is almost empty
      for (int i = 0; i < 2**ADDR_WIDTH - 1; i++) begin
         w_ptr_in = 0;
         r_request_in = 1;
         @(posedge r_clk_in);
         r_request_in = 0;
         @(posedge r_clk_in);
         $display("r_request: %0d, r_addr_out: %0d, w_ptr_in: %0d, r_empty: %0d",
                  r_request_in, r_addr_out, w_ptr_in, r_empty_out);
      end

      // Remain almost empty for a few clock cycles
      r_request_in = 0;
      repeat(2) @(posedge r_clk_in);
      
      // Read last entry in FIFO and test read enable logic
      for (int i = 0; i < 3; i++) begin
         r_request_in = 1;
         @(posedge r_clk_in);
         $display("r_request: %0d, r_addr_out: %0d, w_ptr_in: %0d, r_empty: %0d",
                  r_request_in, r_addr_out, w_ptr_in, r_empty_out);
      end

      // Stop simulation
      $stop;
   end

endmodule


