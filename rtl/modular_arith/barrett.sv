module barrett_reduce (x,mu,q,result_T);
import  Butterfly::*;
input logic [X_WIDTH-1:0]  x;
input logic [MU_WIDTH-1:0] mu;
input logic [23:0] q;
output logic [23:0] result_T;
logic [95:0] x_mu;
logic [95:0] q_hat;
logic [119:0] q_hat_app;
logic [119:0] rem;
always_comb begin
    x_mu = x*mu;
    q_hat = x_mu >> K;
    q_hat_app = q*q_hat;
    rem = x - q_hat_app;
    if (rem >= q) rem = rem-q;
    result_T = rem [23:0];
end
endmodule