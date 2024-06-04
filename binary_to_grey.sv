


module binary_to_grey #(parameter ADDR_WIDTH = 3)
(
  input logic [ADDR_WIDTH - 1:0] binary_ptr_in,  // Input Binary code
  output logic [ADDR_WIDTH - 1:0] grey_ptr_out   // Output Grey code
);

  // Store MSB from input to output as it remains the same in both Binary and Grey codes
  assign grey_ptr_out[ADDR_WIDTH - 1] = binary_ptr_in[ADDR_WIDTH - 1];
  
  // Calculate remaining bits
  genvar i;
  generate 
    for (i = 0; i < ADDR_WIDTH - 1; i++) begin : convert
      // XOR each bit of the Binary code with the next higher-order bit of the Binary code
      assign grey_ptr_out[ADDR_WIDTH - 2 - i] = binary_ptr_in[ADDR_WIDTH - 1 - i] ^ binary_ptr_in[ADDR_WIDTH - 2 - i]; 
    end
  endgenerate
  
endmodule




module binary_to_grey_tb();

  parameter ADDR_WIDTH = 3;

  // Testbench signals
  logic [ADDR_WIDTH - 1:0] binary_ptr_in; // Binary code input
  logic [ADDR_WIDTH - 1:0] grey_ptr_out;  // Grey code output
  
  // Instantiate the binary_to_grey module
  binary_to_grey #(ADDR_WIDTH) BtoG (
    .binary_ptr_in(binary_ptr_in),
    .grey_ptr_out(grey_ptr_out)
  );
  
  // Test sequence
  initial begin
    // Apply test vectors (Binary Code) and wait for 10 time units between each vector
    for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
      binary_ptr_in = i; #10;
      $display("Binary: %0b, Grey: %0b", binary_ptr_in, grey_ptr_out);
    end

    $stop;
  end

endmodule 


