


module write_fifo_top #(parameter ADDR_WIDTH = 3)
(
   input logic w_clk_in,                     // Write clock input
   input logic w_reset_in,                   // Write reset input
   input logic w_request_in,                 // Write request input
   input logic [ADDR_WIDTH - 1:0] r_ptr_in,  // Read pointer input from read_fifo_top module
   output logic w_full_out,                  // Full flag output to indicate write FIFO is full
   output logic [ADDR_WIDTH - 1:0] w_addr_out // Write address output to FIFO memory and read_fifo_top module for pointer comparison
);

   // Internal signals
   logic w_full_ctrl_to_dp;                  // Full signal from control to datapath
   logic [ADDR_WIDTH - 1:0] wptr_dp_to_ctrl; // Present write pointer from datapath to control

   // Output assignments
   assign w_full_out = w_full_ctrl_to_dp;    // Assign full signal to output
   assign w_addr_out = wptr_dp_to_ctrl;      // Assign present write pointer to address output

   // Instantiate write control module
   write_fifo_ctrl #(ADDR_WIDTH) W_CTRL
   ( 
     .w_clk_in(w_clk_in),
     .w_reset_in(w_reset_in),
     .w_request_in(w_request_in),
     .r_ptr_in(r_ptr_in),
     .w_ptr_in(wptr_dp_to_ctrl),
     .ctrl_full_out(w_full_ctrl_to_dp)
   );

   // Instantiate write datapath module
   write_fifo_dpath #(ADDR_WIDTH) W_DP 
   ( 
     .w_clk_in(w_clk_in),
     .w_reset_in(w_reset_in),
     .w_request_in(w_request_in),
     .ctrl_full_in(w_full_ctrl_to_dp),
     .w_ptr_out(wptr_dp_to_ctrl)
   );

endmodule 
 




module write_fifo_top_tb();

   parameter ADDR_WIDTH = 3;

   // Testbench signals
   logic w_clk_in;
   logic w_reset_in;
   logic w_request_in;
   logic [ADDR_WIDTH - 1:0] r_ptr_in;
   logic w_full_out;
   logic [ADDR_WIDTH - 1:0] w_addr_out;

   // Device Under Test (DUT) instantiation
   write_fifo_top #(ADDR_WIDTH) W_TOP
   (
      .w_clk_in(w_clk_in),
      .w_reset_in(w_reset_in),
      .w_request_in(w_request_in),
      .r_ptr_in(r_ptr_in),
      .w_full_out(w_full_out),
      .w_addr_out(w_addr_out)
   );

   // Clock generation parameters
   parameter period = 100;
   
   // Clock generation
   initial begin
      w_clk_in = 0;
      forever #(period / 2) w_clk_in = ~w_clk_in;
   end

   // Test sequence
   initial begin
      // Initialize system
      w_reset_in = 1;
      w_request_in = 0;
      r_ptr_in = 0;
      @(posedge w_clk_in);
      
      // Reset sequence
      repeat(2) @(posedge w_clk_in);
      w_reset_in = 0; 
      @(posedge w_clk_in);
      
      // Write until all but one spot is filled
      for (int i = 0; i < 2**ADDR_WIDTH - 1; i++) begin
         w_request_in = 1; 
         r_ptr_in = 0; 
         @(posedge w_clk_in);
         $display("w_request: %0d, w_addr_out: %0d, w_full: %0d",
                  w_request_in, w_addr_out, w_full_out);
      end
      
      // Remain almost full for 3 clock cycles
      w_request_in = 0; 
      r_ptr_in = 0; 
      @(posedge w_clk_in);
      repeat(2) @(posedge w_clk_in);
      
      // Fill the last spot and test write enable (w_enable will be disabled since FIFO is full)
      for (int i = 0; i < 3; i++) begin
         w_request_in = 1; 
         r_ptr_in = 0; 
         @(posedge w_clk_in);
         $display("w_request: %0d, w_addr_out: %0d, w_full: %0d",
                  w_request_in, w_addr_out, w_full_out);
      end      
      
      // Simulate read operations until FIFO is empty
      for (int i = 0; i < 2**ADDR_WIDTH + 1; i++) begin
         w_request_in = 0; 
         r_ptr_in = i; 
         @(posedge w_clk_in);
         $display("w_request: %0d, w_addr_out: %0d, w_full: %0d",
                  w_request_in, w_addr_out, w_full_out);
      end

      // Stop simulation
      $stop;
   end

endmodule


