% PREPROCESSING ROUTINE FOR DRIFTING VISUAL STIMULUS

% this script will prompt the user to choose a data file containing raw
% data and metadata.mat. It concatenates all the .tif files and saves a
% file with '_cat.tif' appended. Then it saves a tif of frames when
% stimulus occurred for each stim presentation for activity visualization.
% This tif is deposited in a new folder called 'ProcessedData' within the
% raw data folder.

% Next we parse the concatenated movie to split it into stim presentation
% type and trials. This is a cell array with each block containing a movie
% of that particular trial. Each row is a stim position/type and each
% column is an individual trial. this is parsedData variable.

% Movies for each trial are then averaged together to get a stimulation
% position average. Df/f is computes by subtracting the average of normFrames
% from each frame in the movie.

% data is then separated into individual variables - change number of
% variables manually to accomodate changing stimnulus conditions

%% Routine parameters
concatRawSave = 0; %starting from raw/ split up data movies or not
makeGridTifSave = 0;%save grid tif or not
% if saving, go into Gridtif chunk and make sure dimmensions (gridDims)
%are correct for stimulus parameters
saveData = 1; % if 1, saves preprocessed data in a mat file.
%
loadCatTif = 0;

normFrames = 10:20;
stimFrames = 25:150;
stimType = 'driftCheck'; %takes 'bpNoise' or 'driftCheck'
numFramesPerCycle = 835;
numCycles = 10;

%% Concatenate raw data
% Select folder with raw gcamp movies for concatenation
% In this folder, a tif file will be deposited with '_cat.tif' appended
switch concatRawSave
    case 1
        concatRawTifs;
    case 0
        filename = uigetdir(); %select raw data folder to have variable
        cd(filename) % go to correct directory
end

catMovieDir = dir('*cat.tif');
metaFile = dir('*.mat');
if loadCatTif
    fprintf('Loading %s\n',catMovieDir.name);
    catMovie = loadtiff(catMovieDir.name);
    
end
load(metaFile.name,'rectPositions','cycleOrder');

%% Check for dropped frames 
if mod(size(catMovie,3) ,numFramesPerCycle) ~= 0
    fprintf('dropped frames detected\n')
    fprintf('Filtering cycles with dropped frames\n')
    catMovie = removeTrialsDroppedFrames(catMovie,numFramesPerCycle);
    numCycles = size(catMovie,3)/ numFramesPerCycle;
else
    fprintf('no dropped frames\n')
end

%% Gridtif
switch makeGridTifSave
    
    % in theory this is written for batch but i think the data will be
    % organized 1 folder -> all raw data for 1 mouse 1 imaging session +
    % concatenated file + metadata.mat file
    
    case 1 % Save a tif image with each stim in a grid averaged across
        %presentation frames to get a sense of differential activity
        
        % initialize gridstim shape
        gridDims = [2,2];
        
        % Create a 'ProcessedData' folder within raw data folder and deposits
        % gridstim tif
        tiff = catMovie;
        createGridsTiff;
        
    case 0 % if not saving grid, make a folder in data directory
        % for processed data and cd raw data folder
        mkdir('ProcessedData');
        dataPath = [cd,'/','ProcessedData'];
end

%% Parse raw movie and compute Dff
switch stimType
    case 'bpNoise'
        
        %load movie and positions for bandpass filtered noise presentations
        
        
        parsedData = parseVisualStimData(catMovie,rectPositions,stimType, 'numCycles',numCycles,...
            'numFramesPerCycle',numFramesPerCycle); % depending on how we
        %change the bpNoise stim presentation, might need to go back into
        %this function and make it apply properly
        %       Parameters for this function - name/value pairs
        %           data (required raw tif)
        %           rectPositions (required 1x2xn dimmensional array specifying stim
        %               locations)
        %           numPosns = number of locations possible (default 9)
        %           numTrials = number of trials per location (default 6)
        %           numFramesperTrial = number of frames in movie per trial (default 55)
        %           posVector = locations on screen that stims can take default [.2,.5,.8]
        
        
        % average all trials and subtract baseline
        DffAllTrials = avgDff(parsedData,normFrames);
    case 'driftCheck'
        %load movie and grating type
        
        
        parsedData = parseVisualStimData(catMovie,cycleOrder,stimType,'numCycles',numCycles,...
            'numFramesPerCycle',numFramesPerCycle);
        
        
        % average all trials and subtract baseline
        DffAllTrials = avgDff(parsedData,normFrames);
end

%% Separate averaged movies into new variables and save
switch stimType
    case 'driftCheck'
        % permute so that first dimmension is time
        permutedAllTrials = cellfun(@(x) permute(x,[3,1,2]),DffAllTrials,...
            'un',false);
        
        rightLeft = permutedAllTrials{1,1};
        leftRight = permutedAllTrials{2,1};
        topDown = permutedAllTrials{3,1};
        downUp = permutedAllTrials{4,1};
        
        rightLeftTif = uint16(permutedAllTrials{1,1}*6000);
        leftRightTif = uint16(permutedAllTrials{2,1}*6000);
        topDownTif = uint16(permutedAllTrials{3,1}*6000);
        downUpTif = uint16(permutedAllTrials{4,1}*6000);
        
        % generate key-value pair for phase-delay angle conversion in python
        % load(metaFile.name,'
        
        
        if saveData
            save([dataPath,'/avgNormMovies.mat'],'rightLeft','leftRight','topDown','downUp');
%             saveastiff(rightLeft,[dataPath,'/rightLeft.tif'])
%             saveastiff(leftRight,[dataPath,'/leftRight.tif'])
%             saveastiff(topDown,[dataPath,'/topDown.tif'])
%             saveastiff(downUp,[dataPath,'/downUp.tif'])
        end
end