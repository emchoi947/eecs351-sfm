input_video = 'box.mp4';  
output_folder = 'enhanced_frames';  

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

vidReader = VideoReader(input_video);

frame_idx = 1;
while hasFrame(vidReader)
    img_color = readFrame(vidReader);   % Read the next video frame
    img_gray = im2double(im2gray(img_color));  % Convert to grayscale and double

    % Perform FFT on the grayscale frame
    F = fft2(img_gray);
    Fshift = fftshift(F);

    [M, N] = size(F);
    [X, Y] = meshgrid(1:N, 1:M);
    cx = N / 2; cy = M / 2;
    D = sqrt((X - cx).^2 + (Y - cy).^2);

    % Bandpass filter
    low_cutoff = 15;
    high_cutoff = 85;
    bandpass_filter = (D > low_cutoff) & (D < high_cutoff);

    % Apply bandpass filter
    F_filtered = Fshift .* bandpass_filter;

    % Inverse FFT to get the enhanced frame
    F_ishift = ifftshift(F_filtered);
    img_enhanced = real(ifft2(F_ishift));

    % Normalize to [0, 1]
    img_enhanced = img_enhanced - min(img_enhanced(:));
    img_enhanced = img_enhanced / max(img_enhanced(:));

    % Save the enhanced frame
    output_filename = sprintf('frame_%04d.jpg', frame_idx);  % Zero-padded frame number
    output_path = fullfile(output_folder, output_filename);
    imwrite(img_enhanced, output_path);

    fprintf('Saved: %s\n', output_path);

    frame_idx = frame_idx + 1;
end
