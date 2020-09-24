function [activeROIintensities, quietROIintensities] = ROIintensityMask(data,varargin)
% Takes cell array, written for parseVisualStimData output, m-by-n where m
% is number of stimulus positions and n is number of trials per stim.
% averages trials together per location and displays max intensity image,
% at which point you are promted to double click on a region where gcamp
% activity is evoked, then a region where activity was not evoked. This
% occurs for each position average. 

% output is two m by 1 cell arrays containing matrices of n-by-numFrames where 
% row is an individual trial and each column is an individual frame in the
% trial. Values are average intensity pixel values (normalized by
% normFrames) within the active or quiet ROI of radius ROIradius

%% Initialize inputParser
p = inputParser;
p.addRequired('data');
p.addParameter('normalize',true)
p.addParameter('normFrames',(8:14));
p.addParameter('numFrames',55);
p.addParameter('stimFrames',(25:35));
p.addParameter('ROIradius',10);

parse(p,data,varargin{:});

%% create avg intensity, avg stim intensity for each position 

if p.Results.normalize
        data = cellfun(@(x) double(x) ... 
            ./mean(x(:,:,p.Results.normFrames),3),data,...
            'UniformOutput',false);
end

avgIntAllTrials = cell(size(data,1),1);
stimFrameData = cell(size(data,1),1);
avgStimFrames = cell(size(stimFrameData,1),1);
for i = 1:size(data,1)
    avgIntAllTrials{i} = mean(cat(3,data{i,:}),3);
end

stimFrameData = cellfun(@(x) x(:,:,p.Results.stimFrames),data,...
    'UniformOutput',false);

for i = 1:size(stimFrameData,1)
    avgStimFrames{i} = mean(cat(3,stimFrameData{i,:}),3);
end 

%% draw ROIs for active and quiet areas, create masks for each stim position

activeMask = cell(length(avgIntAllTrials),1);
quietMask = cell(length(avgIntAllTrials),1);

for i = 1:length(avgIntAllTrials)
    figure(1)
    imagesc(avgStimFrames{i});colorbar;
    title(['double click ACTIVE ROI: ',num2str(i)])
    [x,y] = getpts;
    activeArea = drawcircle('Center',[x,y],'LineWidth',1,'Color','red',...
        'Radius',p.Results.ROIradius,'InteractionsAllowed','none');
    activeMask{i} = createMask(activeArea,stimFrameData{i,1}(:,:,1));
    close(figure(1))
    
    figure(1)
    imagesc(avgStimFrames{i});colorbar;
    title(['double click NONactive ROI: ',num2str(i)])
    [x,y] = getpts;
    quietArea = drawcircle('Center',[x,y],'LineWidth',1,'Color','red',...
        'Radius',p.Results.ROIradius,'InteractionsAllowed','none');
    quietMask{i} = createMask(quietArea,stimFrameData{i,1}(:,:,1));
    close(figure(1))
    
end

%% Create avg intensity vectors within ROIs for each trial

activeROIintensities = cell(size(activeMask,1),1);
quietROIintensities = cell(size(quietMask,1),1);

for i = 1:length(activeROIintensities)
    for j = 1:size(data,2)
        for k = 1:size(data{i,j},3)
            frame = data{i,j}(:,:,k);
            
            activeROIintensities{i,1}(j,k) = mean(frame(activeMask{i}));
            quietROIintensities{i,1}(j,k) = mean(frame(quietMask{i}));
        end
       
    end
    
end
end