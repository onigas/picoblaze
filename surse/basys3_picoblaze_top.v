module basys3_picoblaze_top (
    input  wire       clk,
    input  wire [7:0] sw,
    output reg  [7:0] led
);

    // PicoBlaze KCPSM6
    wire [11:0] address;
    wire [17:0] instruction;
    wire        bram_enable;

    wire [7:0]  port_id;
    wire [7:0]  out_port;
    wire [7:0]  in_port;

    wire        write_strobe;
    wire        k_write_strobe;
    wire        read_strobe;
    wire        interrupt_ack;
    wire        reset;

    // Procesor
    kcpsm6 #(
        .interrupt_vector(12'h3FF),
        .scratch_pad_memory_size(64),
        .hwbuild(8'h00)
    ) processor (
        .address(address),
        .instruction(instruction),
        .bram_enable(bram_enable),
        .port_id(port_id),
        .write_strobe(write_strobe),
        .k_write_strobe(k_write_strobe),
        .out_port(out_port),
        .read_strobe(read_strobe),
        .in_port(in_port),
        .interrupt(1'b0),
        .interrupt_ack(interrupt_ack),
        .reset(reset),
        .sleep(1'b0),
        .clk(clk)
    );

    // Memorie program cu JTAG Loader
    sw_led #(
        .C_FAMILY("7S"),
        .C_RAM_SIZE_KWORDS(1),
        .C_JTAG_LOADER_ENABLE(1)
    ) program_rom (
        .address(address),
        .instruction(instruction),
        .enable(bram_enable),
        .rdl(reset),
        .clk(clk)
    );

    // Port intrare 00h: switch-uri SW[7:0]
    assign in_port = sw;

    // Port iesire 01h: LED[7:0]
    always @(posedge clk) begin
        if (write_strobe && (port_id == 8'h01))
            led <= out_port;
    end

endmodule
