%% STEP 1 - Select video file
% Get video for analysis.

[videoInfo.filename, videoInfo.pathname] = ...
    uigetfile('*.mp4;*.avi','Pick a video file');
addpath(genpath(videoInfo.pathname))

vidObj = VideoReader(videoInfo.filename);



%% STEP 2 - Read in video file for analysis
% This takes a really, really long time, but I see now obvious way to speed
% it up. I wish I could.

videoToAnalyze = zeros(vidObj.Height,vidObj.Width,vidObj.NumberOfFrames);

for indFrame = 1:vidObj.NumberOfFrames
    videoToAnalyze(:,:,indFrame) = read(vidObj,indFrame);
end


%% STEP 3a - Multithreshold analysis - see what looks good

threshLevel = 1:12;
figure('units','normalized','outerposition',[0 0 1 1])
for indThresh = 1:length(threshLevel)
    thresh = multithresh(videoToAnalyze(:,:,1),threshLevel(indThresh));
    Iseg = imquantize(videoToAnalyze(:,:,1),thresh);
    RGB(:,:,:,indThresh) = label2rgb(Iseg);
    subplot(3,4,indThresh), imshow(RGB(:,:,:,indThresh))
    title(strcat(num2str(indThresh),' threshold levels'))
end


%% STEP 3b - Convert the image to different segments
threshLevel = 2;    % change based on what looks good from 3a

thresh = multithresh(videoToAnalyze(:,:,1),threshLevel);

nFrames = 50000;
for indFrame = 1:nFrames
    videoSegmented(:,:,indFrame) = imquantize(videoToAnalyze(:,:,indFrame),thresh);
end


%% STEP 4 - Track cable motion
cableColLo = 1;
cableColHi = 45;

peakSegment = threshLevel+1;

for indFrame = 1:nFrames
    for indCol = cableColLo:cableColHi
        if find(videoSegmented(:,indCol,indFrame)==peakSegment,1,'first') > 1
            cable(indCol,indFrame) = ...
                find(videoSegmented(:,indCol,indFrame)==peakSegment,1,'first');
        else cable(indCol,indFrame) = NaN;
        end
    end
end

% imshow(test(:,:,1),'DisplayRange',[0 3])
% hold on, plot(cable,'r')

mesh(cable(:,1:1000))


%% PRE-STEP 5 - The effects of smoothing

smoothLevel = 10:10:120;

figure('units','normalized','outerposition',[0 0 1 1])
for indSmooth = 1:length(smoothLevel)
    subplot(3,4,indSmooth), plot(cable(cableColHi,1:1000))
    hold on, plot(smooth(cable(cableColHi,1:1000),smoothLevel(indSmooth)),...
        'Color','r','LineWidth',2);
    title(strcat('A smoothing factor of ', num2str(smoothLevel(indSmooth))))
end


%% STEP 5 - Filter cable motion into low and high frequency

Fs = 18000;

cableMotionLo = zeros(size(cable,1),size(cable,2));
cableMotionHi = zeros(size(cable,1),size(cable,2));

for indCol = cableColLo:cableColHi
    cableMotionLo(indCol,:) = smooth(cable(indCol,:),30);    
end

cableMotionHi(:,:) = cable(:,:) - cableMotionLo(:,:);





