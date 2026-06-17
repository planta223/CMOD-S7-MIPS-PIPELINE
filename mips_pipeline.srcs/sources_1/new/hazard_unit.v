`timescale 1ns/1ps

module hazard_unit (
    // ID stage
    input  wire [4:0] rsD,
    input  wire [4:0] rtD,
    input  wire       branchD,

    // EX stage
    input  wire [4:0] rsE,
    input  wire [4:0] rtE,
    input  wire [4:0] writeregE,
    input  wire       regwriteE,
    input  wire       memtoregE,

    // MEM stage
    input  wire [4:0] writeregM,
    input  wire       regwriteM,
    input  wire       memtoregM,

    // WB stage
    input  wire [4:0] writeregW,
    input  wire       regwriteW,

    // Forwarding outputs
    output reg  [1:0] forwardAE,
    output reg  [1:0] forwardBE,
    output wire       forwardAD,
    output wire       forwardBD,

    // Stall / Flush outputs
    output wire       stallF,
    output wire       stallD,
    output wire       flushE
);

    wire lwstall;
    wire branchstall;

    // ------------------------------------------------------------
    // EX-stage forwarding for ALU input A
    // 00: use RD1E
    // 10: forward from EX/MEM stage, ALUOutM
    // 01: forward from MEM/WB stage, ResultW
    // ------------------------------------------------------------
    always @(*) begin
        if (regwriteM && (writeregM != 5'b0) && (writeregM == rsE)) begin
            forwardAE = 2'b10;
        end else if (regwriteW && (writeregW != 5'b0) && (writeregW == rsE)) begin
            forwardAE = 2'b01;
        end else begin
            forwardAE = 2'b00;
        end
    end

    // ------------------------------------------------------------
    // EX-stage forwarding for ALU input B / store data
    // 00: use RD2E
    // 10: forward from EX/MEM stage, ALUOutM
    // 01: forward from MEM/WB stage, ResultW
    // ------------------------------------------------------------
    always @(*) begin
        if (regwriteM && (writeregM != 5'b0) && (writeregM == rtE)) begin
            forwardBE = 2'b10;
        end else if (regwriteW && (writeregW != 5'b0) && (writeregW == rtE)) begin
            forwardBE = 2'b01;
        end else begin
            forwardBE = 2'b00;
        end
    end

    // ------------------------------------------------------------
    // ID-stage forwarding for branch comparison
    // Used for early branch resolution in ID stage
    // ------------------------------------------------------------
    assign forwardAD = regwriteM && (writeregM != 5'b0) && (writeregM == rsD);
    assign forwardBD = regwriteM && (writeregM != 5'b0) && (writeregM == rtD);

    // ------------------------------------------------------------
    // Load-use hazard
    //
    // Example:
    // lw  $3, 0($0)
    // sub $4, $3, $1
    //
    // lw result is available only after MEM stage.
    // Therefore, one-cycle stall is required.
    // ------------------------------------------------------------
    assign lwstall =
        memtoregE &&
        ((rtE == rsD) || (rtE == rtD));

    // ------------------------------------------------------------
    // Branch stall
    //
    // Branch is resolved in ID stage.
    // If branch depends on a result still in EX stage, stall.
    // If branch depends on a lw result in MEM stage, stall.
    // ------------------------------------------------------------
    assign branchstall =
        branchD &&
        (
            (regwriteE && (writeregE != 5'b0) &&
             ((writeregE == rsD) || (writeregE == rtD))) ||

            (memtoregM && (writeregM != 5'b0) &&
             ((writeregM == rsD) || (writeregM == rtD)))
        );

    // ------------------------------------------------------------
    // Stall / Flush control
    // ------------------------------------------------------------
    assign stallF = lwstall | branchstall;
    assign stallD = lwstall | branchstall;
    assign flushE = lwstall | branchstall;

endmodule