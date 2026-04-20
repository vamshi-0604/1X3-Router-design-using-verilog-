
module router_fifo (
    input        clock,
    input        resetn,      
    input        soft_reset,  
    input        write_enb,  
    input        read_enb,    
    input  [7:0] data_in,     

    output reg [7:0] data_out,  
    output           fifo_full, 
    output           fifo_empty 
);

    
    parameter DEPTH     = 16;
    parameter ADDR_BITS = 4;

    
    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_BITS-1:0] wr_ptr;
    reg [ADDR_BITS-1:0] rd_ptr;
    reg [ADDR_BITS  :0] count;   

   
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            wr_ptr <= 0;
        end else if (soft_reset) begin
            wr_ptr <= 0;
        end else if (write_enb && !fifo_full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr      <= wr_ptr + 1;
        end
    end

  
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rd_ptr   <= 0;
            data_out <= 8'b0;
        end else if (soft_reset) begin
            rd_ptr   <= 0;
            data_out <= 8'b0;
        end else if (read_enb && !fifo_empty) begin
            data_out <= mem[rd_ptr];
            rd_ptr   <= rd_ptr + 1;
        end
    end

  
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            count <= 0;
        else if (soft_reset)
            count <= 0;
        else begin
            case ({write_enb & ~fifo_full, read_enb & ~fifo_empty})
                2'b10: count <= count + 1;   
                2'b01: count <= count - 1;   
                default: count <= count;     
            endcase
        end
    end

   
    assign fifo_full  = (count == DEPTH);
    assign fifo_empty = (count == 0);

endmodule
