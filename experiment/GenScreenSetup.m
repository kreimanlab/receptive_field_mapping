function [win,ScrVars] = GenScreenSetup(BG,Res)

% Based on mlScreenSetup
% 
% Function to set up all the usual screen values that Mark Lescroart uses:
% Inputs: 
%   BackGround - default [128 128 128]
%       Text size = 18
%       Text font = Arial
%       Background = [128 128 128] (gray)
% 

% Inputs: 
if ~exist('BG','var')
    ScrVars.BG = [128 128 128];
else
    ScrVars.BG = BG;
end
AssertOpenGL;

WarnStr = '\n\n\nmlScreenSetup currently has anti-aliasing turned on. This may decrease performance! \nPlease check code timing before proceeding with experiments!\n\n\n';
warning([mfilename ':Anti-Alias Warning'],WarnStr)

%%% Get screen number
ScrVars.ScreenNumber = max(Screen('Screens'));
try
    if exist('Res','var')
        Screen('Resolution', ScrVars.ScreenNumber, Res(1), Res(2));
    end
    
    ExtraParams = Screen('Resolution', ScrVars.ScreenNumber);
    if (ExtraParams.width~=Res(1) || ExtraParams.height~=Res(2)) 
        ScrVars.Xdimensions(1) = ExtraParams.height;
        ScrVars.Xdimensions(2) = ExtraParams.width;
        ScrVars.XframeRate     = ExtraParams.hz;
        beep;
        warning('DisplayError:DisplaySizeChangeFail','Failed to set indicated resolution.');
        display('Saving current resolution to display structure (ScrVars)...');
        pause(.5);
    else
        display('Resolution and refresh rate successfully set.');
    end
catch
    ExtraParams = Screen('Resolution',ScrVars.ScreenNumber);
    ScrVars.Xdimensions(1) = ExtraParams.height;
    ScrVars.Xdimensions(2) = ExtraParams.width;
    ScrVars.XframeRate     = ExtraParams.hz;
    beep;
    pause(.5);
    warning('DisplayError:DisplaySizeChangeFail','Error occurred in Screen(''Resolution'') call.\n\tMay have failed to set indicated resolution and refresh rate.');
    display('Saving current resolution and refresh rate to display structure...');
end
% Open full screen for experiment: 
% Usage: [Window,Rect] = Screen('OpenWindow',windowPtrOrScreenNumber [,color] [,rect][,pixelSize][,numberOfBuffers][,stereomode][,multisample][,imagingmode]);
[win, ScrVars.winRect] = Screen('OpenWindow',ScrVars.ScreenNumber, ScrVars.BG,[],32,2,[],6);

%%% Getting inter-flip interval (ifi):
Priority(MaxPriority(win));
ScrVars.ifi = Screen('GetFlipInterval', win, 20);
Priority(0);

Screen('TextFont', win, 'Arial');
Screen('TextSize', win, 18);

%%% Establishing generally useful screen value variables in a struct array:
ScrVars.x_min = ScrVars.winRect(1);
ScrVars.x_max = ScrVars.winRect(3);
ScrVars.y_min = ScrVars.winRect(2);
ScrVars.y_max = ScrVars.winRect(4);

ScrVars.AspectRatio = ScrVars.x_max/ScrVars.y_max;
ScrVars.winWidth = ScrVars.x_max-ScrVars.x_min;
ScrVars.winHeight = ScrVars.y_max-ScrVars.y_min;
ScrVars.x_center = ScrVars.winWidth/2;
ScrVars.y_center = ScrVars.winHeight/2;

ScrVars.FixRect = [0 0 10 10];
ScrVars.FixRectBig = [0 0 12 12];
ScrVars.Fixation = CenterRectOnPoint (ScrVars.FixRect, ScrVars.x_center, ScrVars.y_center);
ScrVars.FixationBig = CenterRectOnPoint (ScrVars.FixRectBig, ScrVars.x_center, ScrVars.y_center);

Screen('CloseAll');
WaitSecs(1);