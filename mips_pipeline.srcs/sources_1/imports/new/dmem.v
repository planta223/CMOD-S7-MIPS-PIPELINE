module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  addr,
    input  wire [31:0] wd,

    output wire [31:0] rd
);

    reg [31:0] ram [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= wd;
        end
    end

    assign rd = ram[addr];

endmodule