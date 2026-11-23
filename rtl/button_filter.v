`timescale 1ns/1ps
module button_filter #(parameter integer COUNT_MAX = 1_000_000) (
    input wire clk,
    input wire reset,
    input wire [4:0] buttons_async,
    output reg [4:0] buttons_clean
);
    (* ASYNC_REG = "TRUE" *) reg [4:0] sync1, sync2;
    reg [19:0] count [0:4];
    integer n;
    always @(posedge clk) begin
        if (reset) begin
            sync1 <= 0; sync2 <= 0; buttons_clean <= 0;
            for (n = 0; n < 5; n = n + 1) count[n] <= 0;
        end else begin
            sync1 <= buttons_async;
            sync2 <= sync1;
            for (n = 0; n < 5; n = n + 1) begin
                if (sync2[n] == buttons_clean[n]) count[n] <= 0;
                else if (count[n] >= COUNT_MAX - 1) begin
                    buttons_clean[n] <= sync2[n];
                    count[n] <= 0;
                end else count[n] <= count[n] + 1'b1;
            end
        end
    end
endmodule
