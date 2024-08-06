% Set path for Linux
%my_path  = "/scratch/user/ssromerogon/scGEAToolbox";
my_path = "../../../src-v0.2";
addpath(genpath(my_path));

path="../D1_1f_G2M_1000g_Monocle.mat";
data  = load(path);
sce = data.sce;
clear data;

% Pre-processing 
g = sce.g;
X = full(sce.X);
X = full(sc_transform(X, "type","PearsonResiduals"));

% Features to extract
K = 20;

% Predictor
cell_type_target = "monocle3_pseudotime";

% Number of genes
ngenes = 1000;

idx = find(contains(sce.list_cell_attributes(1:2:end), cell_type_target));
if isempty(idx), returen; end
y = sce.list_cell_attributes{idx*2};
y = y';

fprintf("Final matrix size %d , %d \n",size(X));

% readR false will recompute R0 (MI)
readR = false;
Tqubo = qfeatures_qubo_base( X, g, y, K, readR);

Tml = mlfeatures_base(X, g, y, K, 4);

% Label stuff
cts = strcat(string(K),cell_type_target);
cts = strcat("_R0_f",cts);
str_numcells="_5k_cells";
fname0 = strcat("_HVG_remonocle_", int2str(ngenes));
fname0 = strcat(cts, fname0 );
fname0 = strcat(fname0, str_numcells); 
fname1 = strcat('Tqubo_', fname0);
save(strcat(fname1,'.mat'),'Tqubo','-v7.3')
fname1 = strcat('Tml_', fname0);
save(strcat(fname1,'.mat'),'Tml','-v7.3')

% Writting features
fname = "featues";
ftext_name = strcat(fname, fname0,".txt" );
writematrix(Tqubo.sol_genes','qubo_features.txt');
writematrix(Tml.sol_genes_lasso',"lasso_features.txt");
writematrix(Tml.sol_genes_chi2',"chi2_features.txt");
writematrix(Tml.sol_genes_anova',"anova_features.txt");
writematrix(Tml.sol_genes_relief',"relief_features.txt");

% Intersection of lasso with qubo
inter_genes = intersect(Tqubo.sol_genes, Tml.sol_genes_lasso, 'stable');

% Saving matrices for d-wave
load('R0.mat');

R = R0(1:end-1,1:end-1)/(K-1);
J = R0(end,1:end-1);
alpha = Tqubo.alphasol;

[~,qubo_sol ] = howmany(alpha,R,J);

% QUBO matrix (utilized for D-WAVE codes)
Q = (1-alpha)*R - alpha*diag(J);
writematrix(Q,'qubo_matrix.csv')
writematrix(g,'genes.csv')
