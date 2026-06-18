`timescale 1ns/1ps

module tb_top_mips_pipeline;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] aluout;
    wire [31:0] writedata;
    wire [31:0] readdata;
    wire        done;

    integer cycle;
    integer errors;
    integer wrote_r5;
    integer wrote_r6;
    integer saw_done;

    // ============================================================
    // DUT: wrapper 없이 top_mips_pipeline 직접 검증
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
    // 100 MHz clock: period = 10 ns
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Cycle trace 및 오류 명령어 write 감시
    // ============================================================
    always @(posedge clk) begin
        if (reset) begin
            cycle    <= 0;
            wrote_r5 <= 0;
            wrote_r6 <= 0;
            saw_done <= 0;
        end else begin
            cycle <= cycle + 1;

            if (done) begin
                saw_done <= 1;
            end

            // branch flush가 제대로 되면 $5는 write되지 않아야 함
            if (dut.datapath_inst.regwriteW &&
                (dut.datapath_inst.writeregW == 5'd5)) begin

                wrote_r5 <= 1;
                $display("[ERROR] unexpected write to $5 at cycle=%0d pc=%h instr=%h resultW=%h",
                         cycle, pc, instr, dut.datapath_inst.resultW);
            end

            // jump flush가 제대로 되면 $6은 write되지 않아야 함
            if (dut.datapath_inst.regwriteW &&
                (dut.datapath_inst.writeregW == 5'd6)) begin

                wrote_r6 <= 1;
                $display("[ERROR] unexpected write to $6 at cycle=%0d pc=%h instr=%h resultW=%h",
                         cycle, pc, instr, dut.datapath_inst.resultW);
            end
        end
    end

    // ============================================================
    // 사람이 waveform 없이도 흐름을 볼 수 있는 trace
    // ============================================================
    always @(negedge clk) begin
        if (!reset) begin
            $display("cycle=%0d pc=%h instr=%h aluout=%h wd=%h rd=%h done=%b | stallF=%b stallD=%b flushD=%b flushE=%b fAE=%b fBE=%b regW_E/M/W=%b/%b/%b memW=%b",
                     cycle,
                     pc,
                     instr,
                     aluout,
                     writedata,
                     readdata,
                     done,
                     dut.datapath_inst.stallF,
                     dut.datapath_inst.stallD,
                     dut.datapath_inst.flushD,
                     dut.datapath_inst.flushE,
                     dut.datapath_inst.forwardAE,
                     dut.datapath_inst.forwardBE,
                     dut.datapath_inst.regwriteE,
                     dut.datapath_inst.regwriteM,
                     dut.datapath_inst.regwriteW,
                     dut.datapath_inst.memwriteM);
        end
    end

    // ============================================================
    // Main test sequence
    // ============================================================
    initial begin
        errors   = 0;
        cycle    = 0;
        wrote_r5 = 0;
        wrote_r6 = 0;
        saw_done = 0;

        reset = 1'b1;

        // initial block 및 reset 반영 대기
        #1;

        // -------------------------
        // 초기 상태 검증
        // -------------------------
        check_initial_state();

        // reset 유지 후 해제
        #19;
        reset = 1'b0;

        // 종료 루프 도달 대기
        wait_until_done_or_timeout(80);

        // pipeline에 남은 명령어들이 충분히 빠져나가도록 추가 대기
        repeat (10) @(posedge clk);
        #1;

        // -------------------------
        // 최종 레지스터 상태 검증
        // -------------------------
        check_reg(0, 32'h00000000);
        check_reg(1, 32'h00000005);
        check_reg(2, 32'h0000000A);
        check_reg(3, 32'h0000000A);
        check_reg(4, 32'h00000005);
        check_reg(5, 32'h00000000);
        check_reg(6, 32'h00000000);

        // -------------------------
        // 최종 데이터 메모리 검증
        // -------------------------
        check_mem(8'h00, 32'h0000000A);
        check_mem(8'h04, 32'h00000000);
        check_mem(8'h08, 32'h00000005);

        // -------------------------
        // skip 명령어 실행 여부 검증
        // -------------------------
        if (wrote_r5 !== 0) begin
            errors = errors + 1;
            $display("[FAIL] $5 was written. branch flush did not skip PC=0x18 correctly.");
        end

        if (wrote_r6 !== 0) begin
            errors = errors + 1;
            $display("[FAIL] $6 was written. jump flush did not skip PC=0x20 correctly.");
        end

        // -------------------------
        // done 도달 여부 검증
        // -------------------------
        if (saw_done !== 1) begin
            errors = errors + 1;
            $display("[FAIL] done was never asserted. Termination loop was not reached.");
        end else begin
            $display("[ OK ] done was asserted at least once.");
        end

        // -------------------------
        // 최종 판정
        // -------------------------
        if (errors == 0) begin
            $display("========================================");
            $display("[PASS] Pipelined MIPS basic_test passed.");
            $display("========================================");
        end else begin
            $display("========================================");
            $display("[FAIL] Pipelined MIPS basic_test failed. errors=%0d", errors);
            $display("========================================");
            $fatal;
        end

        $stop;
    end

    // ============================================================
    // 초기 상태 검증 task
    // ============================================================
    task check_initial_state;
        begin
            $display("========================================");
            $display("[INFO] Checking initial state...");
            $display("========================================");

            // -------------------------
            // PC reset 확인
            // -------------------------
            if (pc !== 32'h00000000) begin
                errors = errors + 1;
                $display("[FAIL] initial PC expected=00000000 actual=%h", pc);
            end else begin
                $display("[ OK ] initial PC = %h", pc);
            end

            // -------------------------
            // imem 프로그램 로드 확인
            // -------------------------
            check_imem(6'd0,  32'h20010005); // addi $1, $0, 5
            check_imem(6'd1,  32'h00211020); // add  $2, $1, $1
            check_imem(6'd2,  32'hAC020000); // sw   $2, 0($0)
            check_imem(6'd3,  32'h8C030000); // lw   $3, 0($0)
            check_imem(6'd4,  32'h00612022); // sub  $4, $3, $1
            check_imem(6'd5,  32'h10810001); // beq  $4, $1, 1
            check_imem(6'd6,  32'h20050063); // addi $5, $0, 99
            check_imem(6'd7,  32'h0800000A); // j    10
            check_imem(6'd8,  32'h20060063); // addi $6, $0, 99
            check_imem(6'd9,  32'hAC040004); // sw   $4, 4($0)
            check_imem(6'd10, 32'hAC040008); // sw   $4, 8($0)
            check_imem(6'd11, 32'h1000FFFF); // beq  $0, $0, -1

            // -------------------------
            // regfile 초기화 확인
            // -------------------------
            check_reg(0, 32'h00000000);
            check_reg(1, 32'h00000000);
            check_reg(2, 32'h00000000);
            check_reg(3, 32'h00000000);
            check_reg(4, 32'h00000000);
            check_reg(5, 32'h00000000);
            check_reg(6, 32'h00000000);

            // -------------------------
            // dmem 초기화 확인
            // -------------------------
            check_mem(8'h00, 32'h00000000);
            check_mem(8'h04, 32'h00000000);
            check_mem(8'h08, 32'h00000000);

            // -------------------------
            // pipeline register 초기화 확인
            // -------------------------
            check_pipeline_regs_zero();
        end
    endtask

    // ============================================================
    // Pipeline register 초기화 검증 task
    // ============================================================
    task check_pipeline_regs_zero;
        begin
            $display("========================================");
            $display("[INFO] Checking pipeline register initial values...");
            $display("========================================");

            // IF/ID
            check_value32("IF/ID.instrD",
                          dut.datapath_inst.if_id_reg.instrD,
                          32'h00000000);
            check_value32("IF/ID.pcplus4D",
                          dut.datapath_inst.if_id_reg.pcplus4D,
                          32'h00000000);

            // ID/EX control
            check_value1("ID/EX.regwriteE",
                         dut.datapath_inst.id_ex_reg.regwriteE,
                         1'b0);
            check_value1("ID/EX.memtoregE",
                         dut.datapath_inst.id_ex_reg.memtoregE,
                         1'b0);
            check_value1("ID/EX.memwriteE",
                         dut.datapath_inst.id_ex_reg.memwriteE,
                         1'b0);
            check_value3("ID/EX.alucontrolE",
                         dut.datapath_inst.id_ex_reg.alucontrolE,
                         3'b000);
            check_value1("ID/EX.alusrcE",
                         dut.datapath_inst.id_ex_reg.alusrcE,
                         1'b0);
            check_value1("ID/EX.regdstE",
                         dut.datapath_inst.id_ex_reg.regdstE,
                         1'b0);

            // ID/EX data
            check_value32("ID/EX.rd1E",
                          dut.datapath_inst.id_ex_reg.rd1E,
                          32'h00000000);
            check_value32("ID/EX.rd2E",
                          dut.datapath_inst.id_ex_reg.rd2E,
                          32'h00000000);
            check_value32("ID/EX.signimmE",
                          dut.datapath_inst.id_ex_reg.signimmE,
                          32'h00000000);
            check_value5("ID/EX.rsE",
                         dut.datapath_inst.id_ex_reg.rsE,
                         5'b00000);
            check_value5("ID/EX.rtE",
                         dut.datapath_inst.id_ex_reg.rtE,
                         5'b00000);
            check_value5("ID/EX.rdE",
                         dut.datapath_inst.id_ex_reg.rdE,
                         5'b00000);

            // EX/MEM
            check_value1("EX/MEM.regwriteM",
                         dut.datapath_inst.ex_mem_reg.regwriteM,
                         1'b0);
            check_value1("EX/MEM.memtoregM",
                         dut.datapath_inst.ex_mem_reg.memtoregM,
                         1'b0);
            check_value1("EX/MEM.memwriteM",
                         dut.datapath_inst.ex_mem_reg.memwriteM,
                         1'b0);
            check_value32("EX/MEM.aluoutM",
                          dut.datapath_inst.ex_mem_reg.aluoutM,
                          32'h00000000);
            check_value32("EX/MEM.writedataM",
                          dut.datapath_inst.ex_mem_reg.writedataM,
                          32'h00000000);
            check_value5("EX/MEM.writeregM",
                         dut.datapath_inst.ex_mem_reg.writeregM,
                         5'b00000);

            // MEM/WB
            check_value1("MEM/WB.regwriteW",
                         dut.datapath_inst.mem_wb_reg.regwriteW,
                         1'b0);
            check_value1("MEM/WB.memtoregW",
                         dut.datapath_inst.mem_wb_reg.memtoregW,
                         1'b0);
            check_value32("MEM/WB.readdataW",
                          dut.datapath_inst.mem_wb_reg.readdataW,
                          32'h00000000);
            check_value32("MEM/WB.aluoutW",
                          dut.datapath_inst.mem_wb_reg.aluoutW,
                          32'h00000000);
            check_value5("MEM/WB.writeregW",
                         dut.datapath_inst.mem_wb_reg.writeregW,
                         5'b00000);
        end
    endtask

    // ============================================================
    // Register File 검증 task
    // ============================================================
    task check_reg;
        input [4:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            if (idx == 5'd0) begin
                actual = 32'h00000000;
            end else begin
                actual = dut.datapath_inst.regfile_inst.rf[idx];
            end

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] reg[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] reg[%0d] = %h", idx, actual);
            end
        end
    endtask

    // ============================================================
    // Data Memory 검증 task
    // ============================================================
    task check_mem;
        input [7:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            actual = dut.dmem_inst.ram[idx];

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] dmem[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] dmem[%0d] = %h", idx, actual);
            end
        end
    endtask

    // ============================================================
    // Instruction Memory 검증 task
    // ============================================================
    task check_imem;
        input [5:0] idx;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            actual = dut.imem_inst.rom[idx];

            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] imem[%0d] expected=%h actual=%h", idx, expected, actual);
            end else begin
                $display("[ OK ] imem[%0d] = %h", idx, actual);
            end
        end
    endtask

    // ============================================================
    // Generic value check tasks
    // ============================================================
    task check_value1;
        input [255:0] name;
        input         actual;
        input         expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s expected=%b actual=%b", name, expected, actual);
            end else begin
                $display("[ OK ] %0s = %b", name, actual);
            end
        end
    endtask

    task check_value3;
        input [255:0] name;
        input [2:0]   actual;
        input [2:0]   expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s expected=%b actual=%b", name, expected, actual);
            end else begin
                $display("[ OK ] %0s = %b", name, actual);
            end
        end
    endtask

    task check_value5;
        input [255:0] name;
        input [4:0]   actual;
        input [4:0]   expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s expected=%b actual=%b", name, expected, actual);
            end else begin
                $display("[ OK ] %0s = %b", name, actual);
            end
        end
    endtask

    task check_value32;
        input [255:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0s expected=%h actual=%h", name, expected, actual);
            end else begin
                $display("[ OK ] %0s = %h", name, actual);
            end
        end
    endtask

    // ============================================================
    // done 도달 대기 task
    // ============================================================
    task wait_until_done_or_timeout;
        input integer max_cycles;
        integer k;
        begin
            k = 0;

            while ((done !== 1'b1) && (k < max_cycles)) begin
                @(posedge clk);
                #1;
                k = k + 1;
            end

            if (done !== 1'b1) begin
                errors = errors + 1;
                $display("[FAIL] timeout: done was not asserted within %0d cycles. final pc=%h",
                         max_cycles, pc);
            end else begin
                $display("[ OK ] done asserted. cycle=%0d pc=%h", cycle, pc);
            end
        end
    endtask

endmodule