module performance_monitor (
    input  logic clk, reset, bubble_WB,
    output logic [31:0] cycle_cnt, instr_cnt
);

always_ff @(posedge clk or posedge reset) begin
    if (reset) cycle_cnt <= '0;
    else cycle_cnt <= cycle_cnt + 32'd1;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset) instr_cnt <= '0;
    else if (!bubble_WB) instr_cnt <= instr_cnt + 32'd1;
end

endmodule
