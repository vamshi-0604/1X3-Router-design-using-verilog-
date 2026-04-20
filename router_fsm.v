// ============================================================
// Module : router_fsm
// Description : FSM for 1x3 Router
// States : DECODE_ADDRESS, LOAD_FIRST_DATA, LOAD_DATA,
//          LOAD_PARITY, CHECK_PARITY_ERROR, WAIT_TILL_EMPTY,
//          FIFO_FULL_STATE
// ============================================================

module router_fsm (
    input        clock,
    input        resetn,        // active low reset
    input        pkt_valid,     // input packet valid
    input  [1:0] data_in,       // address bits [1:0] from data
    input        fifo_full,     // selected FIFO is full
    input        fifo_empty_0,  // FIFO 0 empty flag
    input        fifo_empty_1,  // FIFO 1 empty flag
    input        fifo_empty_2,  // FIFO 2 empty flag
    input        soft_reset_0,  // soft reset for port 0
    input        soft_reset_1,  // soft reset for port 1
    input        soft_reset_2,  // soft reset for port 2

    output reg       write_enb_reg,  // enable write to register
    output reg       detect_add,     // detect address cycle
    output reg       ld_state,       // load data state active
    output reg       laf_state,      // load after full state
    output reg       full_state,     // FIFO full state active
    output reg       lfd_state,      // load first data state
    output reg       rst_int_reg,    // reset internal register
    output reg       busy            // router busy signal
);

    // State encoding
    parameter DECODE_ADDRESS   = 3'b000;
    parameter LOAD_FIRST_DATA  = 3'b001;
    parameter LOAD_DATA        = 3'b010;
    parameter LOAD_PARITY      = 3'b011;
    parameter CHECK_PARITY_ERR = 3'b100;
    parameter FIFO_FULL_STATE  = 3'b101;
    parameter WAIT_TILL_EMPTY  = 3'b110;

    reg [2:0] current_state, next_state;

    // -------------------------------------------------------
    // State Register (Sequential)
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            current_state <= DECODE_ADDRESS;
        else begin
            // Soft reset: return to DECODE if assigned FIFO becomes empty
            if ((soft_reset_0 && data_in == 2'b00) ||
                (soft_reset_1 && data_in == 2'b01) ||
                (soft_reset_2 && data_in == 2'b10))
                current_state <= DECODE_ADDRESS;
            else
                current_state <= next_state;
        end
    end

    // -------------------------------------------------------
    // Next-State Logic (Combinational)
    // -------------------------------------------------------
    always @(*) begin
        case (current_state)

            DECODE_ADDRESS: begin
                if (pkt_valid &&
                    ((data_in == 2'b00 && fifo_empty_0) ||
                     (data_in == 2'b01 && fifo_empty_1) ||
                     (data_in == 2'b10 && fifo_empty_2)))
                    next_state = LOAD_FIRST_DATA;
                else if (pkt_valid &&
                    ((data_in == 2'b00 && !fifo_empty_0) ||
                     (data_in == 2'b01 && !fifo_empty_1) ||
                     (data_in == 2'b10 && !fifo_empty_2)))
                    next_state = WAIT_TILL_EMPTY;
                else
                    next_state = DECODE_ADDRESS;
            end

            LOAD_FIRST_DATA: begin
                next_state = LOAD_DATA;
            end

            LOAD_DATA: begin
                if (fifo_full)
                    next_state = FIFO_FULL_STATE;
                else if (!pkt_valid)
                    next_state = LOAD_PARITY;
                else
                    next_state = LOAD_DATA;
            end

            FIFO_FULL_STATE: begin
                if (!fifo_full)
                    next_state = LOAD_AFTER_FULL;  // handled via laf_state
                else
                    next_state = FIFO_FULL_STATE;
            end

            LOAD_PARITY: begin
                next_state = CHECK_PARITY_ERR;
            end

            CHECK_PARITY_ERR: begin
                if (fifo_full)
                    next_state = FIFO_FULL_STATE;
                else
                    next_state = DECODE_ADDRESS;
            end

            WAIT_TILL_EMPTY: begin
                if ((data_in == 2'b00 && fifo_empty_0) ||
                    (data_in == 2'b01 && fifo_empty_1) ||
                    (data_in == 2'b10 && fifo_empty_2))
                    next_state = LOAD_FIRST_DATA;
                else
                    next_state = WAIT_TILL_EMPTY;
            end

            default: next_state = DECODE_ADDRESS;
        endcase
    end

    // -------------------------------------------------------
    // Output Logic (Combinational / Mealy-Moore mixed)
    // -------------------------------------------------------
    always @(*) begin
        // Default outputs
        detect_add    = 0;
        ld_state      = 0;
        laf_state     = 0;
        full_state    = 0;
        lfd_state     = 0;
        rst_int_reg   = 0;
        write_enb_reg = 0;
        busy          = 0;

        case (current_state)
            DECODE_ADDRESS: begin
                detect_add = 1;
                busy       = 0;
            end

            LOAD_FIRST_DATA: begin
                lfd_state     = 1;
                busy          = 1;
                write_enb_reg = 1;
            end

            LOAD_DATA: begin
                ld_state      = 1;
                busy          = 1;
                write_enb_reg = 1;
            end

            FIFO_FULL_STATE: begin
                full_state    = 1;
                busy          = 1;
                write_enb_reg = 0;
            end

            LOAD_PARITY: begin
                // laf_state used as "load after full" indicator here
                laf_state     = 1;
                busy          = 1;
                write_enb_reg = 1;
            end

            CHECK_PARITY_ERR: begin
                rst_int_reg = 1;
                busy        = 1;
            end

            WAIT_TILL_EMPTY: begin
                busy = 1;
            end

            default: begin
                detect_add    = 0;
                ld_state      = 0;
                laf_state     = 0;
                full_state    = 0;
                lfd_state     = 0;
                rst_int_reg   = 0;
                write_enb_reg = 0;
                busy          = 0;
            end
        endcase
    end

// Note: LOAD_AFTER_FULL is handled by transitioning from FIFO_FULL_STATE
// back to LOAD_DATA equivalent via laf_state signal in LOAD_PARITY state.

endmodule
