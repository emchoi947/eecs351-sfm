
enhancedFolder = 'enhanced';               % Folder with preprocessed images
featureFolder = 'surf_features';           % Output folder for feature data

% Create the output folder if it doesn't exist
if ~exist(featureFolder, 'dir')
    mkdir(featureFolder);
end

imageFiles = dir(fullfile(enhancedFolder, '*.JPG'));  % Use *.png if needed
numImages = length(imageFiles);

for i = 1:numImages
    % Read enhanced image
    img = imread(fullfile(enhancedFolder, imageFiles(i).name));

    % Convert to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    % Detect SURF features
    points = detectSURFFeatures(img);

    % Save points to a .mat file
    featureData = struct;
    featureData.filename = imageFiles(i).name;
    featureData.points = points;
    
    % Create a name for the output .mat file
    [~, name, ~] = fileparts(imageFiles(i).name);
    save(fullfile(featureFolder, [name, '_surf.mat']), 'featureData');

    % Visualize
    % figure, imshow(img); hold on;
    plot(points.selectStrongest(50));
    % title(['SURF Features: ', imageFiles(i).name]);
end
