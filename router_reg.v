module router_reg (
    input        clock,
    input        resetn,        
    input        pkt_valid,
    input  [7:0] data_in,       
    input        fifo_full,     
    input        detect_add,   
    input        ld_state,      
    input        laf_state,     
    input        lfd_state,     
    input        full_state,    
    input        rst_int_reg,  

    output reg [7:0] dout,          
    output reg       err,           
    output reg       parity_done,   
    output reg [1:0] port_addr      
);

    reg [7:0] header_byte;     
    reg [7:0] internal_parity;   
    reg [7:0] full_state_byte;   


    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            port_addr <= 2'b00;
        else if (detect_add && pkt_valid)
            port_addr <= data_in[1:0];
    end

 
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            header_byte <= 8'b0;
        else if (detect_add && pkt_valid)
            header_byte <= data_in;
    end

 
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            dout <= 8'b0;
        else if (lfd_state)
            dout <= header_byte;        
        else if ((ld_state && !fifo_full) || laf_state)
            dout <= data_in;           
        else if (full_state)
            dout <= full_state_byte;    
    end

   
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            full_state_byte <= 8'b0;
        else if (ld_state && fifo_full)
            full_state_byte <= data_in;
    end

   
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            internal_parity <= 8'b0;
        else if (rst_int_reg)
            internal_parity <= 8'b0;
        else if (lfd_state)
            internal_parity <= data_in;     
        else if (ld_state && !fifo_full)
            internal_parity <= internal_parity ^ data_in;
    end


    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            parity_done <= 1'b0;
        else if (laf_state || (ld_state && !pkt_valid))
            parity_done <= 1'b1;
        else if (detect_add)
            parity_done <= 1'b0;
    end


    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            err <= 1'b0;
        else if (parity_done)
            err <= (internal_parity != data_in) ? 1'b1 : 1'b0;
        else if (detect_add)
            err <= 1'b0;
    end

endmodule
