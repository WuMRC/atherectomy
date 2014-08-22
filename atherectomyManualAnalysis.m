%% STEP 1 - Get video file
% Get video for analysis
[videoInfo.filename, videoInfo.pathname] = ...
    uigetfile('*.mp4;*.avi','Pick a video file');
addpath(genpath(videoInfo.pathname))

videoFile = VideoReader(videoInfo.filename);


%% STEP 2 - Look through frames/regions of interest
implay(videoInfo.filename)

% Select region of interest
figure, imshow(read(videoFile,1))

hBox = imrect;
roiPosition = wait(hBox);

% roiPosition;
roi_xind = round([roiPosition(2), roiPosition(2), ...
    roiPosition(2)+roiPosition(4), roiPosition(2)+roiPosition(4)]);
roi_yind = round([roiPosition(1), roiPosition(1)+roiPosition(3), ...
    roiPosition(1)+roiPosition(3), roiPosition(1)]);
close

video = read(videoFile);
videoROI = video(roi_xind(1):roi_xind(3),roi_yind(1):roi_yind(2),1,:);

%% STEP 3 - Analyze specific frames

frameOfInterest = 2;

videoFile = VideoReader(videoInfo.filename);
imageOfInterest = read(videoFile,frameOfInterest);
imtool(imageOfInterest)


%% STEP 4 - Displacement Analysis

[nRows, nCols, nFrames] = size(videoROI);

fps = 3000;
time = 0:(1/fps):((nFrames-1)/fps);

distancePerPixel = 1.96/64; 
edgeLength = (0:1:nCols-1)*distancePerPixel;



level = graythresh(videoROI(:,:,1));

framesToAnalyze = 200;

BW = zeros(nRows,nCols,nFrames);
bottomEdge = zeros(nCols,nFrames);
displacement = zeros(nCols,nFrames);
displacementS = zeros(nCols,nFrames);
displacementSS = zeros(nCols,nFrames);



for indFrames = 1:framesToAnalyze%nFrames
    BW(:,:,indFrames) = im2bw(videoROI(:,:,indFrames),level);
    for indCol = 1:nCols
        x = find(BW(:,indCol,indFrames),1,'last');
        if size(x,1) == 1
            bottomEdge(indCol,indFrames) = x;
        elseif size(x,1) == 0
            bottomEdge(indCol,indFrames) = NaN;
        end
%         bottomEdgeSMOOTH(indCol,indFrames) = smooth(bottomEdge(indCol,indFrames),10);
    
    end
    displacement(:,indFrames) = (bottomEdge(:,indFrames) ...
        - bottomEdge(:,1))*distancePerPixel*1000;
    displacementS(:,indFrames) = smooth(displacement(:,indFrames),20);
end

for indCol = 1:nCols
    % Delete if you have changed the size of framesToAnalyze
    displacementSS(indCol,:) = smooth(displacementS(indCol,:),3);
end
    

mesh( time(1:framesToAnalyze), edgeLength,displacementSS(:,1:framesToAnalyze))

xlabel('Time [s]')
ylabel('Length Along Edge [mm]')
zlabel('Displacement [µm]')
