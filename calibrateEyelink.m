function result = calibrateEyelink(window, screenRect, edfFile)

try
   Eyelink('Shutdown')
end

el=EyelinkInitDefaults(window);
% Disable key output to Matlab window:
%ListenChar(2);

% STEP 3
% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if ~EyelinkInit(0, 1)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    return;
end

[v vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

Eyelink('command', 'calibration_type = HV9');

% set the eyetracker commands
Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', screenRect(1),screenRect(2),screenRect(3)-1,screenRect(4)-1);
	
Eyelink('Message', 'DISPLAY_COORDS %d %d %d %d', screenRect(1),screenRect(2),screenRect(3)-1,screenRect(4)-1);

Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
	
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,BUTTON');

% make sure that we get gaze data from the Eyelink
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

% open file to record data to
Eyelink('Openfile', edfFile);

% STEP 4
% Calibrate the eye tracker
result = EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
EyelinkDoDriftCorrection(el);

% STEP 5
% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('Message', 'DISPLAY_ON');	% message for RT recording in analysis
Eyelink('Message', 'SYNCTIME');

fprintf('Eyelink set up complete...\n');
end