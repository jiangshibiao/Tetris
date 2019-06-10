module debouncer(
    input wire  raw,
    input wire  clk,
    output wire enabled
    );
    reg debounced;
    reg debounced_prev;
    reg [15:0] counter;
    initial begin
        debounced = 0;
        debounced_prev = 0;
        counter = 0;
    end
    always @ (posedge clk) begin
        if (counter == 12500) begin
            counter <= 0;
            debounced <= raw;
        end else begin
            counter <= counter + 16'd1;
        end
        debounced_prev <= debounced;
    end
    assign enabled = debounced && !debounced_prev;
endmodule