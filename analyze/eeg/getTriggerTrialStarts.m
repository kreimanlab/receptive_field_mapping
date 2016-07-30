function [trialStarts, numInterruptions] = getTriggerTrialStarts(triggerSignal, ...
    threshold, quickSuccessionMaxDistance)
triggers = getTriggerStarts(triggerSignal, threshold);

% distances between trigger and previous trigger
distance = arrayfun(@(i) triggers(i) - triggers(i - 1), 2:numel(triggers));
distance = prepend(Inf, distance);
quickSuccessions = distance < quickSuccessionMaxDistance;

% find trials
trialStarts = cell(0);
state = EegExperimentState.NOT_STARTED;
numInterruptions = 0;
trial = 0;
i = 1;
while i < numel(triggers)
    if state == EegExperimentState.NOT_STARTED % experiment start
        assert(all(quickSuccessions(i + 1:i + 1 + 2))); % 4 triggers = 3 succ
        state = EegExperimentState.INTERRUPTED;
        i = i + 4;
    elseif i < numel(quickSuccessions) && quickSuccessions(i + 1) % interruption
        assert(all(quickSuccessions(i + 1:i + 1 + 1))); % 3 triggers = 2 succ
        state = EegExperimentState.INTERRUPTED;
        i = i + 3;
        numInterruptions = numInterruptions + 1;
    else % stimuli
        switch state
            case EegExperimentState.STIMULI_ON
                state = EegExperimentState.STIMULI_OFF;
            case {EegExperimentState.STIMULI_OFF, ...
                    EegExperimentState.INTERRUPTED}
                trial = trial + 1;
                state = EegExperimentState.STIMULI_ON;
                trialStarts{trial} = triggers(i);
            otherwise
                error('Invalid state %s', state);
        end
        i = i + 1;
    end
end
trialStarts = cell2mat(trialStarts);
end

function startRows = getTriggerStarts(trigger, threshold)
triggerActive = trigger > threshold;
triggerStart = diff(triggerActive) == 1; % 2:end
triggerStart = prepend(triggerActive(1), triggerStart);
assert(isequal(size(triggerStart), size(trigger)));
startRows = find(triggerStart);
end

function a = prepend(e, a)
if isrow(a) % single row, i.e. column
    a = [e, a];
else
    a = [e; a];
end
end
