function fig = plotResponsesPerChannelAndQuadrant(data, ...
    channels, figureName)
if ~exist('channels', 'var')
    channels = unique(data.channel);
end
if ~exist('figureName', 'var')
    figureName = sprintf('%d Electrodes - all quadrants', numel(channels));
end
% use only data where fixated
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
    channelData = data(strcmp(data.channel, channel), :);
    subplot(rows, cols, channelIter);
    for quadrantIter = 1:numel(quadrants)
        quadrant = quadrants{quadrantIter};
        quadrantData = channelData(strcmp(channelData.quadrant, quadrant), :);
        assert(numel(unique(quadrantData.trial)) == ...
            size(quadrantData.voltageResponses, 1));
        % time
        time = quadrantData.timepoints(1, :);
        otherTimes = quadrantData.timepoints(2:end, :);
        matchesOtherTimes = arrayfun(@(i) time == otherTimes(i, :), ...
            1:size(otherTimes, 1), 'UniformOutput', false);
        assert(all([matchesOtherTimes{:}]));
        % response
        responseMean = mean(quadrantData.voltageResponses, 1);
        responseError = stderrmean(quadrantData.voltageResponses, 1);
        shadedErrorBar(time, responseMean, responseError, ...
            {'Color', colorWheel(quadrantIter, :)}, true);
        hold on;
        xlim([min(time), max(time)]);
        title(channel);
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
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
figName = get(fig, 'Name');
figName = strrep(figName, '/', '_');
saveFile = [saveDir, '/', figName];
saveas(fig, saveFile);
export_fig(saveFile, '-png', fig);
end
