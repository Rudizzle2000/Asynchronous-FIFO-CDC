


module binaryToGrey_sync_greyToBinary_top #(parameter ADDR_WIDTH = 3)
(
   input logic clk_in,                    // Clock input from the current clock domain
   input logic reset_in,                  // Reset input from the current clock domain
   input logic [ADDR_WIDTH - 1:0] binary_ptr_in, // Binary pointer from another clock domain
   output logic [ADDR_WIDTH - 1:0] binary_ptr_out // Converted binary pointer to the current clock domain
);

   // Internal signals
   logic [ADDR_WIDTH - 1:0] grey_ptr_to_sync;   // Grey code pointer to be synchronized
   logic [ADDR_WIDTH - 1:0] sync_to_grey_ptr;   // Synchronized grey code pointer

   // Convert binary pointer to grey code
   binary_to_grey #(ADDR_WIDTH) BtoG
   (
      .binary_ptr_in(binary_ptr_in),
      .grey_ptr_out(grey_ptr_to_sync)
   );

   // Synchronize the grey code pointer across clock domains
   sync_dff #(ADDR_WIDTH) SYNC_DFF 
   (
      .clk_in(clk_in),
      .reset_in(reset_in),
      .ptr_in(grey_ptr_to_sync),
      .ptr_out(sync_to_grey_ptr)
   );
   
   // Convert synchronized grey code pointer back to binary
   grey_to_binary #(ADDR_WIDTH) GtoB
   (
      .grey_ptr_in(sync_to_grey_ptr),
      .binary_ptr_out(binary_ptr_out)
   );

endmodule 




module binaryToGrey_sync_greyToBinary_top_tb();

   parameter ADDR_WIDTH = 3;

   // Testbench signals
   logic clk_in;
   logic reset_in;
   logic [ADDR_WIDTH - 1:0] binary_ptr_in;
   logic [ADDR_WIDTH - 1:0] binary_ptr_out;

   // Device Under Test (DUT) instantiation
   binaryToGrey_sync_greyToBinary_top #(ADDR_WIDTH) CONVERT
   (
      .clk_in(clk_in),
      .reset_in(reset_in),
      .binary_ptr_in(binary_ptr_in),
      .binary_ptr_out(binary_ptr_out) 
   );
   
   // Clock generation parameters
   parameter period = 100;
   
   // Clock generation
   initial begin
      clk_in = 0;
      forever #(period / 2) clk_in = ~clk_in;
   end

   // Test sequence
   initial begin   
      // Initialize system
      reset_in = 1;
      binary_ptr_in = 0;
      @(posedge clk_in);
      
      // Reset sequence
      repeat(2) @(posedge clk_in);
      reset_in = 0; 
      @(posedge clk_in);
      
      // Convert all pointer values within the 2**ADDR_WIDTH range
      // from binary to grey -> dff sync -> grey to binary
      for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
         binary_ptr_in = i; 
         @(posedge clk_in);
      end
   
      // Wait for a few cycles for stabilization
      repeat(4) @(posedge clk_in);
      
      $stop;
   end

endmodule


