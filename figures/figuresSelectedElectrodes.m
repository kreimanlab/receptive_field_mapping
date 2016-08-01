function figuresSelectedElectrodes(data, figureNamePrefix)
if ~exist('figureNamePrefix', 'var')
    figureNamePrefix = '';
end

channels = unique(data.mappedChannel);
% % all
% c = filter(channels, '.*');
% plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'all']);
% LO 1-9
c = filter(channels, '^LO([0-9])$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LO1-9']);
% LO 10-19
c = filter(channels, '^LO(1[0-9])$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LO10-19']);
% LO 20-29
c = filter(channels, '^LO(2[0-9])$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LO20-29']);
% LO 30-39
c = filter(channels, '^LO(3[0-9])$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LO30-39']);
% LO 40-49
c = filter(channels, '^LO(4[0-9])$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LO40-49']);
% IM+IL
c = filter(channels, '^I[ML]([0-9]+)$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'IM+IL']);
% LIH
c = filter(channels, '^LIH([0-9]+)$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'LIH']);
% RIH
c = filter(channels, '^RIH([0-9]+)$');
plotResponsesPerChannelAndQuadrant(data, c, [figureNamePrefix, 'RIH']);
end

function filteredChannels = filter(channels, pattern)
tokens = regexp(channels, pattern, 'tokens');
indices = cellfun(@(r) ~isempty(r), tokens, 'UniformOutput', false);
filteredChannels = channels([indices{:}]);
tokens = tokens([indices{:}]);
numbers = cellfun(@(r) str2num(r{1}{1}), tokens, 'UniformOutput', false);
[~, order] = sort([numbers{:}]);
filteredChannels = filteredChannels(order);
end
