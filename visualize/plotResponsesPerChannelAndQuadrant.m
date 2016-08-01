function fig = plotResponsesPerChannelAndQuadrant(data, ...
    channels, figureName)
if ~exist('channels', 'var')
    channels = unique(data.mappedChannel);
end
assert(~isempty(channels));
if ~exist('figureName', 'var')
    figureName = sprintf('%d Electrodes - all quadrants', numel(channels));
end
% use only data where fixated
data.fixated = logical(data.fixated);
data = data(data.fixated, :);
%% plot
fig = figure('Name', figureName);
colorWheel = [...
    1, 0, 0; ...
    0, 0, 1; ...
    1, 153 / 255, 51 / 255; ...
    102 / 255, 153 / 255, 1];
quadrants = unique(data.quadrant);
rows = round(sqrt(numel(channels)));
cols = ceil(numel(channels) / rows);

for channelIter = 1:numel(channels)
    channel = channels{channelIter};
    channelData = data(strcmp(data.mappedChannel, channel), :);
    originalChannel = unique(channelData.channel);
    assert(numel(originalChannel) == 1);
    originalChannel = originalChannel{1};
    subplot(rows, cols, channelIter);
    for quadrantIter = 1:numel(quadrants)
        quadrant = quadrants{quadrantIter};
        quadrantData = channelData(strcmp(channelData.quadrant, quadrant), :);
        % time
        time = quadrantData.timepoints(1, :);
        otherTimes = quadrantData.timepoints(2:end, :);
        matchesOtherTimes = arrayfun(@(i) time == otherTimes(i, :), ...
            1:size(otherTimes, 1), 'UniformOutput', false);
        assert(all([matchesOtherTimes{:}]));
        % response
        responseMean = mean(quadrantData.responseVoltages, 1);
        responseError = stderrmean(quadrantData.responseVoltages, 1);
        shadedErrorBar(time, responseMean, responseError, ...
            {'Color', colorWheel(quadrantIter, :)}, true);
        hold on;
        xlim([min(time), max(time)]);
        title(sprintf('%s (%s)', channel, originalChannel));
    end
    hold off;
end
% legend
hold on;
legendDummies = NaN(size(quadrants));
for quadrantIter = 1:numel(quadrants)
    legendDummies(quadrantIter) = ...
        plot(NaN, NaN, 'Color', colorWheel(quadrantIter, :));
end
leg = legend(legendDummies, quadrants, 'Orientation', 'horizontal');
set(leg, 'Position', [0.37 0.0 0.3 0.05], ...
    'Units', 'normalized');
hold off;
%% save
saveDir = [fileparts(mfilename('fullpath')), ...
    '/../figures/responses_per_channel'];
saveFigures(fig, saveDir, true);
end
