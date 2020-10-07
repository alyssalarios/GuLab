function dfAllSweeps = avgDf(data,preStimFrames) 
% takes parsed data cell array from parseVisualStimData and averages across
% all trials in the same sweep direction. Output is a nx1 cell array with n
% being the number of stimulus presentation types / direction. Each cell
% contains an average movie for that stim with baseline subtracted in each
% frame. 

%prestim frames is an vector for which frames in each trial correspond to 
%prestim period


%% average across all stim presentations (columns in data struct)
avgAllTrials = cell(size(data,1),1);
for i = 1:size(data,1)
    catData = cat(4, data{i,:});
    avgAllTrials{i,1} = mean(catData,4);
end



%% compute df
preStimAvg = cellfun(@(x) mean(x(:,:,preStimFrames),3),avgAllTrials, ...
     'UniformOutput',false);
df = cellfun(@minus, avgAllTrials,preStimAvg,'un',0);

dfAllSweeps = df;

end

