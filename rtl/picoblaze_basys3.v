`timescale 1ns/1ps
module picoblaze_basys3 (
    input wire clk,
    input wire [15:0] sw,
    input wire btnC, btnU, btnD, btnL, btnR,
    output reg [15:0] led,
    output wire [6:0] seg,
    output wire dp,
    output wire [3:0] an,
    input wire RsRx,
    output wire RsTx
);
    // Basys 3 has no separate user CPU_RESETN input. Configuration initializes
    // this counter; hold reset for 65535 clocks after configuration.
    reg [15:0] powerup = 0;
    wire por = ~(&powerup);
    always @(posedge clk) if (por) powerup <= powerup + 1'b1;

    wire [4:0] buttons_clean;
    button_filter buttons (
        .clk(clk), .reset(por),
        .buttons_async({btnU,btnD,btnL,btnR,btnC}),
        .buttons_clean(buttons_clean)
    );
    // All five buttons remain readable. U+D together provide user reset.
    wire user_reset = buttons_clean[4] & buttons_clean[3];
    wire rdl;
    (* ASYNC_REG = "TRUE" *) reg [1:0] loader_reset_sync = 2'b11;
    // Asynchronous assertion, synchronous release of loader reset.
    always @(posedge clk or posedge rdl)
        if (rdl) loader_reset_sync <= 2'b11;
        else loader_reset_sync <= {loader_reset_sync[0],1'b0};
    wire reset = por | user_reset | loader_reset_sync[1];

    (* ASYNC_REG = "TRUE" *) reg [15:0] sw_sync1, sw_sync2;
    always @(posedge clk) begin
        sw_sync1 <= sw;
        sw_sync2 <= sw_sync1;
    end

    wire [11:0] address;
    wire [17:0] instruction;
    wire bram_enable, write_strobe, read_strobe, k_write_strobe;
    wire [7:0] port_id, out_port;
    reg [7:0] in_port;
    kcpsm6 #(.interrupt_vector(12'h3FF), .scratch_pad_memory_size(64),
             .hwbuild(8'hB3)) processor (
        .address(address), .instruction(instruction), .bram_enable(bram_enable),
        .port_id(port_id), .write_strobe(write_strobe),
        .k_write_strobe(k_write_strobe), .out_port(out_port),
        .read_strobe(read_strobe), .in_port(in_port),
        .interrupt(1'b0), .interrupt_ack(), .reset(reset), .sleep(1'b0), .clk(clk)
    );
    demo #(.C_FAMILY("7S"), .C_RAM_SIZE_KWORDS(1),
           .C_JTAG_LOADER_ENABLE(1)) program_memory (
        .rdl(rdl), .enable(bram_enable), .address(address),
        .instruction(instruction), .clk(clk)
    );

    wire [7:0] rx_data;
    wire rx_valid, tx_ready;
    uart_115200 uart (
        .clk(clk), .reset(reset), .rx(RsRx), .tx(RsTx),
        .tx_data(out_port),
        .tx_start(write_strobe && port_id==8'h30 && tx_ready && !reset),
        .tx_ready(tx_ready), .rx_data(rx_data), .rx_valid(rx_valid),
        .rx_read(read_strobe && port_id==8'h30)
    );
    // Registered input mux follows the KCPSM6 input-port timing convention.
    always @(posedge clk) begin
        case (port_id)
            8'h00: in_port <= sw_sync2[7:0];
            8'h01: in_port <= sw_sync2[15:8];
            8'h02: in_port <= {3'b0,buttons_clean};
            8'h30: in_port <= rx_data;
            8'h31: in_port <= {6'b0,tx_ready,rx_valid};
            default: in_port <= 0;
        endcase
    end
    reg [31:0] digits;
    always @(posedge clk) begin
        if (reset) begin led <= 0; digits <= 0; end
        else if (write_strobe) begin
            case (port_id)
                8'h10: led[7:0] <= out_port;
                8'h11: led[15:8] <= out_port;
                8'h20: digits[7:0] <= out_port;
                8'h21: digits[15:8] <= out_port;
                8'h22: digits[23:16] <= out_port;
                8'h23: digits[31:24] <= out_port;
                default: begin end
            endcase
        end
    end
    seven_segment_scan display (.clk(clk), .reset(reset), .digits(digits),
        .seg(seg), .dp(dp), .an(an));
endmodule
