function drawScoreScreen(window, blockIndex, ...
    performance, performanceMessages, color)
if performance > 0.9
    markstr = performanceMessages{5};
elseif performance > 0.8
    markstr = performanceMessages{4};
elseif performance > 0.7
    markstr = performanceMessages{3};
elseif performance > 0.6
    markstr = performanceMessages{2};
else
    markstr = performanceMessages{1};
end
fprintf('%s\n', markstr);
DrawCenteredText(window, ...
    {['Block ', num2str(blockIndex) ':  ', markstr]}, color);
Screen('flip',window);
WaitSecs(1);
end

