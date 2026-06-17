module top_mips_pipeline (
    input  wire clk,
    input  wire reset,
    output wire done
);

    wire [23:0] imem_addr;
    wire [31:0] instrF;
    wire        memwriteM;
    wire [31:0] aluoutM;
    wire [31:0] writedataM;
    wire [31:0] readdataM;
    wire [31:0] pcF;
    wire [31:0] instrD;
    wire [31:0] resultW;
    wire        stallF, stallD, flushD, flushE;
    wire [1:0]  forwardAE, forwardBE;

    datapath_pipeline datapath_inst (
        .clk(clk),
        .reset(reset),
        .imem_addr(imem_addr),
        .instrF(instrF),
        .memwriteM(memwriteM),
        .aluoutM(aluoutM),
        .writedataM(writedataM),
        .readdataM(readdataM),
        .pcF(pcF),
        .instrD(instrD),
        .resultW(resultW),
        .stallF(stallF),
        .stallD(stallD),
        .flushD(flushD),
        .flushE(flushE),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE)
    );

    imem imem_inst (
        .addr(imem_addr),
        .instr(instrF)
    );

    dmem dmem_inst (
        .clk(clk),
        .we(memwriteM),
        .addr(aluoutM[7:0]),
        .wd(writedataM),
        .rd(readdataM)
    );

    // Board-level simple completion indicator.
    // The final test program loops at PC = 0x2C.
    assign done = (pcF == 32'h0000002C);

endmodule
