module controller (
    input  logic [5:0] op, funct,
    output logic       readperf,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regdst, regwrite,
    output logic       jump,
    output logic [2:0] alucontrol
);
    wire [1:0] aluop;
    
    maindec md(
        .op,
        .readperf,
        .memtoreg,
        .memwrite,
        .branch,
        .alusrc,
        .regdst,
        .regwrite,
        .jump,
        .aluop
    );
    aludec ad(
        .funct,
        .aluop,
        .alucontrol
    );
endmodule


module maindec(
    input  logic [5:0] op,
    output logic       readperf,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regdst, regwrite,
    output logic       jump,
    output logic [1:0] aluop
);

    logic [9:0] controls;
    
    assign {readperf, regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop} = controls;

    always_comb begin
        case(op)
            6'b000000: controls = 10'b0110000010; //Rtyp
            6'b100011: controls = 10'b0101001000; //LW
            6'b101011: controls = 10'b0001010000; //SW
            6'b000100: controls = 10'b0000100001; //BEQ
            6'b001000: controls = 10'b0101000000; //ADDI
            6'b000010: controls = 10'b0000000100; //J
            6'b111111: controls = 10'b1100000000; //PERFMON
            default:   controls = 10'bxxxxxxxxxx; //???
        endcase
    end
endmodule


module aludec (
    input  logic [5:0] funct,
    input  logic [1:0] aluop,
    output logic [2:0] alucontrol
);

    logic [2:0] rtype;

    always_comb begin
        case (funct) 
            6'b100000: rtype = 3'b010; // ADD
            6'b011001: rtype = 3'b101; // MULADD
            6'b100010: rtype = 3'b110; // SUB
            6'b100100: rtype = 3'b000; // AND
            6'b100101: rtype = 3'b001; // OR
            6'b101010: rtype = 3'b111; // SLT
            default:   rtype = 3'bxxx; // ???
        endcase
    end

    always_comb begin
        case (aluop)
            2'b00:   alucontrol = 3'b010; // add
            2'b01:   alucontrol = 3'b110; // sub
            default: alucontrol = rtype;  // RTYPE
        endcase
    end
endmodule
