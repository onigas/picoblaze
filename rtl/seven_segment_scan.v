`timescale 1ns/1ps
module seven_segment_scan (
    input wire clk,
    input wire reset,
    input wire [31:0] digits,
    output wire [6:0] seg,
    output reg dp,
    output reg [3:0] an
);
    reg [6:0] decoded;
    assign seg = {decoded[0],decoded[1],decoded[2],decoded[3],decoded[4],decoded[5],decoded[6]};
    reg [16:0] divider;
    reg [1:0] index;
    reg [7:0] digit_data;
    wire [3:0] nibble = digit_data[3:0];

    always @(posedge clk) begin
        if (reset) begin divider <= 0; index <= 0; end
        else if (divider == 17'd12499) begin
            divider <= 0;
            index <= index + 1'b1;
        end else divider <= divider + 1'b1;
    end

    always @* begin
        digit_data = digits[index*8 +: 8];
        an = (reset || divider < 16) ? 4'b1111 : ~(4'b0001 << index);
        dp = ~digit_data[7];
        // Segment order is CA..CG. The display is active-low/common-anode.
        case (nibble)
            4'h0: decoded=7'b0000001; 4'h1: decoded=7'b1001111;
            4'h2: decoded=7'b0010010; 4'h3: decoded=7'b0000110;
            4'h4: decoded=7'b1001100; 4'h5: decoded=7'b0100100;
            4'h6: decoded=7'b0100000; 4'h7: decoded=7'b0001111;
            4'h8: decoded=7'b0000000; 4'h9: decoded=7'b0000100;
            4'hA: decoded=7'b0001000; 4'hB: decoded=7'b1100000;
            4'hC: decoded=7'b0110001; 4'hD: decoded=7'b1000010;
            4'hE: decoded=7'b0110000; 4'hF: decoded=7'b0111000;
            default: decoded=7'b1111111;
        endcase
    end
endmodule
