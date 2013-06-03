% addpath(genpath('/Dropbox/spgl1Latest'));
% addpath(genpath('/Dropbox/MaxNorm/GulfofSuez350/code/Function'));
clear all;
addpath(genpath('/users/slic/rkumar/spgl1Latest'));
%% fetch the data from cluster
RandStream.setDefaultStream(RandStream('mt19937ar','seed',1));
clear all;
load data_index_250.mat
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
D1 = R2*vec(D);
D1 = reshape(D1,nR,nC/2);
I = randperm(nC/2);
J = floor(.1*size(D1,2)); % change here the percentage of outlier in the data set
IT = I(1:J); 
D1(:,IT)= 1e6*rand(nR,length(IT));
D1 = R2'*vec(D1);
Bfun = @(x)SR*vec(x);
b= Bfun(D1);
%% SPGL1 for A
params.afunT = @(x)reshape(x,nR,2*nC);
params.Ind = find(b==0);
params.afun = @(x)afun(x,params.Ind);
params.numr = nR;
params.numc = 2*nC;
params.nr = 40; 
LInit   = randn(params.numr,params.nr)+1i*randn(params.numr,params.nr);
RInit   = randn(params.numc,params.nr)+1i*randn(params.numc,params.nr);
% Run the main algorithm
xinit  =1e-4*[vec(LInit);vec(RInit)]; % Initial guess
gradientTest(@funSelfTuneST, xinit, [], 1e-4)

options.itermax = 300;
options.tol = 1e-6;
funObj = @(x)funCompLBFGS(x, b, @NLfunForward, @funSelfTuneST, params);
tic;
xLS= mylbfgs(funObj,xinit,options);
toc;
e = params.numr*params.nr;
L1 = xLS(1:e);
R1 = xLS(e+1:end);
L1 = reshape(L1,params.numr,params.nr);
R1 = reshape(R1,params.numc,params.nr);
xlsa = L1*R1';
xls2 = reshape(SR'*vec(xlsa),nR,nC);
SNR1 = -20*log10(norm(D-xls2,'fro')/norm(D,'fro'))
% save('Seismic_low_lbfgs_result50perc_miss.mat','SNR1','xls2');

