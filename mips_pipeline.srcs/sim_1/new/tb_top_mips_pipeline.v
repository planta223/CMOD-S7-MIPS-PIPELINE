`timescale 1ns/1ps

module tb_top_mips_pipeline;

    // ============================================================
    // Clock / Reset
    // ============================================================
    reg clk;
    reg reset;

    // ============================================================
    // DUT debug outputs
    // ============================================================
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] aluout;
    wire [31:0] writedata;
    wire [31:0] readdata;
    wire        done;

    integer error_count;

    // ============================================================
    // DUT
    // ============================================================
    top_mips_pipeline dut (
        .clk       (clk),
        .reset     (reset),

        .pc        (pc),
        .instr     (instr),
        .aluout    (aluout),
        .writedata (writedata),
        .readdata  (readdata),

        .done      (done)
    );

    // ============================================================
    // Clock generation: 100 MHz, 10 ns period
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Test sequence
    // ============================================================
    initial begin
        error_count = 0;

        reset = 1'b1;
        #25;
        reset = 1'b0;

        // Pipeline completion margin.
        // 충분히 긴 시간 동안 실행시킨 뒤 register/memory 최종값 확인.
        repeat (120) @(posedge clk);

        $display("==================================================");
        $display(" Pipelined MIPS Simulation Result");
        $display("==================================================");
        $display("pc        = %h", pc);
        $display("instr     = %h", instr);
        $display("aluout    = %h", aluout);
        $display("writedata = %h", writedata);
        $display("readdata  = %h", readdata);
        $display("done      = %b", done);
        $display("--------------------------------------------------");

        $display("$1 = %h", dut.datapath_inst.regfile_inst.rf[1]);
        $display("$2 = %h", dut.datapath_inst.regfile_inst.rf[2]);
        $display("$3 = %h", dut.datapath_inst.regfile_inst.rf[3]);
        $display("$4 = %h", dut.datapath_inst.regfile_inst.rf[4]);
        $display("$5 = %h", dut.datapath_inst.regfile_inst.rf[5]);
        $display("$6 = %h", dut.datapath_inst.regfile_inst.rf[6]);

        $display("--------------------------------------------------");
        $display("M[0x00] = %h", dut.dmem_inst.ram[8'h00]);
        $display("M[0x04] = %h", dut.dmem_inst.ram[8'h04]);
        $display("M[0x08] = %h", dut.dmem_inst.ram[8'h08]);
        $display("==================================================");

        // ========================================================
        // Expected register values
        // ========================================================
        if (dut.datapath_inst.regfile_inst.rf[1] !== 32'h00000005) begin
            $display("ERROR: $1 expected 00000005, got %h",
                     dut.datapath_inst.regfile_inst.rf[1]);
            error_count = error_count + 1;
        end

        if (dut.datapath_inst.regfile_inst.rf[2] !== 32'h0000000A) begin
            $display("ERROR: $2 expected 0000000A, got %h",
                     dut.datapath_inst.regfile_inst.rf[2]);
            error_count = error_count + 1;
        end

        if (dut.datapath_inst.regfile_inst.rf[3] !== 32'h0000000A) begin
            $display("ERROR: $3 expected 0000000A, got %h",
                     dut.datapath_inst.regfile_inst.rf[3]);
            error_count = error_count + 1;
        end

        if (dut.datapath_inst.regfile_inst.rf[4] !== 32'h00000005) begin
            $display("ERROR: $4 expected 00000005, got %h",
                     dut.datapath_inst.regfile_inst.rf[4]);
            error_count = error_count + 1;
        end

        if (dut.datapath_inst.regfile_inst.rf[5] !== 32'h00000000) begin
            $display("ERROR: $5 expected 00000000, got %h",
                     dut.datapath_inst.regfile_inst.rf[5]);
            error_count = error_count + 1;
        end

        if (dut.datapath_inst.regfile_inst.rf[6] !== 32'h00000000) begin
            $display("ERROR: $6 expected 00000000, got %h",
                     dut.datapath_inst.regfile_inst.rf[6]);
            error_count = error_count + 1;
        end

        // ========================================================
        // Expected memory values
        // ========================================================
        if (dut.dmem_inst.ram[8'h00] !== 32'h0000000A) begin
            $display("ERROR: M[0x00] expected 0000000A, got %h",
                     dut.dmem_inst.ram[8'h00]);
            error_count = error_count + 1;
        end

        if (dut.dmem_inst.ram[8'h04] !== 32'h00000000) begin
            $display("ERROR: M[0x04] expected 00000000, got %h",
                     dut.dmem_inst.ram[8'h04]);
            error_count = error_count + 1;
        end

        if (dut.dmem_inst.ram[8'h08] !== 32'h00000005) begin
            $display("ERROR: M[0x08] expected 00000005, got %h",
                     dut.dmem_inst.ram[8'h08]);
            error_count = error_count + 1;
        end

        // ========================================================
        // Final result
        // ========================================================
        if (error_count == 0) begin
            $display("==================================================");
            $display(" TEST PASSED");
            $display("==================================================");
        end else begin
            $display("==================================================");
            $display(" TEST FAILED: %0d error(s)", error_count);
            $display("==================================================");
        end

        #20;
        $finish;
    end

endmodule
