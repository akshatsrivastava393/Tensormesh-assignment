module part_2_fair (
    input wire clk,
    input wire rst,
    input wire req_A,
    input wire req_B,
    input wire [7:0] data_A,
    input wire [7:0] data_B,
    output reg grant_A,
    output reg grant_B,
    output reg [7:0] out_data,
    output reg out_valid
);

    reg last_B;
    reg next_B;

    always @(*) begin
        grant_A = 0;
        grant_B = 0;
        out_data = 0;
        out_valid = 0;
        next_B = last_B;

        if (req_A && req_B) begin
            if (last_B) begin
                grant_A = 1;
                out_data = data_A;
                next_B = 0;
            end
            else begin
                grant_B = 1;
                out_data = data_B;
                next_B = 1;
            end
            out_valid = 1;
        end
        else if (req_A) begin
            grant_A = 1;
            out_data = data_A;
            out_valid = 1;
            next_B = 0;
        end
        else if (req_B) begin
            grant_B = 1;
            out_data = data_B;
            out_valid = 1;
            next_B = 1;
        end
    end

    always @(posedge clk) begin
        if (rst)
            last_B <= 1;
        else if (out_valid)
            last_B <= next_B;
    end

endmodule