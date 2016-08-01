function data = parseEEG(filepathIn, dataRowBegin, dataRowEnd)
% lines
if ~exist('dataRowBegin', 'var')
    dataRowBegin = 1;
end
if ~exist('dataRowEnd', 'var')
    dataRowEnd = Inf;
end
firstLineToRead = dataRowBegin + 15;
lastLineToRead = dataRowEnd + 15;
% files
[directory, filename, extension] = fileparts(filepathIn);
filepathOut = sprintf('%s/%s-tmp-%d_%d%s', ...
    directory, filename, dataRowBegin, dataRowEnd, extension);
if exist(filepathOut, 'file')
    data = readtable(filepathOut);
    return;
end
fin = fopen(filepathIn, 'r');
assert(fin > 0, 'could not open input file');
fout = fopen(filepathOut, 'wt');
assert(fout > 0, 'could not open output file');
% read
lineNumber = 0;
while true
    line = fgetl(fin);
    if ~ ischar(line)
        break;
    end
    lineNumber = lineNumber + 1;
    if lineNumber <= 13 || lineNumber == 15
        continue;
    elseif lineNumber == 14
        line = line(3:end);
        line = strrep(line, 'Date.Time', 'Date Time');
        line = strrep(line, '%c', '');
        line = strtrim(line);
    elseif lineNumber < firstLineToRead
        continue;
    elseif lineNumber > lastLineToRead
        break;
    end
    line = regexprep(line, '[\t ]+', '\t');
    fprintf(fout, '%s\n', line);
end
fclose(fin);
fclose(fout);
data = readtable(filepathOut);
delete(filepathOut);
end
