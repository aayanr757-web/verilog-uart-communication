<CodeBlock language="verilog" editable>
`timescale 1ns/1ps

module uart_tb;

reg clk = 0;
reg reset = 1;
reg tx_start = 0;
reg [7:0] tx_data = 0;

wire tx;
wire tx_busy;
wire tx_done;
wire [7:0] rx_data;
wire rx_done;

integer passed = 0;
integer failed = 0;
integer timed_out;

always #5 clk = ~clk;

uart_tx #(.CLKS_PER_BIT(10)) transmitter (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

uart_rx #(.CLKS_PER_BIT(10)) receiver (
    .clk(clk),
    .reset(reset),
    .rx(tx),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

task send_and_check;
    input [7:0] value;
    integer cycles;
    begin
        @(negedge clk);
        tx_data = value;
        tx_start = 1'b1;

@(negedge clk);
        tx_start = 1'b0;

cycles = 0;
        timed_out = 0;

        while (rx_done !== 1'b1 && cycles <150) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

if (rx_done !== 1'b1) begin
            $display("FAIL: Timeout receiving 0x%02h", value);
            failed = failed + 1;
            timed_out = 1;
        end else if (rx_data === value) begin
            $display("PASS: Sent 0x%02h Received 0x%02h",
                     value, rx_data);
            passed = passed + 1;
        end else begin
            $display("FAIL: Sent 0x%02h Received 0x%02h",
                     value, rx_data);
            failed = failed + 1;
        end

wait(tx_busy == 1'b0);
        repeat (3) @(negedge clk);
    end
endtask

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, uart_tb);

repeat (3) @(negedge clk);
    reset = 0;

send_and_check(8'h55);
    send_and_check(8'hAA);
    send_and_check(8'h00);
    send_and_check(8'hFF);
    send_and_check(8'h42);

$display("-----------------------------");
    $display("PASSED: %0d", passed);
    $display("FAILED: %0d", failed);

if (failed == 0 && passed == 5)
        $display("ALL UART TESTS PASSED!");
    else
        $display("UART TESTING NEEDS ATTENTION");

$finish;
end

initial begin
    #100000;
    $display("ERROR: Global simulation timeout");
    $finish;
end

endmodule