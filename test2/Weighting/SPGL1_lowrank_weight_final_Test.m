clear all;
close all;

addpath(genpath('/Volumes/Users/rkumar/Dropbox/Research/Low-Rank'));
addpath(genpath('/Volumes/Users/rkumar/Dropbox/Research/Low-Rank/spgl1Latest'));
%% fetch the data from cluster
RandStream.setDefaultStream(RandStream('mt19937ar','seed',1));
nt = 1024;
nr = 355;
ns = 355;
% outlier =0;
% D=ReadSuFast('/Users/rkumar/research/Data/SuezShots125.355shots.su');
% D = reshape(D,nt,nr,ns);  
% data = fft(D);
% clear D
% data = permute(reshape(data,nt,nr,ns),[3 2 1]);
% freq = 0; % for low frequency else high frequency
load SuezShots125-355shots-fft.mat;
a=40;
% D = squeeze((data(1:354,1:354,a)));
D = squeeze((data(a,1:354,1:354)));
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
params.Ind = find(b==0);
params.afun = @(x)afun(x,params.Ind);
params.numr = nR;
params.numc = 2*nC;
params.nr = 30; 
params.funForward = @NLfunForward;
%% options for trace norm
opts = spgSetParms('optTol',1e-5, ...
                   'bpTol', 1e-5,...
                    'decTol',1e-4,...
                   'project', @TraceNorm_project, ...
                   'primal_norm', @TraceNorm_primal, ...
                   'dual_norm', @TraceNorm_dual, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'iterations', 150,...
                   'weights', []);

%% Run the main algorithm
LInit   = randn(params.numr,params.nr)+1i*randn(params.numr,params.nr);
RInit   = randn(params.numc,params.nr)+1i*randn(params.numc,params.nr);
xinit  = 1e-3*[vec(LInit);vec(RInit)]; % Initial guess
tau = norm(xinit,1);
sigmafact=0.01;
sigma=sigmafact*norm(b,2);
opts.funPenalty = @funLS;
[xLS,r,g,info] = spgl1(@NLfunForward,b,tau,sigma,xinit,opts,params);
e = params.numr*params.nr;
L1 = xLS(1:e);
R1 = xLS(e+1:end);
L1 = reshape(L1,params.numr,params.nr);
R1 = reshape(R1,params.numc,params.nr);
xls = reshape(SR'*vec(L1*R1'),nR,nC);
SNR = -20*log10(norm(D-xls,'fro')/norm(D,'fro'))
%%
% saveFigure  = @(filename,postfilename) print(gcf,'-depsc',['' postfilename]);
% x=0:12.5:354*12.5;
% y=0:12.5:354*12.5;
% h=figure;
% imagesc(x,y,real(xls));colormap(seiscol);caxis([-500 500]);
% xlabel('Source(m)','FontSize',15, 'FontName','helvetica','FontWeight','demi')
% ylabel('Receiver(m)','FontSize',15, 'FontName','helvetica','FontWeight','demi')
% set(gca,'fontsize',10,'FontName','helvetica','FontWeight','demi')
% set(gca,'XTick',[0:1000:4000])
% set(gca,'XTickLabel',{'0';'1000';'2000';'3000';'4000'})
% set(gca,'YTick',[0:1000:4000])
% set(gca,'YTickLabel',{'0';'1000';'2000';'3000';'4000'})
% % set(gca,'TickDir', 'out')
% %set(gca,'TickLength', [.02 .02])
% % axis('tight');
% saveFigure(h,'Seismic_recoveryintialnoweight_nextfreq')

%% test the weighting
D = squeeze((data(a-1,1:354,1:354)));
b = Bfun(D);
params.Ind = find(b==0);
params.afun = @(x)afun(x,params.Ind);
q = params.nr-15; % low rank approximation
w = sqrt(0.3); % set weight value
xls=L1*R1';
% Dtest=SR*vec(D);
% Dtest=reshape(Dtest,params.numr,params.numc);
[U E V] = svd(xls);
n1 = size(U,1);
n2 = size(V,1);
weigh=[w;q;n1;n2;vec(U);vec(V)];
params.weight=weigh;
%%
% xinit  = [vec(LInit);vec(RInit)]; % Initial guess
% tau = norm(xinit,1);
clear opts;
opts = spgSetParms('optTol',1e-5, ...
                   'bpTol', 1e-5,...
                    'decTol',1e-4,...
                   'project', @TraceNorm_projectweight, ...
                   'primal_norm', @TraceNorm_primalweight, ...
                   'dual_norm', @TraceNorm_dualweight, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'iterations', 150,...
                   'weights', []);
opts.funPenalty = @funLS;
[xLS2,r1,g1,info1] = spgl1(@NLfunForward,b,tau,sigma,xinit,opts,params);
e = params.numr*params.nr;
L2 = xLS2(1:e);
R2 = xLS2(e+1:end);
L2 = reshape(L2,params.numr,params.nr);
R2 = reshape(R2,params.numc,params.nr);
xls2 = reshape(SR'*vec(L2*R2'),nR,nC);
SNR1 = -20*log10(norm(D-xls2,'fro')/norm(D,'fro'))
% x=0:12.5:354*12.5;
% y=0:12.5:354*12.5;
% h=figure;
% imagesc(x,y,real(xls2));colormap(seiscol);caxis([-500 500]);
% xlabel('Source(m)','FontSize',15, 'FontName','helvetica','FontWeight','demi')
% ylabel('Receiver(m)','FontSize',15, 'FontName','helvetica','FontWeight','demi')
% set(gca,'fontsize',10,'FontName','helvetica','FontWeight','demi')
% set(gca,'XTick',[0:1000:4000])
% set(gca,'XTickLabel',{'0';'1000';'2000';'3000';'4000'})
% set(gca,'YTick',[0:1000:4000])
% set(gca,'YTickLabel',{'0';'1000';'2000';'3000';'4000'})
% % set(gca,'TickDir', 'out')
% %set(gca,'TickLength', [.02 .02])
% % axis('tight');
% saveFigure(h,'Seismic_recoverywithweightnextfreq')
