`timescale 1ns/1ps

module pipeline_reg_id_ex (
    input  wire        clk,
    input  wire        clear,

    input  wire        regwriteD,
    input  wire        memtoregD,
    input  wire        memwriteD,
    input  wire [2:0]  alucontrolD,
    input  wire        alusrcD,
    input  wire        regdstD,

    input  wire [31:0] rd1D,
    input  wire [31:0] rd2D,
    input  wire [31:0] signimmD,

    input  wire [4:0]  rsD,
    input  wire [4:0]  rtD,
    input  wire [4:0]  rdD,

    output reg         regwriteE,
    output reg         memtoregE,
    output reg         memwriteE,
    output reg  [2:0]  alucontrolE,
    output reg         alusrcE,
    output reg         regdstE,

    output reg  [31:0] rd1E,
    output reg  [31:0] rd2E,
    output reg  [31:0] signimmE,

    output reg  [4:0]  rsE,
    output reg  [4:0]  rtE,
    output reg  [4:0]  rdE
);

    initial begin
        regwriteE   = 1'b0;
        memtoregE   = 1'b0;
        memwriteE   = 1'b0;
        alucontrolE = 3'b000;
        alusrcE     = 1'b0;
        regdstE     = 1'b0;

        rd1E        = 32'b0;
        rd2E        = 32'b0;
        signimmE    = 32'b0;

        rsE         = 5'b0;
        rtE         = 5'b0;
        rdE         = 5'b0;
    end

    always @(posedge clk) begin
        if (clear) begin
            regwriteE   <= 1'b0;
            memtoregE   <= 1'b0;
            memwriteE   <= 1'b0;
            alucontrolE <= 3'b000;
            alusrcE     <= 1'b0;
            regdstE     <= 1'b0;

            rd1E        <= 32'b0;
            rd2E        <= 32'b0;
            signimmE    <= 32'b0;

            rsE         <= 5'b0;
            rtE         <= 5'b0;
            rdE         <= 5'b0;
        end else begin
            regwriteE   <= regwriteD;
            memtoregE   <= memtoregD;
            memwriteE   <= memwriteD;
            alucontrolE <= alucontrolD;
            alusrcE     <= alusrcD;
            regdstE     <= regdstD;

            rd1E        <= rd1D;
            rd2E        <= rd2D;
            signimmE    <= signimmD;

            rsE         <= rsD;
            rtE         <= rtD;
            rdE         <= rdD;
        end
    end

endmodule