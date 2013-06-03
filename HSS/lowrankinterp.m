function [output] = lowrankinterp(A,opts,rank,sigmafact,initfact)
nm = size(A);
nR = nm(1);
nC = nm(2);
opSR=opSR2MH(nR);
info=opSR([],0);
SR=opFunction(info{1},info{2},opSR);
D=SR*vec(A);
D=reshape(D,nR,2*nC);
params.afunT = @(x)reshape(x,size(D,1),size(D,2));
params.numr = size(D,1);
params.numc = size(D,2);
D=vec(D);
params.Ind = find(D==0);
params.afun = @(x)afun(x,params.Ind);
params.funForward = @NLfunForward;
% Run the main algorithm
params.nr = rank;
LInit   = randn(params.numr,params.nr)+1i*randn(params.numr,params.nr);
RInit   = randn(params.numc,params.nr)+1i*randn(params.numc,params.nr);
xinit  = initfact*[vec(LInit);vec(RInit)]; % Initial guess
tau = norm(xinit,1);
sigma=sigmafact*norm(D,2);
opts.funPenalty = @funLS;
XR = spgl1(@NLfunForward,D,tau,sigma,xinit,opts,params);
e = params.numr*params.nr;
L1 = XR(1:e);
R1 = XR(e+1:end);
L1 = reshape(L1,params.numr,params.nr);
R1 = reshape(R1,params.numc,params.nr);
output = SR'*vec(L1*R1');
output=reshape(output,nR,nC);
end
