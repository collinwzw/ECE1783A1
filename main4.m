clc;
clear all;
systemSetUp();

tic
inputFilename = '.\data\foreman_cif.yuv';
outputFilename = '.\data\foreman_cifY.yuv';
v1 = YUVVideo(inputFilename, 352, 288 , 420);
y_only = true;
v1.writeToFile(outputFilename, y_only);

inputFilename = '.\data\foreman_cifY.yuv';
v1 = YOnlyVideo(inputFilename, 352, 288);

%I frame is 1
%P frame is 0

% %parameter section
block_width = 16;
block_height = block_width;
r = 4;
n = 3;
QP = 7 ;
I_Period = 8;
nRefFrame =4;
FEMEnable = true;
FastME = true;
VBSEnable = true;
% 
%pad the video if necessary
[v1WithPadding,v1Averaged] = v1.block_creation(v1.Y,block_width,block_height);

%encode the video
e = Encoder(v1WithPadding,block_width, block_height,r ,n, QP, I_Period,nRefFrame, FEMEnable, FastME, VBSEnable);

c=ReverseEntropyEngine_Block(e.OutputBitstream,block_width,block_height,288,352);
BlockList = c.BlockList;


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
% fprintf(" SAD for frame 1= %d \n",e.SADPerFrame(1) );
% fprintf(" SAD for frame 2= %d \n",e.SADPerFrame(2) );
% fprintf(" SAD for frame 3= %d \n",e.SADPerFrame(3) );
% fprintf(" SAD for frame 4= %d \n",e.SADPerFrame(4) );
% fprintf(" SAD for frame 5= %d \n",e.SADPerFrame(5) );
% fprintf(" SAD for frame 6= %d \n",e.SADPerFrame(6) );
% fprintf(" SAD for frame 7= %d \n",e.SADPerFrame(7) );
% fprintf(" SAD for frame 8= %d \n",e.SADPerFrame(8) );
% fprintf(" SAD for frame 9= %d \n",e.SADPerFrame(9) );
% fprintf(" SAD for frame 10= %d \n",e.SADPerFrame(10) );
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
%drawing boxes for different reference frame
% matrixWidth=0;
% matrixHeight=0;
% Blocklist= d.BlockList;
% blockIndex=0;
% for k=1:1:d.numberOfFrames
%     imshow(uint8(d.DecodedRefVideo(:,:,k)));
%     hold on;
%     for i=0:1:(d.video_height/block_height) - 1
%         for j=0:1:d.video_width/(block_width) -1
%             blockIndex=blockIndex+1;
%             matrixHeight = (i) * block_height + 1;
%             matrixWidth = (j) * block_width + 1;
%             if(Blocklist(blockIndex))
%                 rectangle('Position',[160 160 16 16],'FaceColor',[0, 0, 1, 0.5])
%             end
% 
%         end
%     end
%     hold off;
%     figure
% end

%%
%drawing arrows around blocks
matrixWidth=0;
matrixHeight=0;
Blocklist= d.BlockList;
blockIndex=0;
for k=1:1:d.numberOfFrames
    
    imshow(uint8(d.DecodedRefVideo(:,:,k)));
set(gcf,'MenuBar','none')
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