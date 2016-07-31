function [eyelinkFile, beyelink] = runExperiment(trigger, varargin)
program_name = 'ReceptiveFieldMapping_Motion';
program_version = 2;

black = 0;
gray = 128;
white = 255;

exp_params.monitor_id = 1;
exp_params.debug_mode = 1;
exp_params.subject_name = '';
exp_params.scr_vars = [];

exp_params.session = 1;
exp_params.images_per_sequence = 5;
exp_params.images_per_score_sequence = 15;
exp_params.sequences_per_block = 10;
exp_params.background_color = gray;

% grating
exp_params.grating_image = [];
exp_params.grating_size = [-1, -1];
exp_params.num_motion_frames = 13;
exp_params.motion_timeout_seconds = 42 / 1000;
exp_params.motion_change_pixels = 2;
exp_params.motion_speed1 = 2;
exp_params.motion_speed2 = exp_params.motion_speed1 * 3;

% trigger
exp_params.trigger_duration = 0.02;
exp_params.trigger_interval = 0.1;
exp_params.num_triggers_experiment_start = 4;
exp_params.num_triggers_interrupt = 3;
exp_params.num_triggers_image_onoff = 1;

% soas
exp_params.grating_duration = 0.2; % seconds
exp_params.background_duration = 0.2; % seconds

% fixation/eyelink
exp_params.eyelink = 1;
exp_params.eyelink_file = '';
exp_params.fixation_threshold = 3; % radius in visual angle degrees around fixation point to count as fixation
exp_params.fixation_time = 0.5; % time in seconds fixation must be maintained before trial starts
exp_params.fixation_timeout = 5; % number of seconds to wait at fixation point before asking about recalibration
exp_params.fixation_size = 14;
exp_params.fixation_width = 2;
exp_params.fixation_color = black;
exp_params.fixation_odd_color = white;

% timing
exp_params.pause_after_message = 0.1;
exp_params.pause_inter_trials = 0.5;
exp_params.pause_before_message = 0.65;

% testing
exp_params.print_score = 0;


% keys
% note that we have to adjust all of our key codes to the computer in the
% lab which runs Mac OS with a Windows keyboard, so some of these might
% seem counter-intuitive.
exp_params.exit_keys = [27, 41]; % 'esc' for exiting the experiment
exp_params.isKBinput = 0; % use keyboard or gamepad input
exp_params.kb_keys = [37, 33, 80, 39, 34, 79];
exp_params.gp_keys = [5, 7, 1, 6, 8, 3];
exp_params.keys_responses = [0, 0, 0, 1, 1, 1];

exp_params.performanceMessages = {'Gamepad batteries low', 'Good', ...
    'Very good', 'Excellent', 'Outstanding'};

% ********** parse arguments **********
exp_params = parseArgs(exp_params, varargin{:});
if exp_params.isKBinput
    exp_params.r_keys = exp_params.kb_keys;
else
    exp_params.r_keys = exp_params.gp_keys;
end

% create directory
subjectDir = fullfile('subjects', exp_params.subject_name);
if ~exist(subjectDir, 'dir')
    fprintf('Creating subject directory: %s\n', subjectDir);
    mkdir(subjectDir);
else
    fprintf('Using existing subject directory %s\n', subjectDir);
end

% create session file name and log file name
sessionFile = sprintf('subjects/%s/%s_v%d_%s_sess%d_%s.mat', ...
    exp_params.subject_name, program_name, program_version, ...
    exp_params.subject_name, exp_params.session, ...
    datestr(datetime(), 'yyyy-mm-dd_HH-MM-SS'));
logFile = strrep(sessionFile, '.mat', '.log');
fprintf('Session file: %s\n', sessionFile);
fprintf('Starting diary: %s\n', logFile);
diary(logFile);


%% setup data
data = dataset();
data.recalibrated = false(0, 1);


% save presentation order to session file
save(sessionFile, 'data', 'exp_params');

exp_params.exp_start = datestr(now);

% start PsychToolbox
Screen('Screens'); % make sure all functions (SCREEN.mex) are in memory
if ~exp_params.debug_mode
    HideCursor; % Hide the mouse cursor
end
FlushEvents('keyDown');

% from now on everything is in a try-catch loop so that we can turn off
% the PsychToolbox screen and go back to Matlab command window
% in case of an error
try
    [window, windowRect] = Screen('OpenWindow', ...
        exp_params.monitor_id, exp_params.background_color);
    Priority(MaxPriority(window, 'WaitBlanking'));
    windowSize = windowRect(3:4);
    exp_params.fixation_position_x = windowSize(1) / 2;
    exp_params.fixation_position_y = windowSize(2) / 2;
    
    % grating
    gratingImage = exp_params.grating_image;
    
    % background texture
    backgroundMatrix = exp_params.background_color * ones(windowSize);
    backgroundScreen = Screen('maketexture', window, backgroundMatrix);
    
    % fixation measures
    fixationSourceRect = [0, 0, exp_params.fixation_size, exp_params.fixation_size];
    fixationDestRect = CenterRectOnPointd(fixationSourceRect, ...
        exp_params.fixation_position_x, ...
        exp_params.fixation_position_y);
    
    % Load screen
    Screen(window, 'TextFont', 'Geneva ');
    Screen(window, 'TextSize', 30);
    Screen('TextStyle', window, 1+2);
    DrawFormattedText(window, ...
        'Welcome. Please wait while we load stuff...', ...
        'center', 'center', black);
    Screen('flip', window);
    
    % trigger
    triggerDevice = trigger.initializeTrigger();
    
    % input parameters
    keyboards = GetKeyboardIndices;
    if exp_params.isKBinput
        exp_params.r_keys = exp_params.kb_keys;
        WaitForKey = @WaitForKeyKeyboard;
    else
        exp_params.r_keys = exp_params.gp_keys;
        devices = PsychHID('Devices');
        if ~ismember('GamePad', {devices.usageName})
            error('No GamePad found. Try restarting Matlab');
        end
        gamepad = devices(strcmp({devices.usageName}, 'GamePad'));
        WaitForKey = @(key, dur, exit) WaitForKeyGamepad(...
            key, gamepad, dur, exp_params.gp_keys, exit);
    end
    
    % start experiment
    if exp_params.eyelink
        Eyelink('message', 'EXP_START');
    end
    
    Screen('DrawTexture', window, backgroundScreen);
    Screen('flip', window);
    
    % setup blocks
    blockIndex = 1;
    imagesPerBlock = ...
        exp_params.images_per_sequence * exp_params.sequences_per_block;
    
    % show block 1
    Screen('flip', window);
    DrawFormattedText(window, ...
        sprintf('Block  %d\n\nPress any key to start', blockIndex), ...
        'center', 'center', black);
    Screen('flip', window);
    
    WaitSecs(exp_params.pause_after_message);
    WaitForKey(keyboards, 0, exp_params.exit_keys);
    
    %% trials
    trial = 0;
    trigger.sendTriggers(triggerDevice, ...
        exp_params.num_triggers_experiment_start, ...
        exp_params.trigger_duration, exp_params.trigger_interval);
    while true
        trial = trial + 1;
        warning('off', 'all'); % ignore default variables warning
        data.trial(trial, 1) = trial;
        warning('on', 'all'); % turn back on
        fprintf('Trial %d\n', trial);
        % fixation
        data.fixation_position_x(trial, 1) = exp_params.fixation_position_x;
        data.fixation_position_y(trial, 1) = exp_params.fixation_position_y;
        % grating
        data.grating_motion_direction(trial, 1) = randsample(4, 1);
        data.grating_motion_speed(trial, 1) = exp_params.motion_speed1 + ...
            (rand(1) > 0.5) * (exp_params.motion_speed2 - exp_params.motion_speed1);
        data.grating_position(trial, 1) = prod(windowSize) * rand(1);
        [data.grating_position_x(trial, 1), ...
            data.grating_position_y(trial, 1)] = ...
            ind2sub(windowSize, ...
            data.grating_position(trial));
        data.odd(trial, 1) = rand(1) < (1 / exp_params.images_per_score_sequence);
        
        %% fixation
        drawFixation = @() centerFixation(window, 3, ...
            exp_params.fixation_size, exp_params.fixation_color, ...
            exp_params.fixation_width);
        drawFixation();
        Screen('flip', window);
        data.recalibrated(trial, 1) = false;
        % check fixation only every images_per_sequence trials
        if mod(trial - 1, exp_params.images_per_sequence) == 0
            if exp_params.eyelink
                [exp_params, hadToRecalibrate] = AwaitGoodFixation(exp_params, ...
                    window, windowRect, drawFixation, ...
                    fixationDestRect, ...
                    curry(@WaitForKeyKeyboard, keyboards,0, exp_params.exit_keys));
                data.recalibrated(trial, 1) = hadToRecalibrate;
            else
                WaitSecs(exp_params.pause_inter_trials);
            end
        end
        
        %% present grating
        currentGratingImage = gratingImage;
        motionShift = [0, exp_params.motion_change_pixels];
        motionShift = motionShift * data.grating_motion_speed(trial);
        if mod(data.grating_motion_direction(trial), 2) == 0
            currentGratingImage = currentGratingImage';
            motionShift(:, [1, 2]) = motionShift(:, [2, 1]);
        end
        if ismember(data.grating_motion_direction(trial), [1, 4])
            motionShift = motionShift * -1;
        end
        
        sourceRect = [0, 0, size(gratingImage)];
        destRect = CenterRectOnPointd(sourceRect, ...
            data.grating_position_x(trial), ...
            data.grating_position_y(trial));
        lastFrameTime = GetSecs();
        for motionIter = 1:exp_params.num_motion_frames
            gratingTexture = Screen('MakeTexture', window, ...
                circshift(currentGratingImage, motionIter * motionShift));
            Screen('DrawTexture', window, gratingTexture, ...
                sourceRect, destRect);
            drawFixation();
            vblGratingStart = Screen('flip', window, ...
                lastFrameTime + exp_params.motion_timeout_seconds);
            lastFrameTime = vblGratingStart;
            if motionIter == 1 % first frame
                if exp_params.eyelink
                    Eyelink('message', sprintf('GRATING_%d ON', trial));
                end
                trigger.sendTriggers(triggerDevice, exp_params.num_triggers_image_onoff, ...
                    exp_params.trigger_duration, exp_params.trigger_interval);
                data.presentationStart(trial, 1) = vblGratingStart;
            end
        end
        
        %% show background for some duration, measure image vbl
        Screen('DrawTexture', window, backgroundScreen);
        centerFixation(window, 3, exp_params.fixation_size, ...
            data.odd(trial) * exp_params.fixation_odd_color, ...
            exp_params.fixation_width);
        vblBackgroundStart = Screen('flip', window, ...
            vblGratingStart + exp_params.grating_duration - 1 / 60 / 10);
        if exp_params.eyelink
            Eyelink('message', sprintf('GRATING_%d OFF', trial));
            Eyelink('message', sprintf('BACKGROUND_%d ON', trial));
        end
        trigger.sendTriggers(triggerDevice, exp_params.num_triggers_image_onoff, ...
            exp_params.trigger_duration, exp_params.trigger_interval);
        stimulusPresentationDuration = vblBackgroundStart - data.presentationStart(trial);
        if exp_params.debug_mode
            fprintf('Real SOA: %f\n', stimulusPresentationDuration);
        end
        data.presentationDuration(trial, 1) = stimulusPresentationDuration;
        data.backgroundPresentationStart(trial, 1) = vblBackgroundStart;
        % off
        vblBackgroundEnd = WaitSecs(exp_params.background_duration);
        if exp_params.eyelink
            Eyelink('message', sprintf('BACKGROUND_%d OFF', trial));
        end
        data.backgroundPresentationDuration(trial, 1) = ...
            vblBackgroundEnd - vblBackgroundStart;
        
        %% task
        if mod(trial, exp_params.images_per_score_sequence) == 0
            trigger.sendTriggers(triggerDevice, exp_params.num_triggers_interrupt, ...
                exp_params.trigger_duration, exp_params.trigger_interval);
            DrawCenteredText(window, {'Did the cross color change?'}, black);
            DrawCenteredText(window, {'No'}, black, -300);
            DrawCenteredText(window, {'Yes'}, black, +300);
            choiceStart = Screen('flip', window);
            data.choicePresentationStart(trial, 1) = choiceStart;
            
            [keyCode, keyTime] = WaitForKey(keyboards, 0, exp_params.exit_keys);
            assert(~isempty(keyCode) && any(exp_params.r_keys == find(keyCode)));
            data.reactionTime(trial, 1) = ...
                keyTime - data.choicePresentationStart(trial);
            data.responseKey(trial, 1) = find(keyCode);
            data.response(trial, 1) = exp_params.keys_responses(find(...
                exp_params.r_keys == data.responseKey(trial), ...
                1, 'first'));
            assert(~isnan(data.response(trial)));
            
            data.truth(trial, 1) = any(any(data.odd(trial - ...
                exp_params.images_per_score_sequence + 1:trial, :)));
            data.correct(trial, 1) = ...
                data.response(trial) == data.truth(trial);
        else
            data.choicePresentationStart(trial, 1) = NaN(1);
            data.reactionTime(trial, 1) = NaN(1);
            data.responseKey(trial, 1) = NaN(1);
            data.response(trial, 1) = NaN(1);
            data.truth(trial, 1) = NaN(1);
            data.correct(trial, 1) = NaN(1);
        end
        
        % block done?
        if(mod(trial, imagesPerBlock) == 0)
            Screen('DrawTexture', window, backgroundScreen);
            Screen('flip', window);
            trigger.sendTriggers(triggerDevice, exp_params.num_triggers_interrupt, ...
                exp_params.trigger_duration, exp_params.trigger_interval);
            
            fprintf('Saving data to %s...\n', sessionFile);
            save(sessionFile, 'data', '-append');
            
            taskTrials = ~isnan(data.truth) & ismember(data.trial, ...
                trial - imagesPerBlock + 1:trial);
            performance = sum(data.correct(taskTrials)) / sum(taskTrials);
            drawScoreScreen(window, blockIndex, performance, ...
                exp_params.performanceMessages, black);
            WaitForKey(keyboards, 0, exp_params.exit_keys);
            
            % next block
            blockIndex = blockIndex + 1;
            Screen('DrawTexture', window, backgroundScreen);
            Screen('flip', window);
            DrawFormattedText(window, ...
                ['Block  ' num2str(blockIndex)], ...
                'center', 'center', black);
            Screen('flip', window);
            WaitSecs(1);
            
            WaitForKey(keyboards, 0, exp_params.exit_keys);
        end
    end
    
    %% exit
    save(sessionFile, 'data', '-append');
    
    % save last eyelink file name (if recalibration occured)
    eyelinkFile = exp_params.eyelink_file;
    if exp_params.eyelink
        Eyelink('message', 'EXPERIMENT_END');
    end
    
    % show goodbye screen
    DrawFormattedText(window, 'Complete! Press any key to exit', ...
        'center', 'center', black);
    Screen('flip', window);
    WaitSecs(0.5);
    WaitForKey(keyboards, 0, exp_params.exit_keys);
    
catch err
    disp(getReport(err, 'extended'));
    
    if exp_params.eyelink
        localEyelinkFile = getEyelinkFilepath('eyemovements_async_', ...
            exp_params.subject_name);
        status = Eyelink('closefile');
        if status ~= 0
            fsprintf('closefile error, status: %d', status);
        end
        Eyelink('ReceiveFile', exp_params.eyelink_file, localEyelinkFile);
    end
    
    Screen('CloseAll');
    clear Screen;
    ShowCursor;
    fprintf('Saving data to %s...\n', sessionFile);
    save(sessionFile, 'data', '-append');
    rethrow(err);
end
beyelink = exp_params.eyelink;
ShowCursor;
Screen('CloseAll');
end

function [b, keyTime] = WaitForKeyGamepad(...
    keyboards, gamepad, duration, acceptedKeys, exitKeys)
startTime = GetSecs();
elements = PsychHID('Elements', gamepad.index);
idx = find([elements.usagePageValue] == 9);
n = length(idx);
b = zeros(1,n);

while ~any(b) && (GetSecs() - startTime < duration || duration == 0)
    [~, ~, keyCode] = KbCheck(keyboards(1));
    i = 1;
    while (~any(b) && i <= n)
        b(i) = PsychHID('RawState', gamepad.index, idx(i));
        if b(i) && ~any(i == acceptedKeys)
            % key pressed but not valid -> ignore
            b(i) = 0;
        end
        i = i + 1;
    end
    if any(keyCode(exitKeys))
        error('Exit key pressed!');
    end
end

if ~any(b)
    b = [];
end

if GetSecs() - startTime < duration
    WaitSecs(startTime + duration - GetSecs());
end
keyTime = GetSecs();
end

function [keyCode, keyTime] = WaitForKeyKeyboard(...
    keyboards, duration, exit_keys)
keyCode = [];
keyTime = [];
startTime = GetSecs();
b = 0;
while ~b && (GetSecs() - startTime < duration || duration == 0)
    [key_down, keyTime, keyCode] = KbCheck(keyboards(1));
    if any(key_down)
        b = 1;
    end
    if any(keyCode(exit_keys))
        error('Exit key pressed!');
    end
end
if GetSecs() - startTime < duration
    WaitSecs(startTime + duration - GetSecs());
end
end
