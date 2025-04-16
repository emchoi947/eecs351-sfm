function videoTo3DModel()
    %% 1. Extract video frames
    videoFile = 'input.mp4';
    framesDir = 'frames';
    
    % Create frames directory if it doesn't exist
    if ~exist(framesDir, 'dir')
        mkdir(framesDir);
    else
        % Clear existing frames
        delete(fullfile(framesDir, '*.jpg'));
    end
    
    % Read video and save frames
    vr = VideoReader(videoFile);
    frameCount = 0;
    
    disp('Extracting video frames...');
    while hasFrame(vr)
        frameCount = frameCount + 1;
        frame = readFrame(vr);
        imwrite(frame, fullfile(framesDir, sprintf('frame_%04d.jpg', frameCount)));
    end
    fprintf('Saved %d frames to %s folder\n', frameCount, framesDir);
    
    %% 2. Load frames and detect SURF features
    imageFiles = dir(fullfile(framesDir, '*.jpg'));
    numFrames = min(50, length(imageFiles)); % Process max 50 frames

    % Create points directory
    pointsDir = 'points';
    if ~exist(pointsDir, 'dir')
        mkdir(pointsDir);
    else
        delete(fullfile(pointsDir, '*.jpg'));
    end

    
    % Initialize variables
    images = cell(1, numFrames);
    grayImages = cell(1, numFrames);
    points = cell(1, numFrames);
    features = cell(1, numFrames);
    
    disp('Detecting SURF features...');
    for i = 1:numFrames
        % Read image
        imgPath = fullfile(framesDir, imageFiles(i).name);
        images{i} = imread(imgPath);
        grayImages{i} = rgb2gray(images{i});
        
        % Detect SURF features
        points{i} = detectSURFFeatures(grayImages{i});
        [features{i}, points{i}] = extractFeatures(grayImages{i}, points{i});
        
        fprintf('Processed frame %d/%d: %d features found\n', i, numFrames, length(points{i}));

        imgWithPoints = insertMarker(images{i}, points{i}.Location, 'x', 'Color', 'green', 'Size', 5);
        outputImgPath = fullfile(pointsDir, sprintf('points_%04d.jpg', i));
        imwrite(imgWithPoints, outputImgPath);
    end
    
    %% 3. Perform Structure from Motion
    disp('Performing Structure from Motion...');
    
    % Camera intrinsics (example - adjust for your camera)
    focalLength = [1000, 1000];  % Rough estimate
    principalPoint = [size(grayImages{1},2)/2, size(grayImages{1},1)/2];
    imageSize = [size(grayImages{1},1), size(grayImages{1},2)];
    intrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize);
    
    % Match features between consecutive frames
    vSet = viewSet;
    vSet = addView(vSet, 1, 'Points', points{1}, 'Orientation', eye(3), 'Location', [0 0 0]);
    
    for i = 2:numFrames
        % Match features
        pairsIdx = matchFeatures(features{i-1}, features{i}, 'Unique', true);
        matchedPoints1 = points{i-1}(pairsIdx(:,1));
        matchedPoints2 = points{i}(pairsIdx(:,2));
        
        % Estimate camera pose
        if size(matchedPoints1, 1) >= 6
            [relOrient, relLoc, inlierIdx] = helperEstimateRelativePose(...
                matchedPoints1, matchedPoints2, intrinsics);
            
            % Add new view
            vSet = addView(vSet, i, 'Points', points{i});
            
            % Update connection
            vSet = addConnection(vSet, i-1, i, 'Matches', pairsIdx(inlierIdx,:));
            
            % Update absolute pose
            prevPose = poses(vSet, i-1);
            absOrient = prevPose.Orientation{1} * relOrient;
            absLoc = prevPose.Location{1} + relLoc * prevPose.Orientation{1};
    
            vSet = updateView(vSet, i, 'Orientation', absOrient, 'Location', absLoc);
        end
    end
    
    %% 4. Triangulate 3D points
    % Find point tracks across all views
    tracks = findTracks(vSet);
    
    % Get camera poses
    camPoses = poses(vSet);
    
    % Triangulate points
    [xyzPoints, errors] = triangulateMultiview(tracks, camPoses, intrinsics);
    
    % Filter points by reprojection error
    validIdx = errors < 5;
    xyzPoints = xyzPoints(validIdx, :);
    
    %% 5. Create and visualize 3D point cloud
    if ~isempty(xyzPoints)
        % Create point cloud
        ptCloud = pointCloud(xyzPoints);
        
        % Visualize
        figure;
        pcshow(ptCloud, 'VerticalAxis', 'Y', 'VerticalAxisDir', 'Down', ...
            'MarkerSize', 45);
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('3D Reconstruction from Video');
        grid on;
        
        % Optional: Save point cloud
        pcwrite(ptCloud, 'reconstructed_model.ply', 'PLYFormat', 'binary');
        disp('Saved 3D model to reconstructed_model.ply');
    else
        disp('No 3D points were reconstructed. Possible issues:');
        disp('- Insufficient camera motion');
        disp('- Poor feature matches');
        disp('- Incorrect camera parameters');
    end
end

% Helper function for pose estimation
function [orientation, location, inlierIdx] = helperEstimateRelativePose(matchedPoints1, matchedPoints2, intrinsics)
    % Estimate essential matrix
    [E, inlierIdx] = estimateEssentialMatrix(...
        matchedPoints1, matchedPoints2, intrinsics, ...
        'Confidence', 99.9, 'MaxDistance', 1);
    
    % Recover relative pose
    [orientation, location] = relativeCameraPose(E, intrinsics, ...
        matchedPoints1(inlierIdx,:), matchedPoints2(inlierIdx,:));
end
