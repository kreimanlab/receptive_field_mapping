function saveFigures(figures, saveDir, closeFigures)
if ~exist('closeFigures', 'var')
    closeFigures = false;
end
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
for figIter = 1:numel(figures)
    fig = figures(figIter);
    % make full screen
    set(fig, 'units', 'normalized', 'outerposition', [0 0 1 1]);
    % filename
    figName = get(fig, 'Name');
    figName = strrep(figName, '/', '_');
    saveFile = [saveDir, '/', figName];
    % save
%     saveas(fig, saveFile);
    print(fig, '-dpng', [saveFile, '.png']);
    % close
    if closeFigures
        close(fig);
    end
end
end
