function centerFixation(w, pattern, sz, color, lineWidth)

% Usage: centerFixation (windowPtr, patternOrStr, fixationOrTextSize, color, lineWidth)
% 
% Draws a fixation point or text in the center of the screen.
% 
% Inputs: Pattern - If pattern is a string, it will be displayed.
%                   Otherwise:
%                   1 - circle
%                   2 - square
%                   3 - + (default)
%                   4 - x
%         fixationOrTextSize - figure it out
%         color - index of CLUT, scalar or triplet.
%         lineWidth - use only if pattern is 3 or 4
% 
% Created by XRL, 09/01/2005

if (nargin<1)
    windowPtrs=Screen('Windows');
    if isempty(windowPtrs) | (Screen('WindowKind',windowPtrs(1)) ~=1); % is not onscreen
        w =Screen('OpenWindow',1,0);
    else, error('On screen window not found');
    end
end
if (nargin<2); pattern=3; end
if (nargin<3); sz=12; end
if (nargin<4); color=Screen('TextColor',w); end
if (nargin<5); lineWidth=1; end
rect =Screen('Rect',w);
if ischar(pattern)
    if (nargin<3), sz=Screen('TextSize',w); end
    oldSize=Screen('TextSize',w,sz);
    xx = round(rect(3)/2-RectWidth(Screen('TextBounds',w,pattern))/2);
    yy = round(rect(4)/2-sz*0.71);
    Screen('DrawText',w,pattern,xx,yy, color);
    Screen('TextSize',w,oldSize);
    return;
end

xc = rect(3)/2; yc = rect(4)/2; 
rect=CenterRect([xc-sz/2 yc-sz/2 xc+sz/2 yc+sz/2], rect);
switch pattern
    case 1      %circle
        Screen('FillOval', w,color, rect);
    case 2     % square
        Screen('FillRect',w, color, rect);
    case 3     % +
        sz=floor((sz+mod(lineWidth+sz,2))/2);% for symmetry when using small fixation
%         s01=mod(lineWidth,2); ss01=mod(lineWidth+1,2); 
        Screen('DrawLine',w, color, xc-sz, yc, xc+sz, yc, lineWidth);
        Screen('DrawLine',w, color, xc, yc-sz, xc, yc+sz, lineWidth);
%         Screen('DrawLine',w, color, xc-sz-ss01, yc, xc+sz+s01, yc, lineWidth);
%         Screen('DrawLine',w, color, xc, yc-sz-ss01, xc, yc+sz+s01, lineWidth);
    case 4     % x
%         sz=sz/2; 
        sz=floor((sz+mod(lineWidth+sz,2))/2/1.4);% for symmetry when using small fixation
        Screen('DrawLine',w, color, xc-sz, yc-sz, xc+sz, yc+sz, lineWidth*1.4);
        Screen('DrawLine',w, color, xc-sz, yc+sz, xc+sz, yc-sz, lineWidth*1.4);
end
