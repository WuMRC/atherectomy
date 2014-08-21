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
