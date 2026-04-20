module router_top (
    input        clock,
    input        resetn,      
    input        pkt_valid,  
    input  [7:0] data_in,    
    input        read_enb_0, 
    input        read_enb_1,  
    input        read_enb_2,  
    output [7:0] data_out_0,  
    output [7:0] data_out_1, 
    output [7:0] data_out_2,  

    output       valid_out_0, 
    output       valid_out_1, 
    output       valid_out_2, 

    output       err,         
    output       busy         
);

   
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
    wire [7:0] dout_reg;  

    
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


    assign valid_out_0 = ~fifo_empty_0;
    assign valid_out_1 = ~fifo_empty_1;
    assign valid_out_2 = ~fifo_empty_2;

endmodule
