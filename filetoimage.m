function image=filetoimage(filename)
fid=fopen(filename,'r');
M=fscanf(fid,'%d');
s=size(M);
siz=sqrt(s(1));
im(:,:)=[1];
count=1;
for i =1:siz
    for j=1:siz
        im(i,j)=M(count);
        count=count+1;
    end
end
image=im;
imshow(uint8(image));
end