`timescale 1ns/1ps
module uart_115200 (
    input wire clk, input wire reset,
    input wire rx, output reg tx,
    input wire [7:0] tx_data, input wire tx_start, output wire tx_ready,
    output reg [7:0] rx_data, output reg rx_valid, input wire rx_read
);
    localparam integer DIVISOR = 868; // 100 MHz / 115200 baud, rounded
    reg [9:0] tx_shift;
    reg [3:0] tx_bit;
    reg [9:0] tx_count;
    reg tx_busy;
    assign tx_ready = ~tx_busy;

    (* ASYNC_REG = "TRUE" *) reg rx_meta, rx_sync;
    reg [3:0] rx_state;
    reg [9:0] rx_count;
    reg [2:0] rx_bit;
    reg [7:0] rx_shift;

    always @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
        if (reset) begin
            rx_meta <= 1; rx_sync <= 1;
            tx <= 1'b1; tx_shift <= 10'h3FF; tx_bit <= 0;
            tx_count <= 0; tx_busy <= 0;
            rx_state <= 0; rx_count <= 0; rx_bit <= 0;
            rx_shift <= 0; rx_data <= 0; rx_valid <= 0;
        end else begin
            if (rx_read) rx_valid <= 0;
            if (tx_start && !tx_busy) begin
                tx_shift <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1; tx_count <= 0; tx_bit <= 0; tx <= 0;
            end else if (tx_busy) begin
                if (tx_count == DIVISOR-1) begin
                    tx_count <= 0;
                    if (tx_bit == 9) begin tx_busy <= 0; tx <= 1; end
                    else begin
                        tx_bit <= tx_bit + 1'b1;
                        tx_shift <= {1'b1, tx_shift[9:1]};
                        tx <= tx_shift[1];
                    end
                end else tx_count <= tx_count + 1'b1;
            end

            case (rx_state)
                0: if (!rx_sync) begin rx_state <= 1; rx_count <= DIVISOR/2; end
                1: if (rx_count == 0) begin
                       if (!rx_sync) begin rx_state <= 2; rx_count <= DIVISOR-1; rx_bit <= 0; end
                       else rx_state <= 0;
                   end else rx_count <= rx_count - 1'b1;
                2: if (rx_count == 0) begin
                       rx_shift[rx_bit] <= rx_sync;
                       rx_count <= DIVISOR-1;
                       if (rx_bit == 7) rx_state <= 3;
                       else rx_bit <= rx_bit + 1'b1;
                   end else rx_count <= rx_count - 1'b1;
                3: if (rx_count == 0) begin
                       if (rx_sync) begin rx_data <= rx_shift; rx_valid <= 1; end
                       rx_state <= 0;
                   end else rx_count <= rx_count - 1'b1;
                default: rx_state <= 0;
            endcase
        end
    end
endmodule
