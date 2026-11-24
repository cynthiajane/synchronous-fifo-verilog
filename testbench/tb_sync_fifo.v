
`timescale 1ns/1ps

module tb_sync_fifo;

    reg clk, rst;
    reg wr_en, rd_en;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire full, empty;

    integer errors = 0;
    integer i;

    // Instantiate FIFO
    sync_fifo uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Write task
    task write_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            data_in = value;
            wr_en = 1;
            rd_en = 0;

            @(posedge clk);
            #1;
            wr_en = 0;
        end
    endtask

    // Read and verify task
    task check_read;
        input [7:0] expected;
        begin
            @(negedge clk);
            rd_en = 1;
            wr_en = 0;

            @(posedge clk);
            #1;

            if (data_out !== expected) begin
                $display("FAIL: Expected %d, Got %d",
                         expected, data_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Read %d correctly", data_out);
            end

            rd_en = 0;
        end
    endtask

    // Main test sequence
    initial begin

        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        // Reset
        @(posedge clk);
        #1;
        rst = 0;

        if (empty !== 1'b1) begin
            $display("FAIL: Reset");
            errors = errors + 1;
        end
        else
            $display("PASS: Reset");

        // Write 8 values
        for (i = 1; i <= 8; i = i + 1)
            write_byte(i);

        // Full check
        if (full !== 1'b1) begin
            $display("FAIL: Full detection");
            errors = errors + 1;
        end
        else
            $display("PASS: Full detection");

        // Overflow test
        write_byte(99);

        if (full !== 1'b1) begin
            $display("FAIL: Overflow protection");
            errors = errors + 1;
        end
        else
            $display("PASS: Overflow protection");

        // Read all values
        for (i = 1; i <= 8; i = i + 1)
            check_read(i);

        // Empty check
        if (empty !== 1'b1) begin
            $display("FAIL: Empty detection");
            errors = errors + 1;
        end
        else
            $display("PASS: Empty detection");

        // Underflow test
        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1;
        rd_en = 0;

        if (empty !== 1'b1) begin
            $display("FAIL: Underflow protection");
            errors = errors + 1;
        end
        else
            $display("PASS: Underflow protection");

        // Simultaneous read and write
        write_byte(8'hAA);

        @(negedge clk);
        wr_en = 1;
        rd_en = 1;
        data_in = 8'hBB;

        @(posedge clk);
        #1;

        if (data_out !== 8'hAA) begin
            $display("FAIL: Simultaneous operation");
            errors = errors + 1;
        end
        else
            $display("PASS: Simultaneous read/write");

        wr_en = 0;
        rd_en = 0;

        check_read(8'hBB);

        // Final report
        if (errors == 0)
            $display("\nALL TESTS PASSED!");
        else
            $display("\nTESTS FAILED: %d errors", errors);

        $finish;
    end

endmodule
