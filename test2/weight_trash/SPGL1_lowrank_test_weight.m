%% Test script for the implementation of General SPG

% open matlab from qmatlabX because of large data file used in this example

% update here the location of spgl2 folder
% addpath(genpath('/Dropbox/spgl1Latest'));
% addpath(genpath('/Dropbox/MaxNorm/GulfofSuez350/code/Function'));
addpath(genpath('/users/slic/rkumar/spgl1Latest'));
%% fetch the data from cluster
clear all;
close all;
nt = 1024;
nr = 355;
ns = 355;
outlier =0;
% %for server
D=ReadSuFast('/scratch/slic/rkumar/SuezShots125-355shots.su');
D = reshape(D,nt,nr,ns);  
data = fft(D);
clear D
data = permute(reshape(data,nt,nr,ns),[3 2 1]);
freq = 0; % for low frequency else high frequency

if freq== 0
    D = squeeze((data(1:354,1:354,40)));
else
    D = squeeze((data(1:354,1:354,280)));
end
clear data;
% load Dtest.mat;
nm = size(D);
nR = nm(2);
nC = nm(1);% length of frequency axis

%% Define Restriction Operator
inds=randperm(nR);
ind=inds(1:floor(nR/2));
R1 = opRestriction(nR,ind);
R2 = opKron(R1,opDirac(nR));
opSR=opSR2MH(354);
info=opSR([],0);
SR=opFunction(info{1},info{2},opSR);
Bfun = @(x)SR*R2'*R2*vec(x);
b = Bfun(D);
%% Function Handle
params.afunT = @(x)reshape(x,nR,nC*2);
%params.F = @(x)R2*SR'*vec(x);
params.Ind = find(b==0);
params.afun = @(x)afun(x,params.Ind);
params.numr = nR;
params.numc = 2*nC;
params.nr = 50; % define here the rank value to evaluate. right now the rank 
% to be assumed is 20.

params.funForward = @NLfunForward;
regularizer = 'trace_norm_regularize';

%% options for trace norm
switch regularizer
    case 'trace_norm_regularize'
        % options for Max-Norm
opts = spgSetParms('optTol',1e-4, ...
                   'bpTol', 1e-6,...
                    'decTol',1e-4,...
                   'project', @TraceNorm_project, ...
                   'primal_norm', @TraceNorm_primal, ...
                   'dual_norm', @TraceNorm_dual, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'iterations', 150);
    case 'max_norm_regularize'
        % options for Max-Norm
opts = spgSetParms('optTol',1e-4, ...
                   'bpTol', 1e-6,...
                   'decTol',1e-5,...
                   'project', @MaxNorm_project, ...
                   'primal_norm', @MaxNorm_primal, ...
                   'dual_norm', @MaxNorm_dual, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'iterations', 150);
end
 
%% Run the main algorithm

LInit   = (1e-2*randn(params.numr,params.nr)+1i*1e-2*randn(params.numr,params.nr));
RInit   = (1e-2*randn(params.numc,params.nr)+1i*1e-2*randn(params.numc,params.nr));
xinit  = [vec(LInit);vec(RInit)]; % Initial guess
tau = norm(xinit,1);
sigma = 5;
opts.funPenalty = @funLS;
[xLS,r1,g1,info1] = spgl1(@NLfunForward,b,tau,sigma,xinit,opts,params);
e = params.numr*params.nr;
L1 = xLS(1:e);
R1 = xLS(e+1:end);
L1 = reshape(L1,params.numr,params.nr);
R1 = reshape(R1,params.numc,params.nr);
xls = reshape(SR'*vec(L1*R1'),nR,nC);
SNR = -20*log10(norm(D-xls,'fro')/norm(D,'fro'))
    %% Run the same but now with weighted stuff
% doing weigthed analysis for the next frequency slice
[UL EL VL] = svd(L1);
[UR ER VR] = svd(R1);
q = params.nr-30; % low rank approximation
w = sqrt(0.1); % set weight value
m1 = size(UL,1);
n1 = size(VL,1);
m2 = size(UR,1);
n2 = size(VR,1);
% column and row space weighting for L and R factors
QL = UL*diag([w*ones(q,1); ones(m1-q,1)])*UL';
RL = VL*diag([w*ones(q,1); ones(n1-q,1)])*VL';
QR = UR*diag([w*ones(q,1); ones(m2-q,1)])*UR';
RR = VR*diag([w*ones(q,1); ones(n2-q,1)])*VR';
LN = QL*L1*RL;
RN = QR*R1*RR;
% xinit = [vec(LN);vec(RN)];
%%
xls=L1*R1';
[UX EX VX] = svd(xls);
% q = params.nr; % low rank approximation
% w = sqrt(0.3); % set weight value
m3 = size(UX,1);
n3 = size(VX,1);
QX = UX*diag([w^(-1)*ones(q,1); ones(m3-q,1)])*UX';
RX = VX*diag([w^(-1)*ones(q,1); ones(n3-q,1)])*VX';
w11=size(QX,1);w21=size(QX,2);
w31=size(RX,1);w41=size(RX,2);
weigh=[w11;w21;w31;w41;vec(QX);vec(RX)];
params.weight=weigh;
%%
w1=size(QL,1);w2=size(QL,2);
w3=size(RL,1);w4=size(RL,2);
w5=size(QR,1);w6=size(QR,2);
w7=size(RR,1);w8=size(RR,2);
Weight=[w1;w2;w3;w4;w5;w6;w7;w8;vec(QL);vec(RL);vec(QR);vec(RR)];
clear opts;
opts = spgSetParms('optTol',1e-4, ...
                   'bpTol', 1e-6,...
                    'decTol',1e-4,...
                    'weights',Weight,...
                   'project', @TraceNorm_projectweight, ...
                   'primal_norm', @TraceNorm_primalweight, ...
                   'dual_norm', @TraceNorm_dualweight, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'iterations', 150);
tau = norm(xinit,1);
sigma = 5;
opts.funPenalty = @funLS;
[xLS,r1,g1,info1] = spgl1(@NLfunForward,b,tau,sigma,xinit,opts,params);
e = params.numr*params.nr;
L2 = xLS(1:e);
R2 = xLS(e+1:end);
L2 = reshape(L2,params.numr,params.nr);
R2 = reshape(R2,params.numc,params.nr);
xls = reshape(SR'*vec(L2*R2'),nR,nC);
SNR = -20*log10(norm(D-xls,'fro')/norm(D,'fro'))   


