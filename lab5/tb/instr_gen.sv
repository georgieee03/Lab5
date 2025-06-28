`include "uvm_macros.svh"
`include "instruction.sv"

class instr_gen extends uvm_sequence #(instruction);
  `uvm_object_utils(instr_gen)

  rand int unsigned n_instrs;
  instruction instr_stream[$];

  constraint size_c { n_instrs inside {[30:50]}; }

  function new(string name="instr_gen");
    super.new(name);
  endfunction

  virtual task body();
    // 1. Generate initialization sequence
    generate_init();

    // 2. Generate randomized sequence
    repeat (n_instrs) begin
      generate_stimulus();
    end
    
    // 3. Assemble all instructions into machine code
    foreach (instr_stream[i]) begin
      if (instr_stream[i] != null) begin
        instr_stream[i].assemble();
      end
    end
  endtask

  // Generates instructions to zero out the 4 architected registers
  task generate_init();
    for (int i = 1; i <= 4; i++) begin
        instruction init_instr = instruction::type_id::create($sformatf("init_reg%0d", i));
        assert(init_instr.randomize() with {
            opcode == 6'h00; // R-type
            funct  == 6'h20; // ADD
            rd     == i;
            rs     == 0; // add $i, $zero, $zero
            rt     == 0;
        });
        instr_stream.push_back(init_instr);
    end
  endtask
  
  // Main stimulus generation task, decides what to generate
  task generate_stimulus();
    int choice;
    choice = $urandom_range(0, 9);
    
    case(choice)
        0: generate_pair(1); // Reg-reg dependency
        1: generate_pair(0); // Mem dependency
        2: generate_beq();
        default: generate_single();
    endcase
  endtask

  task generate_single();
    instruction t;
    t = instruction::type_id::create("single_instr");
    assert(t.randomize());
    instr_stream.push_back(t);
  endtask

  task generate_pair(bit is_reg_dep);
    instruction a, b;
    a = instruction::type_id::create("pair_A");
    b = instruction::type_id::create("pair_B");
    
    if (is_reg_dep) {
        assert(a.randomize() with { opcode == 6'h00; }); // ADD or AND
        assert(b.randomize() with { rs == a.rd; });      // RAW dependency
    } else {
        assert(a.randomize() with { opcode == 6'h2b; }); // SW
        assert(b.randomize() with { opcode == 6'h23; imm == a.imm; rs == a.rs; }); // LW from same addr
    }
    
    instr_stream.push_back(a);
    // Insert NOPs for the gap
    for (int i = 0; i < a.gap + 1; i++) begin
        instr_stream.push_back(null);
    end
    instr_stream.push_back(b);
  endtask

  // Generates a BEQ and prepends instructions to set up the condition
  task generate_beq();
      instruction beq_instr, setup1, setup2;
      beq_instr = instruction::type_id::create("beq");
      setup1 = instruction::type_id::create("beq_setup1");
      setup2 = instruction::type_id::create("beq_setup2");

      assert(beq_instr.randomize() with { opcode == 6'h04; });
      
      // Setup for branch taken
      if (beq_instr.branch_taken) {
        assert(setup1.randomize() with { opcode == 6'h0; funct == 6'h20; rd == beq_instr.rs; }); // ADD rs, r_val, r_val
        assert(setup2.randomize() with { opcode == 6'h0; funct == 6'h20; rd == beq_instr.rt; rs == beq_instr.rs; rt == 0; }); // ADD rt, rs, $zero
      } 
      // Setup for branch not taken
      else {
        assert(setup1.randomize() with { opcode == 6'h0; funct == 6'h20; rd == beq_instr.rs; }); // ADD rs, ...
        assert(setup2.randomize() with { opcode == 6'h0; funct == 6'h20; rd == beq_instr.rt; rs != beq_instr.rs; }); // ADD rt, ...
      }
      instr_stream.push_back(setup1);
      instr_stream.push_back(setup2);
      instr_stream.push_back(beq_instr);
  endtask

endclass 