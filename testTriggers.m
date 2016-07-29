function idx=testTriggers(trigger_on)


exit_key=41;
test_triggers=1;
trigger_duration=0.06;
trigger_interval=0.03;
WaitSecs(1)
keyboards=GetKeyboardIndices;


% ********** initialize trigger device **********
if (trigger_on)
    % initialize PMD1208FS
    device=initPMD1208FS;
    if isnumeric(device) && device<0
        error('Trigger device not found');
    else
        device=device.index;
        err=DaqDConfigPort(device,0,0); % port = 0 direction = 0
        FastDaqDout=inline('PsychHID(''SetReport'', device, 2, hex2dec(''04''), uint8([0 port data]))','device', 'port', 'data');
    end
    di = DaqDeviceIndex;
    DaqDConfigPort(di,0,0);
    DaqDOut(di,0,0);
end
disp(' ')
disp('Testing triggers; press any key to continue to the experiment or Esc to quit')

idx=[];

while isempty(idx)

    if trigger_on
        send_triggers(di,test_triggers,trigger_duration,trigger_interval);  % block end triggers
    end

    [key_code]=WaitForKey(keyboards,trigger_interval,exit_key);

    idx=find(key_code);
end

end

% -- end main function --

function key_code=WaitForKey(keyboards,duration,exit_key)

start_time=GetSecs();
b=0;

while ~b && (GetSecs()-start_time<duration || duration==0)
    [key_down,secs,key_code]=KbCheck(keyboards(1));
    [x,y,button]=GetMouse;
    if any([button key_down])
        b=1;
    end
    if key_code(exit_key)==1
        error('Exit key pressed!');
    end
end

if GetSecs()-start_time<duration
    WaitSecs(start_time+duration-GetSecs());
end

end
% -- end of function --

function send_triggers(device,n_triggers,trigger_duration,trigger_interval)

for i=1:n_triggers
    DaqDOut(device,0,1);
    WaitSecs(trigger_duration);
    DaqDOut(device,0,0);
    if i<n_triggers
        WaitSecs(trigger_interval-trigger_duration);
    end
end

end
% -- end of function --
