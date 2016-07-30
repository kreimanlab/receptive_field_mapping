function data = parseEEG(filenameIn)
filenameOut = [filenameIn, '.tmp'];
fin = fopen(filenameIn, 'r');
fout = fopen(filenameOut, 'wt');
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
    end
    line = regexprep(line, '[\t ]+', '\t');
    fprintf(fout, '%s\n', line);
end
fclose(fin);
fclose(fout);
data = readtable(filenameOut);
delete(filenameOut);
end
