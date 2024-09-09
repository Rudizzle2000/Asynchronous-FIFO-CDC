
module async_reset(
	input logic clk,
	input logic async_reset_in,
	output logic sync_reset_out
);

   logic reset_connect;
	
   // Ensures a safe synchronous reset de-assertion. If "async_reset_in" is high "sync_reset_out" will immediately reflect this
   // and go high. If "async_reset_in" is low, "sync_reset_out" will remain high for 1 clock cycle, then on the rising edge of
   // the second clock cycle "clk" "sync_reset_out" will go low. This synchronizes the change (from 1 to 0) in "sync_reset_out" with
   // the rising edge of the clock. Yes, it takes an extra cc to make "sync_reset_out" low, but this technique also mitigates
   // the possibility of metastability occurring.

   always_ff @(posedge clk or posedge async_reset_in) begin
	if (async_reset_in) begin
	   reset_connect <= 1'b1;
	   sync_reset_out <= 1'b1;
	end
	else begin
	   reset_connect <= 1'b0;
	   sync_reset_out <= reset_connect;
	end
   end

endmodule 