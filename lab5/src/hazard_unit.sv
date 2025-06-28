module hazard_unit(
    output logic stall, flush_ID,
    output logic [1:0] forward_A, forward_B,

    // ID
    input logic jump_ID, branch_ID, pcsrc_ID,
    input logic [4:0] rs_ID,
    input logic [4:0] rt_ID,

    // EX
    input logic flush_EX, memtoreg_EX, regwrite_EX,
    input logic [4:0] writereg_EX,
    input logic [4:0] rs_EX,
    input logic [4:0] rt_EX,

    // MEM
    input logic memtoreg_MEM, regwrite_MEM,
    input logic [4:0] writereg_MEM,

    // WB
    input logic memtoreg_WB, regwrite_WB,
    input logic [4:0] writereg_WB
);

    logic match_EX, match_MEM, match_WB;
    assign match_EX  = (writereg_EX  != 5'd0) && (rs_ID == writereg_EX  || rt_ID == writereg_EX);
    assign match_MEM = (writereg_MEM != 5'd0) && (rs_ID == writereg_MEM || rt_ID == writereg_MEM);
    assign match_WB  = (writereg_WB  != 5'd0) && (rs_ID == writereg_WB  || rt_ID == writereg_WB);

    // Forwarding logic for source A (rs_EX)
    always_comb begin
        if (regwrite_MEM && (writereg_MEM != 0) && (writereg_MEM == rs_EX))
            forward_A = 2'b01; // Forward from MEM
        else if (regwrite_WB && (writereg_WB != 0) && (writereg_WB == rs_EX))
            forward_A = 2'b10; // Forward from WB
        else
            forward_A = 2'b00; // No forwarding
    end

    // Forwarding logic for source B (rt_EX)
    always_comb begin
        if (regwrite_MEM && (writereg_MEM != 0) && (writereg_MEM == rt_EX))
            forward_B = 2'b01; // Forward from MEM
        else if (regwrite_WB && (writereg_WB != 0) && (writereg_WB == rt_EX))
            forward_B = 2'b10; // Forward from WB
        else
            forward_B = 2'b00; // No forwarding
    end

    // Stall for read after write (RAW) hazards
    assign stall = !flush_ID && !flush_EX && (
        (memtoreg_EX  && match_EX)  ||
        (regwrite_EX  && match_EX && branch_ID)  ||
        (regwrite_MEM && match_MEM) ||
        (memtoreg_WB  && match_WB && branch_ID)  ||
        (regwrite_WB  && match_WB)
    );

    // Flush if a jump or branch was taken
    assign flush_ID = jump_ID || pcsrc_ID;
endmodule
