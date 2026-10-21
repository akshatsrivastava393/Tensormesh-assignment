
module part3 (
    input wire clk,
    input wire rst,

    input wire [1:0] dens_N,
    input wire [1:0] dens_E,
    input wire [1:0] dens_S,
    input wire [1:0] dens_W,

    // Output order: {W, E, S, N}
    // bit 0 = N, bit 1 = E, bit 2 = S, bit 3 = W
    output reg [3:0] green,
    output reg [3:0] yellow
);

    // FSM states
    localparam SELECT = 2'b00;
    localparam GREEN  = 2'b01;
    localparam YELLOW = 2'b10;

    // Direction encoding
    localparam N = 2'd0;
    localparam E = 2'd1;
    localparam S = 2'd2;
    localparam W = 2'd3;

    reg [1:0] state;
    reg [1:0] chosen;
    reg [1:0] last_served;

    // Combinational selection is separate from registered chosen.
    reg [1:0] selected_direction;

    reg [3:0] green_length;
    reg [3:0] timer;

    // Saturating wait counters
    reg [2:0] wait_N;
    reg [2:0] wait_E;
    reg [2:0] wait_S;
    reg [2:0] wait_W;

    // Internal arrays: index 0=N, 1=E, 2=S, 3=W
    reg [1:0] density [0:3];
    reg [2:0] wait_count [0:3];

    reg [3:0] candidates;
    reg forced;
    reg found;

    reg [2:0] max_wait;
    reg [1:0] max_density;

    integer i;
    integer k;
    integer idx;

    // ==================================================
    // COMBINATIONAL TRAFFIC SELECTOR
    // ==================================================

    always @(*) begin
        density[0] = dens_N;
        density[1] = dens_E;
        density[2] = dens_S;
        density[3] = dens_W;

        wait_count[0] = wait_N;
        wait_count[1] = wait_E;
        wait_count[2] = wait_S;
        wait_count[3] = wait_W;

        candidates = 4'b0000;
        forced = 1'b0;
        found = 1'b0;
        max_wait = 3'd0;
        max_density = 2'd0;
        selected_direction = N;
        idx = 0;

        // Priority 1: starvation prevention.
        // A road is forced into consideration after
        // its wait counter reaches 3.
        for (i = 0; i < 4; i = i + 1) begin
            if (wait_count[i] >= 3'd3)
                forced = 1'b1;
        end

        if (forced) begin
            // Find the greatest wait count among
            // directions whose counters are >= 3.
            for (i = 0; i < 4; i = i + 1) begin
                if ((wait_count[i] >= 3'd3) &&
                    (wait_count[i] > max_wait))
                    max_wait = wait_count[i];
            end

            // Mark directions tied at that maximum.
            for (i = 0; i < 4; i = i + 1) begin
                if ((wait_count[i] >= 3'd3) &&
                    (wait_count[i] == max_wait))
                    candidates[i] = 1'b1;
            end
        end
        else begin
            // Priority 2: highest traffic density.
            for (i = 0; i < 4; i = i + 1) begin
                if (density[i] > max_density)
                    max_density = density[i];
            end

            // Include every direction tied for the
            // highest density, including all-zero traffic.
            for (i = 0; i < 4; i = i + 1) begin
                if (density[i] == max_density)
                    candidates[i] = 1'b1;
            end
        end

        // Priority 3: circular tie-break after last served.
        // Order: N -> E -> S -> W -> N.
        for (k = 1; k <= 4; k = k + 1) begin
            idx = (last_served + k) % 4;

            if (!found && candidates[idx]) begin
                selected_direction = idx;
                found = 1'b1;
            end
        end
    end

    // ==================================================
    // FSM, TIMER AND WAIT COUNTERS
    // ==================================================

    always @(posedge clk) begin
        if (rst) begin
            state <= SELECT;
            chosen <= N;

            // Makes N the first direction in an initial tie.
            last_served <= W;

            green_length <= 4'd4;
            timer <= 4'd0;

            wait_N <= 3'd0;
            wait_E <= 3'd0;
            wait_S <= 3'd0;
            wait_W <= 3'd0;
        end
        else begin
            case (state)

                // --------------------------------------
                // SELECT: all directions red for one tick
                // --------------------------------------
                SELECT: begin
                    // Latch the chosen direction.
                    chosen <= selected_direction;
                    last_served <= selected_direction;

                    // Green duration = 4 + 2 * density.
                    // Density is sampled at this selection.
                    green_length <= 4'd4 +
                        {density[selected_direction], 1'b0};

                    timer <= 4'd0;

                    // Reset the selected road's wait counter.
                    // Increment the other counters, saturating
                    // at 7 to avoid overflow.
                    if (selected_direction == N)
                        wait_N <= 3'd0;
                    else if (wait_N < 3'd7)
                        wait_N <= wait_N + 1'b1;

                    if (selected_direction == E)
                        wait_E <= 3'd0;
                    else if (wait_E < 3'd7)
                        wait_E <= wait_E + 1'b1;

                    if (selected_direction == S)
                        wait_S <= 3'd0;
                    else if (wait_S < 3'd7)
                        wait_S <= wait_S + 1'b1;

                    if (selected_direction == W)
                        wait_W <= 3'd0;
                    else if (wait_W < 3'd7)
                        wait_W <= wait_W + 1'b1;

                    state <= GREEN;
                end

                // --------------------------------------
                // GREEN: exactly 4, 6, 8 or 10 ticks
                // --------------------------------------
                GREEN: begin
                    if (timer >= green_length - 1'b1) begin
                        timer <= 4'd0;
                        state <= YELLOW;
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                // --------------------------------------
                // YELLOW: exactly 2 ticks
                // --------------------------------------
                YELLOW: begin
                    if (timer == 4'd1) begin
                        timer <= 4'd0;
                        state <= SELECT;
                    end
                    else begin
                        timer <= timer + 1'b1;
                    end
                end

                default: begin
                    state <= SELECT;
                    timer <= 4'd0;
                end

            endcase
        end
    end

    // ==================================================
    // OUTPUT DECODING
    // ==================================================

    always @(*) begin
        green  = 4'b0000;
        yellow = 4'b0000;

        case (state)
            GREEN: begin
                green[chosen] = 1'b1;
            end

            YELLOW: begin
                yellow[chosen] = 1'b1;
            end

            // SELECT: all-red phase
            default: begin
                green  = 4'b0000;
                yellow = 4'b0000;
            end
        endcase
    end

endmodule
