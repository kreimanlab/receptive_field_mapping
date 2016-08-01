function data = analyzeEyetracking(file, expectedNumTrials)

% data
trialNum = -1;
eyeState = EyeState.NONE;
experimentState = EyetrackingExperimentState.NONE;

% read
fid = fopen(file);
assert(fid > 0);
line = fgetl(fid);
trial = NaN(expectedNumTrials, 1);
fixated = NaN(expectedNumTrials, 1);
while ischar(line)
    eyeState = checkState(line, eyeState);
    [trialNum, experimentState] = checkImage(line, trialNum, experimentState);
    assert(trialNum <= expectedNumTrials);
    if experimentState == EyetrackingExperimentState.GRATING
        fixatedSoFar = isnan(fixated(trialNum)) || fixated(trialNum);
        trial(trialNum, 1) = trialNum;
        fixated(trialNum, 1) = fixatedSoFar && ...
            eyeState == EyeState.FIXATION;
    end
    line = fgetl(fid);
end
assert(~any(isnan(trial)) && ~any(isnan(fixated)));
fixated = logical(fixated);
data = table(trial, fixated);
fclose(fid);
end

function eyeState = checkState(line, eyeState)
saccadeStart = '^SSACC [LR]';
saccadeEnd = '^ESACC [LR]';
fixationStart = '^SFIX [LR]';
fixationEnd = '^EFIX [LR]';
if regexp(line, fixationStart)
    assert(eyeState == EyeState.NONE);
    eyeState = EyeState.FIXATION;
elseif regexp(line, fixationEnd)
    assert(eyeState == EyeState.FIXATION);
    eyeState = EyeState.NONE;
elseif regexp(line, saccadeStart)
    assert(eyeState == EyeState.NONE);
    eyeState = EyeState.SACCADE;
elseif regexp(line, saccadeEnd)
    assert(eyeState == EyeState.SACCADE);
    eyeState = EyeState.NONE;
end
end

function [id, experimentState] = ...
    checkImage(line, currentId, experimentState)
start = '^MSG.*EXP_START$';
pattern = '^MSG.*(GRATING|BACKGROUND)_([0-9]+) (ON|OFF)';

if regexp(line, start)
    assert(currentId < 1);
    id = 0;
else
    tokens = regexp(line, pattern, 'tokens');
    if isempty(tokens)
        id = currentId;
        return;
    end
    imageType = tokens{1}{1};
    id = str2num(tokens{1}{2});
    status = tokens{1}{3};
    if strcmp(status, 'ON')
        switch imageType
            case 'GRATING'
                assert(experimentState == EyetrackingExperimentState.NONE);
                assert(id == currentId + 1);
                experimentState = EyetrackingExperimentState.GRATING;
            case 'BACKGROUND'
                assert(experimentState == EyetrackingExperimentState.NONE);
                assert(id == currentId); % same as grating
                experimentState = EyetrackingExperimentState.BACKGROUND;
            otherwise
                error('unknown imageType %s', imageType);
        end
    elseif strcmp(status, 'OFF')
        switch imageType
            case 'GRATING'
                assert(experimentState == EyetrackingExperimentState.GRATING);
                assert(id == currentId);
                experimentState = EyetrackingExperimentState.NONE;
            case 'BACKGROUND'
                assert(experimentState == EyetrackingExperimentState.BACKGROUND);
                assert(id == currentId);
                experimentState = EyetrackingExperimentState.NONE;
            otherwise
                error('unknown imageType %s', imageType);
        end
    else
        error('invalid status %s', status);
    end
end
end
