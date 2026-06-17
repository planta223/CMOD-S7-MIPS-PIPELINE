`timescale 1ns/1ps

module pipeline_reg_mem_wb (
    input  wire        clk,

    // Control signals from MEM stage
    input  wire        regwriteM,
    input  wire        memtoregM,

    // Data signals from MEM stage
    input  wire [31:0] readdataM,
    input  wire [31:0] aluoutM,
    input  wire [4:0]  writeregM,

    // Control signals to WB stage
    output reg         regwriteW,
    output reg         memtoregW,

    // Data signals to WB stage
    output reg  [31:0] readdataW,
    output reg  [31:0] aluoutW,
    output reg  [4:0]  writeregW
);

    initial begin
        regwriteW = 1'b0;
        memtoregW = 1'b0;

        readdataW = 32'b0;
        aluoutW   = 32'b0;
        writeregW = 5'b0;
    end

    always @(posedge clk) begin
        regwriteW <= regwriteM;
        memtoregW <= memtoregM;

        readdataW <= readdataM;
        aluoutW   <= aluoutM;
        writeregW <= writeregM;
    end

endmodule