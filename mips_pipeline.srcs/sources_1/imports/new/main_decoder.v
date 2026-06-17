`timescale 1ns / 1ps

module main_decoder (
    input  wire [5:0] op,

    output reg        regwrite,
    output reg        regdst,
    output reg        alusrc,
    output reg        branch,
    output reg        branchneq,
    output reg        memwrite,
    output reg        memtoreg,
    output reg [1:0]  aluop,
    output reg        jump,
    output reg        zeroext
);

    always @(*) begin
        // default: unsupported instruction = safe NOP-like behavior
        regwrite  = 1'b0;
        regdst    = 1'b0;
        alusrc    = 1'b0;
        branch    = 1'b0;
        branchneq = 1'b0;
        memwrite  = 1'b0;
        memtoreg  = 1'b0;
        aluop     = 2'b00;
        jump      = 1'b0;
        zeroext   = 1'b0;

        case (op)
            6'b000000: begin // R-type: sub, or, slt, abs
                regwrite  = 1'b1;
                regdst    = 1'b1;
                alusrc    = 1'b0;
                branch    = 1'b0;
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b0;
                aluop     = 2'b10;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b100011: begin // lw
                regwrite  = 1'b1;
                regdst    = 1'b0;
                alusrc    = 1'b1;
                branch    = 1'b0;
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b1;
                aluop     = 2'b00;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b101011: begin // sw
                regwrite  = 1'b0;
                regdst    = 1'b0; // don't-care in Logisim, fixed to 0 in RTL
                alusrc    = 1'b1;
                branch    = 1'b0;
                branchneq = 1'b0;
                memwrite  = 1'b1;
                memtoreg  = 1'b0; // don't-care in Logisim, fixed to 0 in RTL
                aluop     = 2'b00;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b000100: begin // beq
                regwrite  = 1'b0;
                regdst    = 1'b0; // don't-care
                alusrc    = 1'b0;
                branch    = 1'b1;
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b0; // don't-care
                aluop     = 2'b01;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b000101: begin // bne
                regwrite  = 1'b0;
                regdst    = 1'b0; // don't-care
                alusrc    = 1'b0;
                branch    = 1'b0;
                branchneq = 1'b1;
                memwrite  = 1'b0;
                memtoreg  = 1'b0; // don't-care
                aluop     = 2'b01;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b001000: begin // addi
                regwrite  = 1'b1;
                regdst    = 1'b0;
                alusrc    = 1'b1;
                branch    = 1'b0;
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b0;
                aluop     = 2'b00;
                jump      = 1'b0;
                zeroext   = 1'b0;
            end

            6'b001101: begin // ori
                regwrite  = 1'b1;
                regdst    = 1'b0;
                alusrc    = 1'b1;
                branch    = 1'b0;
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b0;
                aluop     = 2'b11;
                jump      = 1'b0;
                zeroext   = 1'b1;
            end

            6'b000010: begin // j
                regwrite  = 1'b0;
                regdst    = 1'b0; // don't-care
                alusrc    = 1'b0; // don't-care
                branch    = 1'b0; // don't-care in table, fixed to 0
                branchneq = 1'b0;
                memwrite  = 1'b0;
                memtoreg  = 1'b0; // don't-care
                aluop     = 2'b00; // don't-care
                jump      = 1'b1;
                zeroext   = 1'b0;
            end

            default: begin
                // keep default safe values
            end
        endcase
    end

endmodule