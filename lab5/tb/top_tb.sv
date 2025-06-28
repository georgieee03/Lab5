`include "uvm_macros.svh"
import uvm_pkg::*;

`include "top.sv"
`include "tb/instr_gen.sv"

module top_tb;
  logic clk = 0;
  logic reset = 1;

  // DUT connections
  logic [31:0] pc, instr, readdata;
  logic        memwrite;
  logic [31:0] dataadr, writedata;

  // Clock generation
  always #5 clk = ~clk;

  // DUT instantiation
  top dut (
      .clk(clk),
      .reset(reset),
      .pc(pc),
      .instr(instr),
      .memwrite(memwrite),
      .dataadr(dataadr),
      .writedata(writedata),
      .readdata(readdata)
  );

  // Behavioral memories
  imem imem_inst (.a(pc[7:2]), .rd(instr));
  dmem dmem_inst (.clk(clk), .we(memwrite), .a(dataadr), .wd(writedata), .rd(readdata));

  initial begin
    instr_gen gen;

    // 1. Create and randomize the instruction generator
    gen = instr_gen::type_id::create("gen");
    assert(gen.randomize());

    // 2. Call the body task to generate the instruction stream
    gen.body();

    // 3. Load the generated machine code into the behavioral instruction memory
    $display("Loading %0d instructions into instruction memory...", gen.instr_stream.size());
    for (int i = 0; i < gen.instr_stream.size(); i++) begin
      if (gen.instr_stream[i] != null) begin
        imem_inst.RAM[i] = gen.instr_stream[i].machine_code;
        $display("IMEM[%0d] = %h", i, gen.instr_stream[i].machine_code);
      end else begin
        // Handle null instructions (NOPs)
        imem_inst.RAM[i] = 32'h00000000;
        $display("IMEM[%0d] = %h (NOP)", i, 32'h00000000);
      end
    end

    // 4. Start the simulation
    #10;
    reset = 1;
    #20;
    reset = 0;
    $display("De-asserting reset. MIPS core should start fetching.");
    
    // 5. Run for some time and finish
    #5000;
    $display("Simulation finished.");
    $finish;
  end

endmodule

// Behavioral Data Memory
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

// Behavioral Instruction Memory
module imem(
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    // NOTE: Initial loading from memfile is removed.
    // The testbench now controls memory content.
    assign rd = RAM[a];
endmodule 