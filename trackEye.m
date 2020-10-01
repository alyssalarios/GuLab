function [pupil, pupilMontageOverlay] = trackEye(varargin)
%takes a mouse eye movie and outputs a struct with pupil measurements
%across whole movie. Struct contains info about pupil centroid, diameter,
%perimeter, eccentricity, major axis, minor axis per frame in the movie

%% intitialize input parser

%filtering parameters: 
% %sensitivity = luminance threshold
% %pixelAreaThresh = filter out contiguous objects in image smaller than
% %this number
% %maskSurround = intensity to match region just outside ROI
% %frameBinSize = number of frames to average per measurement

p = inputParser;
p.addRequired('vidPath');
p.addParameter('sensitivity',0.1);
p.addParameter('pixelAreaThresh',30);
p.addParameter('maskSurround',256);
p.addParameter('frameBinSize',3);
p.addOptional('showFilterSteps',false);% make true when finding correct filtering...
                                       %params for the movie 
p.addParameter('showPupilDetect',true);
p.addParameter('keepOrigLength',true);

parse(p,varargin{:});

%create video object and initialize filtering parameters
eyeVid = VideoReader(p.Results.vidPath);
binnedSize = eyeVid.NumFrames / p.Results.frameBinSize;
showImgs = p.Results.showFilterSteps;

%% Initialize blob analysis, eye ROI and data structures for deposition

%create blob analysis object
eBlob = vision.BlobAnalysis('MajorAxisLengthOutputPort',true,...
    'MinorAxisLengthOutputPort',true,'EccentricityOutputPort',true, ...
    'PerimeterOutputPort',true);

%create ROI for mask
fig = figure(1);
imshow(read(eyeVid,1));
eyeRect = drawrectangle('LineWidth',1,'Color','red');
fig3 = figure(3);
title('Close this window when done drawing ROI');
uiwait(fig3);

%applymask
frame1 = rgb2gray(read(eyeVid,1));
mask = createMask(eyeRect,frame1);
notEyeRect = find(mask == 0);

%initialize empty arrays for width,height,eccentricity, centroid coordinates
widthHeightVector = zeros(binnedSize,2);
eccentricityVector = zeros(binnedSize,3);
centroidCoordVector = zeros(binnedSize,2);
areaPeriVector = zeros(binnedSize,2);

%detection stack for output
pupilMontageOverlay = zeros(size(frame1,1),size(frame1,2),binnedSize);

counter = 0;


%% loop through frames in eyeVid movie object

for i = 1:eyeVid.NumFrames
    frame = read(eyeVid,i);
    
    %read frame, apply mask, and binarize image
    bw = rgb2gray(frame);
    bw(notEyeRect) = p.Results.maskSurround;
    bin = imbinarize(bw,'adaptive','ForegroundPolarity','dark',...
        'Sensitivity',p.Results.sensitivity);
    bin = imcomplement(bin);
    
    %show mask and binarized image
    if showImgs
        figure(1);
        subplot(2,1,1)
        imshowpair(bw,bin,'montage')
        title('threshold')
    end
    
    %filter out stray pixels with object size threshold and filter by
    %smallest eccentricity
    areafilter = bwareaopen(bin,p.Results.pixelAreaThresh);
    
    if mod(i,p.Results.frameBinSize) ~= 0
        spot = mod(i,p.Results.frameBinSize);
        areafilterblock(:,:,spot) = areafilter;
        continue
    else
        
        %average the frames together
        counter = counter +1;
        areafilterblock(:,:,p.Results.frameBinSize) = areafilter;
        doubleblock = double(areafilterblock);
        averagefilterblock = mean(areafilterblock,3);
        
        %filter out pixels there 2/5 or lower
        avgFilter = averagefilterblock <= .4;
        averagefilterblock(avgFilter) = 0;
        averagedbin = imbinarize(averagefilterblock);
        
        %filter by eccentricity
        Ecleaned = bwpropfilt(averagedbin,'Eccentricity',3,'smallest');
        MaxisCleaned = bwpropfilt(Ecleaned,'MajorAxisLength',[7,200]);
        ExtentFilter = bwpropfilt(MaxisCleaned,'Extent',1,'largest');
        
        %show open aread and eccentricity filter
        if showImgs
            subplot(2,1,2)
            imshowpair(areafilter,Ecleaned,'montage');
            title('area and eccentricity filter')
        end
        
        %fill in holes in object
        filled = imfill(ExtentFilter,8,'holes');
        filled = imfill(filled,8,'holes');
        
        %show filled object
        if showImgs
            figure(2)
            subplot(2,1,1)
            imshowpair(Ecleaned,filled,'montage');
            title('fill holes')
        end
        
        %do blob analysis and draw over frame
        [area,centroid,bbox,majoraxis,minoraxis,eccentricity,perimeter] = eBlob(filled);
        if isempty(centroid)
            centroid(1:4) = 0;
            bbox(1:4) = 0;
            area = 0;
            majoraxis = 0;
            minoraxis = 0;
            eccentricity = 0;
            perimeter = 0;
        end
        pupilDetect = insertShape(frame,'Circle',[centroid(1),centroid(2),bbox(3)/2],...
            'LineWidth',2,'Color','black');
%         centroidDetect = insertShape(filled,'Circle',[centroid(1),centroid(2),bbox(3)/2],...
%             'LineWidth',1,'Color','red');
        %       pupilDetectB = insertShape(frame,'rectangle',bbox,...
        %          'LineWidth',1,'Color','green');
        
        %show centroid and pupil detection
        if showImgs
            
            subplot(2,1,2)
            imshow(pupilDetect)
        end
        
        %add detection to stack
        pupilMontageOverlay(:,:,counter) = rgb2gray(pupilDetect);
        
        %grab pupil measurements
        centroidCoordVector(counter,:) = centroid(1:2);
        widthHeightVector(counter,:) = [bbox(3),bbox(4)];
        eccentricityVector(counter,:) = [majoraxis,minoraxis,eccentricity];
        areaPeriVector(counter,:) = [area,perimeter];
        
        
        if p.Results.showPupilDetect
            imshow(pupilDetect);
            title(i)
        end
        
    end
       
end
if ~ p.Results.keepOrigLength
    rep = 1;
else
    rep = p.Results.frameBinSize;
end
pupil.centroid = repelem(centroidCoordVector,rep,1);
pupil.width = repelem(widthHeightVector(:,1),rep,1);
pupil.height = repelem(widthHeightVector(:,2),rep,1);
pupil.eccentricity = repelem(eccentricityVector(:,3),rep,1);
pupil.majorAxis = repelem(eccentricityVector(:,1),rep,1);
pupil.minorAxis = repelem(eccentricityVector(:,2),rep,1);
pupil.area = repelem(areaPeriVector(:,1),rep,1);
pupil.perimeter = repelem(areaPeriVector(:,2),rep,1);

end
%% plot blob measurements
% %plot width / time, height/time, eccentricity/time, width/height, mvmt
% figure(3)
% subplot(3,1,1)
% plot(1:binnedSize,widthHeightVector(:,1))
% title('Width over time')
% 
% subplot(3,1,2)
% plot(1:binnedSize,widthHeightVector(:,2))
% title('height over time')
% 
% subplot(3,1,3)
% scatter(widthHeightVector(:,1),widthHeightVector(:,2),'o')
% xlabel('width')
% ylabel('height')
% 
% figure(4)
% subplot(3,1,1)
% plot(1:binnedSize,eccentricityVector(:,3))
% title('eccentricity over time')
% subplot(3,1,2)
% plot(1:binnedSize,eccentricityVector(:,1))
% title('major axis over time')
% subplot(3,1,3)
% plot(1:binnedSize,eccentricityVector(:,2))
% title('minor axis over time')
% 
% figure(5)
% subplot(2,1,1)
% plot(1:binnedSize,centroidCoordVector(:,1),'g')
% hold on 
% plot(1:binnedSize,centroidCoordVector(:,2),'r')
% subplot(2,1,2)
% plot(1:binnedSize-1,diff(centroidCoordVector(:,1)),'g')
% hold on
% plot(1:binnedSize-1,diff(centroidCoordVector(:,2)),'r')
% title('change in centroid position (X -green, Y-red')
% 
% 
% figure(6)
% subplot(2,1,1)
% plot(1:binnedSize,areaPeriVector(:,1))
% title('area over time')
% subplot(2,1,2)
% plot(1:binnedSize,areaPeriVector(:,2))
% title('perimeter over time')

