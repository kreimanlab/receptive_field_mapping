addpath(genpath(pwd));

black = 0;
gray = 128;
white = 255;
trigger = Trigger();
%% experiment details
subjectName = 'subj01-cortex';

debug = 1;
if debug
    Screen('Preference', 'SkipSyncTests', 1);
    trigger = DummyTrigger();
end

%% advanced options
[~, ScrVars] = GenScreenSetup();
% grating
ScrWdCm = 70; %
DistToScrCm = 85; % 
gratingImageDegrees = 5;
Geo = GKlab_ScreenGeometry(ScrVars.winWidth, ScrWdCm, DistToScrCm);
gratingImage = createGratingImage(gratingImageDegrees, ...
    Geo.FovDegPerPix, gray, black);

monitorID = ScrVars.ScreenNumber;

images_per_sequence = 5;
images_per_score_sequence = 10;
sequences_per_block = 100;

% confirm experimental details
fprintf('*************************************************\n');
fprintf('PHYSIOLOGY_EXPERIMENT Identification-Occlusion\n');
fprintf('Experiment Start: %s\n', datestr(now));
fprintf('Monitor ID: %d\n', monitorID);
fprintf('*************************************************\n');

%% setup eyetracker
eyelink = ~debug;
if(eyelink)
    [eyelinkFile, success] = setupEyetracker(monitorID, subjectName);
    if ~success
        eyelink = false;
    end
else
    eyelinkFile = '';
end

%% run actual experiment
[eyelinkFile, eyelink] = runExperiment(trigger, ...
    'images_per_sequence', images_per_sequence, ...
    'images_per_score_sequence', images_per_score_sequence, ...
    'sequences_per_block', sequences_per_block, ...
    'grating_image', gratingImage, ...
    'subject_name', subjectName, ...
    'eyelink', eyelink, 'eyelink_file', eyelinkFile, ...
    'monitor_id', monitorID, ...
    'scr_vars', ScrVars, ...
    'debug_mode', debug);

% grab eyelink data
if eyelink
    c = clock;
    localEyelinkFile = getEyelinkFilepath('eyemovements_async_', ...
            subjectName);
    status = Eyelink('closefile');
    if status ~= 0
        fprintf('closefile error, status: %d', status);
    end
    Eyelink('ReceiveFile', eyelinkFile, localEyelinkFile);
    fprintf('Eyelink file received! You may quit now.\n');
end

Screen('Close');
