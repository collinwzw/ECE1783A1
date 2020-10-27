function [Y1, U1, V1] = UpSampling(Y, U, V,factor)
%Get dim of the file from Y component of the frame
width  = size(Y,1);
height = size(Y,2);
nFrame = size(Y,3);

%UpScaling U
n=1;
m=1;
for k=1:1:nFrame
    n=1;
    for i=1:1:width/factor
        m=1;
        for j=1:1:height/factor
            U1(n,m,k)=U(i,j,k);
            U1(n+1,m,k)=U(i,j,k);
            U1(n,m+1,k)=U(i,j,k);
            U1(n+1,m+1,k)=U(i,j,k);
            m=m+2;
        end
        n=n+2;
    end
       
end

%UpScaling V
a=1;
b=1;
for k=1:1:nFrame
    a=1;
    for i=1:1:width/factor
        b=1;
        for j=1:1:height/factor
            V1(a,b,k)=V(i,j,k);
            V1(a+1,b,k)=V(i,j,k);
            V1(a,b+1,k)=V(i,j,k);
            V1(a+1,b+1,k)=V(i,j,k);
            b=b+2;
        end
        a=a+2;
    end
end

%Y remain same
Y1=Y;
end