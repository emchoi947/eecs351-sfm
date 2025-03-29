function camera_trajectory()
    %% 1. SETUP - CHANGE THESE IF NEEDED
    image_folder = 'Apple';      % Folder containing your images
    min_features = 100;          % Minimum features to track
    initial_z = 300;             % Initial distance guess (mm)
    
    %% 2. INITIALIZATION
    % Check folder exists
    if ~isfolder(image_folder)
        error(['Folder not found: ' image_folder '. Create an "Apple" folder with images.']);
    end
    
    % Find all image files
    img_exts = {'.jpg','.jpeg','.png'};
    image_files = [];
    for ext = img_exts
        image_files = [image_files; dir(fullfile(image_folder, ['*' ext{1}]))];
    end
    
    if isempty(image_files)
        error('No images found in folder. Supported formats: .jpg, .jpeg, .png');
    end
    
    % Simple numeric sort (for files named like frame1.jpg, frame2.jpg)
    [~, idx] = sort_naturally({image_files.name});
    image_files = image_files(idx);
    num_frames = length(image_files);
    fprintf('Found %d images\n', num_frames);
    
    %% 3. FIRST FRAME PROCESSING
    fprintf('Processing first frame...\n');
    img1 = imread(fullfile(image_folder, image_files(1).name));
    if size(img1,3) == 3
        gray1 = rgb2gray(img1);
    else
        gray1 = img1;
    end
    
    % Edge detection with automatic threshold
    edges1 = edge(gray1, 'Canny', [], 1.5);
    edges1_uint8 = uint8(edges1)*255;  % Convert to uint8
    
    % Feature detection with adaptive threshold
    points1 = detectSURFFeatures(edges1_uint8, 'MetricThreshold', 200);
    while points1.Count < min_features && points1.MetricThreshold > 10
        points1 = detectSURFFeatures(edges1_uint8, 'MetricThreshold', points1.MetricThreshold*0.7);
    end
    fprintf('Detected %d features in first frame\n', points1.Count);
    
    %% 4. INITIALIZE TRACKING
    measurement_matrix = nan(2*num_frames, points1.Count);
    measurement_matrix(1:2,:) = points1.Location';
    
    tracker = vision.PointTracker(...
        'MaxBidirectionalError', 2, ...
        'NumPyramidLevels', 3, ...
        'BlockSize', [25 25]);
    initialize(tracker, points1.Location, edges1_uint8);
    
    % Initialize camera trajectory
    camera_poses = zeros(num_frames, 3);
    camera_poses(1,:) = [0 0 0];  % First frame at origin
    
    %% 5. TRACK THROUGH FRAMES
    fprintf('Tracking features...\n');
    for i = 2:num_frames
        % Read and process image
        img = imread(fullfile(image_folder, image_files(i).name));
        if size(img,3) == 3
            gray = rgb2gray(img);
        else
            gray = img;
        end
        edges = edge(gray, 'Canny', [], 1.5);
        edges_uint8 = uint8(edges)*255;  % Convert to uint8
        
        % Track points
        [points, validity] = tracker(edges_uint8);
        valid_idx = find(validity);
        
        % Ensure we have enough valid points
        if numel(valid_idx) < 5
            fprintf('Warning: Only %d points tracked in frame %d - skipping\n', numel(valid_idx), i);
            camera_poses(i,:) = camera_poses(i-1,:);  % Use previous position
            continue;
        end
        
        % Store measurements
        measurement_matrix(2*i-1:2*i, valid_idx) = points(valid_idx,:)';
        
        % Calculate movement (ensure we have both x and y components)
        if i == 2
            movement = mean(points(valid_idx,:) - points1.Location(valid_idx,:), 1);
        else
            prev_points = measurement_matrix(2*i-3:2*i-2, valid_idx)';
            movement = mean(points(valid_idx,:) - prev_points, 1);
        end
        
        % Ensure movement has both x and y components
        if numel(movement) < 2
            movement = [0 0];  % Default to no movement if calculation failed
        end
        
        % Update camera position
        camera_poses(i,:) = camera_poses(i-1,:) + [movement(1), movement(2), initial_z/num_frames];
        
        % Show progress
        if mod(i,5) == 0
            fprintf('Processed frame %d/%d - %d points tracked\n', i, num_frames, numel(valid_idx));
        end
    end
    
    %% 6. SAVE AND VISUALIZE RESULTS
    % Save data
    if ~isfolder('Results')
        mkdir('Results');
    end
   writematrix(measurement_matrix, fullfile('Results', 'measurement_matrix.csv'));
   writematrix(camera_poses, fullfile('Results', 'camera_trajectory.csv'));
    
    % Plot trajectory
    figure;
    plot3(camera_poses(:,1), camera_poses(:,2), camera_poses(:,3), '-o', ...
        'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
    grid on; axis equal;
    xlabel('X (pixels)'); ylabel('Y (pixels)'); zlabel('Z (mm)');
    title('Estimated Camera Trajectory');
    
    fprintf('Done! Results saved in "Results" folder.\n');
end

%% Helper function for natural sorting
function [sorted_names, indices] = sort_naturally(names)
    % Extract numbers from filenames
    num_str = regexp(names, '\d+', 'match');
    num = cellfun(@(x) str2double(x{1}), num_str, 'UniformOutput', false);
    num(cellfun(@isempty, num)) = {Inf}; % Handle files without numbers
    
    % Convert to matrix and sort
    [~, indices] = sort(cell2mat(num));
    sorted_names = names(indices);
end
