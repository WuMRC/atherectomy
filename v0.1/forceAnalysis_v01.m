% ROI = 3491:27000;
force = data2(:,2);
nPoints = length(force);
NFFT = 2^nextpow2(nPoints); % Next power of 2 from length of y
Y = fft (force,NFFT)/nPoints;
Fs = 1000;
f = Fs/2*linspace(0,1,NFFT/2+1);

time = (1:nPoints)./Fs;

figure(1), plot(time, force)
figure(2), plot(f,2*abs(Y(1:NFFT/2+1)))


%%
lowFreq = smooth(force, 125);

nPoints = length(lowFreq);
NFFT = 2^nextpow2(nPoints); % Next power of 2 from length of y
Y = fft (lowFreq,NFFT)/nPoints;
Fs = 1000;
f = Fs/2*linspace(0,1,NFFT/2+1);

time = (1:nPoints)./Fs;

figure(1), plot(time, lowFreq)
figure(2), plot(f,2*abs(Y(1:NFFT/2+1)))

%%

% %%
dataHiFreq = force-lowFreq;

figure(2),plot(dataHiFreq)

%%
nPoints = length(dataHiFreq);
NFFT = 2^nextpow2(nPoints); % Next power of 2 from length of y
Y = fft (dataHiFreq,NFFT)/nPoints;
f = 1000/2*linspace(0,1,NFFT/2+1);

figure(1), plot(time, dataHiFreq)
figure(2), plot(f,2*abs(Y(1:NFFT/2+1)))


