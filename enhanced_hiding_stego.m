clc;

fprintf('===========================================================================\n');
fprintf('=============================== H I D I N G ===============================\n');
fprintf('===========================================================================\n\n');

% Step H1: Load the cover image and change the data type to int16.
cover_image         = int16(imread("E:\Research\Sample Images\Abdominal.tiff"));

% Step H2: Load the payload or secret bits data.
payload             = readmatrix("E:\Research\Sample Payloads\random-binary_1Kb.txt");

% Step H3: Compute the width and height of the cover image.
fprintf('Embedding Payload Process Start...\n');
tic

cover_image_size    = size(cover_image);
width               = cover_image_size(2);         
height              = cover_image_size(1);

% Step H4: Reshape the cover image into 1D array.
cover_image_1d      = reshape(cover_image, 1, []);
stego_image_1d      = cover_image_1d;
size_1d             = width * height;


% Step H5: Count the total of the blocks that can be created.
d_arr               = zeros(1, size_1d);
block_size          = 4;
block_num           = 0;
counter             = 1;  

for i = 1:size_1d
    if mod(i, 4) == 1
        counter     = counter + 1;
        block_num   = block_num + 1;
    end
end


% Step H6: Set a new table (a matrix of same size as image) as the key with default values (zeros).
key                 = zeros(1, size_1d);


% Step H7: Find the best subtractor from pixels of each blocks.
% Best subtractor is when the other pixel in a block subtracted with it, there is maximal number of differences resulted in -1, 0, or +1.
best_subtractors    = zeros(1, block_num);
index_subtractors   = zeros(1, block_num);
prime_num           = [2, 3, 5, 7];

for i = 1:block_num
    block_index                         = (i - 1) * block_size;
    block                               = cover_image_1d(block_index + 1 : block_index + 4);  
    
    [best_subtractor, index_subtractor] = find_best_subtractor(block);    
    best_subtractors(i)                 = best_subtractor;
    index_subtractors(i)                = index_subtractor;

    % Create a flag in key in the index of the subtractor pixel
    key(block_index + index_subtractor) = prime_num(randi(length(prime_num)));
end


% Step H8: Compute the differences between all the pixels except the subtracator pixel and store it.
for i = 1:block_num
    block_index = (i - 1) * block_size;
    
    for j = 1:block_size
        if j ~= index_subtractors(i)
            d_arr(block_index + j)      = cover_image_1d(block_index + j) - best_subtractors(i);
        end
    end
end


% Step H9: Change the data type of payload or secret bits data into int16.
payload_s           = int16(payload);


% Step H10: Consider the difference between -1 and +1 for data hiding (means: -1 ≤ D ≤ +1). 
diff_min            = -1;
diff_max            = 1;


% Step H11: Embedding process happen if the D value is between -1 and +1. If true, then the embedding process will be done.
payload_capacity    = 0;
counter             = 1;
rest_num            = [0, 1, 9];

for i = 1:size_1d
    if d_arr(i) >= diff_min && d_arr(i) <= diff_max && key(i) == 0
        if counter <= length(payload_s)
            stego_image_1d(i) = cover_image_1d(i) + d_arr(i) + payload_s(counter);

            % If the D value satisfy the range, give flag to the key by change the value.
            if(key(i) == 0)
                key(i)  = 2 * randi([2, 4]);
            end

            counter = counter + 1;
        end

        payload_capacity = payload_capacity + 1;

    % If the D value doesn't satisfy the range, then the key can be flagged.
    else
        if(key(i) == 0)
            key(i) = rest_num(randi(length(rest_num)));
        end
    end
end

elapsed_time = toc;
fprintf(['Embedding Payload Process Done with Elapsed Time: ' num2str(elapsed_time) ' s\n\n']);


% Step H12: Reshape the stego image (SI) into 2D array and display the cover image and stego image.
stego_image         = reshape(stego_image_1d, height, width);

figure; image(cover_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Cover Image (Hiding)');

figure; image(stego_image,'CDataMapping','scaled'); colormap('gray');
title('Output: Stego image (Hiding)');


% Step H13: Analysis the payload capacity, payload capacity per pixel, and PSNR.
fprintf('Payload Capacity (int16)\t\t\t: %d\n', payload_capacity);
fprintf('Payload Capacity per Pixel (int16)\t: %f\n', payload_capacity / (width * height));
fprintf('PSNR (int16)\t\t\t\t\t\t: %f\n\n', psnr(stego_image, cover_image));

cover_image         = cast(cover_image, 'uint8');
stego_image         = cast(stego_image, 'uint8');

fprintf('Payload Capacity (uint8)\t\t\t: %d\n', payload_capacity);
fprintf('Payload Capacity per Pixel (uint8)\t: %f\n', payload_capacity / (width * height));
fprintf('PSNR (uint8)\t\t\t\t\t\t: %f\n\n', psnr(stego_image, cover_image));


% Step H14: Export the stego image and the key table.
output_stego_path   = 'E:\Research\Hiding Result\stego_image_nur.tiff';
imwrite(stego_image, output_stego_path, 'tiff');

output_key_path = 'E:\Research\Hiding Result\key_nur.txt';
dlmwrite(output_key_path, reshape(key, 1, []), 'precision','%d');

fprintf('End of Data Hiding Process\n\n\n\n');

% Step H00: Function to get the best substractor in each block
function [best_subtractor, index_subtractor] = find_best_subtractor(block)
    max_count           = 0;
    index_subtractor    = 1;
    best_subtractor     = block(1);

    for i = 1:numel(block)
        current_subtractor  = block(i);
        count               = 0;
        
        for j = 1:numel(block)
            if i ~= j
                diff = block(j) - current_subtractor;
                if abs(diff) <= 1
                    count = count + 1;
                end
            end
        end
      
        if count > max_count
            best_subtractor     = current_subtractor;
            max_count           = count;
            index_subtractor    = i;
        end
    end
end