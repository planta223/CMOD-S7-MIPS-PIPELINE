module hazard_unit (
    input  wire [4:0] rsD,
    input  wire [4:0] rtD,
    input  wire [4:0] rsE,
    input  wire [4:0] rtE,
    input  wire [4:0] writeregE,
    input  wire [4:0] writeregM,
    input  wire [4:0] writeregW,

    input  wire       regwriteE,
    input  wire       regwriteM,
    input  wire       regwriteW,
    input  wire       memtoregE,
    input  wire       memtoregM,
    input  wire       branchD,
    input  wire       branchneqD,

    output reg  [1:0] forwardAE,
    output reg  [1:0] forwardBE,
    output wire       forwardAD,
    output wire       forwardBD,
    output wire       stallF,
    output wire       stallD,
    output wire       flushE
);

    wire branch_anyD;
    wire lwstall;
    wire branchstall;

    assign branch_anyD = branchD | branchneqD;

    always @(*) begin
        if (regwriteM && (writeregM != 5'b0) && (writeregM == rsE))
            forwardAE = 2'b10;
        else if (regwriteW && (writeregW != 5'b0) && (writeregW == rsE))
            forwardAE = 2'b01;
        else
            forwardAE = 2'b00;
    end

    always @(*) begin
        if (regwriteM && (writeregM != 5'b0) && (writeregM == rtE))
            forwardBE = 2'b10;
        else if (regwriteW && (writeregW != 5'b0) && (writeregW == rtE))
            forwardBE = 2'b01;
        else
            forwardBE = 2'b00;
    end

    assign forwardAD = regwriteM && (writeregM != 5'b0) && (writeregM == rsD);
    assign forwardBD = regwriteM && (writeregM != 5'b0) && (writeregM == rtD);

    assign lwstall = memtoregE && ((rtE == rsD) || (rtE == rtD));

    assign branchstall = branch_anyD &&
        (
            (regwriteE && (writeregE != 5'b0) &&
                ((writeregE == rsD) || (writeregE == rtD))) ||
            (memtoregM && (writeregM != 5'b0) &&
                ((writeregM == rsD) || (writeregM == rtD)))
        );

    assign stallF = lwstall | branchstall;
    assign stallD = lwstall | branchstall;
    assign flushE = lwstall | branchstall;

endmodule
