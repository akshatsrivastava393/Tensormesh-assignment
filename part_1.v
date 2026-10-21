module part_1 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire stop,
    output reg [1:0] state,
    output reg [3:0] count
);

    parameter S0 = 2'b00,  // IDLE
              S1 = 2'b01,  // ACTIVE
              S2 = 2'b10;  // DONE

    reg [1:0] next_state;

    // declaring the state registers like how reset will work
    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // writing the next state logic using blocking statements 
    always @(*) begin
        case (state)
            S0: begin
                if (start)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if (stop)
                    next_state = S2;
                else
                    next_state = S1;
            end

            S2: begin
                next_state = S0;
            end

            default: next_state = S0;
        endcase
    end

    // writing logic for count and how it will inc when it remains in ACTIVE state using case statemenst
    always @(posedge clk) begin
        if (rst)
            count <= 4'd0;
        else begin
            case (state)
                S0: begin
                    if (start)
                        count <= 4'd2;
                    //here else statement is not there so it will form a latch means it will hold the value of count 
                end

                S1: begin
                    if (!stop) begin
                        case (count)
                            4'd2:  count <= 4'd3;
                            4'd3:  count <= 4'd5;
                            4'd5:  count <= 4'd7;
                            4'd7:  count <= 4'd11;
                            4'd11: count <= 4'd13;
                            4'd13: count <= 4'd2;
                            default: count <= 4'd2;
                        endcase
                    end
                    
                end

                S2: begin
                    
                end

                default: count <= 4'd0;
            endcase
        end
    end

endmodule