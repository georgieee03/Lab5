module alu(
    input  logic [31:0] a, b, c,
    input  logic [2:0]  control,
    output logic [31:0] result
);
    always_comb begin
        case(control)
            3'b000: result = a & b;                     // AND
            3'b001: result = a | b;                     // OR
            3'b010: result = a + b;                     // ADD
            3'b101: result = (a * b) + c;               // MULADD
            3'b110: result = a - b;                     // SUB
            3'b111: result = ($signed(a) < $signed(b)); // SLT (signed)
            default: result = 'x;
        endcase
    end
endmodule
