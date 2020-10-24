function [R,G,B]=YUV_RGB_CSC(CscFormulasPart1,CscFormulasPart2,Y,U,V,OutputImageAddress)
%Get dim of the file from Y component of the frame
width  = size(Y,1);%352
height = size(Y,2);%288
nFrame = size(Y,3);%300
Coeff1=CscFormulasPart2(1,1);
Coeff2=CscFormulasPart2(2,1);
Coeff3=CscFormulasPart2(3,1);
for k=1:1:nFrame
    for i=1:1:width
        for j=1:1:height
            n=[double(Y(i,j,k))-Coeff1;double(U(i,j,k))-Coeff2;double(V(i,j,k))-Coeff3];
            b=Y(i,j,k)-Coeff1;
            a=CscFormulasPart1*n;
            R(i,j)=a(1);
            G(i,j)=a(2);
            B(i,j)=a(3);
        end
    end
    im(:,:,1)=R(:,:)';
    im(:,:,2)=G(:,:)';
    im(:,:,3)=B(:,:)';
    Image=uint8(im);
    imwrite(uint8(im),[OutputImageAddress, int2str(k), '.png']);
end

end