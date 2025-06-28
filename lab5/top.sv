module top (
    input  logic        clk, reset,
    // Instruction memory interface
    output logic [31:0] pc,
    input  logic [31:0] instr,
    
    // Data memory interface
    output logic        memwrite,
    output logic [31:0] dataadr,
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);
    // instantiate processor
    mips mips (
        .clk,
        .reset,
        .pc(pc),
        .instr(instr),
        .memwrite(memwrite),
        .aluout(dataadr),
        .writedata(writedata),
        .readdata(readdata)
    );
endmodule


module dmem(
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    assign rd = RAM[a[31:2]];
    always_ff @(posedge clk)
        if (we) RAM[a[31:2]] <= wd;
endmodule


module imem(
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    initial $readmemh("../memfile.dat", RAM, 0, 36);
    assign rd = RAM[a];
endmodule
