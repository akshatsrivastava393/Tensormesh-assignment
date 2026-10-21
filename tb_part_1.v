`timescale 1ns/1ps

module tb_part_1;

    reg clk, rst, start, stop;
    wire [1:0] state;
    wire [3:0] count;

    parameter S0 = 2'b00,
               S1 = 2'b01,
               S2 = 2'b10;

    integer i;
    reg [3:0] expected [0:6];

    part_1 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .stop(stop),
        .state(state),
        .count(count)
    );

    always #5 clk = ~clk;

    task check;
        input [1:0] exp_state;
        input [3:0] exp_count;
        begin
            if (state !== exp_state || count !== exp_count) begin
                $display("FAIL: state=%b count=%d, expected state=%b count=%d",
                         state, count, exp_state, exp_count);
                $finish;
            end

            if (state == S1 &&
                !(count == 2 || count == 3 || count == 5 ||
                  count == 7 || count == 11 || count == 13)) begin
                $display("FAIL: Non-prime count during ACTIVE");
                $finish;
            end
        end
    endtask

    task apply_inputs;
        input s;
        input t;
        begin
            @(negedge clk);
            start = s;
            stop = t;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        stop = 0;

        expected[0] = 2;
        expected[1] = 3;
        expected[2] = 5;
        expected[3] = 7;
        expected[4] = 11;
        expected[5] = 13;
        expected[6] = 2;

        @(posedge clk);
        #1;
        check(S0, 0);
        rst = 0;

        apply_inputs(0, 0);
        check(S0, 0);

        apply_inputs(1, 0);
        check(S1, 2);

        for (i = 1; i <= 6; i = i + 1) begin
            apply_inputs(0, 0);
            check(S1, expected[i]);
        end

        apply_inputs(0, 1);
        check(S2, 2);

        apply_inputs(0, 0);
        check(S0, 2);

        apply_inputs(0, 0);
        check(S0, 2);

        apply_inputs(1, 0);
        check(S1, 2);

        apply_inputs(1, 1);
        check(S2, 2);

        apply_inputs(0, 0);
        check(S0, 2);

        $display("PASS: All prime counter FSM tests passed.");
        $finish;
    end

    initial begin
        #500;
        $display("FAIL: Testbench timeout.");
        $finish;
    end

endmodule