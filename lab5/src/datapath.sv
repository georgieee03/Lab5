module datapath(
    input logic clk, reset,

    // Control signals
    output logic [31:0] instr_ID,
    input  logic        memtoreg_ID,
    input  logic        memwrite_ID,
    input  logic        alusrc_ID,
    input  logic        regdst_ID,
    input  logic        regwrite_ID,
    input  logic        jump_ID,
    input  logic        branch_ID,
    input  logic        readperf_ID,
    input  logic [2:0]  alucontrol_ID,

    // Instruction memory interface
    output logic [31:0] pc_IF,
    input  logic [31:0] instr_IF,

    // Data memory interface
    output logic [31:0] aluout_MEM, writedata_MEM,
    input  logic [31:0] readdata_MEM,
    output logic        memwrite_MEM
);

    // Internal signals
    logic stall, flush_ID;
    logic flush_EX;

    logic [31:0] pcnextbr, pcjump;
    logic [31:0] pcnext_IF;
    logic [31:0] pcplus4_IF;

    logic [31:0] pcplus4_ID, signimm_ID, srca_ID, writedata_ID, srcc_ID;
    logic [31:0] signimmsh_ID, pcbranch_ID;

    logic memtoreg_EX, memwrite_EX, alusrc_EX, regdst_EX, regwrite_EX;
    logic [2:0] alucontrol_EX;
    logic [31:0] pcplus4_EX, srca_EX, writedata_EX, signimm_EX, instr_EX;
    logic [31:0] srcb_EX, srcc_EX, aluout_EX;
    logic [4:0] writereg_EX;

    logic memtoreg_MEM, regwrite_MEM;
    logic [4:0] writereg_MEM;

    logic memtoreg_WB, regwrite_WB;
    logic [31:0] aluout_WB, readdata_WB;
    logic [4:0] writereg_WB;
    logic [31:0] result_WB;

    logic bubble_EX, bubble_MEM, bubble_WB;
    logic perf_flag_EX, perf_flag_MEM, perf_flag_WB;
    logic readperf_EX, readperf_MEM, readperf_WB;
    logic [31:0] cycle_cnt, instr_cnt;
    logic [31:0] reg_result_WB, perf_result_WB;

    logic [1:0] forward_A, forward_B;
    logic [31:0] srca_regular, writedata_regular;

    // IF
    mux2 #(32) pcbrmux(
        .d0(pcplus4_IF),
        .d1(pcbranch_ID),
        .s(pcsrc_ID),
        .y(pcnextbr)
    );
    assign pcjump = {pcplus4_IF[31:28], instr_ID[25:0], 2'b00};
    mux2 #(32) pcmux(
        .d0(pcnextbr),
        .d1(pcjump),
        .s(jump_ID),
        .y(pcnext_IF)
    );
    flopr #(32) pcreg(
        .clk(clk),
        .reset(reset),
        .en(!stall),
        .d(pcnext_IF),
        .q(pc_IF)
    );
    adder pcadd1(.a(pc_IF), .b(32'd4), .y(pcplus4_IF));

    // IF/ID
    if_id if_id(
        .clk,
        .reset,
        .stall,
        .pcplus4_IF,
        .instr_IF,
        .pcplus4_ID,
        .instr_ID
    );

    // ID
    regfile rf(
        .clk(clk),
        .we3(regwrite_WB),
        .ra1(instr_ID[25:21]),
        .ra2(instr_ID[20:16]),
        .ra3(instr_ID[15:11]), // for MULADD
        .wa3(writereg_WB),
        .wd3(result_WB),
        .rd1(srca_ID),
        .rd2(writedata_ID),
        .rd3(srcc_ID) // for MULADD
    );
    signext se(.a(instr_ID[15:0]), .y(signimm_ID));
    sl2 immsh(.a(signimm_ID), .y(signimmsh_ID));
    adder pcadd2(.a(pcplus4_ID), .b(signimmsh_ID), .y(pcbranch_ID));
    assign pcsrc_ID = branch_ID && (srca_ID == writedata_ID);

    // ID/EX
    id_ex id_ex(
        .clk,
        .reset,
        .stall,
        .flush_EX,
        .readperf_ID,
        .memtoreg_ID,
        .memwrite_ID,
        .alusrc_ID,
        .regdst_ID,
        .regwrite_ID,
        .alucontrol_ID,
        .pcplus4_ID,
        .srca_ID,
        .srcc_ID,
        .writedata_ID,
        .signimm_ID,
        .instr_ID,
        .readperf_EX,
        .memtoreg_EX,
        .memwrite_EX,
        .alusrc_EX,
        .regdst_EX,
        .regwrite_EX,
        .alucontrol_EX,
        .pcplus4_EX,
        .srca_EX(srca_regular),
        .srcc_EX,
        .writedata_EX(writedata_regular),
        .signimm_EX,
        .instr_EX
    );

    // Forwarding logic
    always_comb begin
        if (forward_A == 2'b01)
            srca_EX = aluout_MEM; // Forward from MEM stage
        else if (forward_A == 2'b10)
            srca_EX = result_WB; // Forward from WB stage
        else
            srca_EX = srca_regular; // No forwarding
    end
    always_comb begin
        if (forward_B == 2'b01)
            writedata_EX = aluout_MEM; // Forward from MEM stage
        else if (forward_B == 2'b10)
            writedata_EX = result_WB; // Forward from WB stage
        else
            writedata_EX = writedata_regular; // No forwarding
    end

    // EX
    mux2 #(32) srcbmux(
        .d0(writedata_EX),
        .d1(signimm_EX),
        .s(alusrc_EX),
        .y(srcb_EX)
    );
    alu alu(
        .a(srca_EX),
        .b(srcb_EX),
        .c(srcc_EX), // for MULADD
        .control(alucontrol_EX),
        .result(aluout_EX)
    );
    mux2 #(5) wrmux(
        .d0(instr_EX[20:16]),
        .d1(instr_EX[15:11]),
        .s(regdst_EX),
        .y(writereg_EX)
    );
    assign bubble_EX = (instr_EX == 32'd0);
    assign perf_flag_EX = instr_EX[0];
    
    // EX/MEM
    ex_mem ex_mem(
        .clk,
        .reset,
        .bubble_EX,
        .readperf_EX,
        .perf_flag_EX,
        .memtoreg_EX,
        .memwrite_EX,
        .regwrite_EX,
        .aluout_EX,
        .writedata_EX,
        .writereg_EX,
        .bubble_MEM,
        .readperf_MEM,
        .perf_flag_MEM,
        .memtoreg_MEM,
        .memwrite_MEM,
        .regwrite_MEM,
        .aluout_MEM,
        .writedata_MEM,
        .writereg_MEM
    );

    // MEM/WB
    mem_wb mem_wb(
        .clk,
        .reset,
        .bubble_MEM,
        .readperf_MEM,
        .perf_flag_MEM,
        .memtoreg_MEM,
        .regwrite_MEM,
        .aluout_MEM,
        .readdata_MEM,
        .writereg_MEM,
        .bubble_WB,
        .readperf_WB,
        .perf_flag_WB,
        .memtoreg_WB,
        .regwrite_WB,
        .aluout_WB,
        .readdata_WB,
        .writereg_WB
    );

    // WB
    mux2 #(32) alumux(
        .d0(aluout_WB),
        .d1(readdata_WB),
        .s(memtoreg_WB),
        .y(reg_result_WB)
    );
    mux2 #(32) perfmux(
        .d0(cycle_cnt),
        .d1(instr_cnt),
        .s(perf_flag_WB),
        .y(perf_result_WB)
    );
    mux2 #(32) resmux(
        .d0(reg_result_WB),
        .d1(perf_result_WB),
        .s(readperf_WB),
        .y(result_WB)
    );

    // Hazard detection
    hazard_unit hazard_unit(
        .stall,
        .flush_ID,
        .jump_ID,
        .branch_ID,
        .pcsrc_ID,
        .rs_ID(instr_ID[25:21]),
        .rt_ID(instr_ID[20:16]),
        .rs_EX(instr_EX[25:21]),
        .rt_EX(instr_EX[20:16]),
        .flush_EX,
        .memtoreg_EX, 
        .regwrite_EX,
        .writereg_EX,
        .memtoreg_MEM,
        .regwrite_MEM,
        .writereg_MEM,
        .memtoreg_WB,
        .regwrite_WB,
        .forward_A,
        .forward_B,
        .writereg_WB
    );
    always_ff @(posedge clk or posedge reset) begin
        if (reset) flush_EX <= 1'b0;
        else flush_EX <= flush_ID;
    end

    // Performance monitor
    performance_monitor performance_monitor(
        .clk,
        .reset,
        .bubble_WB,
        .cycle_cnt,
        .instr_cnt
    );
endmodule
