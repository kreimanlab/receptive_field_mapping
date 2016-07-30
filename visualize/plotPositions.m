function plotPositions(data, screenSize)
colorWheel = [...
    1, 0, 0; ...
    0, 1, 0; ...
    0, 0, 1; ...
    1, 1, 0];
texts = {'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right'};
assert(size(colorWheel, 1) == numel(texts));

colors = NaN(size(data, 1), 3);
indices = cell(size(data, 1), 1);
for i = 1:numel(texts)
    indices{i} = strcmp(data.quadrant, texts{i});
    colors(indices{i}, :) = repmat(colorWheel(i, :), sum(indices{i}), 1);
end
scatter(data.grating_position_x, ...
    screenSize(2) - data.grating_position_y, ...
    100, colors);
hold on;
text(data.grating_position_x, ...
    screenSize(2) - data.grating_position_y, ...
    num2str(data.trial), 'Color', [0.7, 0.7, 0.7]);
for i = 1:numel(texts)
    text(mean(data.grating_position_x(indices{i})), ...
        mean(screenSize(2) - data.grating_position_y(indices{i})), ...
        {texts{i}, sprintf('(%d points)', sum(indices{i}))});
end
hold off;
end
