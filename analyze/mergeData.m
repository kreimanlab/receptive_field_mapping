function data = mergeData(varargin)
for dataIter = 1:numel(varargin)
    if ~istable(varargin{dataIter})
        assert(isa(varargin{dataIter}, 'dataset'));
        varargin{dataIter} = dataset2table(varargin{dataIter});
    end
    assert(ismember('trial', varargin{dataIter}.Properties.VariableNames));
    if ~exist('data', 'var')
        data = varargin{dataIter};
    else
        data = join(data, varargin{dataIter}, 'Keys', 'trial');
    end
end
