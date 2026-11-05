
`timescale 1ns/1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 10
)(
    input clk,
    input reset,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_done
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
        clk_count <= 0;
        bit_index <= 0;
        data_buffer <= 0;
        rx_data <= 0;
        rx_done <= 0;
    end else begin
        rx_done <= 0;

        case (state)
            IDLE: begin
                clk_count <= 0;
                if (rx == 1'b0) begin
                    state <= START;
                    clk_count <= 0;
                end
            end

            START: begin
                if (clk_count == (CLKS_PER_BIT/2) - 1) begin
                    clk_count <= 0;
                    if (rx == 1'b0) begin
                        bit_index <= 0;
                        state <= DATA;
                    end else begin
                        state <= IDLE;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    data_buffer[bit_index] <= rx;

                    if (bit_index == 7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            STOP: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    if (rx == 1'b1) begin
                        rx_data <= data_buffer;
                        rx_done <= 1;
                    end
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
