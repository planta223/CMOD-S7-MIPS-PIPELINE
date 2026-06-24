# CMOD-S7-MIPS-PIPELINE

> **Status:** Completed on 2026-06-18

Digilent Cmod S7-25 보드를 대상으로 32-bit 5-stage Pipelined MIPS Processor를 Verilog RTL로 구현하고, Vivado에서 기능 검증 및 타이밍 분석을 수행한 프로젝트입니다.

## 개발 환경

* Board: Digilent Cmod S7-25
* FPGA: Xilinx Spartan-7 XC7S25
* Tool: Xilinx Vivado 2019.2
* HDL: Verilog
* Simulation: Vivado XSim

## 프로젝트 목표

Logisim으로 설계한 5-stage Pipelined MIPS Processor를 Verilog RTL로 재구현한다. 이후 테스트벤치를 통해 기능 동작을 검증하고, Vivado Synthesis 및 Implementation 결과를 바탕으로 타이밍 성능을 분석한다. 최종적으로 이전 Single-cycle MIPS 구현과 클럭 주기 및 최대 동작 주파수 관점에서 비교한다.

## 구현 범위

* 5-stage pipeline 구조

  * IF: Instruction Fetch
  * ID: Instruction Decode
  * EX: Execute
  * MEM: Memory Access
  * WB: Write Back

* 주요 RTL 모듈

  * `pipeline_reg_if_id`
  * `pipeline_reg_id_ex`
  * `pipeline_reg_ex_mem`
  * `pipeline_reg_mem_wb`
  * `hazard_unit`
  * `datapath_pipeline`
  * `top_mips_pipeline`
  * `top_mips_pipeline_timing`

* 재사용 모듈

  * `alu`
  * `alu_decoder`
  * `main_decoder`
  * `controller`
  * `regfile`
  * `imem`
  * `dmem`

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
* EX/MEM 및 MEM/WB forwarding 검증
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
|  1 |          12.500 |                  80.0 |    4.288 | Pass      |
|  2 |          10.000 |                 100.0 |    1.788 | Pass      |
|  3 |           8.500 |                 117.6 |    0.288 | Pass      |
|  4 |           8.250 |                 121.2 |    0.038 | Pass      |
|  5 |           8.000 |                 125.0 |   -0.212 | Fail      |

결과적으로 8.25 ns 조건에서는 timing을 만족하였고, 8.00 ns 조건에서는 setup timing violation이 발생하였다. 8.25 ns 조건의 WNS를 기준으로 critical path delay는 8.25 - 0.038 = 8.212 ns로 계산되며, synthesis 기준 최대 동작 주파수는 약 121.8 MHz로 추정된다.

## Implementation Timing 결과

Implementation 이후 실제 placement 및 routing이 반영된 timing analysis를 수행하였다.

| 순번 | CLK Period (ns) | Clock Frequency (MHz) | WNS (ns) | Pass/Fail |
| -: | --------------: | --------------------: | -------: | --------- |
|  1 |           8.250 |                 121.2 |    0.251 | Pass      |
|  2 |           8.000 |                 125.0 |    0.376 | Pass      |
|  3 |           7.500 |                 133.3 |    0.145 | Pass      |
|  4 |           7.250 |                 137.9 |   -0.354 | Fail      |

Implementation 결과에서는 8.25 ns 조건보다 8.00 ns 조건에서 WNS가 더 크게 나타났다. 이는 implementation 단계에서 clock constraint에 따라 placement, routing, physical optimization 결과가 달라질 수 있기 때문이다.

결과적으로 7.50 ns 조건에서는 timing을 만족하였고, 7.25 ns 조건에서는 setup timing violation이 발생하였다. 따라서 implementation 기준 최대 동작 주파수는 133.3 MHz와 137.9 MHz 사이에 존재한다고 볼 수 있다. 7.50 ns 조건의 WNS를 이용하면 critical path delay는 7.50 - 0.145 = 7.355 ns이고, 이에 따른 최대 동작 주파수는 약 136.0 MHz로 추정된다.

## 현재 진행 상황

* RTL 설계 완료
* 테스트벤치 작성 완료
* Vivado XSim 기능 검증 완료
* Synthesis timing analysis 완료
* Implementation timing analysis 완료
* Single-cycle MIPS와의 timing 결과 비교 완료
* FPGA 보드 업로드 및 실보드 동작 검증은 미수행

## 비고

본 프로젝트는 Cmod S7-25 보드를 대상으로 한 FPGA implementation timing 분석까지 수행하였다. 실제 보드 업로드는 필수 검증 범위에서 제외하였으며, 현재 결과는 Vivado Synthesis 및 Implementation timing report를 기준으로 한다.
