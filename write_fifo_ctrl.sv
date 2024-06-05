


module write_fifo_ctrl #(parameter ADDR_WIDTH = 3)
(
  input logic w_clk_in,                         // Write clock input
  input logic w_reset_in,                       // Write reset input
  input logic w_request_in,                     // Write request input
  input logic [ADDR_WIDTH - 1:0] r_ptr_in,      // Read pointer input
  input logic [ADDR_WIDTH - 1:0] w_ptr_in,      // Present write pointer input
  output logic ctrl_full_out                    // Control signal indicating if FIFO is full
);

  // Internal signals
  logic [ADDR_WIDTH - 1:0] w_ptr_next_in;        // Next write pointer
  logic [ADDR_WIDTH-1:0] one_hot = 1;            // One-hot encoding for incrementing write pointer

  // State encoding
  typedef enum logic {CONTINUE, FULL} state_t;
  state_t p_state, n_state; // Present and next state variables

  // Output assignment for full signal
  assign ctrl_full_out = (p_state == FULL);
  
  // Calculate next read pointer
  assign w_ptr_next_in = w_ptr_in + one_hot;

  // Sequential logic for state transition
  always_ff @(posedge w_clk_in or posedge w_reset_in) begin
    if (w_reset_in) begin
      p_state <= CONTINUE; // Initialize to CONTINUE state on reset
    end else begin
      p_state <= n_state; // Update state on clock edge
    end
  end

  // Combinational logic for next state logic
  always_comb begin
    case(p_state)
      CONTINUE: begin
        if ((w_ptr_next_in == r_ptr_in) & w_request_in) begin
          n_state = FULL; // Transition to FULL if next write pointer equals read pointer and write request is asserted
        end else begin
          n_state = CONTINUE; // Remain in CONTINUE state
        end
      end
      FULL: begin
        if (w_ptr_in != r_ptr_in) begin
          n_state = CONTINUE; // Transition to CONTINUE if present write pointer does not equal read pointer
        end else begin
          n_state = FULL; // Remain in FULL state
        end
      end
    endcase
  end

endmodule




module write_fifo_ctrl_tb();

  parameter ADDR_WIDTH = 3;
  
  // Testbench signals
  logic w_clk_in;
  logic w_reset_in;
  logic w_request_in;
  logic [ADDR_WIDTH - 1:0] r_ptr_in;
  logic [ADDR_WIDTH - 1:0] w_ptr_in;
  logic ctrl_full_out;
  
  // Module instantiation
  write_fifo_ctrl #(ADDR_WIDTH) W_CTRL (
    .w_clk_in(w_clk_in),
    .w_reset_in(w_reset_in),
    .w_request_in(w_request_in),
    .r_ptr_in(r_ptr_in),
    .w_ptr_in(w_ptr_in),
    .ctrl_full_out(ctrl_full_out)
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
    // Initialize signals
    w_reset_in = 1;
    w_request_in = 0;
    r_ptr_in = 0;
    w_ptr_in = 0;

    // Apply reset
    @(posedge w_clk_in);
    repeat(2) @(posedge w_clk_in);
    w_reset_in = 0;
    @(posedge w_clk_in);
    
    // Write until all but one spot is filled
    for (int curr = 0; curr < 2**ADDR_WIDTH - 1; curr++) begin
      w_request_in = 1;
      r_ptr_in = 0;
      w_ptr_in = curr;
      @(posedge w_clk_in);
      
      $display("read_ptr: %0d, w_present: %0d, full: %0d", 
               r_ptr_in, w_ptr_in, ctrl_full_out);
    end
    
    // Remain almost full for 3 clock cycles
    w_request_in = 0;
    r_ptr_in = 0;
    @(posedge w_clk_in);
    repeat(2) @(posedge w_clk_in);
    
    // Now fill that last spot to be FULL
    w_request_in = 1;
	 w_ptr_in = w_ptr_in + 1;
    r_ptr_in = 0;
    @(posedge w_clk_in);
    $display("read_ptr: %0d, w_present: %0d, full: %0d", 
               r_ptr_in, w_ptr_in, ctrl_full_out);   
    
    // Reading until EMPTY state
    for (int curr = 0; curr < 2**ADDR_WIDTH; curr++) begin
      w_request_in = 0;
      r_ptr_in = curr;
      @(posedge w_clk_in);
      
      $display("read_ptr: %0d, w_present: %0d, full: %0d", 
               r_ptr_in, w_ptr_in, ctrl_full_out);
    end

    // Stop simulation
    $stop;
  end

endmodule



