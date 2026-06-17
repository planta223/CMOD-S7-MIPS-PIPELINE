module imem (
    input  wire [23:0] addr,
    output wire [31:0] instr
);

    reg [31:0] rom [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            rom[i] = 32'h00000000; // NOP
        end

        $readmemh("basic_test.hex", rom);
    end

    assign instr = rom[addr[5:0]];

endmodule