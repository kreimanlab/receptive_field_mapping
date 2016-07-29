black = 0;
gray = 128;
white = 255;
%% experiment details
subjectName = 'subj01-cortex';

debug = 1;
if debug
    Screen('Preference', 'SkipSyncTests', 1);
end

%% advanced options
ScrWdCm = 36; %
DistToScrCm = 53.34; % 
[monitorID, ScrVars] = GenScreenSetup;
Geo = GKlab_ScreenGeometry(ScrVars.winWidth, ScrWdCm, DistToScrCm);
images_per_sequence = 5;
images_per_score_sequence = 15;
sequences_per_block = 150;
gratingImageDegrees = 3;

% create grating
gratingImage = createGratingImage(gratingImageDegrees, Geo.FovDegPerPix, ...
    gray, black);

% confirm experimental details
fprintf('*************************************************\n');
fprintf('PHYSIOLOGY_EXPERIMENT Identification-Occlusion\n');
fprintf('Experiment Start: %s\n', datestr(now));
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
[eyelinkFile, eyelink] = runExperiment(...
    'grating_image', gratingImage, ...
    'images_per_sequence', images_per_sequence, ...
    'images_per_score_sequence', images_per_score_sequence, ...
    'sequences_per_block', sequences_per_block, ...
    'subject_name', subjectName, ...
    'eyelink', eyelink, 'eyelink_file', eyelinkFile, ...
    'monitor_ID', monitorID, 'debug_mode', debug);

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
