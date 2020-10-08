%% SAVE GRID TIF OF AVERAGE ACTIVITY DURING STIM PRESENTATION
% bulk movie analysis routine where a folder containing widefield gcamp
% movies are fed in, the movies are parsed and separated into data
% structures separated by stimulus location and trials. 

% average intensity plots are created into a grid to visualize region
% specific activation. Normalized to first few frames for presentation
% purposes

% script makes a folder ProcessedData in the input data folder and deposits
% a tif of this inensity grid per stimulus position for each movie

%% uncomment below if using this script outside of preprocessing routine
% %% initialize parameters 
% normFrames = 8:14;
% stimFrames = 25:35;
% gridDims = [3,3];

%Leave variable if doing preprocessing routine
preprocessingRoutine = 1;

%% grab data file to loop through and change directory for data depo

%uncomment three lines below if using this script outside preprocessing
%routine

% fprintf('Choose data file\n');
% filename = uigetdir('','Select file');
% cd(filename);
filelist = dir(fullfile(filename,'*cat.tif')); %can alter the last string to 
    %match naming convention for concatenated tif

metalist = dir(fullfile(filename,'*.mat'));
 

mkdir('ProcessedData');
dataPath = [cd,'/','ProcessedData'];

%% loop through filelist and make a gridstim tiff for each gcamp movie
% parseVisualStimData parameters
%   data (required raw tif)
%   rectPositions (required 1x2xn dimmensional array specifying stim
%   locations)
%   numPosns = number of locations possible (default 9)
%   numTrials = number of trials per location (default 6)
%   numFramesperTrial = number of frames in movie per trial (default 55)
%   posVector = locations on screen that stims can take default [.2,.5,.8]


for i = 1: length(filelist)

    if ~preprocessingRoutine
        tiff = loadtiff(filelist(i).name);
    end
    parsedData = parseVisualStimData(tiff, cycleOrder,'driftCheck','numCycles',numCycles,'numFramesPerCycle',...
        numFramesPerCycle);
    a = 1;
    %normalize 
    normData = cellfun(@(x) double(x) ... 
            ./mean(x(:,:,normFrames),3),parsedData,'UniformOutput',false);
    
    %average stimframes 
    stimFrameData = cellfun(@(x) x(:,:,stimFrames),normData,...
    'UniformOutput',false);
    avgStimFrames = cell(size(stimFrameData,1),1);
    for j = 1:size(stimFrameData,1)
        avgStimFrames{j} = mean(cat(3,stimFrameData{j,:}),3);
    end 
    
    % make large array with all avg trials
    reshapedAvg = reshape(avgStimFrames,gridDims);
    posnConcat = [];
    for k = 1:gridDims(2)
        a = cat(1,reshapedAvg{:,k});
        posnConcat = [posnConcat,a];
    end
    posnConcat = posnConcat*60000;
    finalArray = uint16(posnConcat);
    
    % save array as tif in processedData folder
    cd(dataPath)
    fprintf('saving %s grid\n',filelist(i).name);
    imwrite(finalArray,[filelist(i).name(1:end-4),'_grid.tif'],'Compression','none');
    cd .. 
end 