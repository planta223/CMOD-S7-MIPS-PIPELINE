# CMOD-S7-MIPS-PIPELINE

Digilent Cmod S7-25 보드를 대상으로 32-bit MIPS Pipeline Processor를 Verilog RTL로 구현하고, Vivado에서 기능 검증 및 타이밍 분석을 수행한 프로젝트입니다.

## 개발 환경

* Board: Digilent Cmod S7-25
* FPGA: Xilinx Spartan-7 XC7S25
* Tool: Xilinx Vivado 2019.2
* HDL: Verilog
* Simulation: Vivado XSim

## 프로젝트 목표

Logisim으로 설계한 5-stage Pipelined MIPS Processor를 기반으로 주요 모듈을 Verilog RTL로 재구현한다. 이후 테스트벤치를 통해 기능 동작을 검증하고, Vivado Synthesis 및 Implementation 결과를 바탕으로 타이밍 성능을 분석한다. 최종적으로 이전 Single-cycle MIPS 구현과 클럭 주기 및 최대 동작 주파수 관점에서 비교한다.

## 구현 범위

* 5-stage pipeline 구조

  * IF: Instruction Fetch
  * ID: Instruction Decode
  * EX: Execute
  * MEM: Memory Access
  * WB: Write Back

* 주요 RTL 모듈

  * `reg_if_id`
  * `reg_id_ex`
  * `reg_ex_mem`
  * `reg_mem_wb`
  * `hazard_unit`
  * `datapath_pipeline`
  * `top_mips_pipeline`
  * `top_mips_pipeline_timing`

* 지원 명령어

  * `addi`
  * `add`
  * `sub`
  * `lw`
  * `sw`
  * `beq`
  * `j`

* Hazard 처리

  * EX/MEM forwarding
  * MEM/WB forwarding
  * Load-use stall
  * Branch flush
  * Jump flush

## 기능 검증

Vivado XSim 기반 테스트벤치를 작성하여 pipeline 동작을 검증하였다.

검증 프로그램은 다음 기능을 포함한다.

* `addi`를 통한 레지스터 초기화
* EX/MEM forwarding 검증
* `sw`, `lw` 메모리 접근 검증
* Load-use hazard stall 검증
* Branch flush 검증
* Jump flush 검증
* 잘못 실행되면 안 되는 명령어의 무효화 확인

최종 시뮬레이션 결과:

```text
[PASS] Pipelined MIPS basic_test passed.
```

주요 결과:

```text
$1 = 00000005
$2 = 0000000a
$3 = 0000000a
$4 = 00000005
$5 = 00000000
$6 = 00000000

M[0x00] = 0000000a
M[0x04] = 00000000
M[0x08] = 00000005
```

## Synthesis Timing 결과

Vivado Synthesis 단계에서 clock period를 변화시키며 timing constraint 만족 여부를 확인하였다.

| 순번 | CLK Period (ns) | Clock Frequency (MHz) | WNS (ns) | Pass/Fail |
| -: | --------------: | --------------------: | -------: | --------- |
|  1 |          10.000 |                 100.0 |    1.788 | Pass      |
|  2 |           8.500 |                 117.6 |    0.288 | Pass      |
|  3 |           8.250 |                 121.2 |    0.038 | Pass      |
|  4 |           8.000 |                 125.0 |   -0.212 | Fail      |
|  5 |           5.000 |                 200.0 |   -3.220 | Fail      |

Synthesis 기준으로는 약 8.25 ns, 즉 약 121 MHz 부근까지 timing을 만족하였다.

## Implementation Timing 결과

Implementation 이후 실제 placement 및 routing이 반영된 timing analysis를 수행하였다.

| 순번 | CLK Period (ns) | Clock Frequency (MHz) | WNS (ns) | WHS (ns) | Pass/Fail |
| -: | --------------: | --------------------: | -------: | -------: | --------- |
|  1 |           8.250 |                 121.2 |    0.251 |    0.082 | Pass      |
|  2 |           8.000 |                 125.0 |    0.376 |    0.067 | Pass      |
|  3 |           7.500 |                 133.3 |    0.145 |    0.098 | Pass      |
|  4 |           7.250 |                 137.9 |   -0.354 |    0.086 | Fail      |

Implementation 기준으로는 7.50 ns, 즉 약 133.3 MHz까지 timing을 만족하였다. 7.25 ns에서는 setup timing violation이 발생하였으므로, 본 설계의 안정적인 최대 동작 주파수는 약 133 MHz 수준으로 판단된다.

## 현재 진행 상황

* RTL 설계 완료
* 테스트벤치 작성 완료
* Vivado XSim 기능 검증 완료
* Synthesis timing analysis 완료
* Implementation timing analysis 완료
* FPGA 보드 업로드 및 실보드 동작 검증은 미수행
* Single-cycle MIPS와의 timing 결과 비교 정리 예정

## 비고

본 프로젝트는 Cmod S7-25 보드를 대상으로 한 FPGA implementation timing 분석까지 수행하였다. 실제 보드 업로드는 필수 검증 범위에서 제외하였으며, 현재 결과는 Vivado Synthesis 및 Implementation timing report를 기준으로 한다.
