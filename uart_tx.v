
`timescale 1ns/1ps

// UART TRANSMITTER - 8 data bits, no parity, 1 stop bit
module uart_tx #(
    parameter CLKS_PER_BIT = 10
)(
    input clk,
    input reset,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0] state;
integer clk_count;
reg [2:0] bit_index;
reg [7:0] data_buffer;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        tx <= 1'b1;
        tx_busy <= 0;
        tx_done <= 0;
        clk_count <= 0;
        bit_index <= 0;
        data_buffer <= 0;
    end else begin
        tx_done <= 0;

        case (state)
            IDLE: begin
                tx <= 1'b1;
                tx_busy <= 0;
                clk_count <= 0;

                if (tx_start) begin
                    data_buffer <= tx_data;
                    bit_index <= 0;
                    tx_busy <= 1;
                    state <= START;
                end
            end

            START: begin
                tx <= 1'b0;
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    state <= DATA;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                tx <= data_buffer[bit_index];

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            STOP: begin
                tx <= 1'b1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    tx_busy <= 0;
                    tx_done <= 1;
                    state <= IDLE;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
