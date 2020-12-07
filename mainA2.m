clc;
clear all;
systemSetUp();

tic
% inputFilename = '.\data\foreman_cif.yuv';
% outputFilename = '.\data\foremanY_cif.yuv';
inputFilename = '.\data\CIF.yuv';
outputFilename = '.\data\CIFY.yuv';
v1 = YUVVideo(inputFilename, 352, 288 , 420);
y_only = true;
v1.writeToFile(outputFilename, y_only);

inputFilename = outputFilename;
v1 = YOnlyVideo(inputFilename, 352, 288);

%I frame is 1
%P frame is 0


% %parameter section
block_width = 16;
block_height = block_width;
r = 16;
n = 3;
QP = 4;
I_Period = 1;
nRefFrame = 1;
FEMEnable = true;
FastME = true;
VBSEnable = true;
RCflag = 1;
targetBPPerSecond=2400000;
framePerSecond = 30;
ParallelMode = 0;
%
%pad the video if necessary
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

%creating QP table section
createQPTable = false;
if createQPTable == 1
    %creating QP table
%     QPinputFilename = '.\data\CIF.yuv';
%     QPouputFilename = '.\data\CIFY.yuv';
%     video = YUVVideo(QPinputFilename, 352, 288 , 420);
%     y_only = true;
%     video.writeToFile(QPouputFilename, y_only);
%     video = YOnlyVideo(QPouputFilename, 352, 288);
%     CIF = true;
    QPinputFilename = '.\data\QCIF.yuv';
    QPouputFilename = '.\data\QCIFY.yuv';
    video = YUVVideo(QPinputFilename, 176, 144 , 420);
    y_only = true;
    video.writeToFile(QPouputFilename, y_only);
    video = YOnlyVideo(QPouputFilename, 176, 144);
    [videoWithPadding,v1Averaged] = video.block_creation(video.Y,block_width,block_height);
    intra = false;
    CIF = false;
    c = CreateQPTable(videoWithPadding,block_width, block_height,r,nRefFrame, FEMEnable, FastME, VBSEnable, intra, CIF);
    return;
end

%calculating budget
QPTableInterFilename = '.\result\CIFQPTableInter.txt';
QPTableIntraFilename = '.\result\CIFQPTableIntra.txt';
bitBudget = BitBudget(targetBPPerSecond, framePerSecond,v1WithPadding.width, block_width, QPTableInterFilename, QPTableIntraFilename );

if RCflag == 2
    QP = 6;
    e = EncoderBuildQPTable(v1WithPadding,block_width, block_height,r , QP, 21,nRefFrame, FEMEnable, FastME, VBSEnable, RCflag );
    bitCountRowsVideo = zeros(v1WithPadding.width/block_width, v1WithPadding.numberOfFrames);
    TotalBitInCurrentFrame = zeros(v1WithPadding.width/block_width, v1WithPadding.numberOfFrames);
    TotalBitInCurrentFrame = zeros(v1WithPadding.numberOfFrames);
    for i = 1:1:v1WithPadding.numberOfFrames
        for row=1:1:v1WithPadding.width/block_width
            bitCountRowsVideo(row,i) = sum(e.bitCountVideo(row,:,i));
        end
        TotalBitInCurrentFrame(i) = sum(bitCountRowsVideo(:,i));
        for row=1:1:v1WithPadding.width/block_width
            bitCountRowsVideo(row,i) = bitCountRowsVideo(row,i)/TotalBitInCurrentFrame(i);
        end
    end
end



%* (v1WithPadding.width/block_width);

%encode the video
e = Encoder(v1WithPadding,block_width, block_height,r , QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable,RCflag, bitBudget, ParallelMode);
%%
c=ReverseEntropyEngine_Block(e.OutputBitstream,block_width,block_height,288,352, RCflag);
BlockList = c.BlockList;

%%
d=MotionCompensationEngine_Block(BlockList,block_width,block_height,288,352,FEMEnable,nRefFrame);

toc 
acc_PSNR = 0;
for k=1:1:10
    acc_PSNR = acc_PSNR + psnr(d.DecodedRefVideo(:,:,k),double(v1WithPadding.Y(:,:,k)));
end

totalBit = size(e.OutputBitstream);
fprintf(" configuration: i = %d, r = %d, QP = %d, IP = %d \n",block_width, r, QP, I_Period);
fprintf(" PSNR = %d \n",acc_PSNR );
fprintf(" number of bits for 10 frame = %d \n",totalBit );

%%
Blocks = c.BlockList;
SplitList = [];
for p = 1:1:size (Blocks,2)
    SplitList = [SplitList BlockList(1, p).split];
end
%%
%drawing boxes around blocks
matrixWidth=0;
matrixHeight=0;
p=0;
for k=1:1:d.numberOfFrames
    imshow(uint8(d.DecodedRefVideo(:,:,k)));
    hold on;
    for i=0:1:(d.video_height/block_height) - 1
        for j=0:1:d.video_width/(block_width) -1

            p=p+1;
            matrixHeight = (i) * block_height + 1;
            matrixWidth = (j) * block_width + 1;
            plot([matrixWidth,matrixWidth+block_width],[matrixHeight,matrixHeight],'Color','k')
            plot([matrixWidth,matrixWidth],[matrixHeight,matrixHeight+block_height],'Color','k')
            plot([matrixWidth+block_width,matrixWidth+block_width],[matrixHeight,matrixHeight+block_height],'Color','k')
            plot([matrixWidth,matrixWidth+block_width],[matrixHeight+block_height,matrixHeight+block_height],'Color','k')
            if(SplitList(p)==1)
                plot([matrixWidth+(block_width/2),matrixWidth+(block_width/2)],[matrixHeight,matrixHeight+block_height],'Color','k')
                plot([matrixWidth,matrixWidth+block_width],[matrixHeight+(block_height/2),matrixHeight+(block_height/2)],'Color','k')
                p = p + 3;

            end

        end
    end
    hold off;
    figure
end

%%
% drawing boxes for different reference frame
matrixWidth=0;
matrixHeight=0;
Blocklist= d.BlockList;
blockIndex=0;


for k=1:1:10
    PreviousRefIn = 0;
    imshow(uint8(d.DecodedRefVideo(:,:,k)));

    set(gca,'DataAspectRatioMode','auto')
    set(gca,'Position',[0 0 1 1])
    hold on;
    for i=0:1:(d.video_height/block_height) - 1
        for j=0:1:d.video_width/(block_width) -1
            blockIndex=blockIndex+1;
            matrixHeight = (i) * block_height + 1;
            matrixWidth = (j) * block_width + 1;
            if (Blocklist(blockIndex).frameType == 0)
                 RefIn = BlockList(1,blockIndex).referenceFrameIndex;
                 RefIn = PreviousRefIn - RefIn;
                 PreviousRefIn = RefIn;
                if(RefIn == 1)
                    rectangle('Position',[matrixWidth,matrixHeight,  16 16],'FaceColor',[0, 1, 0, 0.08])
                end
                if(RefIn == 2)
                    rectangle('Position',[matrixWidth,matrixHeight,  16 16],'FaceColor',[0, 0, 1, 0.08])
                end
                if(RefIn == 3)
                    rectangle('Position',[matrixWidth,matrixHeight,  16 16],'FaceColor',[1, 0, 0, 0.08])
                end
            end
            
        end
    end
    hold off;
    figure
end

%%
%drawing arrows around blocks
matrixWidth=0;
matrixHeight=0;
Blocklist= d.BlockList;
blockIndex=0;
for k=1:1:2
    
    imshow(uint8(d.DecodedRefVideo(:,:,k)));

set(gca,'DataAspectRatioMode','auto')
set(gca,'Position',[0 0 1 1])
    hold on;
    Previousmvx = 0;
    Previousmvy = 0;
    for i=0:1:(d.video_height/block_height) - 1
        for j=0:1:d.video_width/(block_width) -1
            blockIndex=blockIndex+1;
            mvx = Blocklist(blockIndex).MotionVector.x;
            mvy = Blocklist(blockIndex).MotionVector.y;
            mvx = Previousmvx - mvx;
            mvy = Previousmvy - mvy;
            Previousmvx = mvx;
            Previousmvy = mvy;
            matrixHeight = (i) * block_height + 1;
            matrixWidth = (j) * block_width + 1;
            xstart = (matrixWidth+Blocklist(blockIndex).block_width/2)/d.video_width;
            xend = (matrixWidth+Blocklist(blockIndex).block_width/2 + mvx)/d.video_width;
            ystart = (matrixHeight+Blocklist(blockIndex).block_height/2)/d.video_height;
            yend = (matrixHeight+Blocklist(blockIndex).block_height/2 + mvy)/d.video_height;
            if (Blocklist(blockIndex).frameType == 0)
                ar = annotation('arrow',[xstart xend],[ystart yend]);
                ar.HeadStyle = 'vback3';
                ar.HeadLength = 1;
                ar.HeadWidth = 5;
            end

        end
    end
    hold off;
    figure
end