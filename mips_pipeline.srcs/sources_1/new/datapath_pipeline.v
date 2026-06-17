`timescale 1ns/1ps

module datapath_pipeline (
    input  wire        clk,
    input  wire        reset,

    // Instruction memory interface
    output wire [31:0] pcF,
    input  wire [31:0] instrF,

    // Data memory interface
    output wire        memwriteM,
    output wire [31:0] aluoutM,
    output wire [31:0] writedataM,
    input  wire [31:0] readdataM,

    // Debug outputs
    output wire [31:0] instrD,
    output wire [31:0] resultW,
    output wire        stallF,
    output wire        stallD,
    output wire        flushD,
    output wire        flushE,
    output wire [1:0]  forwardAE,
    output wire [1:0]  forwardBE
);

    // ============================================================
    // Common / forward declarations
    // ============================================================
    wire        forwardAD;
    wire        forwardBD;

    wire        regwriteM;
    wire        memtoregM;
    wire [4:0]  writeregM;

    wire        regwriteW;
    wire        memtoregW;
    wire [31:0] readdataW;
    wire [31:0] aluoutW;
    wire [4:0]  writeregW;

    // ============================================================
    // IF stage
    // ============================================================
    reg  [31:0] pc_reg;
    wire [31:0] pcnextF;
    wire [31:0] pcplus4F;

    assign pcF      = pc_reg;
    assign pcplus4F = pcF + 32'd4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'b0;
        end else if (!stallF) begin
            pc_reg <= pcnextF;
        end
    end

    // ============================================================
    // IF/ID pipeline register
    // ============================================================
    wire [31:0] pcplus4D;

    pipeline_reg_if_id if_id_reg (
        .clk      (clk),
        .stall    (stallD),
        .clear    (flushD),
        .instrF   (instrF),
        .pcplus4F (pcplus4F),
        .instrD   (instrD),
        .pcplus4D (pcplus4D)
    );

    // ============================================================
    // ID stage
    // ============================================================
    wire        regwriteD;
    wire        memtoregD;
    wire        memwriteD;
    wire        branchD;
    wire        branchneqD;
    wire        alusrcD;
    wire        regdstD;
    wire        jumpD;
    wire        zeroextD;
    wire [2:0]  alucontrolD;

    wire [4:0]  rsD;
    wire [4:0]  rtD;
    wire [4:0]  rdD;

    wire [31:0] rd1D;
    wire [31:0] rd2D;

    wire [31:0] signimmD;
    wire [31:0] zeroimmD;
    wire [31:0] immextD;

    wire [31:0] srcaD;
    wire [31:0] srcbD;
    wire        equalD;
    wire        pcsrcD;

    wire [31:0] pcbranchD;
    wire [31:0] pcjumpD;

    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];

    assign signimmD = {{16{instrD[15]}}, instrD[15:0]};
    assign zeroimmD = {16'b0, instrD[15:0]};
    assign immextD  = zeroextD ? zeroimmD : signimmD;

    controller controller_inst (
        .op         (instrD[31:26]),
        .funct      (instrD[5:0]),

        .memtoreg   (memtoregD),
        .memwrite   (memwriteD),
        .branch     (branchD),
        .branchneq  (branchneqD),
        .alusrc     (alusrcD),
        .regdst     (regdstD),
        .regwrite   (regwriteD),
        .jump       (jumpD),
        .zeroext    (zeroextD),
        .alucontrol (alucontrolD)
    );

    regfile regfile_inst (
        .clk (clk),
        .we3 (regwriteW),
        .a1  (rsD),
        .a2  (rtD),
        .a3  (writeregW),
        .wd3 (resultW),
        .rd1 (rd1D),
        .rd2 (rd2D)
    );

    // Branch comparison forwarding in ID stage
    assign srcaD = forwardAD ? aluoutM : rd1D;
    assign srcbD = forwardBD ? aluoutM : rd2D;

    assign equalD = (srcaD == srcbD);

    // beq / bne branch decision
    assign pcsrcD = (branchD    &&  equalD) ||
                    (branchneqD && !equalD);

    assign pcbranchD = pcplus4D + (immextD << 2);
    assign pcjumpD   = {pcplus4D[31:28], instrD[25:0], 2'b00};

    assign pcnextF = jumpD  ? pcjumpD   :
                     pcsrcD ? pcbranchD :
                              pcplus4F;

    assign flushD = pcsrcD | jumpD;

    // ============================================================
    // ID/EX pipeline register
    // ============================================================
    wire        regwriteE;
    wire        memtoregE;
    wire        memwriteE;
    wire [2:0]  alucontrolE;
    wire        alusrcE;
    wire        regdstE;

    wire [31:0] rd1E;
    wire [31:0] rd2E;
    wire [31:0] immextE;

    wire [4:0]  rsE;
    wire [4:0]  rtE;
    wire [4:0]  rdE;

    pipeline_reg_id_ex id_ex_reg (
        .clk         (clk),
        .clear       (flushE),

        .regwriteD   (regwriteD),
        .memtoregD   (memtoregD),
        .memwriteD   (memwriteD),
        .alucontrolD (alucontrolD),
        .alusrcD     (alusrcD),
        .regdstD     (regdstD),

        .rd1D        (rd1D),
        .rd2D        (rd2D),
        .signimmD    (immextD),

        .rsD         (rsD),
        .rtD         (rtD),
        .rdD         (rdD),

        .regwriteE   (regwriteE),
        .memtoregE   (memtoregE),
        .memwriteE   (memwriteE),
        .alucontrolE (alucontrolE),
        .alusrcE     (alusrcE),
        .regdstE     (regdstE),

        .rd1E        (rd1E),
        .rd2E        (rd2E),
        .signimmE    (immextE),

        .rsE         (rsE),
        .rtE         (rtE),
        .rdE         (rdE)
    );

    // ============================================================
    // EX stage
    // ============================================================
    wire [31:0] srcaE;
    wire [31:0] writedataE;
    wire [31:0] srcbE;
    wire [31:0] aluoutE;
    wire        zeroE;
    wire [4:0]  writeregE;

    assign srcaE =
        (forwardAE == 2'b00) ? rd1E    :
        (forwardAE == 2'b10) ? aluoutM  :
                               resultW;

    assign writedataE =
        (forwardBE == 2'b00) ? rd2E    :
        (forwardBE == 2'b10) ? aluoutM  :
                               resultW;

    assign srcbE = alusrcE ? immextE : writedataE;

    assign writeregE = regdstE ? rdE : rtE;

    alu alu_inst (
        .a          (srcaE),
        .b          (srcbE),
        .alucontrol (alucontrolE),
        .result     (aluoutE),
        .zero       (zeroE)
    );

    // ============================================================
    // EX/MEM pipeline register
    // ============================================================
    pipeline_reg_ex_mem ex_mem_reg (
        .clk        (clk),

        .regwriteE  (regwriteE),
        .memtoregE  (memtoregE),
        .memwriteE  (memwriteE),

        .aluoutE    (aluoutE),
        .writedataE (writedataE),
        .writeregE  (writeregE),

        .regwriteM  (regwriteM),
        .memtoregM  (memtoregM),
        .memwriteM  (memwriteM),

        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .writeregM  (writeregM)
    );

    // ============================================================
    // MEM/WB pipeline register
    // ============================================================
    pipeline_reg_mem_wb mem_wb_reg (
        .clk        (clk),

        .regwriteM  (regwriteM),
        .memtoregM  (memtoregM),

        .readdataM  (readdataM),
        .aluoutM    (aluoutM),
        .writeregM  (writeregM),

        .regwriteW  (regwriteW),
        .memtoregW  (memtoregW),

        .readdataW  (readdataW),
        .aluoutW    (aluoutW),
        .writeregW  (writeregW)
    );

    // ============================================================
    // WB stage
    // ============================================================
    assign resultW = memtoregW ? readdataW : aluoutW;

    // ============================================================
    // Hazard Unit
    // ============================================================
    hazard_unit hazard_unit_inst (
        // ID stage
        .rsD       (rsD),
        .rtD       (rtD),
        .branchD   (branchD | branchneqD),

        // EX stage
        .rsE       (rsE),
        .rtE       (rtE),
        .writeregE (writeregE),
        .regwriteE (regwriteE),
        .memtoregE (memtoregE),

        // MEM stage
        .writeregM (writeregM),
        .regwriteM (regwriteM),
        .memtoregM (memtoregM),

        // WB stage
        .writeregW (writeregW),
        .regwriteW (regwriteW),

        // Forwarding
        .forwardAE (forwardAE),
        .forwardBE (forwardBE),
        .forwardAD (forwardAD),
        .forwardBD (forwardBD),

        // Stall / Flush
        .stallF    (stallF),
        .stallD    (stallD),
        .flushE    (flushE)
    );

endmodule