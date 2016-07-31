function gratingImage = createGratingImage(targetDegrees, degreesPerPixel, ...
    background, foreground)
pixels = round(targetDegrees / degreesPerPixel);
gratingImage = background * ones(pixels, pixels);
numBars = 4;
gratingWidth = round((targetDegrees / numBars) / degreesPerPixel);
for x = 1:gratingWidth * 2:pixels
    gratingImage(:, x:x + gratingWidth) = foreground;
end
end
