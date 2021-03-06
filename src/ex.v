`include "defines.v"

module ex(input wire rst,
          input wire [`AluOpBus] aluop_i,
          input wire [`AluSelBus] alusel_i,
          input wire [`RegBus] reg1_i,
          input wire [`RegBus] reg2_i,
          input wire [`InstAddrBus] pc_i,
          input wire [`RegAddrBus] shamt_i,
          input wire [`RegBus] imm_i,
          input wire [`RegAddrBus] rd_i,
          input wire [`MemAddrBus] link_addr_i, 
          input wire wreg_i,
          input wire [`MemSelBus] mem_sel_i,
          input wire mem_we_i,
          input wire load_sign_i,
          output reg [`RegAddrBus] rd_o,
          output reg wreg_o,
          output wire [`InstAddrBus] pc_o,
          output reg [`RegBus] wdata_o, // write to rd & data forwarding
          output reg [`MemAddrBus] mem_addr_o, // send to mem
          output wire [`AluOpBus] aluop_o, // send to MEM(for LD and SD)
          output wire [`AluSelBus] alusel_o,
          output wire [`MemSelBus] mem_sel_o,
          output wire mem_we_o,
          output wire load_sign_o,
          output wire [`RegBus] reg2_o); 

    assign aluop_o = aluop_i;
    assign reg2_o = reg2_i;
    assign pc_o = pc_i;    
    assign mem_sel_o = mem_sel_i;
    assign mem_we_o = mem_we_i;
    assign load_sign_o = load_sign_i;
    assign alusel_o = alusel_i;


    reg [`RegBus] logic_out;
    reg [`RegBus] shift_out;
    reg [`RegBus] arith_out;
    reg [`RegBus] mem_out;
    
    // All logic operation are done in this submodule
    always @(*) begin
        if (rst == `RstEnable || alusel_i != `EXE_RES_LOGIC) begin
            logic_out <= `ZeroWord;
            end else begin
            case (aluop_i)
                `EXE_OR_OP:   logic_out <= $signed(reg1_i) | $signed(reg2_i);
                `EXE_AND_OP:  logic_out <= $signed(reg1_i) & $signed(reg2_i);
                `EXE_XOR_OP:  logic_out <= $signed(reg1_i) ^ $signed(reg2_i);
                `EXE_ORI_OP:  logic_out <= $signed(reg1_i) | $signed(imm_i);
                `EXE_ANDI_OP: logic_out <= $signed(reg1_i) & $signed(imm_i);
                `EXE_XORI_OP: logic_out <= $signed(reg1_i) ^ $signed(imm_i);
                `EXE_SLT_OP:   logic_out <= $signed(reg1_i) < $signed(reg2_i) ? 1 : 0;
                `EXE_SLTI_OP:  logic_out <= $signed(reg1_i) < $signed(imm_i) ? 1 : 0;
                `EXE_SLTU_OP:  logic_out <= reg1_i < reg2_i ? 1 : 0;
                `EXE_SLTIU_OP: logic_out <= reg1_i < imm_i ? 1 : 0;
                default : begin
                    logic_out <= `ZeroWord;
                end
            endcase
        end
    end
    
    // all shift operations are done here
    always @(*) begin
        if (rst == `RstEnable || alusel_i != `EXE_RES_SHIFT) begin
            shift_out <= `ZeroWord;
            end else begin
            case (aluop_i)
                `EXE_SLL_OP:   shift_out <= reg1_i << reg2_i[4:0];
                `EXE_SLLI_OP:  shift_out <= reg1_i << shamt_i;
                `EXE_SRL_OP:   shift_out <= reg1_i >> reg2_i[4:0];
                `EXE_SRLI_OP:  shift_out <= reg1_i >> shamt_i;
                `EXE_SRAI_OP:  shift_out <= $signed(reg1_i) >>> shamt_i;
                // TODO: May need to escape shift
                default : begin
                    shift_out <= `ZeroWord;
                end
            endcase
        end
    end

    
    // all arithmetic operations are done here including pc
    always @(*) begin
        if (rst == `RstEnable || alusel_i != `EXE_RES_ARITH) begin
            arith_out <= `ZeroWord;
            end else begin
            //$display("arith detected");
            case (aluop_i)
                `EXE_ADD_OP:   arith_out  <= $signed(reg1_i) + $signed(reg2_i);
                `EXE_ADDI_OP:  arith_out  <= $signed(reg1_i) + $signed(imm_i);
                `EXE_SUB_OP:   arith_out  <= $signed(reg1_i) - $signed(reg2_i);
                `EXE_SUBI_OP:   arith_out <= $signed(reg1_i) - $signed(imm_i);
                `EXE_AUIPC_OP: arith_out <= pc_i + imm_i;
                `EXE_LUI_OP: begin 
                    arith_out <= imm_i;
                    //$display("lui detected in ex");
                end
                // JAL and so on ...
                default : begin
                    arith_out <= `ZeroWord;
                end
            endcase
        end
    end
    
    always @(*) begin
        if (rst == `RstEnable || alusel_i != `EXE_RES_LOAD_STORE) begin
            mem_out <= `ZeroWord;
        end
        else begin
            mem_out <= reg1_i + $signed(imm_i);
        end
    end
    
    always @(*) begin
        if (rst == `RstEnable) begin
            rd_o <= 5'b00000;
            wreg_o <= 1'b0;
        end else begin
            rd_o   <= rd_i;
            wreg_o <= wreg_i;
        end
    end
    // By the inst alusel_i given, choose one as the final result
    // There will only be logic op here
    always @(*) begin
        if (rst == `RstEnable) begin 
            wdata_o <= `ZeroWord;
            mem_addr_o <= `ZeroWord;
        end else begin 
            case (alusel_i)
                `EXE_RES_LOGIC: wdata_o <= logic_out;
                `EXE_RES_ARITH: wdata_o <= arith_out;
                `EXE_RES_SHIFT: wdata_o <= shift_out;
                `EXE_RES_LOAD_STORE: begin
                    wdata_o    <= `ZeroWord;
                    mem_addr_o <= mem_out;
                end
                `EXE_RES_JUMP_BRANCH: if (wreg_o == `WriteEnable) wdata_o <= link_addr_i;
                default : begin
                    wdata_o <= `ZeroWord;
                end
            endcase
        end
    end
    
endmodule
