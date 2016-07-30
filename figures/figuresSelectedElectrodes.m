function figuresSelectedElectrodes(data)
channels = unique(data.channel);
% LO
c = filter(channels, '^LO([0-9]+)');
plotResponsesPerChannelAndQuadrant(data, c, 'LO');
% IM+IL
c = filter(channels, '^I[ML]([0-9]+)');
plotResponsesPerChannelAndQuadrant(data, c, 'IM+IL');
% LIH
c = filter(channels, '^LIH([0-9]+)');
plotResponsesPerChannelAndQuadrant(data, c, 'LIH');
% RIH
c = filter(channels, '^RIH([0-9]+)');
plotResponsesPerChannelAndQuadrant(data, c, 'RIH');
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
