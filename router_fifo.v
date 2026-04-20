// ============================================================
// Module : router_fifo
// Description : Synchronous FIFO for 1x3 Router output port
//               Depth : 16 x 8-bit
// ============================================================

module router_fifo (
    input        clock,
    input        resetn,      // active low reset
    input        soft_reset,  // soft reset (timeout based)
    input        write_enb,   // write enable
    input        read_enb,    // read enable
    input  [7:0] data_in,     // data from router register

    output reg [7:0] data_out,  // data to output port
    output           fifo_full, // FIFO full flag
    output           fifo_empty // FIFO empty flag
);

    // -------------------------------------------------------
    // Parameters
    // -------------------------------------------------------
    parameter DEPTH     = 16;
    parameter ADDR_BITS = 4;

    // -------------------------------------------------------
    // Internal Storage
    // -------------------------------------------------------
    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_BITS-1:0] wr_ptr;
    reg [ADDR_BITS-1:0] rd_ptr;
    reg [ADDR_BITS  :0] count;    // one extra bit to distinguish full/empty

    // -------------------------------------------------------
    // Write Logic
    // -------------------------------------------------------
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

    // -------------------------------------------------------
    // Read Logic
    // -------------------------------------------------------
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

    // -------------------------------------------------------
    // Count (number of entries in FIFO)
    // -------------------------------------------------------
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            count <= 0;
        else if (soft_reset)
            count <= 0;
        else begin
            case ({write_enb & ~fifo_full, read_enb & ~fifo_empty})
                2'b10: count <= count + 1;   // write only
                2'b01: count <= count - 1;   // read only
                default: count <= count;     // both or neither
            endcase
        end
    end

    // -------------------------------------------------------
    // Status Flags
    // -------------------------------------------------------
    assign fifo_full  = (count == DEPTH);
    assign fifo_empty = (count == 0);

endmodule
