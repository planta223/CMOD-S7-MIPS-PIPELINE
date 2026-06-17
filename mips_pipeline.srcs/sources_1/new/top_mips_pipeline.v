`timescale 1ns/1ps

module top_mips_pipeline (
    input  wire        clk,
    input  wire        reset,

    // debug outputs
    output wire [31:0] pc,
    output wire [31:0] instr,
    output wire [31:0] aluout,
    output wire [31:0] writedata,
    output wire [31:0] readdata,

    output wire        done
);

    // -------------------------
    // Internal wires
    // -------------------------
    wire [31:0] pcF;
    wire [31:0] instrF;

    wire        memwriteM;
    wire [31:0] aluoutM;
    wire [31:0] writedataM;
    wire [31:0] readdataM;

    wire [31:0] instrD;
    wire [31:0] resultW;

    wire        stallF;
    wire        stallD;
    wire        flushD;
    wire        flushE;

    wire [1:0]  forwardAE;
    wire [1:0]  forwardBE;

    // imem.v uses 24-bit address input
    wire [23:0] imem_addr;

    assign imem_addr = pcF[25:2];

    // -------------------------
    // Datapath
    // -------------------------
    datapath_pipeline datapath_inst (
        .clk        (clk),
        .reset      (reset),

        // Instruction memory interface
        .pcF        (pcF),
        .instrF     (instrF),

        // Data memory interface
        .memwriteM  (memwriteM),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .readdataM  (readdataM),

        // Debug outputs
        .instrD     (instrD),
        .resultW    (resultW),
        .stallF     (stallF),
        .stallD     (stallD),
        .flushD     (flushD),
        .flushE     (flushE),
        .forwardAE  (forwardAE),
        .forwardBE  (forwardBE)
    );

    // -------------------------
    // Instruction Memory
    // -------------------------
    imem imem_inst (
        .addr  (imem_addr),
        .instr (instrF)
    );

    // -------------------------
    // Data Memory
    // -------------------------
    dmem dmem_inst (
        .clk  (clk),
        .we   (memwriteM),
        .addr (aluoutM[7:0]),
        .wd   (writedataM),
        .rd   (readdataM)
    );

    // -------------------------
    // Debug output mapping
    // -------------------------
    assign pc        = pcF;
    assign instr     = instrF;
    assign aluout    = aluoutM;
    assign writedata = writedataM;
    assign readdata  = readdataM;

    // pipeline test program loops at PC = 0x2C
    assign done = (pcF == 32'h0000002C);

endmodule