function [maximum] = maxValue(s, param, modelID)

% Get maximum values (parameter upper bounds) for parameters:
% k - effort discounting

% Jo Cutler March 2022

minEffort = min(s.beh{1, 1}.effort); % minimum effort level
maxEffort = max(s.beh{1, 1}.effort); % maximum effort level
minReward = min(s.beh{1, 1}.reward); % minimum reward level
maxReward = max(s.beh{1, 1}.reward); % maximum reward level

% maximum k calculated as the discount rate that means the
% maximum reward and minimum effort has a value of 0

% val = reward - (discount.*(effort.^2));
maxKp = round(maxReward - 0)/(minEffort^2); % parabolic
% val = reward - (discount.*(effort));
maxKl = (maxReward - 0)/(minEffort); % linear
% val = reward ./ (1 + (discount.*(effort)));
maxKh = (maxReward)/(minEffort*2); % hyperbolic

if contains(modelID, 'all')
    maxK = round(max([maxKp, maxKl, maxKh]),2);
elseif contains(modelID, 'linear')
    maxK = round(maxKl,2);
elseif contains(modelID, 'hyperbolic')
    maxK = round(maxKh,2);
else
    maxK = round(maxKp,2);
end
   
switch param
    case 'k'
        maximum = maxK;
    case 'rew'
        maximum = maxrew;
end

end

