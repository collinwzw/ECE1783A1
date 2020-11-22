clc;
clear all;
block_width=16;
block_height=16;
OutputBitstream = [];
OutputBitstream1 = [];
video_width=128;
video_height=128;
QP = 4;
ReferenceFrame(1:video_width,1:video_height) = uint8(127);
b=Block(ReferenceFrame, 1,1, 16, 16);
b.data(1,:)=0;
b.data(2,:)=10;
b.data(3,:)=30;
b.data(4,:)=30;
b.data(5,:)=60;
b.data(6,:)=60;
b.data(7,:)=90;
b.data(8,:)=90;
b.data(9,:)=120;
b.data(10,:)=120;
b.left_width_index = 3;
b.QP=2;
b.referenceFrameIndex = 1;
b.frameType = 1;
b.MotionVector = MotionVector(0,0);
b.split = 0;

b1=b;
b1.data=transpose(b.data);

b3=b;
b3.split = 1;
b3.block_width=8;
b3.block_height=8;
b3.data=b.data(1:8,1:8);

en = EntropyEngine_Block(b);
OutputBitstream = [OutputBitstream en.bitstream];

en=0;
en = EntropyEngine_Block(b1);
OutputBitstream = [OutputBitstream en.bitstream];

en=0;
en = EntropyEngine_Block(b3);
OutputBitstream = [OutputBitstream en.bitstream];


c=ReverseEntropyEngine_Block(OutputBitstream,block_width,block_height,video_width,video_height);
BlockList = c.BlockList;
i=2;
r = RescalingEngine(BlockList(i));
BlockList(i).data=idct2(r.rescalingResult);
