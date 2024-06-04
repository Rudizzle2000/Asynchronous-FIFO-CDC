


module read_fifo_ctrl #(parameter ADDR_WIDTH = 3)
(
  input logic r_clk_in,                          // Read clock input
  input logic r_reset_in,                        // Read reset input
  input logic r_request_in,                      // Read request input
  input logic [ADDR_WIDTH - 1:0] w_ptr_in,       // Write pointer input from write clock domain
  input logic [ADDR_WIDTH - 1:0] r_ptr_in,       // Read pointer input
  output logic ctrl_empty_out                    // Control signal indicating if FIFO is empty
);

  // Internal signals
  logic [ADDR_WIDTH - 1:0] r_ptr_next_in;        // Next read pointer
  logic [ADDR_WIDTH-1:0] one_hot = 1;            // One-hot encoding for incrementing read pointer

  // State encoding
  typedef enum logic[1:0] {EMPTY, CONTINUE} state_t;
  state_t p_state, n_state;                      // Present and next state variables

  // Output assignment for empty signal
  assign ctrl_empty_out = (p_state == EMPTY);

  // Calculate next read pointer
  assign r_ptr_next_in = r_ptr_in + one_hot;

  // State register
  always_ff @(posedge r_clk_in or posedge r_reset_in) begin
    if (r_reset_in) begin
      p_state <= EMPTY; // Initialize to EMPTY state on reset
    end else begin
      p_state <= n_state; // Update state on clock edge
    end
  end

  // Next state logic
  always_comb begin
    case (p_state)
      EMPTY: begin
        if (r_ptr_in != w_ptr_in) begin
          n_state = CONTINUE; // Transition to CONTINUE if read pointer is not equal to write pointer
        end else begin
          n_state = EMPTY;    // Remain in EMPTY state
        end
      end
      CONTINUE: begin
        if ((r_ptr_next_in == w_ptr_in) & r_request_in) begin
          n_state = EMPTY;    // Transition to EMPTY if next read pointer equals write pointer and read request is asserted
        end else begin
          n_state = CONTINUE; // Remain in CONTINUE state
        end
      end
    endcase
  end

endmodule





module read_fifo_ctrl_tb();

  parameter ADDR_WIDTH = 3;
  
  // Testbench signals
  logic r_clk_in;
  logic r_reset_in;
  logic r_request_in;
  logic [ADDR_WIDTH - 1:0] w_ptr_in;
  logic [ADDR_WIDTH - 1:0] r_ptr_in;
  logic ctrl_empty_out;
  
  // Module instantiation
  read_fifo_ctrl #(ADDR_WIDTH) R_CTRL (
    .r_clk_in(r_clk_in),
    .r_reset_in(r_reset_in),
    .r_request_in(r_request_in),
    .w_ptr_in(w_ptr_in),
    .r_ptr_in(r_ptr_in),
    .ctrl_empty_out(ctrl_empty_out)
  );

  // Clock period
  parameter period = 100;

  // Clock generation
  initial begin
    r_clk_in = 0;
    forever #(period / 2) r_clk_in = ~r_clk_in;
  end

  // Test sequence
  initial begin
  
    // Initialize signals
    r_reset_in = 1;
    r_request_in = 0;
    r_ptr_in = 0;
    w_ptr_in = 0;
  
    // Apply reset
    @(posedge r_clk_in);
    repeat(2) @(posedge r_clk_in);
    r_reset_in = 0;
    @(posedge r_clk_in);

    // Simulate filling up the FIFO (write operations)
    for (int curr = 0; curr < 2**ADDR_WIDTH + 1; curr++) begin
      r_request_in = 0;
      r_ptr_in = 0;
      w_ptr_in = curr;
      @(posedge r_clk_in);
      
      $display("read_ptr: %0d, write_ptr: %0d, empty: %0d", 
               r_ptr_in, w_ptr_in, ctrl_empty_out);
    end

    // Simulate reading until all but one spot is read (1 entry in the FIFO)
    for (int curr = 0; curr < 2**ADDR_WIDTH - 1; curr++) begin
      r_request_in = 1;
      r_ptr_in = curr;
      @(posedge r_clk_in);
      
      $display("read_ptr: %0d, write_ptr: %0d, empty: %0d", 
               r_ptr_in, w_ptr_in, ctrl_empty_out);
    end

    // Remain almost empty for 3 clock cycles
    r_request_in = 0;
    @(posedge r_clk_in);
    repeat(2) @(posedge r_clk_in);

    // Read the last entry in the FIFO
    r_request_in = 1;
    r_ptr_in = 2**ADDR_WIDTH - 1;
    @(posedge r_clk_in);
    
    // Remain EMPTY
    r_request_in = 0;
    r_ptr_in = 0;
    @(posedge r_clk_in);

    // Stop simulation
    $stop;
  end

endmodule



