`timescale 1ns/1ps

module tb_part_2;

    reg clk, rst, req_A, req_B;
    reg [7:0] data_A, data_B;

    wire fa, fb, fv;
    wire [7:0] fd;
    wire ra, rb, rv;
    wire [7:0] rd;

    integer i;
    integer fixed_B;
    integer fair_B;

    part_2_fixed u1 (
        .clk(clk), .rst(rst),
        .req_A(req_A), .req_B(req_B),
        .data_A(data_A), .data_B(data_B),
        .grant_A(fa), .grant_B(fb),
        .out_data(fd), .out_valid(fv)
    );

    part_2_fair u2 (
        .clk(clk), .rst(rst),
        .req_A(req_A), .req_B(req_B),
        .data_A(data_A), .data_B(data_B),
        .grant_A(ra), .grant_B(rb),
        .out_data(rd), .out_valid(rv)
    );

    always #5 clk = ~clk;

    task check;
        begin
            #1;

            if ((fa && fb) || (ra && rb)) begin
                $display("FAIL: Both grants are high");
                $finish;
            end

            if (fv !== (fa || fb) || rv !== (ra || rb)) begin
                $display("FAIL: Invalid out_valid");
                $finish;
            end

            if ((fa && fd !== data_A) ||
                (fb && fd !== data_B)) begin
                $display("FAIL: Fixed arbiter data mismatch");
                $finish;
            end

            if ((ra && rd !== data_A) ||
                (rb && rd !== data_B)) begin
                $display("FAIL: Fair arbiter data mismatch");
                $finish;
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        req_A = 0;
        req_B = 0;
        data_A = 8'hAA;
        data_B = 8'h55;
        fixed_B = 0;
        fair_B = 0;

        @(posedge clk);
        #1;
        rst = 0;

        @(negedge clk);
        req_A = 1;
        req_B = 0;
        check();

        if (!fa || !ra) begin
            $display("FAIL: A alone was not granted");
            $finish;
        end

        @(negedge clk);
        req_A = 0;
        req_B = 1;
        check();

        if (!fb || !rb) begin
            $display("FAIL: B alone was not granted");
            $finish;
        end

        @(negedge clk);
        req_A = 0;
        req_B = 0;
        check();

        if (fv || rv) begin
            $display("FAIL: Output valid with no requests");
            $finish;
        end

        @(negedge clk);
        req_A = 1;
        req_B = 1;
        check();

        if (!fa || !rb) begin
            $display("FAIL: Initial tie-break incorrect");
            $finish;
        end

        @(posedge clk);
        #1;

        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk);
            req_A = 1;
            req_B = 1;
            check();

            if (fb)
                fixed_B = fixed_B + 1;

            if (rb)
                fair_B = fair_B + 1;

            @(posedge clk);
            #1;
        end

        if (fixed_B != 0 || fair_B != 10) begin
            $display("FAIL: Fixed B=%0d Fair B=%0d",
                     fixed_B, fair_B);
            $finish;
        end

        $display("Fixed priority B grants = %0d", fixed_B);
        $display("Fair arbiter B grants = %0d", fair_B);
        $display("PASS: All arbiter tests passed.");
        $finish;
    end

    initial begin
        #500;
        $display("FAIL: Testbench timeout");
        $finish;
    end

endmodule