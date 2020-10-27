a=round(255*rand(8));
b=a;
a(2:size(a,1),2:size(a,2))=0;
o=intraprediction_engine(a,b,8);

% value=dct2(b);
% valu1=idct2(value);