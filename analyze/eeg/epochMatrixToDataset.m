function epochData = epochMatrixToDataset(filename)
channelLabels = load('subjects/subj01-cortex/ChLabel.mat');
channelLabels = channelLabels.ChLabel;
data = load(filename);
EpochDataAllCh = data.EpochDataAllCh;
epochData = table();
epochData.trial = EpochDataAllCh(:, 1);
epochData.voltageResponses = EpochDataAllCh(:, 3:253);
epochData.timepoints = EpochDataAllCh(:, 254:end - 1);
epochData.channelNumber = EpochDataAllCh(:, 505);
epochData.channel = repmat({''}, size(epochData, 1), 1);
warning('off', 'all'); % get rid of default variables warning
for channelNumber = unique(EpochDataAllCh(:, 505))'
    epochData.channel(epochData.channelNumber == channelNumber) = ...
        repmat({sprintf('C%03d', channelNumber)}, ...
        sum(epochData.channelNumber == channelNumber), 1);
    epochData.mappedChannel(epochData.channelNumber == channelNumber) = ...
        repmat(channelLabels(channelNumber), ...
        sum(epochData.channelNumber == channelNumber), 1);
end
warning('on', 'all'); % turn back on
end
