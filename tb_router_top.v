// ============================================================
// Module : tb_router_top
// Description : Testbench for 1x3 Router Top Level
// ============================================================

`timescale 1ns/1ps

module tb_router_top;

    reg        clock;
    reg        resetn;
    reg        pkt_valid;
    reg  [7:0] data_in;
    reg        read_enb_0, read_enb_1, read_enb_2;

    wire [7:0] data_out_0, data_out_1, data_out_2;
    wire       valid_out_0, valid_out_1, valid_out_2;
    wire       err, busy;

    // Clock: 10ns period
    initial clock = 0;
    always #5 clock = ~clock;

    // DUT
    router_top dut (
        .clock      (clock),      .resetn     (resetn),
        .pkt_valid  (pkt_valid),  .data_in    (data_in),
        .read_enb_0 (read_enb_0), .read_enb_1 (read_enb_1),
        .read_enb_2 (read_enb_2),
        .data_out_0 (data_out_0), .data_out_1 (data_out_1),
        .data_out_2 (data_out_2),
        .valid_out_0(valid_out_0),.valid_out_1(valid_out_1),
        .valid_out_2(valid_out_2),
        .err(err), .busy(busy)
    );

    // -------------------------------------------------------
    // Task: Send a packet to given address
    // -------------------------------------------------------
    task send_packet;
        input [1:0] addr;
        input [5:0] payload_len;
        input [7:0] base_data;
        integer i;
        reg [7:0] hdr, parity_calc;
        begin
            hdr         = {payload_len, addr};
            parity_calc = hdr;

            // Header
            @(negedge clock);
            pkt_valid = 1'b1;
            data_in   = hdr;
            @(negedge clock);

            // Payload
            for (i = 0; i < payload_len; i = i + 1) begin
                data_in     = base_data + i;
                parity_calc = parity_calc ^ (base_data + i);
                @(negedge clock);
            end

            // De-assert valid, send parity
            pkt_valid = 1'b0;
            data_in   = parity_calc;
            @(negedge clock);
            data_in = 8'bx;
        end
    endtask

    // -------------------------------------------------------
    // Task: Drain a port
    // -------------------------------------------------------
    task drain_port;
        input [1:0] port;
        integer k;
        begin
            for (k = 0; k < 20; k = k + 1) begin
                @(negedge clock);
                case (port)
                    2'd0: read_enb_0 = 1'b1;
                    2'd1: read_enb_1 = 1'b1;
                    2'd2: read_enb_2 = 1'b1;
                endcase
            end
            @(negedge clock);
            read_enb_0 = 0; read_enb_1 = 0; read_enb_2 = 0;
        end
    endtask

    // -------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------
    initial begin
        // Initialise
        resetn     = 1'b0;
        pkt_valid  = 1'b0;
        data_in    = 8'b0;
        read_enb_0 = 1'b0;
        read_enb_1 = 1'b0;
        read_enb_2 = 1'b0;

        // Apply reset for 3 cycles
        repeat(3) @(negedge clock);
        resetn = 1'b1;
        repeat(2) @(negedge clock);

        // --------------------------------------------------
        // Test 1: Send packet to Port 0 (addr = 2'b00)
        // --------------------------------------------------
        $display("=== TEST 1: Packet to Port 0 ===");
        send_packet(2'b00, 6'd4, 8'hAA);
        repeat(2) @(negedge clock);
        drain_port(2'd0);
        $display("Port 0 data_out = %h, err = %b", data_out_0, err);

        // --------------------------------------------------
        // Test 2: Send packet to Port 1 (addr = 2'b01)
        // --------------------------------------------------
        $display("=== TEST 2: Packet to Port 1 ===");
        send_packet(2'b01, 6'd3, 8'hBB);
        repeat(2) @(negedge clock);
        drain_port(2'd1);
        $display("Port 1 data_out = %h, err = %b", data_out_1, err);

        // --------------------------------------------------
        // Test 3: Send packet to Port 2 (addr = 2'b10)
        // --------------------------------------------------
        $display("=== TEST 3: Packet to Port 2 ===");
        send_packet(2'b10, 6'd5, 8'hCC);
        repeat(2) @(negedge clock);
        drain_port(2'd2);
        $display("Port 2 data_out = %h, err = %b", data_out_2, err);

        // --------------------------------------------------
        // Test 4: Parity Error Injection
        // --------------------------------------------------
        $display("=== TEST 4: Parity Error Injection ===");
        @(negedge clock); pkt_valid = 1; data_in = 8'b00001000; // header: len=2, addr=0
        @(negedge clock); data_in = 8'hDE;
        @(negedge clock); data_in = 8'hAD; pkt_valid = 0;
        @(negedge clock); data_in = 8'hFF; // wrong parity
        @(negedge clock); data_in = 8'bx;
        repeat(3) @(negedge clock);
        $display("Parity error flag = %b (expect 1)", err);

        repeat(5) @(negedge clock);
        $display("=== ALL TESTS DONE ===");
        $finish;
    end

    // -------------------------------------------------------
    // Monitor
    // -------------------------------------------------------
    initial begin
        $monitor("T=%0t | din=%h pkt_valid=%b busy=%b err=%b | out0=%h out1=%h out2=%h | v0=%b v1=%b v2=%b",
                 $time, data_in, pkt_valid, busy, err,
                 data_out_0, data_out_1, data_out_2,
                 valid_out_0, valid_out_1, valid_out_2);
    end

    // Waveform dump (for GTKWave in Ubuntu)
    initial begin
        $dumpfile("router_tb.vcd");
        $dumpvars(0, tb_router_top);
    end

endmodule
