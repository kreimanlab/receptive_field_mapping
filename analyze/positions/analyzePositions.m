function data = analyzePositions(data, screenSize)
width = screenSize(1); height = screenSize(2);
centerX = width / 2;
centerY = height / 2;

data.quadrant = repmat({''}, size(data, 1), 1);
% Top Left
topLeft = ...
    data.grating_position_x < centerX & ...
    data.grating_position_y < centerY;
data.quadrant(topLeft) = repmat({'Top Left'}, sum(topLeft), 1);
% Top Right
topRight = ...
    data.grating_position_x >= centerX & ...
    data.grating_position_y < centerY;
data.quadrant(topRight) = repmat({'Top Right'}, sum(topRight), 1);
% Bottom Left
bottomLeft = ...
    data.grating_position_x < centerX & ...
    data.grating_position_y >= centerY;
data.quadrant(bottomLeft) = repmat({'Bottom Left'}, sum(bottomLeft), 1);
% Bottom Right
bottomRight = ...
    data.grating_position_x >= centerX & ...
    data.grating_position_y >= centerY;
data.quadrant(bottomRight) = repmat({'Bottom Right'}, sum(bottomRight), 1);

assert(~any(isempty(data.quadrant)));
end
