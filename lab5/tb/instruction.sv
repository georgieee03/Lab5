`include "uvm_macros.svh"

class instruction extends uvm_sequence_item;
  rand bit [5:0]  opcode;
  rand bit [4:0]  rs, rt, rd;
  rand bit [15:0] imm;
  rand bit [5:0]  funct;
  rand bit [1:0]  gap;          // 0-3, yielding a gap of 1-4 NOPs
  rand bit        branch_taken; // For BEQ conditional branch

  logic [31:0] machine_code;

  constraint legal_c {
    rs inside {5'd1, 5'd2, 5'd3, 5'd4};
    rt inside {5'd1, 5'd2, 5'd3, 5'd4};
    rd inside {5'd1, 5'd2, 5'd3, 5'd4};
  }

  constraint opcode_c {
    // R-type
    (opcode == 6'h00 && (funct inside {6'h20, 6'h24})) || // ADD, AND
    // I-type
    opcode inside {6'h23, 6'h2b, 6'h04};                  // LW, SW, BEQ
  }

  // Constrain immediate for LW/SW to be one of 4 aligned addresses
  constraint mem_addr_c {
    if (opcode inside {6'h23, 6'h2b}) { // LW, SW
      imm[15:4] == 0;
      imm[3:2] inside {2'b00, 2'b01, 2'b10, 2'b11}; // 0,4,8,C
      imm[1:0] == 2'b00; // word aligned
    }
  }

  // Constrain immediate for BEQ to be one of 4 offset values
  constraint branch_off_c {
    if (opcode == 6'h04) { // BEQ
      imm inside {16'd1, 16'd2, 16'd3, 16'd4};
    }
  }

  `uvm_object_utils(instruction)

  function new(string name="instruction");
    super.new(name);
  endfunction

  function void assemble();
    case(opcode)
      6'h00:  // R-type (ADD, AND)
        machine_code = {opcode, rs, rt, rd, 5'h0, funct};
      6'h23, 6'h2b, 6'h04:  // I-type (LW, SW, BEQ)
        machine_code = {opcode, rs, rt, imm};
      default:
        machine_code = 32'h0; // Should not happen with constraints
    endcase
  endfunction

endclass 