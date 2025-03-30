% Specify the folder containing the images
image_folder = 'Images/Apple';  % Replace with your folder path

% Check if the folder exists
if ~isfolder(image_folder)
    error('The specified folder does not exist.');
end

% Load all JPG images from the folder
image_files = dir(fullfile(image_folder, "*.jpg"));
if isempty(image_files)
    error('No JPG images found in the specified folder');
end

% Sort files by name to ensure correct order
[~, idx] = sort({image_files.name});
image_files = image_files(idx);

% Initialize measurement matrix
W = get_points(fullfile(image_folder, image_files(1).name));

for i = 2:length(image_files)
    points = get_points(fullfile(image_folder, image_files(i).name));

    prev_points = W(:, end-1:end);
    matches = matchFeatures(prev_points, points);

    matched_points = NaN(length(W), 2);
    matched_points(matches(:,1), :) = points(matches(:,2), :);

    new_points_mask = 1:length(points);
    new_points_mask(matches(:, 2)) = NaN;
    new_points_mask = ~isnan(new_points_mask);
    
    new_points = [NaN(sum(new_points_mask), width(W)) points(new_points_mask, :)];

    W = [W matched_points];
    W = [W; new_points];
end

%{a
obs_plot = W;
obs_plot(obs_plot > 0) = 255;
image(obs_plot)
%}

%{
n = 3;
imshow(fullfile(image_folder, image_files(n).name)); hold on;
scatter(W(:, 2*n-1), W(:, 2*n), "LineWidth", 2);
%}

%{
img1 = imshow(fullfile(image_folder, image_files(1).name));
img2 = imshow(fullfile(image_folder, image_files(2).name));
showMatchedFeatures(img1, img2, W(), matchedPoints2);
%}

function points = get_points(file)
    img = imread(file);
    img_gray = im2gray(img);

    points = detectSURFFeatures(img_gray, 'MetricThreshold', 200).Location;
end