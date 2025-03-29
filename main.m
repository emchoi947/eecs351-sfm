% Specify the folder containing the images
image_folder = 'Apple';  % Replace with your folder path

% Check if the folder exists
if ~isfolder(image_folder)
    error('The specified folder does not exist.');
end

% Load all JPG images from the folder
image_files = dir(fullfile(image_folder, '*.jpg'));
if isempty(image_files)
    error('No JPG images found in the specified folder');
end

% Sort files by name to ensure correct order
[~, idx] = sort({image_files.name});
image_files = image_files(idx);

% Read the first image to initialize
img1 = imread(fullfile(image_folder, image_files(1).name));
gray1 = rgb2gray(img1);

% Detect features in the first image
points1 = detectSURFFeatures(gray1);
if points1.Count < 100
    % Try with a lower threshold if not enough features
    points1 = detectSURFFeatures(gray1, 'MetricThreshold', 100);
end

% Initialize measurement matrix
num_frames = length(image_files);
num_points = points1.Count;
measurement_matrix = NaN(2 * num_frames, num_points);  % Initialize with NaN

% Store the first frame points in the measurement matrix
measurement_matrix(1:2, :) = points1.Location';

% Create point tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1, 'NumPyramidLevels', 3);
initialize(tracker, points1.Location, gray1);

% Track points through the remaining frames
for i = 2:num_frames
    % Read the next image
    img = imread(fullfile(image_folder, image_files(i).name));
    gray = rgb2gray(img);
    
    % Track points
    [points, validity] = tracker(gray);
    
    % Store only valid points
    valid_points = points(validity, :);
    
    % Resize the measurement matrix if the number of points differs from the first frame
    num_valid_points = size(valid_points, 1);
    measurement_matrix(2 * i - 1:2 * i, 1:num_valid_points) = valid_points';
    
    % Reset the tracker if too many points are lost
    if sum(validity) < 0.5 * num_points
        release(tracker);
        points1 = detectSURFFeatures(gray, 'MetricThreshold', 100);
        initialize(tracker, points1.Location, gray);
        fprintf('Re-initialized tracker at frame %d\n', i);
    end
end

release(tracker);

% Remove points that weren't tracked in at least 50% of the frames
tracked_frames = sum(~isnan(measurement_matrix(1:2:end, :)));
valid_points = tracked_frames > num_frames / 2;
measurement_matrix = measurement_matrix(:, valid_points);

fprintf('Final measurement matrix size: %dx%d\n', size(measurement_matrix));
fprintf('Percentage of valid tracks: %.1f%%\n', 100 * sum(~isnan(measurement_matrix(:))) / numel(measurement_matrix));

% Save the measurement matrix to a CSV file with the folder name
output_file = strcat(image_folder, '_measurement_matrix.csv');
csvwrite(output_file, measurement_matrix);

fprintf('Measurement matrix saved as: %s\n', output_file);

