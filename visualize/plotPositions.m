function plotPositions(data)
colors = NaN(size(data, 1), 3);
indices = strcmp(data.quadrant, 'Top Left');
colors(indices, :) = repmat([1, 0, 0], sum(indices), 1);
text(mean(data.grating_position_x(indices)), ...
    mean(data.grating_position_y(indices)), 'Top Left');
hold on;

indices = strcmp(data.quadrant, 'Top Right');
colors(indices, :) = repmat([0, 1, 0], sum(indices), 1);
text(mean(data.grating_position_x(indices)), ...
    mean(data.grating_position_y(indices)), 'Top Right');

indices = strcmp(data.quadrant, 'Bottom Left');
colors(indices, :) = repmat([0, 0, 1], sum(indices), 1);
text(mean(data.grating_position_x(indices)), ...
    mean(data.grating_position_y(indices)), 'Bottom Left');

indices = strcmp(data.quadrant, 'Bottom Right');
colors(indices, :) = repmat([1, 1, 0], sum(indices), 1);
text(mean(data.grating_position_x(indices)), ...
    mean(data.grating_position_y(indices)), 'Bottom Right');

scatter(data.grating_position_x, data.grating_position_y, 10, colors);
hold off;
end
