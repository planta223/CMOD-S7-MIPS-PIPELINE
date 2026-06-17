`timescale 1ns / 1ps

module tb_top_mips_pipeline;
    reg clk;
    reg reset;
    wire done;

    top_mips_pipeline dut (
        .clk(clk),
        .reset(reset),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #22;
        reset = 1'b0;

        repeat (40) @(posedge clk);

        $display("r1  = %h", dut.datapath_inst.rf.rf[1]);
        $display("r2  = %h", dut.datapath_inst.rf.rf[2]);
        $display("r3  = %h", dut.datapath_inst.rf.rf[3]);
        $display("r4  = %h", dut.datapath_inst.rf.rf[4]);
        $display("r5  = %h", dut.datapath_inst.rf.rf[5]);
        $display("r6  = %h", dut.datapath_inst.rf.rf[6]);
        $display("M0  = %h", dut.dmem_inst.ram[0]);
        $display("M4  = %h", dut.dmem_inst.ram[4]);
        $display("M8  = %h", dut.dmem_inst.ram[8]);

        if (dut.datapath_inst.rf.rf[1] !== 32'h00000005) $fatal(1, "r1 mismatch");
        if (dut.datapath_inst.rf.rf[2] !== 32'h0000000a) $fatal(1, "r2 mismatch");
        if (dut.datapath_inst.rf.rf[3] !== 32'h0000000a) $fatal(1, "r3 mismatch");
        if (dut.datapath_inst.rf.rf[4] !== 32'h00000005) $fatal(1, "r4 mismatch");
        if (dut.datapath_inst.rf.rf[5] !== 32'h00000000) $fatal(1, "r5 must be flushed");
        if (dut.datapath_inst.rf.rf[6] !== 32'h00000000) $fatal(1, "r6 must be flushed");
        if (dut.dmem_inst.ram[0] !== 32'h0000000a) $fatal(1, "M[0] mismatch");
        if (dut.dmem_inst.ram[4] !== 32'h00000000) $fatal(1, "M[4] must not be written");
        if (dut.dmem_inst.ram[8] !== 32'h00000005) $fatal(1, "M[8] mismatch");

        $display("PIPELINE TEST PASS");
        $finish;
    end
endmodule
