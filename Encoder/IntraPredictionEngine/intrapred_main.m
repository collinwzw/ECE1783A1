a=round(255*rand(256));
block_height=8;
block_width=8;
k=1;
l=1;
for i=1:block_height:size(a,1)  
    for j=1:block_width:size(a,2)
        e=IntraPredictionEngine(a,block_height,block_width,i,j);
        frame(i:i+block_width-1,j:j+block_height-1)=e.predictedblock;
        mode(k,l)=e.mode;
        l=l+1;
    end
    l=1;
    k=k+1;
end
resi=frame-a;
v=1;
c=1;
ori_frame(1:size(a,1),1:size(a,2))=0;
for i=1:block_height:size(a,1)  
    for j=1:block_width:size(a,2)
        mode_val=mode(v,c);
        f=IntraPredictionEngine_decode(resi,block_height,block_width,i,j,mode_val,ori_frame);
        ori_frame(i:i+block_width-1,j:j+block_height-1)=f.decoded_block;
        
        c=c+1;
    end
    c=1;
    v=v+1;
end
%o=intraprediction_engine(a,b,8);

% value=dct2(b);
% valu1=idct2(value);