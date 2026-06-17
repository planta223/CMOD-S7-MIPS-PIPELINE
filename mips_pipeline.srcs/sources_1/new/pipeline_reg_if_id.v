module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        reset,
    input  wire        en,
    input  wire        clear,
    input  wire [31:0] instrF,
    input  wire [31:0] pcplus4F,
    output reg  [31:0] instrD,
    output reg  [31:0] pcplus4D
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instrD   <= 32'b0;
            pcplus4D <= 32'b0;
        end else if (en) begin
            if (clear) begin
                instrD   <= 32'b0;
                pcplus4D <= 32'b0;
            end else begin
                instrD   <= instrF;
                pcplus4D <= pcplus4F;
            end
        end
    end

endmodule
