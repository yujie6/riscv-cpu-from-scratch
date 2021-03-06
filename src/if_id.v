`include "defines.v"

module if_id(input wire clk,
             input wire rst,
             input wire rdy,
             input wire[`InstAddrBus] if_pc,
             input wire[`InstBus] if_inst,
             input wire[6:0] stall,
             output reg[`InstAddrBus] id_pc,
             output reg[`InstBus] id_inst);
    
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            id_pc   <= `ZeroWord;
            id_inst <= `ZeroWord;
            end else if (stall[0] == `Stop && stall[1] == `NoStop) begin
            // id_pc   <= `ZeroWord;
            // id_inst <= `ZeroWord;
            end else if (stall[0] == `NoStop) begin
            id_pc   <= if_pc;
            id_inst <= if_inst;
        end
    end
    
endmodule // if_id
