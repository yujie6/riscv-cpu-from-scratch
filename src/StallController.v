// connect to 4 stage module to control stalls
// Possible Improvement 
// 1. out-of-order execution (renaming...)
// 2. multiple issueing (multiple modules to decode )
// 3. data forwarding 
// 4. Cache memory
`include "./defines.v"

module StallController(
    input wire rst,
    input wire rdy,
    input wire stallreq_ex,
    input wire stallreq_id,
    input wire stallreq_mem,
    input wire stallreq_if,
    input wire stallreq_branch,
    output reg [6:0] stall
);
    // stall[0] -> stop PC
    // stall[1] -> stop if
    // stall[2] -> stop id
    // stall[3] -> stop ex
    // stall[4] -> stop mem
    // stall[5] -> stop wb
    always @(*) begin
        if (rst == `RstEnable) begin
            stall <= 7'b0000000;
        end else if (stallreq_mem == `Stop) begin 
            stall <= 7'b1001111; // [5:0]
        end else if (stallreq_branch == `Stop) begin
            stall <= 7'b0100010; // cancel previous inst
        end 
        else if (stallreq_id == `Stop) begin
            stall <= 7'b0000111;
        end else if (stallreq_if == `Stop) begin
            stall <= 7'b0000001;    
        end else begin
            stall <= 7'b0000000;     
        end
    end

endmodule // StallControler