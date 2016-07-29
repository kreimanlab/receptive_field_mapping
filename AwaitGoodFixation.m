function [exp_params, hadToRecalibrate] = AwaitGoodFixation(exp_params, ...
    window, windowRect, ...
    fixationScreen, fixationSourceRect, fixationDestRect,...
    getKeyInput)
%AWAITGOODFIXATION wait for good fixation and recalibrate if necessary
goodFixation = false;
hadToRecalibrate = false;
while(~goodFixation)
    goodFixation = fixationPoint(window, fixationScreen, ...
        fixationSourceRect, fixationDestRect, ...
        exp_params.fixation_threshold, exp_params.fixation_time, ...
        exp_params.fixation_timeout);
    
    if ~goodFixation
        hadToRecalibrate = true;
        DrawCenteredText(window, ...
            {'Unable to detect fixation. Recalibrate [y/n]?'}, 0);
        Screen('flip', window);
        keyCode = getKeyInput();
        localEyelinkFile = getEyelinkFilepath(...
            'eyemovements_OcclusionQT_', exp_params.subject_name);
        c = clock;
        expEyelinkFile = [...
            exp_params.subject_name(end-2:end) ...
            num2str(mod(c(3), 10), '%0.1d') num2str(c(4), '%0.2d') ...
            num2str(c(5), '%0.2d') '.edf'];
        if(find(keyCode) == KbName('y')) % recalibrate if 'y' is entered
            status = Eyelink('closefile');
            if status ~= 0
                fprintf('closefile error, status: %d', status);
            end
            Eyelink('ReceiveFile', exp_params.eyelink_file, localEyelinkFile);
            exp_params.eyelink_file = expEyelinkFile;
            calibrateEyelink(window, windowRect, exp_params.eyelink_file);
        elseif find(keyCode) == KbName('x')
            % save existing eyelink data
            status = Eyelink('closefile');
            if status ~= 0
                fprintf('closefile error, status: %d', status);
            end
            Eyelink('ReceiveFile', exp_params.eyelink_file, ...
                localEyelinkFile);
            exp_params.eyelink_file = expEyelinkFile;
            
            % turn eyelink OFF
            exp_params.eyelink = 0;
            goodFixation = true;
        end
    end
end
end

function resultcode = fixationPoint(window, fixationScreen, ...
    fixationSourceRect, fixationDestRect, ...
    fixAccuracy, fixTime, timeout)
Screen('DrawTexture',window,fixationScreen, fixationSourceRect, fixationDestRect);
Screen('flip',window);
fixOnTime = GetSecs;
fixX = (fixationDestRect(1) + fixationDestRect(3)) / 2;
fixY = (fixationDestRect(2) + fixationDestRect(4)) / 2;

resultcode = 0;
firstGoodTime = -1;
lastGoodTime = -1;
while (GetSecs - fixOnTime < timeout) && (resultcode < 1)
    fsample = Eyelink('NewestFloatSample');
    if isstruct(fsample)
        gx = max(fsample.gx); %gaze position in pixels - I think whichever eye is not tracked is -32768, so this should pull out the useful position
        gy = max(fsample.gy);
        rx = fsample.rx; %pixels per degree
        ry = fsample.ry;
        fixError = sqrt(((fixX - gx)/rx)^2 + ((fixY - gy)/ry)^2);
        if fixError <= fixAccuracy
            lastGoodTime = GetSecs;
            if firstGoodTime == -1
                firstGoodTime = lastGoodTime;
            end
        else
            lastGoodTime = -1;
            firstGoodTime = -1;
        end
        if lastGoodTime - firstGoodTime > fixTime
            resultcode = 1;
        end
    elseif GetSecs - lastGoodTime > .05
        firstGoodTime = -1;
        lastGoodTime = -1;
    end
end
end
