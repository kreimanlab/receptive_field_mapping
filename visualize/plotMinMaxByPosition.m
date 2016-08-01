function plotMinMaxByPosition(data, figurePrefix)
if ~exist('figurePrefix', 'var')
    figurePrefix = '';
end
channels = unique(data.mappedChannel);
trials = unique(data.trial)';

oldScreenResolution = [1920, 1080];
scaledScreenResolution = [1000, 600];
gratingPlotSize = 20;

Xpos = round(data.grating_position_x * ...
    scaledScreenResolution(1) / oldScreenResolution(1));
Ypos = round(data.grating_position_y * ...
    scaledScreenResolution(2) / oldScreenResolution(2));
Ypos = scaledScreenResolution(2) - Ypos;

% plotting
figures = NaN(numel(channels), 1);
for channelIter = 1:numel(channels)
    channel = channels{channelIter};
    activations = zeros(scaledScreenResolution(2:1));
    for trial = trials
        dataIndex = strcmp(data.mappedChannel, channel) & ...
            data.trial == trial;
        currentData = data(dataIndex, :);
        minMax = max(currentData.responseVoltages) - ...
            min(currentData.responseVoltages);
        y = max(1, Ypos(dataIndex) - gratingPlotSize / 2 + 1):...
            min(scaledScreenResolution(2), Ypos(dataIndex) + gratingPlotSize / 2);
        x = max(1, Xpos(dataIndex) - gratingPlotSize / 2 + 1):...
            min(scaledScreenResolution(1), Xpos(dataIndex) + gratingPlotSize / 2);
        activations(y, x) = ...
            repmat(minMax, [numel(y), numel(x)]);
    end
    figures(channelIter) = figure('Name', ...
        sprintf('%sChannel %s - Trial %d', figurePrefix, channel, trial));
    imagesc(activations);
    colormap('gray');
    colorbar;
end
saveDir = [fileparts(mfilename('fullpath')), ...
    '/../figures/channel_positions'];
saveFigures(figures, saveDir, true);
end
