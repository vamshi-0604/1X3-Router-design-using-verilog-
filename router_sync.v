// ============================================================
// Module : router_sync
// Description : Synchronizer for 1x3 Router
//               - Selects correct FIFO full signal
//               - Generates write enables for each FIFO
//               - Generates soft resets on timeout
// ============================================================

module router_sync (
    input        clock,
    input        resetn,        // active low reset
    input  [1:0] port_addr,     // decoded port address from reg
    input        detect_add,    // FSM in DECODE_ADDRESS state
    input        write_enb_reg, // write enable from FSM
    input        pkt_valid,     // packet valid
    input        fifo_full_0,   // FIFO 0 full
    input        fifo_full_1,   // FIFO 1 full
    input        fifo_full_2,   // FIFO 2 full
    input        fifo_empty_0,  // FIFO 0 empty
    input        fifo_empty_1,  // FIFO 1 empty
    input        fifo_empty_2,  // FIFO 2 empty

    output reg        fifo_full,     // selected FIFO full (to FSM)
    output reg [2:0]  write_enb,     // per-FIFO write enables
    output reg        soft_reset_0,  // soft reset for FIFO 0
    output reg        soft_reset_1,  // soft reset for FIFO 1
    output reg        soft_reset_2   // soft reset for FIFO 2
);

    // -------------------------------------------------------
    // Timeout counters (30-cycle timeout per port)
    // -------------------------------------------------------
    reg [4:0] count0, count1, count2;

    // -------------------------------------------------------
    // FIFO Full MUX — select full signal for current port
    // -------------------------------------------------------
    always @(*) begin
        case (port_addr)
            2'b00: fifo_full = fifo_full_0;
            2'b01: fifo_full = fifo_full_1;
            2'b10: fifo_full = fifo_full_2;
            default: fifo_full = 1'b0;
        endcase
    end

    // -------------------------------------------------------
    // Write Enable Decoder
    // -------------------------------------------------------
    always @(*) begin
        write_enb = 3'b000;
        if (write_enb_reg) begin
            case (port_addr)
                2'b00: write_enb = 3'b001;
                2'b01: write_enb = 3'b010;
                2'b10: write_enb = 3'b100;
                default: write_enb = 3'b000;
            endcase
        end
    end

    // -------------------------------------------------------
    // Soft Reset Logic — Port 0
    // Asserted if FIFO 0 is not empty for 30 clock cycles
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            count0      <= 5'b0;
            soft_reset_0 <= 1'b0;
        end else if (fifo_empty_0) begin
            count0      <= 5'b0;
            soft_reset_0 <= 1'b0;
        end else if (count0 == 5'd29) begin
            soft_reset_0 <= 1'b1;
            count0       <= 5'b0;
        end else begin
            count0       <= count0 + 1;
            soft_reset_0 <= 1'b0;
        end
    end

    // -------------------------------------------------------
    // Soft Reset Logic — Port 1
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            count1      <= 5'b0;
            soft_reset_1 <= 1'b0;
        end else if (fifo_empty_1) begin
            count1      <= 5'b0;
            soft_reset_1 <= 1'b0;
        end else if (count1 == 5'd29) begin
            soft_reset_1 <= 1'b1;
            count1       <= 5'b0;
        end else begin
            count1       <= count1 + 1;
            soft_reset_1 <= 1'b0;
        end
    end

    // -------------------------------------------------------
    // Soft Reset Logic — Port 2
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            count2      <= 5'b0;
            soft_reset_2 <= 1'b0;
        end else if (fifo_empty_2) begin
            count2      <= 5'b0;
            soft_reset_2 <= 1'b0;
        end else if (count2 == 5'd29) begin
            soft_reset_2 <= 1'b1;
            count2       <= 5'b0;
        end else begin
            count2       <= count2 + 1;
            soft_reset_2 <= 1'b0;
        end
    end

endmodule
