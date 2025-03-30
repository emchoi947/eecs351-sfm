% Specify the folder containing the images
image_folder = 'C:\Users\seohy\Documents\EECS351\eecs351-sfm\Images';  % Replace with your folder path

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
img1 = rgb2gray(img1);

% Detect corners in the first image.
prevPoints = detectMinEigenFeatures(img1, MinQuality=0.001);

% Create the point tracker object to track the points across views.
tracker = vision.PointTracker(MaxBidirectionalError=1, NumPyramidLevels=6);

% Initialize the point tracker.
prevPoints = prevPoints.Location;
initialize(tracker, prevPoints, img1);

vSet = imageviewset;
viewId = 1;
vSet = addView(vSet, viewId, rigidtform3d, Points=prevPoints);

% Store the dense points in the view set.

vSet = updateConnection(vSet, 1, 2, Matches=zeros(0, 2));
vSet = updateView(vSet, 1, Points=prevPoints);

num_frames = length(image_files);

% Track the points across all views.
for i = 2:num_frames
    % Read and undistort the current image.
    I = imread(fullfile(image_folder, image_files(1).name));
    I = rgb2gray(I);
    
    % Track the points.
    [currPoints, validIdx] = step(tracker, I);
    
    % Clear the old matches between the points.
    if i < num_frames
        vSet = updateConnection(vSet, i, i+1, Matches=zeros(0, 2));
    end
    vSet = updateView(vSet, i, Points=currPoints);
    
    % Store the point matches in the view set.
    matches = repmat((1:size(prevPoints, 1))', [1, 2]);
    matches = matches(validIdx, :);        
    vSet = updateConnection(vSet, i-1, i, Matches=matches);
end

% Find point tracks across all views.
tracks = findTracks(vSet);

% Find point tracks across all views.
camPoses = poses(vSet);

% Triangulate initial locations for the 3-D world points.
xyzPoints = triangulateMultiview(tracks, camPoses,...
    intrinsics);

% Refine the 3-D world points and camera poses.
[xyzPoints, camPoses, reprojectionErrors] = bundleAdjustment(...
    xyzPoints, tracks, camPoses, intrinsics, FixedViewId=1, ...
    PointsUndistorted=true);