


module grey_to_binary #(parameter ADDR_WIDTH = 3)
(
  input logic [ADDR_WIDTH - 1:0] grey_ptr_in,  // Input Grey code
  output logic [ADDR_WIDTH - 1:0] binary_ptr_out // Output Binary code
);
  
  // Store MSB from input to output as it remains the same in both Grey and Binary codes
  assign binary_ptr_out[ADDR_WIDTH - 1] = grey_ptr_in[ADDR_WIDTH - 1];

  // Calculate remaining bits
  genvar i;
  generate 
    for (i = 0; i < ADDR_WIDTH - 1; i++) begin : convert
      // XOR each bit of the Grey code with the next higher-order bit of the Binary code
      assign binary_ptr_out[ADDR_WIDTH - 2 - i] = binary_ptr_out[ADDR_WIDTH - 1 - i] ^ grey_ptr_in[ADDR_WIDTH - 2 - i];
    end
  endgenerate
  
endmodule




module grey_to_binary_tb();

  parameter ADDR_WIDTH = 3;

  // Testbench signals
  logic [ADDR_WIDTH - 1:0] grey_ptr_in;  // Grey code input
  logic [ADDR_WIDTH - 1:0] binary_ptr_out; // Binary code output
  
  // Instantiate the grey_to_binary module
  grey_to_binary #(ADDR_WIDTH) GtoB (
    .grey_ptr_in(grey_ptr_in),
    .binary_ptr_out(binary_ptr_out)
  );
  
  // Test sequence
  initial begin
    // Apply test vectors (Grey Code) and wait for 10 time units between each vector
    grey_ptr_in = 3'b000; #10; // Grey code 000 -> Binary 000
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b001; #10; // Grey code 001 -> Binary 001
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b011; #10; // Grey code 011 -> Binary 010
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b010; #10; // Grey code 010 -> Binary 011
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b110; #10; // Grey code 110 -> Binary 100
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b111; #10; // Grey code 111 -> Binary 101
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b101; #10; // Grey code 101 -> Binary 110
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    grey_ptr_in = 3'b100; #10; // Grey code 100 -> Binary 111
    $display("Grey: %0b, Binary: %0b", grey_ptr_in, binary_ptr_out);
    
    $stop;
  end

endmodule



