%%%%%%%%%
%% Modelling for prosocial motivation task using expectation maximisation
%%%%%%%%%

% Fits models using expectation maximisation (em) approach and does model comparison
% Written by Patricia Lockwood, January 2020
% Based on code by MK Wittmann, October 2018
% Edited by Jo Cutler, August 2020

%%%%%%%%%
% Step 1 - get data in the format of a varible 's' that contains a struct for each persons data
% Step 2 - run this script to fit models
% Dependencies: tools subfolder containing required functions e.g. fit_PM_model
%               models subfolder containing various comp models you have made
% Step 3 - compare the AIC's and BIC's using the script visualize_model_PM
% (see below)

%% Input for script
%       - Participants data file format saved in 's':

%% Output from script
%   - workspaces/EM_fit_results_[date] has all variables from script
%           - 's.PM.em' contains model results including the model parameters per ppt
%   - datafiles in specified output directory:
%       - PM_model_fit_statistics.csv - model comparison fit statistics
%       - EM_fit_parameters.csv - estimated parameters for each participant
%       - Compare_fit_between_groups.csv - median R^2 for each participant with group index

%% Prosocial motivation models based Lockwood et al. (2017)
% test different variations of discount rate (k) and beta parameters:
%   - one_k_one_beta
%   - two_k_one_beta
%   - one_k_two_beta
%   - two_k_two_beta
% and shape of discounting:
%   - parabolic
%   - linear
%   - hyperbolic

%%

%== -I) Prepare workspace: ============================================================================================

clearvars
addpath('models');
addpath('tools');
setFigDefaults; % custom function - make sure it is in the folder

rng default % resets the randomisation seed to ensure results are reproducible (MATLAB 2019b)

include = 'all'; % 'all' (all age-matched controls, all lesion patients) **
output_dir = '../PM_R_code/data/'; % enter path to save output in **

%== 0) Load and organise data: ==========================================================================================
% load data:
file_name = ['Combined_data_',include,'.mat']; % specify data **
load([file_name]); % .mat file saved from the behavioural script that contains all participants data in 's'
s.PM.expname = 'ProsocialMotivation';
s.PM.em = {};

sheet = ['PM_included_',include];
[~, ~, groups] = xlsread('vmPFC_participant_index.xlsx', sheet);
groups = groups(2:end,:);

% how to fit RL:
M.dofit     = 1;                                                                            % whether to fit or not
M.doMC      = 1;                                                                            % whether to do model comparison or not
M.modid     = {'ms_one_k_one_beta', 'ms_one_k_one_beta_linear', 'ms_one_k_one_beta_hyperbolic'...
    'ms_one_k_two_beta', 'ms_one_k_two_beta_linear', 'ms_one_k_two_beta_hyperbolic'...
    'ms_two_k_one_beta', 'ms_two_k_one_beta_linear', 'ms_two_k_one_beta_hyperbolic'...
    'ms_two_k_two_beta', 'ms_two_k_two_beta_linear', 'ms_two_k_two_beta_hyperbolic'};

fitMeasures = {'lme','bicint','xp','pseudoR2','choiceProbMedianR2'}; % which fit measures to calculate **
criteria = 'bicint'; % of above, which to use to choose the best model **

% run optional additional analysis using the VBA toolbox? (see below)
doVBA = 0; % 1 = yes, 0 = no **

% define experiment of interest:
e = 'PM'; % **

bounds.beta = [0, 5];

%== I) RUN MODELS: ==========================================================================================

if M.dofit
    %%% EM fit %%%
    for im = 1:numel(M.modid) % for the number of models
        dotry=1;
        while 1==dotry
            %try
            close all;
            s.(e).em = EMfit_ms(s.(e),M.modid{im},bounds);dotry=0;
            %catch
            %dotry=1; disp('caught');
            %end
        end
    end
end

%%% calc BICint for EM fit
for im = 1:numel(M.modid)
    
    s.(e).em.(M.modid{im}).fit.bicint =  cal_BICint_ms(s.(e), M.modid{im}, bounds);
    
end

%== II) COMPARE MODELS: ==========================================================================================

if M.doMC
    s.(e) = EMmc_ms(s.(e),M.modid);
end

% Calculate R^2 & extract model fit measures

for im = 1:numel(M.modid) % for the number of models
    s.(e).em.(M.modid{im}).fit.pseudoR2 = pseudoR2(s.(e),M.modid{im},2,1);
    s.(e) = choiceProbR2(s.(e),M.modid{im},1);
end
[fits.(e),fitstab.(e)] = getfits(s.(e),fitMeasures,M.modid);

%== III) LOOK AT PARAMETERS: ==========================================================================================

bestPMmod = find(fitstab.PM.(criteria) == min(fitstab.PM.bicint));
bestPMmodname = M.modid{bestPMmod};
disp(['Extracting parameters from ', bestPMmodname,' based on best ',criteria])

% For PM models:
for sub=1:length(s.PM.ID)
    
    ID_all(sub, :)=s.PM.ID{1,sub}.ID;
    
end

%== IV) SAVE: ==========================================================================================

fit = fits.(e);
fit = [[1:numel(M.modid)]',fit];
fit(:,end+1) = fit(:,find(contains(fitMeasures, 'bicint'))+1) - min(fit(:,find(contains(fitMeasures, 'bicint'))+1));
fittabnum = cell2table(num2cell(fit), 'VariableNames', ['model', fitMeasures, 'relbic']);
writetable(fittabnum,[output_dir,e,'_model_fit_statistics_',include,'.csv'],'WriteRowNames',true)

IDs = strrep(ID_all, 'PM', ''); % remove characters PM and .log from the ID codes
IDs = strrep(IDs, '.log', '');

for i = 1:length(ID_all)
    try
        s.PM.groups(i,1) = groups{find(strcmp(ID_all(i),groups(:,1))),end};
    catch
    end
end

params = getparams(s.PM, bestPMmodname, bounds, IDs, s.PM.groups);

writetable(params.all_table,[output_dir,'EM_fit_parameters_',include,'.csv'],'WriteRowNames',true) % combine this with other participant data for analysis

save(['workspaces/EM_fit_results_',include,'_',date,'.mat'])

%== V) COMPARE PARAMETERS BETWEEN GROUPS: ==========================================================================================

compareFitGroups = [(s.PM.groups),(s.PM.em.(bestPMmodname).fit.bic),(s.PM.em.(bestPMmodname).fit.eachSubProbMedianR2)];
compareFitTab = cell2table(num2cell(compareFitGroups), 'VariableNames', {'group', 'bic', 'R2'});
writetable(compareFitTab,[output_dir,'Compare_em_fit_between_groups_',include,'.csv'],'WriteVariableNames',true) % export file to analyse in R

if doVBA == 1
    
    % optional - use the VBA toolbox - https://mbb-team.github.io/VBA-toolbox/
    % to calcuate the xp and expected frequencies in each group and test
    % whether the groups are different in model fit
    
    L1ind = find(s.PM.groups == 1); % group 1
    L2ind = find(s.PM.groups == 2); % group 2
    L3ind = find(s.PM.groups == 3); % group 3
    Lallind = [L1ind;L2ind;L3ind]; % all groups
    
    for im = 1:numel(M.modid) % for the number of models
        Lall(im,1:length(Lallind)) = s.PM.em.(M.modid{im}).fit.lme(Lallind); % extract log model evidence for each participant
        L1(im,1:length(L1ind)) = s.PM.em.(M.modid{im}).fit.lme(L1ind);
        L2(im,1:length(L2ind)) = s.PM.em.(M.modid{im}).fit.lme(L2ind);
        L3(im,1:length(L3ind)) = s.PM.em.(M.modid{im}).fit.lme(L3ind);
    end
    
    [posterior,out] = VBA_groupBMC(Lall); % all groups
    [posterior1, out1] = VBA_groupBMC(L1) ; % group 1
    [posterior2, out2] = VBA_groupBMC(L2) ; % group 2
    [posterior3, out3] = VBA_groupBMC(L3) ; % group 3
    [h12, p12] = VBA_groupBMC_btwGroups({L1, L2}); % between groups comparison
    [h13, p13] = VBA_groupBMC_btwGroups({L1, L3}); % between groups comparison
    [h23, p23] = VBA_groupBMC_btwGroups({L2, L3}); % between groups comparison
    
else
end