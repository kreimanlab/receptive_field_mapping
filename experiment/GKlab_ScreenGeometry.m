function [Geo] = GKlab_ScreenGeometry (ScrWdPix, ScrWdCm, DistToScrCm)

% General screen considerations: 

% Scanner Projection System Measurements:
HalfScrWdCm = ScrWdCm/2;

% Screen Size (Scanner Projector) in Pixels:
% ScrWdPix = 1920; %1024
HalfScrWdPix = ScrWdPix/2;

CmPerPix = ScrWdCm/ScrWdPix; % = .035
DistToScrPix = ceil(DistToScrCm/CmPerPix); % = 2429

% For the Pixs nearest to the Fov: 
PixFromFov = 1;

Geo.FovDegPerPix = atand(PixFromFov/DistToScrPix);
Geo.FovPixPerDeg = Geo.FovDegPerPix^(-1);

% For the Pixs nearest to the Scr's edge:
PixNearPeriph1 = HalfScrWdPix-1;
PixNearPeriph2 = HalfScrWdPix;

Geo.PeriphDegPerPix = atand(PixNearPeriph2/DistToScrPix) - atand(PixNearPeriph1/DistToScrPix);
Geo.PeriphPixPerDeg = Geo.PeriphDegPerPix^(-1);

Geo.GenPixPerDeg = pi * ScrWdPix / atan(ScrWdCm/DistToScrCm/2) / 360; % slightly different.