%% STEP 1 - Select video file
% Get video for analysis.

[videoInfo.filename, videoInfo.pathname] = ...
    uigetfile('*.mp4;*.avi','Pick a video file');
addpath(genpath(videoInfo.pathname))

vidObj = VideoReader(videoInfo.filename);



%% STEP 2 - Read in video file for analysis
% This takes a really, really long time, but I see now obvious way to speed
% it up. I wish I could.

% nFrames = vidObj.NumberOfFrames;
nFrames = 18000;

videoToAnalyze = zeros(vidObj.Height,vidObj.Width,nFrames);

for indFrame = 1:nFrames
    videoToAnalyze(:,:,indFrame) = read(vidObj,indFrame);
end


%% STEP 3a - Multithreshold analysis - see what looks good (optional)


threshLevel = 1:12;

RGB = zeros(vidObj.Height,vidObj.Width,3,max(threshLevel));

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

videoSegmented = zeros(vidObj.Height,vidObj.Width,nFrames);

for indFrame = 1:nFrames
    videoSegmented(:,:,indFrame) = imquantize(videoToAnalyze(:,:,indFrame),thresh);
end


%% STEP 4 - Track cable motion
cableColLo = 1;
cableColHi = 45;

peakSegment = threshLevel+1;

cable = zeros(vidObj.Height,length(cableColLo:cableColHi),nFrames);

for indFrame = 1:nFrames
    for indCol = cableColLo:cableColHi
        if find(videoSegmented(:,indCol,indFrame)==peakSegment,1,'first') > 1
            cable(indCol,indFrame) = ...
                find(videoSegmented(:,indCol,indFrame)==peakSegment,1,'first');
        else cable(indCol,indFrame) = NaN;
        end
        
    end
%     % Remove any gaps we may have caused
%     cable(indCol,indFrame) = naninterp(cable(:,indFrame));
end


% imshow(test(:,:,1),'DisplayRange',[0 3])
% hold on, plot(cable,'r')

mesh(cable(:,1:1000))


%% PRE-STEP 5 - The effects of smoothing (optional)

smoothLevel = 10:10:120;

figure('units','normalized','outerposition',[0 0 1 1])
for indSmooth = 1:length(smoothLevel)
    subplot(3,4,indSmooth), plot(cable(cableColHi,1:1000))
    hold on, plot(smooth(cable(cableColHi,1:1000),smoothLevel(indSmooth)),...
        'Color','r','LineWidth',2);
    title(strcat('A smoothing factor of ', num2str(smoothLevel(indSmooth))))
end


%% STEP 5 - Filter cable motion into low and high frequency

cableMotionLo = zeros(size(cable,1),size(cable,2));
cableMotionHi = zeros(size(cable,1),size(cable,2));

% Choose the portion of cable whose data you want to smooth, because it
% takes so long I have only chosen one value, but it might be worthwile to
% select the whole region if time permits
colOfInterest = 1;
for indCol = colOfInterest%cableColLo:cableColHi
    cableMotionLo(indCol,:) = smooth(cable(indCol,:),30);    
end

cableMotionHi(:,:) = cable(:,:) - cableMotionLo(:,:);


%% STEP 6 - Detect peak frequency of the cable
FsCamera = 18000;
FsRot = 60000/60;   % rpm/(sec/min) = Hz

% If you get errors below insert either naninterp(cableMotionHi(colOfInterest,:))
% or naninterp(cableMotionLo(colOfInterest,:)) into the pesky part

[freqCableLo, magCableLo] = ...
    peakFreq(naninterp(cableMotionLo(colOfInterest,:)),FsCamera,'low',FsRot*2);
[freqCableHi, magCableHi] = ...
    peakFreq(naninterp(cableMotionHi(colOfInterest,:)),FsCamera,'low',FsRot*2);

%% Setp 7 - Track midpoint of the ginding burr
% Select the midpoint
imshow(videoToAnalyze(:,:,1),'DisplayRange',[0 255])
title('Select the middle of the grinding burr, then hit "Enter"')
figHandle = gcf;
[poiX, poiY] = getpts(figHandle);
close

midCol = uint8(poiX);

burr = zeros(nFrames);

% Track the midpoint
for indFrame = 1:nFrames
    
    if find(videoSegmented(:,midCol,indFrame)==peakSegment,1,'first') > 1
        burr(indFrame) = ...
            find(videoSegmented(:,midCol,indFrame)==peakSegment,1,'first');
    else burr(indFrame) = NaN;
    end
%     % Remove any gaps we may have caused
%     burr(indFrame) = naninterp(burr(indFrame));
end


% imshow(test(:,:,1),'DisplayRange',[0 3])
% hold on, plot(cable,'r')

plot(burr(1:5000))

%% STEP 8 - Smooth burr motion
smoothLevel = 30;
burrMotionLo = smooth(naninterp(burr),smoothLevel);

plot(burr(1:1000)), hold on, plot(burrMotionLo(1:1000),'r')

%% STEP 9 - Frequency decomposition of the burr's motion
FsCamera = 18000;
FsRot = 60000/60;   % rpm/(sec/min) = Hz

[freqBurrLo, magBurrLo] = ...
    peakFreq(burrMotionLo,FsCamera,'low',FsRot*2);

%% STEP 10 - Compare cable and burr motion (low frequency)
% Note the lag-lead
plot(burrMotionLo(1:5000))
hold on, plot(cableMotionLo(1,1:5000),'r')

%% STEP 11 - Force analysis
% Select force file
[forceInfo.filename, forceInfo.pathname] = ...
    uigetfile('*.txt','Select the .txt corresponding to the force data.');
addpath(genpath(forceInfo.pathname))

% Import the data and detrend it
force = importdata(strcat(forceInfo.pathname,forceInfo.filename));
forceCorrected = detrend(force);

% Find the peak frequency values from the force
FsForce = 5000;
[freqForceLoZ, MagForceLoZ] = ...
    peakFreq(forceCorrected(:,1),FsForce,'low',FsRot/2);
[freqForceLoX, MagForceLox] = ...
    peakFreq(forceCorrected(:,2),FsForce,'low',FsRot/2);

[freqForceHiZ, MagForceHiZ] = ... 
    peakFreq(forceCorrected(:,1),FsForce,'high',FsRot/2);
[freqForceHiX, MagForceHiX] = ...
    peakFreq(forceCorrected(:,2),FsForce,'high',FsRot/2);





