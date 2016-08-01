function [data, numInterruptions] = analyzeEEGData(rawData, relevantRows)
if ~istable(rawData) && ~isa(rawData, 'dataset')
    [~, ~, extension] = fileparts(rawData);
    switch extension
        case '.mat'
            rawData = load(rawData);
            rawData = rawData.data;
        case '.txt'
            if exist('relevantRows', 'var')
                rawData = parseEEG(rawData, ...
                    min(relevantRows), max(relevantRows));
                relevantRows = relevantRows - min(relevantRows) + 1;
            else
                rawData = parseEEG(rawData);
            end
        otherwise
            error('Unknown extension %s', extension);
    end
end
if exist('relevantRows', 'var')
    assert(~isempty(relevantRows));
    rawData = rawData(relevantRows, :);
end

%% settings
stopFrequencies = 60 * (1:4);
samplingRate = 500; % Hz = 1/1000ms
samplesPerSecond = 1000 / samplingRate;
timeFrameToExtract = -100:samplesPerSecond:400;
threshold = -0.8;
selectedChannels = 1:78;
quickSuccessionMaxDistance = 75;
triggerChannel1 = 'C123';
triggerChannel2 = 'C124';
channelNameMapping = {...
    'LO1', 'LO2', 'LO3', 'LO4', 'LO5', 'LO6', 'LO7', 'LO8', 'LO9', ...
    'LO10', 'LO11', 'LO12', 'LO13', 'LO14', 'LO15', 'LO16', 'LO17', 'LO18', 'LO19', ...
    'LO20', 'LO21', 'LO22', 'LO23', 'LO24', 'LO25', 'LO26', 'LO27', 'LO28', 'LO29', ...
    'LO30', 'LO31', 'LO32', 'LO33', 'LO34', 'LO35', 'LO36', 'LO37', 'LO38', 'LO39', ...
    'LO40', 'LO41', 'LO42', 'LO43', 'LO44', 'LO45', 'LO46', 'LO47', 'LO48', ...
    'IM1', 'IM2', 'IM3', 'IM4', ...
    'IL1', 'IL2', 'IL3', 'IL4', 'IL5', 'IL6', ...
    'LIH1', 'LIH2', 'LIH3', 'LIH4', 'LIH5', 'LIH6', 'LIH7', 'LIH8', 'LIH9', 'LIH10', ...
    'RIH1', 'RIH2', 'RIH3', 'RIH4', 'RIH5', 'RIH6', 'RIH7', 'RIH8', 'RIH9', 'RIH10'};

%% properties
channelNames = arrayfun(@(i) sprintf('C%03d', i), selectedChannels, ...
    'UniformOutput', false);
assert(all(ismember(channelNames, rawData.Properties.VariableNames)));
assert(numel(channelNames) == numel(channelNameMapping));

timeIndicesToExtract = timeFrameToExtract / samplesPerSecond;

%% triggers
triggerSignal = rawData.(triggerChannel1) - rawData.(triggerChannel2);
[trialStarts, trials, numInterruptions] = getTriggerTrialStarts(...
    triggerSignal, threshold, quickSuccessionMaxDistance);
%% voltages
% preallocate table
numRows = numel(channelNames) * numel(trialStarts);
trial = NaN(numRows, 1);
timepoints = NaN(numRows, numel(timeFrameToExtract));
timeIndices = NaN(numRows, numel(timeIndicesToExtract));
responseVoltages = NaN(numRows, numel(timeIndicesToExtract));
channel = cell(numRows, 1);
mappedChannel = cell(numRows, 1);
% fill
rowIter = 1;
for channelIter = 1:numel(channelNames)
    channelName = channelNames{channelIter};
    mappedChannelName = channelNameMapping{channelIter};
    
    for trialIter = 1:numel(trialStarts)
        trialTimeIndices = timeIndicesToExtract + trialStarts(trialIter);
        trialVoltages = rawData.(channelName);
        trialVoltages = notchfilt(trialVoltages, samplingRate, stopFrequencies);
        trialVoltages = trialVoltages(trialTimeIndices);
        
        trial(rowIter) = trials(trialIter);
        timepoints(rowIter, :) = timeFrameToExtract;
        timeIndices(rowIter, :) = trialTimeIndices;
        responseVoltages(rowIter, :) = trialVoltages;
        channel(rowIter, 1) = {channelName};
        mappedChannel(rowIter, 1) = {mappedChannelName};
        rowIter = rowIter + 1;
    end
end
data = table(trial, timepoints, timeIndices, responseVoltages, ...
    channel, mappedChannel);
end
