module alu_decoder (
    input  wire [1:0] aluop,
    input  wire [5:0] funct,
    output reg  [2:0] alucontrol
);

    always @(*) begin
        case (aluop)
            2'b00: alucontrol = 3'b010; // ADD: lw, sw, addi
            2'b01: alucontrol = 3'b110; // SUB: beq, bne
            2'b11: alucontrol = 3'b001; // OR: ori

            2'b10: begin
                case (funct)
                    6'b100000: alucontrol = 3'b010; // add, optional
                    6'b100010: alucontrol = 3'b110; // sub
                    6'b100100: alucontrol = 3'b000; // and, optional
                    6'b100101: alucontrol = 3'b001; // or
                    6'b101010: alucontrol = 3'b111; // slt
                    6'b100011: alucontrol = 3'b011; // abs
                    default:   alucontrol = 3'b010;
                endcase
            end

            default: alucontrol = 3'b010;
        endcase
    end

endmodule