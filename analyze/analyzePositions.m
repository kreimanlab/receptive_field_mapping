function data = analyzePositions(data, screenSize)
width = screenSize(1); height = screenSize(2);
centerX = width / 2;
centerY = height / 2;

data.quadrant = repmat({''}, size(data, 1), 1);
% Bottom Left
topLeft = ...
    data.grating_position_x < centerX & ...
    data.grating_position_y < centerY;
data.quadrant(topLeft) = repmat({'Bottom Left'}, sum(topLeft), 1);
% Bottom Right
topRight = ...
    data.grating_position_x >= centerX & ...
    data.grating_position_y < centerY;
data.quadrant(topRight) = repmat({'Bottom Right'}, sum(topRight), 1);
% Top Left
bottomLeft = ...
    data.grating_position_x < centerX & ...
    data.grating_position_y >= centerY;
data.quadrant(bottomLeft) = repmat({'Top Left'}, sum(bottomLeft), 1);
% Top Right
bottomRight = ...
    data.grating_position_x >= centerX & ...
    data.grating_position_y >= centerY;
data.quadrant(bottomRight) = repmat({'Top Right'}, sum(bottomRight), 1);

assert(~any(isempty(data.quadrant)));
end
