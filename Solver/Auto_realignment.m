function  [realignFolderSub, Nshift]=Auto_realignment(RawDir, Nnum) 
% Auto-registration preprocess for correcting system-error pixel-realignment 
%
% The Code is created based on the method described in the following paper 
%   [1]  ZHI LU etc,
%        "A practical guide to scanning light-field microscopy with digital adaptive optics"
%        submitted to Nature Protocols, 2021
%
%    Contact: ZHI LU (luz18@mails.tsinghua.edu.cn)
%    Date  : 07/24/2021

rotation = 0;        % Angle of clockwise rotation of scanning light field images
preResize = 0.9995;  % Scanning light field images resizing scale (The default value is 1)
autoCenterMode = 1;  % Automatic identification for the center point of light field (on/off)

dirOutput=dir(fullfile(RawDir,'*.0.tiff')); % information of rawdata
source={dirOutput.name}';                   % filename list of rawdata

for sourceIdx = 1:size(source,1)
    if(source{sourceIdx}(end - 8) == 'C')
        continue;
    end
    try
        ticer = tic;
        front = source{sourceIdx}(1:end-6);
        dirOutput=dir(fullfile(RawDir,strcat(front, '*')));
        this_name = {dirOutput.name}';
        Itmp = imread(strcat(RawDir, '/',source{sourceIdx}), 1);
        [h,w] = size(Itmp);
        Nx = floor(w * preResize / (2*Nnum)) - 2;
        Ny = floor(h * preResize / (2*Nnum)) - 2;
        imgSize = h * w * 2;
        fileSizes = cell2mat({dirOutput.bytes});
        imgCount = 0;
        for fileIdx = 1:size(fileSizes, 2)
            imgCount = imgCount + floor(fileSizes(fileIdx) / imgSize);
        end
        name = strcat(RawDir, '/',source{sourceIdx});
        [laserCountIdxS, laserCountIdxE] = regexp(front, '(?<=_LaserCount)[^/]+(?=_)');
        frameJump = str2num(front(laserCountIdxS:laserCountIdxE)); 
        [shiftIdxS, shiftIdxE] = regexp(front, '(?<=_)[[0-9]]+(?=x)');
        Nshift = str2num(front(shiftIdxS(end):shiftIdxE(end)));
        if(rotation == 0)
            confName = sprintf('./%dx%d.conf.sk.png', Nshift, Nshift);
        else
            confName = sprintf('./%dx%d.conf.sk.rot%d.png', Nshift, Nshift, rotation);
        end
        
        groupMode = 1;       % "0": interval mode (for 1-9, 10-18,...); "1": sliding-window mode (for 1-9, 2-10,...) (The default value is 1)
        groupCount = floor(imgCount / frameJump);
        if(Nshift ~= 1)
            if(groupMode == 1)
                groupCount = groupCount - Nshift * Nshift + 1;
            else
                groupCount = floor(groupCount / (Nshift * Nshift));
            end
        end
        clear centerviewList
        for startFrame = 0:frameJump - 1
            autoCenterFrame = startFrame; % The image frame used for center view identification
            realignFolder = strcat('Data_realign/',source{sourceIdx}(1:end-7), '__', num2str(startFrame));
            mkdir(realignFolder);
            realignFolderSub = strcat(realignFolder,'/realign');
            mkdir(realignFolderSub);
            realignName =  strcat(realignFolderSub, '/test');

            centerView = strcat(realignFolder, '/centerView.tiff');


            centerviewList(startFrame+1, :) = strcat(centerView(1:end-4),'0.tif'); % TODO: now we only support .0.tif
            
            centerX=1024;        % center point selection (x-direction) manually£¬invalid when autoCenterMode = 1
            centerY=1024;        % center point selection (y-direction) manually£¬invalid when autoCenterMode = 1
            if(autoCenterMode == 1)
                [centerX, centerY, centerProb] = AutoCenter(imread(name, autoCenterFrame + 1), Nnum);
            else
                centerProb = 999;
            end
            WriteCenterPt(realignFolder, centerX, centerY, centerProb, imread(name, autoCenterFrame + 1));
            addpath('./Util/');
            
            realignMode = 'LZ';  % Default, no need to modify
            resize = 0;          % "0": No upsampling; "1":Upsamping Nnum/Nshift times in spatial domain (The default value is 0)
            
            % pixel-realignment (c++ program)
            % ./ReAlign [CaptureNshift] [OutputFile] [RawData]
            % [RawDataIdx] [CenterPixelX] [CenterPixelY]
            % [PickLensSizeX] (DataGroup = 1) (GroupMode = 0){0=individual, 1=continues} (ShiftConfigFile = Auto)
            % (FrameJump = 1) (Resize = 1) (ResizeShift = 13) (PickLensSizeY = X)

            command = sprintf('ReAlign %d %s %s %d %d %d %d %d %d %s %d %d %d %d %s %s %d %f',...
            Nshift, realignName, name, startFrame, centerX, centerY, Nx,...
            groupCount, groupMode, confName, frameJump, resize, Nnum, Ny, realignMode, centerView, rotation, preResize);
            system(command);

        end
        LaserMergeOption = 1;%=1 means merging of all channels£¬=0 means no merging channels
        if(frameJump > 1 && LaserMergeOption ~= 0)
            fprintf('working on channel merge...\n');
            channel = min([3, frameJump]);
            mergeView = uint16(zeros((Ny*2+1)*Nshift, (Nx*2+1)*Nshift, 3, groupCount));
            outPath = strcat(source{sourceIdx}(1:end-7), '__merge');
            mkdir(outPath);
            for frameIdx = 1:groupCount
                for channelIdx = 1:channel
                    if(exist(centerviewList(channelIdx, :), 'file'))
                        mergeView(:,:,channelIdx,frameIdx) = imread(centerviewList(channelIdx, :),  frameIdx);
                    end
                end
            end
            for channelIdx = 1:channel
                mergeView(:,:,channelIdx,:) = double(mergeView(:,:,channelIdx,:)) / double(max(max(max(max(mergeView(:,:,channelIdx,:)))))) * 255 * 2;
            end
            mergeView = uint8(mergeView);
            % imwrite time-lapse multi-color center view
            for frameIdx = 1:groupCount
                if(frameIdx == 1)
                        imwrite(squeeze(mergeView(:,:,:,frameIdx)), strcat(outPath,'/centerViewMerge_channel.tif')); 
                    else
                        imwrite(squeeze(mergeView(:,:,:,frameIdx)), strcat(outPath,'/centerViewMerge_channel.tif'), 'WriteMode', 'append');
                end
            end
        end
        fprintf('Realign %s, frame count : %d, cost %f sec\n', source{sourceIdx}, groupCount, toc(ticer));
    catch
       warning('we met some error!'); 
    end
end

function [] = WriteCenterPt(path, CX, CY, prob, img) % write center view
    txt = fopen(strcat(path,'/CenterPoint.txt'), 'w');
    fprintf(txt, 'X = %d\nY = %d\nprob = %.2f%%\n##Both (X,Y) in [0, N-1]', CX, CY, prob*100);
    fclose(txt);
    imwrite(img, strcat(path,'/UsedImg.tiff'));
end

function [Xcenter,Ycenter, prob] = AutoCenter(img, Nnum) % Automatic identification algorithm

    SUB_NUM = 3; % number of blocks
    SUB_MAX_RANGE_RATIO = 5; % pixels
    MAX_AREA_TRUST_RATIO = 4;% confidence
    img = double(img);
    fullX = size(img, 2);
    fullY = size(img, 1);

    ansList = zeros(1 + MAX_AREA_TRUST_RATIO + SUB_NUM*SUB_NUM, 3);
    fprintf('Full Image :');
    [ansList(1,1), ansList(1,2), ansList(1,3)] = AutoCenterSub(img, Nnum, 0, 0);
    fprintf('\n');
    maxImg = max(img(:));
    [maxPosY, maxPosX] = find(img == maxImg);
    maxPosX = maxPosX(round(size(maxPosX, 1) / 2));
    maxPosY = maxPosY(round(size(maxPosY, 1) / 2));
    
    rangeSX = round(maxPosX - fullX / SUB_MAX_RANGE_RATIO);
    if(rangeSX < 1) rangeSX = 1; end
    rangeEX = round(maxPosX + fullX / SUB_MAX_RANGE_RATIO);
    if(rangeEX > fullX) rangeEX = fullX; end
    
    rangeSY = round(maxPosY - fullY / SUB_MAX_RANGE_RATIO);
    if(rangeSY < 1) rangeSY = 1; end
    rangeEY = round(maxPosY + fullY / SUB_MAX_RANGE_RATIO);
    if(rangeEY > fullY) rangeEY = fullY; end
    fprintf('Lightest x%d:', MAX_AREA_TRUST_RATIO);
    [ansList(2,1), ansList(2,2), ansList(2,3)] = ...
        AutoCenterSub(img(rangeSY : rangeEY, rangeSX : rangeEX), Nnum, rangeSX - 1, rangeSY - 1);
    fprintf('\n');
    ansList(2:2+MAX_AREA_TRUST_RATIO-1, :) = repmat(ansList(2,:), [MAX_AREA_TRUST_RATIO, 1]);
    
    anchorPtX = zeros(SUB_NUM+1, 1);
    for i = 0:SUB_NUM
        anchorX = round(1 + i * fullX/SUB_NUM);
        if(anchorX > fullX) anchorX = fullX; end
        anchorPtX(i+1) = anchorX;
    end
    anchorPtY = zeros(SUB_NUM+1, 1);
    for i = 0:SUB_NUM
        anchorY = round(1 + i * fullY/SUB_NUM);
        if(anchorY > fullY) anchorY = fullY; end
        anchorPtY(i+1) = anchorY;
    end
    
    idx = 1 + MAX_AREA_TRUST_RATIO + 1;
    
    for i = 1:SUB_NUM % x direction
        for j = 1:SUB_NUM % y direction
            fprintf('Sub X=%d Y=%d:', i,j);
            [ansList(idx,1), ansList(idx,2), ansList(idx,3)] = ...
                AutoCenterSub(img(anchorPtY(j) : anchorPtY(j+1), anchorPtX(i) : anchorPtX(i+1)), Nnum, anchorPtX(i) - 1, anchorPtY(j) - 1);
            distance = sqrt((i - ((SUB_NUM + 1) /2))^2 + (j - ((SUB_NUM + 1) /2))^2);
            prob_loss = 1 - (distance / SUB_NUM);
            fprintf('prob loss ratio = %.2f\n',  prob_loss);
            ansList(idx,3) = ansList(idx,3) * prob_loss;
            idx = idx + 1;
        end
    end
    savedAnsList = ansList;
    ansList(:,3) = ansList(:,3) / sum(ansList(:,3));
    ansList(:,1) = ansList(:,1) .* ansList(:,3);
    ansList(:,2) = ansList(:,2) .* ansList(:,3);
    myAns = round([sum(ansList(:,1)), sum(ansList(:,2))]);
    prob = 0;
    probCount = 0;
    for i = 1:size(savedAnsList, 1)
        if(myAns == savedAnsList(i, 1:2))
            probCount = probCount + 1;
            prob = prob + savedAnsList(i, 3);
        end
    end
    if(probCount ~= 0)
        prob = prob / probCount;
    end
    Xcenter = myAns(1) + floor(size(img,2) / Nnum / 2) * Nnum;
    Ycenter = myAns(2) + floor(size(img,1) / Nnum / 2) * Nnum;
    fprintf('AutoCenter found x = %d, y = %d (range from 0~[size-1]), credibility = %.2f%%, check at ImageJ\n', Xcenter, Ycenter, prob*100);
end

function [Xcenter, Ycenter, prob] = AutoCenterSub(img, Nnum, x_offset, y_offset) % Automatic identification algorithm in the sub-region
    
    BEST_RATIO = 0.3;
    WORST_RATIO = 0.9;

    img = double(img);
    img = img ./ max(img(:));
    img = img.^2;
    kernal = fspecial('gaussian',[Nnum,Nnum],3);
    img = imfilter(img, kernal);
    locMatrix = zeros(Nnum, Nnum);
    for i = 1:Nnum
        for j = 1:Nnum
            picMat = img(i:Nnum:end, j:Nnum:end);
            avg = mean(mean(picMat));
            picMat(picMat < avg) = 0;
            hugePos = find(picMat ~= 0);
            locMatrix(i,j) = sum(picMat(:)) / size(hugePos, 1);
        end
    end
    
    sumX = sum(locMatrix);
    sumY = sum(locMatrix,2);
    sumX = sumX + circshift(sumX, 1, 2);
    sumY = sumY + circshift(sumY, 1, 1);
    darkX = 1;
    for i = 1:Nnum
        if(sumX(i) < sumX(darkX))
            darkX = i;
        end
    end
    darkY = 1;
    for i = 1:Nnum
        if(sumY(i) < sumY(darkY))
            darkY = i;
        end
    end
    Xcenter = mod(darkX + floor(Nnum / 2) - 1 + x_offset, Nnum);
    Ycenter = mod(darkY + floor(Nnum / 2) - 1 + y_offset, Nnum);
    prob = (WORST_RATIO - min(min(locMatrix)) / max(max(locMatrix))) / (WORST_RATIO - BEST_RATIO);
    if(prob > 1) 
        prob = 1; 
    elseif(prob < 0) 
        prob = 0; 
    end
    fprintf('AutoCenterSub x = %d, y = %d, prob = %f ', Xcenter, Ycenter, prob);
end




end

