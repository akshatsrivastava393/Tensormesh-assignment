
`timescale 1ns/1ps

module tb_part3;

    reg clk;
    reg rst;

    reg [1:0] dens_N;
    reg [1:0] dens_E;
    reg [1:0] dens_S;
    reg [1:0] dens_W;

    wire [3:0] green;
    wire [3:0] yellow;

    integer errors;
    integer tests;
    integer seed;
    integer i;
    integer j;
    integer change_after;
    integer random_value;

    integer green_count;
    integer yellow_count;
    integer previous_green;
    integer current_green;
    integer previous_yellow;
    integer current_yellow;
    integer saw_all_red;

    integer phase_number;
    integer last_phase [0:3];
    integer direction;
    integer gap;

   
    part3 dut (
        .clk(clk),
        .rst(rst),
        .dens_N(dens_N),
        .dens_E(dens_E),
        .dens_S(dens_S),
        .dens_W(dens_W),
        .green(green),
        .yellow(yellow)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    
    initial begin
        errors = 0;
        tests = 0;

        green_count = 0;
        yellow_count = 0;

        previous_green = 0;
        current_green = 0;
        previous_yellow = 0;
        current_yellow = 0;

        saw_all_red = 1;
        phase_number = 0;

        for (i = 0; i < 4; i = i + 1)
            last_phase[i] = 0;
    end

    always @(negedge clk) begin
        if (!rst) begin
            tests = tests + 1;

            
            if ((green == 4'b0000) ||
                ((green & (green - 1'b1)) == 0)) begin
                
            end
            else begin
                $display("FAIL: Multiple green lights at time %0t", $time);
                errors = errors + 1;
            end

            if ((yellow != 4'b0000) &&
                ((yellow & (yellow - 1'b1)) != 0)) begin
                $display("FAIL: Multiple yellow lights at time %0t", $time);
                errors = errors + 1;
            end

            if ((green != 4'b0000) &&
                (yellow != 4'b0000)) begin
                $display("FAIL: Green and yellow overlap at time %0t", $time);
                errors = errors + 1;
            end

            
            if (green != 4'b0000) begin
                if (previous_green == 0) begin
                    if (green_count != 0) begin
                        if ((green_count != 4) &&
                            (green_count != 6) &&
                            (green_count != 8) &&
                            (green_count != 10)) begin
                            $display("FAIL: Illegal green duration = %0d",
                                     green_count);
                            errors = errors + 1;
                        end
                    end

                    current_green = 1;
                    green_count = 1;

                  
                    direction = 0;
                    while ((direction < 4) &&
                           !green[direction])
                        direction = direction + 1;

                    phase_number = phase_number + 1;

                    if (direction < 4) begin
                        gap = phase_number - last_phase[direction] - 1;

                        if ((last_phase[direction] != 0) && (gap > 5)) begin
                            $display(
                                "FAIL: Starvation bound exceeded for direction %0d; skipped %0d phases",
                                direction, gap
                            );
                            errors = errors + 1;
                        end

                        last_phase[direction] = phase_number;
                    end

                    if (!saw_all_red &&
                        (previous_green != 0) &&
                        (green != previous_green)) begin
                        $display("FAIL: Different greens without all-red separation");
                        errors = errors + 1;
                    end

                    saw_all_red = 0;
                end
                else begin
                    green_count = green_count + 1;

                    if (green != previous_green) begin
                        $display("FAIL: Green direction changed without a red phase");
                        errors = errors + 1;
                    end
                end
            end
            else begin
                if (previous_green != 0) begin
                    if ((green_count != 4) &&
                        (green_count != 6) &&
                        (green_count != 8) &&
                        (green_count != 10)) begin
                        $display("FAIL: Green lasted %0d clocks", green_count);
                        errors = errors + 1;
                    end

                    green_count = 0;
                end

            
                if (yellow == 4'b0000)
                    saw_all_red = 1;
            end

            
            if (yellow != 4'b0000) begin
                if (previous_yellow == 0)
                    yellow_count = 1;
                else
                    yellow_count = yellow_count + 1;
            end
            else if (previous_yellow != 0) begin
                if (yellow_count != 2) begin
                    $display("FAIL: Yellow lasted %0d clocks",
                             yellow_count);
                    errors = errors + 1;
                end

                yellow_count = 0;
            end

            previous_green = green;
            previous_yellow = yellow;
        end
        else begin
            previous_green = 0;
            previous_yellow = 0;
            green_count = 0;
            yellow_count = 0;
            saw_all_red = 1;
        end
    end

  

    initial begin
        rst = 1'b1;

        dens_N = 0;
        dens_E = 0;
        dens_S = 0;
        dens_W = 0;

        seed = 32'h13579BDF;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        $display("\nTEST 1: All directions have density 2");

        dens_N = 2;
        dens_E = 2;
        dens_S = 2;
        dens_W = 2;

        repeat (180) @(negedge clk);


        $display("\nTEST 2: North heavy, others light");

        dens_N = 3;
        dens_E = 1;
        dens_S = 1;
        dens_W = 1;

        repeat (220) @(negedge clk);

        $display("\nTEST 3: Scripted North-to-East traffic shift");

        dens_N = 3;
        dens_E = 0;
        dens_S = 1;
        dens_W = 1;

        repeat (80) @(negedge clk);

        dens_N = 0;
        dens_E = 3;
        dens_S = 1;
        dens_W = 1;

        repeat (120) @(negedge clk);

        
        $display("\nTEST 4: Random traffic changes");

        for (i = 0; i < 300; i = i + 1) begin
            random_value = $random(seed);

            dens_N = random_value[1:0];
            dens_E = random_value[3:2];
            dens_S = random_value[5:4];
            dens_W = random_value[7:6];

            random_value = $random(seed);
            change_after = (random_value & 3) + 1;

            repeat (change_after) @(negedge clk);
        end

        // Allow the last active phase to finish.
        repeat (15) @(negedge clk);

        // Final result
       
        $display("Simulation checks: %0d", tests);
        $display("Total errors:      %0d", errors);

        if (errors == 0)
            $display("PASS: All monitored checks passed.");
        else
            $display("FAIL: One or more checks failed.");

        $display("==================================\n");

        $finish;
    end

endmodule
