module if_id(
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic [31:0] pcplus4_IF,
    input  logic [31:0] instr_IF,
    output logic [31:0] pcplus4_ID,
    output logic [31:0] instr_ID
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pcplus4_ID <= '0;
            instr_ID   <= '0;
        end else if (!stall) begin
            pcplus4_ID <= pcplus4_IF;
            instr_ID   <= instr_IF;
        end
    end
endmodule
