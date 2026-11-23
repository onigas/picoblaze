`timescale 1ns/1ps
module tb_basys3;
    reg clk=0;
    always #5 clk=~clk;
    reg [15:0] sw=16'hA53C;
    reg btnC=0,btnU=0,btnD=0,btnL=0,btnR=0;
    wire [15:0] led;
    wire [6:0] seg;
    wire dp;
    wire [3:0] an;
    reg rx=1;
    wire tx;
    picoblaze_basys3 dut(clk,sw,btnC,btnU,btnD,btnL,btnR,led,seg,dp,an,rx,tx);
    // Accelerate only the mechanical debounce for this simulation.
    defparam dut.buttons.COUNT_MAX=100;
    localparam BIT_NS=8680;
    integer i;
    reg [7:0] received;
    task send_byte(input [7:0] value);
        integer b;
        begin
            rx=0; #(BIT_NS);
            for(b=0;b<8;b=b+1) begin rx=value[b]; #(BIT_NS); end
            rx=1; #(BIT_NS);
        end
    endtask
    task receive_byte(input [7:0] expected);
        integer b;
        begin
            @(negedge tx); #(BIT_NS+BIT_NS/2);
            for(b=0;b<8;b=b+1) begin received[b]=tx; #(BIT_NS); end
            if(tx!==1 || received!==expected) $fatal(1,"UART echo mismatch");
        end
    endtask
    task check_echo(input [7:0] value);
        begin fork send_byte(value); receive_byte(value); join end
    endtask
    initial begin
        #750000;
        if(led!==sw) $fatal(1,"Initial switch-to-LED map");
        if(dut.digits!==32'h0A05030C) $fatal(1,"Four digit data order");
        // Each switch independently exercises both byte ports.
        for(i=0;i<16;i=i+1) begin
            sw=16'h1<<i; #2000;
            if(led!==sw) $fatal(1,"Switch bit %0d",i);
        end
        sw=16'hA53C; #2000;
        // Test actual active-low segments for digit 0 = C.
        wait(an==4'b1110); #1;
        if(seg!==7'b1000110) $fatal(1,"Segment A..G wiring");
        btnC=1; #5000;
        if(dut.digits[7]!==1) $fatal(1,"Center button decimal point");
        btnC=0; btnR=1; #5000;
        if(dut.digits[15]!==1 || dut.digits[7]!==0) $fatal(1,"Right button");
        btnR=0; btnL=1; #5000;
        if(dut.digits[23]!==1) $fatal(1,"Left button");
        btnL=0; btnD=1; #5000;
        if(dut.digits[31]!==1) $fatal(1,"Down button");
        btnD=0; btnU=1; #5000;
        if(dut.buttons_clean!==5'b10000 || dut.digits[31]!==1) $fatal(1,"Up button");
        btnU=0; #5000;
        check_echo(8'h55); check_echo(8'h00); check_echo(8'hFF); check_echo(8'hA6);
        btnU=1; btnD=1; #5000;
        if(led!==0 || tx!==1 || an!==4'hF) $fatal(1,"User reset");
        btnU=0; btnD=0; #5000;
        if(led!==sw) $fatal(1,"Restart after user reset");
        // Verify reset wiring, not the external JTAG transport protocol.
        force dut.rdl=1'b1; #1000;
        if(led!==0) $fatal(1,"Reset during program load");
        release dut.rdl; #5000;
        if(led!==sw) $fatal(1,"Restart after loader reset");
        $display("SIM_PASS: CPU, ROM, switches, LEDs, digits, buttons, UART and resets");
        $finish;
    end
    initial begin #5000000; $fatal(1,"Simulation timeout"); end
endmodule
