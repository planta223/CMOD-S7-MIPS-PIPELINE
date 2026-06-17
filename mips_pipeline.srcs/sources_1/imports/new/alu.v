module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  alucontrol,
    output reg  [31:0] result,
    output wire        zero
);

    wire [31:0] abs_a;

    assign abs_a = a[31] ? (~a + 32'd1) : a;

    always @(*) begin
        case (alucontrol)
            3'b000: result = a & b;                                      // AND
            3'b001: result = a | b;                                      // OR
            3'b010: result = a + b;                                      // ADD
            3'b011: result = abs_a;                                      // ABS
            3'b110: result = a - b;                                      // SUB
            3'b111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // SLT
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule