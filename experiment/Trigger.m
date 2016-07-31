classdef Trigger
    methods
        function deviceIndex = initializeTrigger(~)
            % initialize PMD1208FS
            device=initPMD1208FS;
            if isnumeric(device) && device<0
                error('Trigger device not found');
            else
                device=device.index;
                err=DaqDConfigPort(device,0,0); % port = 0 direction = 0
                FastDaqDout=inline('PsychHID(''SetReport'', device, 2, hex2dec(''04''), uint8([0 port data]))','device', 'port', 'data');
            end
            deviceIndex = DaqDeviceIndex;
            DaqDConfigPort(deviceIndex,0,0);
            DaqDOut(deviceIndex,0,0);
        end

        function sendTriggers(~, deviceIndex, numTriggers, ...
                trigger_duration, trigger_interval)
            for i=1:numTriggers
                DaqDOut(deviceIndex,0,1);
                WaitSecs(trigger_duration);
                DaqDOut(deviceIndex,0,0);
                if i<numTriggers
                    WaitSecs(trigger_interval-trigger_duration);
                end
            end
        end
    end
end

