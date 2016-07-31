classdef DummyTrigger    
    methods
        function deviceIndex = initializeTrigger(~)
            fprintf('Initializing DummyTrigger\n');
            deviceIndex = -1;
        end

        function sendTriggers(~, deviceIndex, numTriggers, ...
                trigger_duration, trigger_interval)
            fprintf('Sending %d triggers on device %d with duration %d and interval %d\n', ...
                numTriggers, deviceIndex, trigger_duration, trigger_interval);
        end
    end
end

