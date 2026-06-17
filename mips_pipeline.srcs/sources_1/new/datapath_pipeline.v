module datapath_pipeline (
    input  wire        clk,
    input  wire        reset,

    output wire [23:0] imem_addr,
    input  wire [31:0] instrF,

    output wire        memwriteM,
    output wire [31:0] aluoutM,
    output wire [31:0] writedataM,
    input  wire [31:0] readdataM,

    output wire [31:0] pcF,
    output wire [31:0] instrD,
    output wire [31:0] resultW,

    output wire        stallF,
    output wire        stallD,
    output wire        flushD,
    output wire        flushE,
    output wire [1:0]  forwardAE,
    output wire [1:0]  forwardBE
);

    reg [31:0] pc_reg;

    wire [31:0] pcnextF;
    wire [31:0] pcplus4F;
    wire [31:0] pcplus4D;
    wire [31:0] pcbranchD;
    wire [31:0] pcjumpD;

    wire [5:0] opD;
    wire [5:0] functD;
    wire [4:0] rsD;
    wire [4:0] rtD;
    wire [4:0] rdD;
    wire [15:0] immD;

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

    wire [31:0] rd1D;
    wire [31:0] rd2D;
    wire [31:0] signimmD;
    wire [31:0] zeroimmD;
    wire [31:0] extimmD;
    wire [31:0] srcaD;
    wire [31:0] srcbD;
    wire        equalD;
    wire        pcsrcD_raw;
    wire        pcsrcD;

    wire        regwriteE;
    wire        memtoregE;
    wire        memwriteE;
    wire        alusrcE;
    wire        regdstE;
    wire [2:0]  alucontrolE;
    wire [31:0] rd1E;
    wire [31:0] rd2E;
    wire [31:0] extimmE;
    wire [4:0]  rsE;
    wire [4:0]  rtE;
    wire [4:0]  rdE;
    wire [31:0] srcaE;
    wire [31:0] writedataE;
    wire [31:0] srcbE;
    wire [31:0] aluoutE;
    wire        zeroE;
    wire [4:0]  writeregE;

    wire        regwriteM;
    wire        memtoregM;
    wire [4:0]  writeregM;

    wire        regwriteW;
    wire        memtoregW;
    wire [31:0] readdataW;
    wire [31:0] aluoutW;
    wire [4:0]  writeregW;

    wire        forwardAD;
    wire        forwardBD;

    assign pcF       = pc_reg;
    assign pcplus4F  = pc_reg + 32'd4;
    assign imem_addr = pc_reg[23:0] >> 2;

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_reg <= 32'b0;
        else if (!stallF)
            pc_reg <= pcnextF;
    end

    pipeline_reg_if_id if_id_reg (
        .clk(clk),
        .reset(reset),
        .en(~stallD),
        .clear(flushD),
        .instrF(instrF),
        .pcplus4F(pcplus4F),
        .instrD(instrD),
        .pcplus4D(pcplus4D)
    );

    assign opD    = instrD[31:26];
    assign rsD    = instrD[25:21];
    assign rtD    = instrD[20:16];
    assign rdD    = instrD[15:11];
    assign immD   = instrD[15:0];
    assign functD = instrD[5:0];

    controller controller_inst (
        .op(opD),
        .funct(functD),
        .memtoreg(memtoregD),
        .memwrite(memwriteD),
        .branch(branchD),
        .branchneq(branchneqD),
        .alusrc(alusrcD),
        .regdst(regdstD),
        .regwrite(regwriteD),
        .jump(jumpD),
        .zeroext(zeroextD),
        .alucontrol(alucontrolD)
    );

    regfile rf (
        .clk(clk),
        .we3(regwriteW),
        .a1(rsD),
        .a2(rtD),
        .a3(writeregW),
        .wd3(resultW),
        .rd1(rd1D),
        .rd2(rd2D)
    );

    assign signimmD = {{16{immD[15]}}, immD};
    assign zeroimmD = {16'b0, immD};
    assign extimmD  = zeroextD ? zeroimmD : signimmD;

    assign srcaD  = forwardAD ? aluoutM : rd1D;
    assign srcbD  = forwardBD ? aluoutM : rd2D;
    assign equalD = (srcaD == srcbD);

    assign pcbranchD  = pcplus4D + (signimmD << 2);
    assign pcjumpD    = {pcplus4D[31:28], instrD[25:0], 2'b00};
    assign pcsrcD_raw = (branchD & equalD) | (branchneqD & ~equalD);
    assign pcsrcD     = pcsrcD_raw & ~stallD;
    assign flushD     = (pcsrcD | jumpD) & ~stallD;
    assign pcnextF    = jumpD  ? pcjumpD   :
                        pcsrcD ? pcbranchD :
                                 pcplus4F;

    pipeline_reg_id_ex id_ex_reg (
        .clk(clk),
        .reset(reset),
        .clear(flushE),
        .regwriteD(regwriteD),
        .memtoregD(memtoregD),
        .memwriteD(memwriteD),
        .alusrcD(alusrcD),
        .regdstD(regdstD),
        .alucontrolD(alucontrolD),
        .rd1D(rd1D),
        .rd2D(rd2D),
        .extimmD(extimmD),
        .rsD(rsD),
        .rtD(rtD),
        .rdD(rdD),
        .regwriteE(regwriteE),
        .memtoregE(memtoregE),
        .memwriteE(memwriteE),
        .alusrcE(alusrcE),
        .regdstE(regdstE),
        .alucontrolE(alucontrolE),
        .rd1E(rd1E),
        .rd2E(rd2E),
        .extimmE(extimmE),
        .rsE(rsE),
        .rtE(rtE),
        .rdE(rdE)
    );

    assign writeregE = regdstE ? rdE : rtE;

    assign srcaE = (forwardAE == 2'b10) ? aluoutM :
                   (forwardAE == 2'b01) ? resultW :
                                           rd1E;

    assign writedataE = (forwardBE == 2'b10) ? aluoutM :
                        (forwardBE == 2'b01) ? resultW :
                                                rd2E;

    assign srcbE = alusrcE ? extimmE : writedataE;

    alu alu_inst (
        .a(srcaE),
        .b(srcbE),
        .alucontrol(alucontrolE),
        .result(aluoutE),
        .zero(zeroE)
    );

    pipeline_reg_ex_mem ex_mem_reg (
        .clk(clk),
        .reset(reset),
        .regwriteE(regwriteE),
        .memtoregE(memtoregE),
        .memwriteE(memwriteE),
        .aluoutE(aluoutE),
        .writedataE(writedataE),
        .writeregE(writeregE),
        .regwriteM(regwriteM),
        .memtoregM(memtoregM),
        .memwriteM(memwriteM),
        .aluoutM(aluoutM),
        .writedataM(writedataM),
        .writeregM(writeregM)
    );

    pipeline_reg_mem_wb mem_wb_reg (
        .clk(clk),
        .reset(reset),
        .regwriteM(regwriteM),
        .memtoregM(memtoregM),
        .readdataM(readdataM),
        .aluoutM(aluoutM),
        .writeregM(writeregM),
        .regwriteW(regwriteW),
        .memtoregW(memtoregW),
        .readdataW(readdataW),
        .aluoutW(aluoutW),
        .writeregW(writeregW)
    );

    assign resultW = memtoregW ? readdataW : aluoutW;

    hazard_unit hazard_unit_inst (
        .rsD(rsD),
        .rtD(rtD),
        .rsE(rsE),
        .rtE(rtE),
        .writeregE(writeregE),
        .writeregM(writeregM),
        .writeregW(writeregW),
        .regwriteE(regwriteE),
        .regwriteM(regwriteM),
        .regwriteW(regwriteW),
        .memtoregE(memtoregE),
        .memtoregM(memtoregM),
        .branchD(branchD),
        .branchneqD(branchneqD),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE),
        .forwardAD(forwardAD),
        .forwardBD(forwardBD),
        .stallF(stallF),
        .stallD(stallD),
        .flushE(flushE)
    );

endmodule
