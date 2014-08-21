%% STEP 1 - Get video file
% Get video for analysis
[videoInfo.filename, videoInfo.pathname] = ...
    uigetfile('*.mp4;*.avi','Pick a video file');
addpath(genpath(videoInfo.pathname))


%% STEP 2 - Play through video looking for frames of interest
implay(videoInfo.filename)


%% STEP 3 - Analyze specific frames

frameOfInterest = 165;

videoFile = VideoReader(videoInfo.filename);
imageOfInterest = read(videoFile,frameOfInterest);
imtool(imageOfInterest)


%%

[nRow, nCols, nFrames] = size(videoROI);


level = graythresh(videoROI(:,:,1));

for indFrames = 1:200%nFrames
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
    displacement(:,indFrames) = bottomEdge(:,indFrames) ...
        - bottomEdge(:,1);
    displacementSMOOTH(:,indFrames) = smooth(bottomEdge(:,indFrames) ...
        - bottomEdge(:,1),10);
end

for indCol = 1:nCols
    
end
    

    framesToAnalyze = 200;
mesh(displacementSMOOTH(:,1:framesToAnalyze))