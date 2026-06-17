`timescale 1ns/1ps

module pipeline_reg_ex_mem (
    input  wire        clk,

    // Control signals from EX stage
    input  wire        regwriteE,
    input  wire        memtoregE,
    input  wire        memwriteE,

    // Data signals from EX stage
    input  wire [31:0] aluoutE,
    input  wire [31:0] writedataE,
    input  wire [4:0]  writeregE,

    // Control signals to MEM stage
    output reg         regwriteM,
    output reg         memtoregM,
    output reg         memwriteM,

    // Data signals to MEM stage
    output reg  [31:0] aluoutM,
    output reg  [31:0] writedataM,
    output reg  [4:0]  writeregM
);

    initial begin
        regwriteM  = 1'b0;
        memtoregM  = 1'b0;
        memwriteM  = 1'b0;

        aluoutM    = 32'b0;
        writedataM = 32'b0;
        writeregM  = 5'b0;
    end

    always @(posedge clk) begin
        regwriteM  <= regwriteE;
        memtoregM  <= memtoregE;
        memwriteM  <= memwriteE;

        aluoutM    <= aluoutE;
        writedataM <= writedataE;
        writeregM  <= writeregE;
    end

endmodule