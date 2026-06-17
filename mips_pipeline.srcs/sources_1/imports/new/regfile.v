module regfile (
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  a1,
    input  wire [4:0]  a2,
    input  wire [4:0]  a3,
    input  wire [31:0] wd3,

    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] rf [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rf[i] = 32'h00000000;
        end
    end

    always @(posedge clk) begin
        if (we3 && (a3 != 5'd0)) begin
            rf[a3] <= wd3;
        end
    end

    assign rd1 = (a1 == 5'd0) ? 32'd0 : rf[a1];
    assign rd2 = (a2 == 5'd0) ? 32'd0 : rf[a2];

endmodule