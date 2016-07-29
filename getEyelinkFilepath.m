function filepath = getEyelinkFilepath(prefix, subjectName)
c = clock;
filepath = fullfile('subjects', subjectName, ...
    [prefix subjectName ...
	'-' num2str(c(1)) '_' num2str(c(2),'%0.2d') '_' ...
    num2str(c(3), '%0.2d') '-' num2str(c(4),'%0.2d') '_' ...
    num2str(c(5), '%0.2d') '_' num2str(round(c(6)), '%0.2d') ...
    '.edf']);
end
