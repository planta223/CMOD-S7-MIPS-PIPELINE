module pipeline_reg_mem_wb (
    input  wire        clk,
    input  wire        reset,

    input  wire        regwriteM,
    input  wire        memtoregM,
    input  wire [31:0] readdataM,
    input  wire [31:0] aluoutM,
    input  wire [4:0]  writeregM,

    output reg         regwriteW,
    output reg         memtoregW,
    output reg  [31:0] readdataW,
    output reg  [31:0] aluoutW,
    output reg  [4:0]  writeregW
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteW <= 1'b0;
            memtoregW <= 1'b0;
            readdataW <= 32'b0;
            aluoutW   <= 32'b0;
            writeregW <= 5'b0;
        end else begin
            regwriteW <= regwriteM;
            memtoregW <= memtoregM;
            readdataW <= readdataM;
            aluoutW   <= aluoutM;
            writeregW <= writeregM;
        end
    end

endmodule
