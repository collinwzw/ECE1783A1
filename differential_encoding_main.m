a=linspace(1,64,64);
n=64;
b=randi([0, 1], [1, n]);
a=reshape(a,[8,8]);
b=reshape(b,[8,8]);
d=differential_encoding(a,b);