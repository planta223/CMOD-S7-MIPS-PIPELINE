`timescale 1ns/1ps

module top_mips_pipeline_timing (
    input  wire clk,
    input  wire reset,
    output wire done
);

    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] aluout;
    wire [31:0] writedata;
    wire [31:0] readdata;

    (* keep_hierarchy = "yes" *)
    top_mips_pipeline u_top_mips_pipeline (
        .clk       (clk),
        .reset     (reset),

        .pc        (pc),
        .instr     (instr),
        .aluout    (aluout),
        .writedata (writedata),
        .readdata  (readdata),

        .done      (done)
    );

endmodule