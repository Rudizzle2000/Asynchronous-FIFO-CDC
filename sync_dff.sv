


module sync_dff #(parameter ADDR_WIDTH = 4)
(
    input logic clk_in,                   // Clock input
    input logic reset_in,                 // Reset input
    input logic [ADDR_WIDTH - 1:0] ptr_in,  // Input pointer
    output logic [ADDR_WIDTH - 1:0] ptr_out // Output pointer
);

    logic [ADDR_WIDTH - 1:0] ptr_move; // Temporary storage for pointer

    // Sequential logic for synchronization
    always_ff @(posedge clk_in or posedge reset_in) begin
        if (reset_in) begin
            ptr_move <= 0;         // Reset the pointer
            ptr_out <= 0;
        end
        else begin
            ptr_move <= ptr_in;     // Move pointer to temporary storage
            ptr_out <= ptr_move;    // Assign temporary storage value to output
        end
    end

endmodule




module sync_dff_tb();

    parameter ADDR_WIDTH = 4;

    logic clk_in;                       // Clock input
    logic reset_in;                     // Reset input
    logic [ADDR_WIDTH-1:0] ptr_in;      // Input pointer
    logic [ADDR_WIDTH-1:0] ptr_out;     // Output pointer

    // Instantiate the sync_dff module
    sync_dff #(ADDR_WIDTH) SYNC_DFF (
        .clk_in(clk_in),
        .reset_in(reset_in),
        .ptr_in(ptr_in),
        .ptr_out(ptr_out)
    );

    parameter period = 100;             // Clock period

    // Clock generation
    initial begin
        clk_in = 0;
        forever #(period / 2) clk_in = ~clk_in;
    end
    
    // Test sequence
    initial begin
        reset_in = 1;  @(posedge clk_in); // Initial reset
        repeat(2)      @(posedge clk_in);
        reset_in = 0;

        ptr_in = 2;    @(posedge clk_in);
        ptr_in = 4;    @(posedge clk_in);
        ptr_in = 6;    @(posedge clk_in);
        ptr_in = 8;    @(posedge clk_in);
        ptr_in = 10;   @(posedge clk_in);
        repeat(2)      @(posedge clk_in); // Allow 2 clock cycles for the last entry to stabilize

        reset_in = 1;  @(posedge clk_in); // Reset again
        repeat(2)      @(posedge clk_in);
        reset_in = 0;

        ptr_in = 10;   @(posedge clk_in);
        ptr_in = 8;    @(posedge clk_in);
        ptr_in = 6;    @(posedge clk_in);
        ptr_in = 4;    @(posedge clk_in);
        ptr_in = 2;    @(posedge clk_in);
        repeat(2)      @(posedge clk_in); // Allow 2 clock cycles for the last entry to stabilize

        $stop;
    end

endmodule



