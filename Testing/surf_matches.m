% Purpose: Perform SURF feature detection and matching on preprocessed images

% Define folders
inputFolder = 'enhanced';         % Folder with enhanced images
outputFolder = 'surf_matches';    % Folder to save match visualizations

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load all image files from the input folder
imageFiles = dir(fullfile(inputFolder, '*.JPG'));
numImages = length(imageFiles);

if numImages < 2
    error('Not enough images in the enhanced folder to match.');
end

% Loop through image pairs
for i = 1:numImages - 1
    % Read current and next image
    img1 = imread(fullfile(inputFolder, imageFiles(i).name));
    img2 = imread(fullfile(inputFolder, imageFiles(i+1).name));

    % Convert to grayscale if RGB
    if size(img1, 3) == 3
        gray1 = rgb2gray(img1);
    else
        gray1 = img1;
    end

    if size(img2, 3) == 3
        gray2 = rgb2gray(img2);
    else
        gray2 = img2;
    end

    % Detect SURF keypoints
    points1 = detectSURFFeatures(gray1);
    points2 = detectSURFFeatures(gray2);

    % Extract features
    [features1, validPts1] = extractFeatures(gray1, points1);
    [features2, validPts2] = extractFeatures(gray2, points2);

    % Match features
    indexPairs = matchFeatures(features1, features2);

    % Retrieve matched points
    matchedPts1 = validPts1(indexPairs(:, 1));
    matchedPts2 = validPts2(indexPairs(:, 2));

    % Show matches
    figure('Visible', 'off');
    showMatchedFeatures(gray1, gray2, matchedPts1, matchedPts2, 'montage');
    title(sprintf('Matched Features: %s <-> %s', ...
        imageFiles(i).name, imageFiles(i+1).name));

    % Save match visualization
    saveas(gcf, fullfile(outputFolder, sprintf('match_%02d_%02d.png', i, i+1)));
    close(gcf);
end

disp('Feature matching complete. Results saved to surf_matches folder.');
