function [x] = TraceNorm_pproject(x,weights, B,params)
%%%% Force the rows of L and R to have norm at most B.
%
% (LOut, ROut) = arg min_(U,V) || [L;R]-[U;V] ||_F^2 s.t. || [U;V] ||_mr<B
%
% Where || A ||_mr is the maximum Euclidean norm of a row of A.
%
e = params.numr*params.nr;
L = x(1:e,:);
R = x(e+1:end,:);
 spmd
    X_Local=norm(x);
    c=gcat(X_Local);
    normx_global=sqrt(norm(c));
 end
    
% here i have to define norm of complete x since projection i am doing
% element wise 
C=sqrt(B/(0.5))*normx_global{1};
LOut = min(1,C)*L(:);
ROut = min(1,C)*R(:);

x = [vec(LOut);vec(ROut)];
end