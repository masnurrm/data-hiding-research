clc;

fprintf('===========================================================================\n');
fprintf('=========================== E X T R A C T I O N ===========================\n');
fprintf('===========================================================================\n\n');

fprintf('Start of Data Hiding Extraction\n\n');


% Step E1: Import the key file and reshape it into the 1D array.
key_file            = 'E:\Research\Hiding Result\key_nur.txt';
key_data            = dlmread(key_file);
[m, n]              = size(key_data);
key                 = reshape(key_data, [n, m]);


% Step E2: Import the stego image and resize into 1D array.
stego_image         = imread('E:\Research\Hiding Result\stego_image_nur.tiff');
stego_image_1d      = int16(reshape(stego_image, 1, []));


% Step E3: Compute the width and height of the stego image.
stego_image_size    = size(stego_image);
height              = stego_image_size(1);  
width               = stego_image_size(2);
size_1d             = height * width;

fprintf('Data Hiding Extraction Process Start...\n');
tic


% Step E4: Count the total of the blocks that can be created.
si_muh_arr          = zeros(1, size_1d);
block_size          = 4;
block_num           = 0;

for i = 1:size_1d
    if mod(i, 4) == 1
        block_num   = block_num + 1;
    end
end


% Step E5: Find the best subtractors for each block by flag in the key and save it for each block.
% Step E6: Compute the differences between all the pixels except the subtracator pixel and store it.
best_subtractors    = zeros(1, block_num);
index_subtractors   = zeros(1, block_num);

for i = 1:block_num
    block_index     = (i - 1) * block_size;
    
    % Finding the best subtractor of each blocks.
    for j = 1:block_size
        index       = block_index + j;
        if ismember(key(index), [2, 3, 5, 7])
            best_subtractors(i)     = stego_image_1d(index);
            index_subtractors(i)    = j;
        end
    end

    % Compute the differences.
    for j = 1:block_size
        if j ~= index_subtractors(i)
            si_muh_arr(block_index + j)      = stego_image_1d(block_index + j) - best_subtractors(i);
        end
    end
end


% Step E7: Count the payload size.
cover_image_1d  = stego_image_1d;
payload_size    = 0;

for i = 1:length(key)
    if ismember(key(i), [4, 6, 8])
        payload_size = payload_size + 1;
    end
end


% Step E8: Extract the secret data and also find the cover image pixel.
payload         = int16(zeros(1, payload_size)); 
counter         = 1;

for i = 1:size_1d
    if ismember(key(i), [4, 6, 8])
        payload(counter)    = mod(si_muh_arr(i), 2);
        counter             = counter + 1;

        cover_image_1d(i)   = stego_image_1d(i) - ceil(si_muh_arr(i) / 2);
    else
        cover_image_1d(i)   = stego_image_1d(i);
    end
end


% Step E9: Export the secret data.
file_name           = 'E:\Research\Extraction Result\secret_data_final.txt';
extract_file_id     = fopen(file_name, 'w');

if extract_file_id == -1
    error('Unable to open the file for writing.');
else
    for i = 1:length(payload)
        fprintf(extract_file_id, '%d\t', payload(i));
    end

    fclose(extract_file_id);
    disp(['Secret data has been saved to ' file_name]);
end


% Step E10: Analysis the PSNR value.
cover_image = reshape(cover_image_1d, height, width);
stego_image = reshape(stego_image_1d, height, width);

fprintf('PSNR (int16)\t\t\t\t\t\t: %f\n\n', psnr(stego_image, cover_image));

cover_image = cast(cover_image, 'uint8');
stego_image = cast(stego_image, 'uint8');

fprintf('PSNR (Compare Cover Image)\t\t\t: %f\n\n', psnr(stego_image, cover_image));


% Step E11: Display the cover image (extracted) and the stego image.
figure; image(cover_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Cover Image (Extracted)');

figure; image(stego_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Stego image (Extracted)');


% Step E12: Analysis of the time elapsed to extraction and also differences between original secret data and extracted secret data.
elapsed_time        = toc;
fprintf(['Data Hiding Extraction Process Done with Elapsed Time: ' num2str(elapsed_time) ' s\n\n']);

% file1               = dlmread('E:\Research\Sample Payloads\random-binary_1Kb.txt');
file1               = payload;
file2               = readmatrix('E:\Research\Extraction Result\secret_data_final.txt');
num_diff_bits       = 0;

for i = 1:length(file2)
    if file1(i) ~= file2(i)
        num_diff_bits = num_diff_bits + 1; 
    end
end

fprintf('Secret Data Differences\t\t\t\t: %d\n', num_diff_bits);

% Step E13: Export the cover image that have been extracted.
output_cover_path   = 'E:\Research\Extraction Result\cover_image_nur.tiff';
imwrite(cover_image, output_cover_path, 'tiff');

fprintf('End of Data Hiding Extraction\n\n');