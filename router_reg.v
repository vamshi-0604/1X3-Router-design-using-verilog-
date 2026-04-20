// ============================================================
// Module : router_reg
// Description : Input Register for 1x3 Router
//               Holds header byte, data bytes, and parity
// ============================================================

module router_reg (
    input        clock,
    input        resetn,        // active low reset
    input        pkt_valid,     // packet valid from source
    input  [7:0] data_in,       // 8-bit input data
    input        fifo_full,     // selected FIFO full
    input        detect_add,    // from FSM: address decode state
    input        ld_state,      // from FSM: load data state
    input        laf_state,     // from FSM: load after full state
    input        lfd_state,     // from FSM: load first data state
    input        full_state,    // from FSM: fifo full state
    input        rst_int_reg,   // reset internal parity register

    output reg [7:0] dout,          // data output to FIFO
    output reg       err,           // parity error flag
    output reg       parity_done,   // parity computation done
    output reg [1:0] port_addr      // decoded port address
);

    reg [7:0] header_byte;       // stores the header/address byte
    reg [7:0] internal_parity;   // running parity
    reg [7:0] full_state_byte;   // byte held when FIFO was full

    // -------------------------------------------------------
    // Port Address Decode
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            port_addr <= 2'b00;
        else if (detect_add && pkt_valid)
            port_addr <= data_in[1:0];
    end

    // -------------------------------------------------------
    // Header Byte Register
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            header_byte <= 8'b0;
        else if (detect_add && pkt_valid)
            header_byte <= data_in;
    end

    // -------------------------------------------------------
    // Data Output Register
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            dout <= 8'b0;
        else if (lfd_state)
            dout <= header_byte;        // first word: header
        else if ((ld_state && !fifo_full) || laf_state)
            dout <= data_in;            // subsequent data bytes
        else if (full_state)
            dout <= full_state_byte;    // re-present held byte
    end

    // -------------------------------------------------------
    // Hold byte when FIFO goes full mid-packet
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            full_state_byte <= 8'b0;
        else if (ld_state && fifo_full)
            full_state_byte <= data_in;
    end

    // -------------------------------------------------------
    // Internal Parity Calculation (XOR of all data bytes)
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            internal_parity <= 8'b0;
        else if (rst_int_reg)
            internal_parity <= 8'b0;
        else if (lfd_state)
            internal_parity <= data_in;      // start with header byte
        else if (ld_state && !fifo_full)
            internal_parity <= internal_parity ^ data_in;
    end

    // -------------------------------------------------------
    // Parity Done Flag
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            parity_done <= 1'b0;
        else if (laf_state || (ld_state && !pkt_valid))
            parity_done <= 1'b1;
        else if (detect_add)
            parity_done <= 1'b0;
    end

    // -------------------------------------------------------
    // Error Detection (compare received parity vs calculated)
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            err <= 1'b0;
        else if (parity_done)
            err <= (internal_parity != data_in) ? 1'b1 : 1'b0;
        else if (detect_add)
            err <= 1'b0;
    end

endmodule
