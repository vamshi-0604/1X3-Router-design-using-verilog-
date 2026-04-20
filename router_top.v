// ============================================================
// Module : router_top
// Description : Top-level 1x3 Router integrating FSM,
//               Register, Synchronizer, and 3 FIFOs
// ============================================================

module router_top (
    input        clock,
    input        resetn,      // active low reset
    input        pkt_valid,   // input packet valid
    input  [7:0] data_in,     // 8-bit serial input data

    input        read_enb_0,  // read enable for port 0
    input        read_enb_1,  // read enable for port 1
    input        read_enb_2,  // read enable for port 2

    output [7:0] data_out_0,  // output data port 0
    output [7:0] data_out_1,  // output data port 1
    output [7:0] data_out_2,  // output data port 2

    output       valid_out_0, // data valid at port 0 (= ~empty)
    output       valid_out_1, // data valid at port 1
    output       valid_out_2, // data valid at port 2

    output       err,         // parity error
    output       busy         // router busy
);

    // -------------------------------------------------------
    // Internal Wires
    // -------------------------------------------------------
    wire [1:0] port_addr;
    wire       fifo_full;
    wire       fifo_full_0, fifo_full_1, fifo_full_2;
    wire       fifo_empty_0, fifo_empty_1, fifo_empty_2;
    wire [2:0] write_enb;
    wire       write_enb_reg;
    wire       soft_reset_0, soft_reset_1, soft_reset_2;
    wire       detect_add, ld_state, laf_state, full_state;
    wire       lfd_state, rst_int_reg;
    wire       parity_done;
    wire [7:0] dout_reg;   // from register to FIFOs

    // -------------------------------------------------------
    // FSM
    // -------------------------------------------------------
    router_fsm u_fsm (
        .clock         (clock),
        .resetn        (resetn),
        .pkt_valid     (pkt_valid),
        .data_in       (data_in[1:0]),
        .fifo_full     (fifo_full),
        .fifo_empty_0  (fifo_empty_0),
        .fifo_empty_1  (fifo_empty_1),
        .fifo_empty_2  (fifo_empty_2),
        .soft_reset_0  (soft_reset_0),
        .soft_reset_1  (soft_reset_1),
        .soft_reset_2  (soft_reset_2),
        .write_enb_reg (write_enb_reg),
        .detect_add    (detect_add),
        .ld_state      (ld_state),
        .laf_state     (laf_state),
        .full_state    (full_state),
        .lfd_state     (lfd_state),
        .rst_int_reg   (rst_int_reg),
        .busy          (busy)
    );

    // -------------------------------------------------------
    // Input Register
    // -------------------------------------------------------
    router_reg u_reg (
        .clock        (clock),
        .resetn       (resetn),
        .pkt_valid    (pkt_valid),
        .data_in      (data_in),
        .fifo_full    (fifo_full),
        .detect_add   (detect_add),
        .ld_state     (ld_state),
        .laf_state    (laf_state),
        .lfd_state    (lfd_state),
        .full_state   (full_state),
        .rst_int_reg  (rst_int_reg),
        .dout         (dout_reg),
        .err          (err),
        .parity_done  (parity_done),
        .port_addr    (port_addr)
    );

    // -------------------------------------------------------
    // Synchronizer
    // -------------------------------------------------------
    router_sync u_sync (
        .clock        (clock),
        .resetn       (resetn),
        .port_addr    (port_addr),
        .detect_add   (detect_add),
        .write_enb_reg(write_enb_reg),
        .pkt_valid    (pkt_valid),
        .fifo_full_0  (fifo_full_0),
        .fifo_full_1  (fifo_full_1),
        .fifo_full_2  (fifo_full_2),
        .fifo_empty_0 (fifo_empty_0),
        .fifo_empty_1 (fifo_empty_1),
        .fifo_empty_2 (fifo_empty_2),
        .fifo_full    (fifo_full),
        .write_enb    (write_enb),
        .soft_reset_0 (soft_reset_0),
        .soft_reset_1 (soft_reset_1),
        .soft_reset_2 (soft_reset_2)
    );

    // -------------------------------------------------------
    // FIFO 0 — Port 0
    // -------------------------------------------------------
    router_fifo u_fifo0 (
        .clock      (clock),
        .resetn     (resetn),
        .soft_reset (soft_reset_0),
        .write_enb  (write_enb[0]),
        .read_enb   (read_enb_0),
        .data_in    (dout_reg),
        .data_out   (data_out_0),
        .fifo_full  (fifo_full_0),
        .fifo_empty (fifo_empty_0)
    );

    // -------------------------------------------------------
    // FIFO 1 — Port 1
    // -------------------------------------------------------
    router_fifo u_fifo1 (
        .clock      (clock),
        .resetn     (resetn),
        .soft_reset (soft_reset_1),
        .write_enb  (write_enb[1]),
        .read_enb   (read_enb_1),
        .data_in    (dout_reg),
        .data_out   (data_out_1),
        .fifo_full  (fifo_full_1),
        .fifo_empty (fifo_empty_1)
    );

    // -------------------------------------------------------
    // FIFO 2 — Port 2
    // -------------------------------------------------------
    router_fifo u_fifo2 (
        .clock      (clock),
        .resetn     (resetn),
        .soft_reset (soft_reset_2),
        .write_enb  (write_enb[2]),
        .read_enb   (read_enb_2),
        .data_in    (dout_reg),
        .data_out   (data_out_2),
        .fifo_full  (fifo_full_2),
        .fifo_empty (fifo_empty_2)
    );

    // -------------------------------------------------------
    // Valid Output = ~empty (data available at port)
    // -------------------------------------------------------
    assign valid_out_0 = ~fifo_empty_0;
    assign valid_out_1 = ~fifo_empty_1;
    assign valid_out_2 = ~fifo_empty_2;

endmodule
