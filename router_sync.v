module router_sync (
    input        clock,
    input        resetn,       
    input  [1:0] port_addr,     
    input        detect_add,   
    input        write_enb_reg, 
    input        pkt_valid,     
    input        fifo_full_0,   
    input        fifo_full_1,  
    input        fifo_full_2,  
    input        fifo_empty_0,  
    input        fifo_empty_1,  
    input        fifo_empty_2, 

    output reg        fifo_full,   
    output reg [2:0]  write_enb,    
    output reg        soft_reset_0,  
    output reg        soft_reset_1, 
    output reg        soft_reset_2   
);


    reg [4:0] count0, count1, count2;

   
    always @(*) begin
        case (port_addr)
            2'b00: fifo_full = fifo_full_0;
            2'b01: fifo_full = fifo_full_1;
            2'b10: fifo_full = fifo_full_2;
            default: fifo_full = 1'b0;
        endcase
    end

 
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
