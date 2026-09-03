module barrett_mult(B,W,mod_sel,result_T);
import  Butterfly::*;
input logic [23:0] B,W;
input logic mod_sel;
output logic [23:0] result_T;
logic [47:0] mult;
logic [47:0] mu;
logic [23:0] q;
assign mult=B*W;
    always_comb begin
        if (mod_sel == 1) begin
            mu=MU_DILITHIUM;
            q=Q_DILITHIUM;
        end
        else begin
            mu=MU_KYBER;
            q=Q_KYBER;
        end
    end
barrett_reduce REDUCE(.x(mult),.mu(mu),.q(q),.result_T(result_T));
endmodule
