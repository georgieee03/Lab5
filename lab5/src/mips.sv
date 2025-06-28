module mips (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluout, writedata,
    input  logic [31:0] readdata
);

    wire readperf, memtoreg, branch, alusrc, regdst, regwrite, jump, memwrite_ID;
    wire [2:0] alucontrol;
    wire [31:0] instr_ID;

    controller c(
        .op(instr_ID[31:26]),
        .funct(instr_ID[5:0]),
        .readperf,
        .branch,
        .memtoreg,
        .memwrite(memwrite_ID),
        .alusrc,
        .regdst,
        .regwrite,
        .jump,
        .alucontrol
    );

    datapath dp(
        .clk,
        .reset,
        .instr_ID(instr_ID),
        .readperf_ID(readperf),
        .memtoreg_ID(memtoreg),
        .memwrite_ID(memwrite_ID),
        .alusrc_ID(alusrc),
        .regdst_ID(regdst), 
        .regwrite_ID(regwrite),
        .jump_ID(jump),
        .branch_ID(branch),
        .alucontrol_ID(alucontrol),
        .pc_IF(pc),
        .instr_IF(instr),
        .aluout_MEM(aluout),
        .writedata_MEM(writedata),
        .readdata_MEM(readdata),
        .memwrite_MEM(memwrite)
    );
endmodule
