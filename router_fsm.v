module router_fsm (
    input        clock,
    input        resetn,        
    input        pkt_valid,    
    input  [1:0] data_in,     
    input        fifo_full,    
    input        fifo_empty_0,  
    input        fifo_empty_1,  
    input        fifo_empty_2,  
    input        soft_reset_0,
    input        soft_reset_1,  
    input        soft_reset_2,  

    output reg       write_enb_reg,  
    output reg       detect_add,     
    output reg       ld_state,       
    output reg       laf_state,    
    output reg       full_state,     
    output reg       lfd_state,      
    output reg       rst_int_reg,   
    output reg       busy            
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


    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            current_state <= DECODE_ADDRESS;
        else begin
            
            if ((soft_reset_0 && data_in == 2'b00) ||
                (soft_reset_1 && data_in == 2'b01) ||
                (soft_reset_2 && data_in == 2'b10))
                current_state <= DECODE_ADDRESS;
            else
                current_state <= next_state;
        end
    end

    
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
                    next_state = LOAD_AFTER_FULL;  
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


    always @(*) begin
     
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
