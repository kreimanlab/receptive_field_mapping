function d=initPMD1208FS();

% initPMD1208FS
% usage:
% d=initPMD1208FS
% 
% last modified: Itamar Khan / Hesehng Liu

daq=DaqDeviceIndex;
switch length(daq)
    case 0,
        fprintf('Sorry. Couldn''t find a PMD-1208FS box connected to your computer.\n');
        d = -1;
        return;
    case 1,
        fprintf('Yay. You have a PMD-1208FS daq: \n');
    case 2,
        fprintf('Yay. You have two PMD-1208FS daqs: \n');
    otherwise,
        fprintf('Yay. You have %d PMD-1208FS daqs: \n',length(daq));
end
devices=PsychHID('Devices');
for i=1:length(daq)
    d=devices(daq(i));
    fprintf('device %d, serialNumber %s\n',d.index,d.serialNumber);
end
