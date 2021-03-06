%%  Test script to compare the classical versis factorized formulation
% For a given matrix with predefined rank, solve the classical and
% factorized formulation in LASSO mode for various rank and tau values

%%
clear all;
clc;
% script1='/Volumes/Users/rkumar/Dropbox/Research/Low-Rank/Matrix_Pareto_Factorization/SLIM.Projects.MatrixParetoFact/scripts/Classical_NuclearNorm/';
script1='C:\Users\mona\Dropbox\Research\Low-Rank\Matrix_Pareto_Factorization\SLIM.Projects.MatrixParetoFact\scripts\Classical_NuclearNorm\';
addpath(genpath([script1 'scripts-2']));
addpath(genpath([script1 'scripts/dependencies']));
run([script1 'TR201002-Figures/scripts/runme']);
RandStream.setDefaultStream(RandStream('mt19937ar','seed',1));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Solving the following problem for different tau and rank
% Minimize  ||X(idx) - M(idx)||_2 subject to  ||X||_*<=tau
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate rank=70 matrix 
    sigmas = [1e2*rand(70,1); zeros((100-70), 1)];
    % set up U and V
    U = randn(100, 70);
    [Q R] = qr(U);
    U = Q;
    V = randn(100,70);
    [Q R] = qr(V);
    V = Q;
    % Form A
    D = U*diag(sigmas)*V';
    nm = size(D);
    nR = nm(2);
    nC = nm(1);
    opts = spgSetParms('verbosity',1);    
%     'optTol',1e-8, ...
%         'bpTol', 1e-8,...
%         'decTol',1e-6,...
%         'verbosity',1);
     [m,n] = size(D);
    opts.project     = @(x,weight,tau) NormNuc_project(m,n,x,tau);
    opts.primal_norm = @(x,weight)     NormNuc_primal(m,n,x);
    opts.dual_norm   = @(x,weight)     NormNuc_dual(m,n,x);
    idx = randperm(m*n);
    k   = min(m*n,max(1,round(m*n*50/100)));
    idx = sort(idx(1:k));
    op  = opRestriction(m*n,idx);
    tau = [1e2 3e2 5e2 7e2 8e2 1e3 1.5e3];   
    b=D(:); 
    % Define a rank vector        
    for j =1:length(tau)
        t = tau(j);
        % =====================================================================
        [XM,resi,grad,data] = spgl1(op, b(idx), t,[], [], opts);
        % =====================================================================
        XM=reshape(XM,nR,nC);
        tau_calcul(j) = sum(svd(XM));
        SNR_Class(j) = -20*log10(norm(D-XM,'fro')/norm(D,'fro'));
        Data{j}=data;
        value(j) = norm(resi,2);
        deri(j)  = norm(grad,inf);
    end
save('Exp1_LASSO.mat','SNR_Class','Data','value','deri','tau_calcul');

%% Solving the factorized formulation in LASSO mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Minimize   ||A(LR') - b ||_2  subject to ||LR'||_*<=tau
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
RandStream.setDefaultStream(RandStream('mt19937ar','seed',1));
% script1='/Volumes/Users/rkumar/Dropbox/Research/Low-Rank/';
% addpath(genpath([script1 'spgl1Latest']));
% addpath(genpath('/users/slic/rkumar/spgl1Latest'));
addpath(genpath('/users/slic/rkumar/solver/tuningspgl1/spgl1'));
addpath(genpath('/users/slic/rkumar/Self_Function'));
% Generate rank=70 matrix 
    sigmas = [1e2*rand(70,1); zeros((100-70), 1)];
    % set up U and V
    U = randn(100, 70);
    [Q R] = qr(U);
    U = Q;
    V = randn(100,70);
    [Q R] = qr(V);
    V = Q;
    % Form A
    D = U*diag(sigmas)*V';
    opts = spgSetParms('project', @TraceNorm_project, ...
        'primal_norm', @TraceNorm_primal, ...
        'dual_norm', @TraceNorm_dual, ...
        'proxy', 1, ...
        'verbosity',1,...
        'ignorePErr', 1, ...
        'weights', []);
    % deleted params: 
    %    'optTol',1e-8, ...
 %       'bpTol', 1e-8,...
 %       'decTol',1e-6,...
    nm = size(D);
    nR = nm(2);
    nC = nm(1);
    [m,n] = size(D);
    idx = randperm(m*n);
    k   = min(m*n,max(1,round(m*n*60/100)));
    idx = sort(idx(1:k));
    op  = opRestriction(m*n,idx);
    Bfun = @(x)op'*op*vec(x);
    params.numr = nR;
    params.numc = nC;
    params.funForward = @NLfunForward;
    b = Bfun(D);
    params.afunT = @(x)reshape(x,nR,nC);
    params.Ind = find(b==0);
    params.afun = @(x)afun(x,params.Ind);
    rank = [20,30,50,70];
    tau = [1e2 3e2 5e2 7e2 8e2 1e3 1.5e3]; 
    opts.funPenalty = @funLS;
for i = 1:length(rank)
    r = rank(i);   
    params.nr=r;
    LInit   = randn(params.numr,params.nr);
    RInit   = randn(params.numc,params.nr);
    xinit   = [vec(LInit);vec(RInit)]; % Initial guess
    for j = 1:length(tau)
        Tau = tau(j);
        % =====================================================================
        [xS,resi,grad,info] = spgl1(@NLfunForward,b,Tau,[],xinit,opts,params);
        % =====================================================================
        e = params.numr*params.nr;
        L1 = xS(1:e);
        R1 = xS(e+1:end);
        L1 = reshape(L1,params.numr,params.nr);
        R1 = reshape(R1,params.numc,params.nr);
        xs = L1*R1';
        tau_proxy(i,j) = 0.5*norm([L1; R1], 'fro')^2;
        tau_calcul(i,j) = sum(svd(xs));
        SNR_fact(i,j) = -20*log10(norm(D-xs,'fro')/norm(D,'fro'));
        Data_Fact{i,j}= info;
        value(i,j) = norm(resi,2);
        deri(i,j)  = norm(resi,2)*norm(grad,inf);
    end
    % can you compute A^T (A (LR') - b)? 
    
end

save('Exp1_Factorized.mat','SNR_fact','Data_Fact','value','deri','tau_proxy','tau_calcul');
