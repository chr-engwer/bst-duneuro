function mat=read_duneuro_binary_file(inFile)
% read the binary output from duneuro
% created by juan GPC
% modified and adapted to bst-duneuro toolbox by Takfarinas MEDANI
[inFid,~] = fopen(inFile);

[nRows,nCols]=read_header(inFid);
mat=read_matrix(inFid,nRows,nCols);

fclose(inFid);

end

function [numRows,numCols]=read_header(fid)

char1 = fread(fid,1,'uint8');
char2 = fread(fid,1,'uint8');
if((char1~=double(':')) || (char2~=double(':')))
  error('Something went wrong while reading the binary file');
end

numRows=[];
ni=fread(fid,1,'uint8');
while(ni~=double(':'))
  numRows=cat(2,numRows,ni);
  ni=fread(fid,1,'uint8');
end
ni=fread(fid,1,'uint8');
if(ni~=double(':'))
  error('Something went wrong while reading the binary file');
end
numCols=[];
ni=fread(fid,1,'uint8');
while(ni~=double(':'))
  numCols=cat(2,numCols,ni);
  ni=fread(fid,1,'uint8');
end
ni=fread(fid,1,'uint8');
if(ni~=double(':'))
  error('Something went wrong while reading the binary file');
end

numRows=str2double(char(numRows));
numCols=str2double(char(numCols));

end

function m=read_matrix(fid,numRows,numCols)
  m=fread(fid,numRows*numCols,'double');
  m=reshape(m,[numCols numRows])';
end


