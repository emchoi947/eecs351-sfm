%% Configurationss
global imageFolder
imageFolder = 'Images/Pig';     

global detectPoints SURF_threshold
detectPoints   = @ (img) getPointsSURF(img);
SURF_threshold = 500;

global matchPoints
matchPoints = @ (prevImg, img) matchPointsSURF(prevImg, img);

%% Preprocessing
% Check if image folder exists
if ~isfolder(imageFolder)
    error('The specified folder does not exist.');
end

% Load all JPG images from the folder
imageFiles = dir(fullfile(imageFolder, "*.*"));
if isempty(imageFiles)
    error('No JPG images found in the specified folder');
end

% Sort files by name to ensure correct order
[~, idx] = sort({imageFiles.name});
images = imageFiles(idx(3:end)); % Ignore 

% Initialize measurement matrix
W = detectPoints(images(1).name);

for i = 2:length(images)
    prevImg = images(i-1).name;
    img = images(i).name;

    points = detectPoints(img);

    matches = matchPoints(prevImg, img);

    matchedPoints = NaN(length(W), 2);
    matchedPoints(matches(:,1), :) = points(matches(:,2), :);

    newPointsMask = 1:length(points);
    newPointsMask(matches(:, 2)) = NaN;
    newPointsMask = ~isnan(newPointsMask);
    
    newPoints = [NaN(sum(newPointsMask), width(W)) points(newPointsMask, :)];

    W = [W matchedPoints; newPoints];
end

%displayFeatures(images(24).name);
displayMatches(images(24).name, images(25).name, 20);

%{ m
    obs = W;
    obs = 0;
%}

%% Feature Detection
function displayFeatures(image)
    global imageFolder detectPoints

    imshow(fullfile(imageFolder, image)); hold on;

    points = detectPoints(image);

    scatter(points(:,1), points(:,2), "LineWidth", 2);
end

function points = getPointsSURF(image)
    global imageFolder SURF_threshold

    img = im2gray(imread(fullfile(imageFolder, image)));

    points = detectSURFFeatures(img, 'MetricThreshold', SURF_threshold).Location;
end

function points = getPointsCustom(image)
    global imageFolder
    
    img = imread(fullfile(imageFolder, image));
    
    points = [0, 0];
end

%% Feature Matching
function displayMatches(prevImg, img, numPoints)
    global imageFolder detectPoints matchPoints

    img1 = imread(fullfile(imageFolder, prevImg));
    img2 = imread(fullfile(imageFolder, img));

    points1 = detectPoints(prevImg);
    points2 = detectPoints(img);

    matches = matchPoints(prevImg, img);
    matches = matches;
    
    showMatchedFeatures(img1, img2, points1(matches(:, 1),:), points2(matches(:, 2),:), "montage");
end

function matches = matchPointsSURF(prevImg, img)
    global imageFolder SURF_threshold

    img1 = im2gray(imread(fullfile(imageFolder, prevImg)));
    img2 = im2gray(imread(fullfile(imageFolder, img)));

    ft1 = detectSURFFeatures(img1, 'MetricThreshold', SURF_threshold);
    ft2 = detectSURFFeatures(img2, 'MetricThreshold', SURF_threshold);

    [desc1, points1] = extractFeatures(img1, ft1);
    [desc2, points2] = extractFeatures(img2, ft2);

    matches = matchFeatures(desc1, desc2);
end