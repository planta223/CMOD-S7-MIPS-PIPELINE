`timescale 1ns/1ps

module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        stall,
    input  wire        clear,
    input  wire [31:0] instrF,
    input  wire [31:0] pcplus4F,
    output reg  [31:0] instrD,
    output reg  [31:0] pcplus4D
);

    initial begin
        instrD   = 32'b0;
        pcplus4D = 32'b0;
    end

    always @(posedge clk) begin
        if (clear) begin
            instrD   <= 32'b0;
            pcplus4D <= 32'b0;
        end else if (!stall) begin
            instrD   <= instrF;
            pcplus4D <= pcplus4F;
        end
    end

endmodule