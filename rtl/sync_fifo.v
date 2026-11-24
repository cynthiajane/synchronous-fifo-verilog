
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input wire clk,
    input wire rst,

    input wire wr_en,
    input wire rd_en,

    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,

    output wire full,
    output wire empty
);

    // FIFO depth = 2^ADDR_WIDTH
    localparam DEPTH = (1 << ADDR_WIDTH);

    // Memory storage
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read and write pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Tracks the number of stored entries
    reg [ADDR_WIDTH:0] count;

    // Status flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // FIFO operations
    always @(posedge clk) begin

        if (rst) begin
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            data_out <= 0;
        end

        else begin

            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Read operation
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Update occupancy counter
            case ({wr_en && !full, rd_en && !empty})

                2'b10: count <= count + 1'b1;

                2'b01: count <= count - 1'b1;

                default: count <= count;

            endcase

        end
    end

endmodule
