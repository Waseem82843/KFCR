function [nuser,nmovie,ndata]=movie_data_preload(sdir,sfile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loads 
%  - the data files
%  - transform the user and the movie indeces into continues, gap free,
%  range
%  -sort the data items ( user,movie,rank) into ascending order 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% inputs
%     sdir        data directory name
%     sfile       data file name
% outputs
%     nuser       number of users
%     nmovie      number of movies
%     ndata       number of ranks  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  global xdata;
  global fdata;
  global gdata;
  global kernel_param;
  global whichVersion;
  global xdata_ub; 
  
  
  % From original file, user and movie index are given:
  userIndex  = 1;
  movieIndex = 2;
  ndataIndex = 1;  
  
  % Infact, it will replace the names, i.e. users (actual name) will be movies and 
  % movies (actual name) will be users 
%   if whichVersion==1        % For inverted index, see it
%       userIndex  = 2;
%       movieIndex = 1;      
%   end
      
  if kernel_param.idataset==0
    xdata=dlmread([sdir,sfile]);
%     sfileg='genre1.dat';
%      sfilef='director.dat';
%      fdata=dlmread([sdir,sfilef]);
%       gdata=dlmread([sdir,sfileg]);
  else
% $$$     sdelimit='::';
% $$$     [xdata]=movie_data_txt(sdir,sfile,sdelimit,kernel_param);
    sdelimit=',';
    xdata=dlmread([sdir,sfile],sdelimit);
  end
  
  if(whichVersion==1)    % ib
     [xdata(:,1),xdata(:,2)] = deal(xdata(:,2),xdata(:,1));
  end
  
%  [mitem,nvar]=size(xdata);
  
%  nuser=kernel_param.nuser;
%  nmovie=kernel_param.nmovie;
%  ndata=kernel_param.ndata;



  xdata = xdata(:,1:3);
  
  nuser  = max(xdata(:,userIndex));        
  nmovie = max(xdata(:,movieIndex));        
  ndata  = size(xdata,ndataIndex);                 
  
% transform the user and movie indeces into a continous range

  disp('compress range of movies and users');
  disp(nuser);    
  disp(nmovie);
  disp(ndata);
  
% movies
  xmovie0 = zeros(nmovie,2);
  xuser0  = zeros(nuser,2);
  for i=1:ndata  
    iuser  = xdata(i,userIndex);
    imovie = xdata(i,movieIndex);
    xmovie0(imovie,1) = xmovie0(imovie,1)+1;
    xuser0(iuser,1)   = xuser0(iuser,1)+1;
    if mod(i,1000000)==0
      disp(i)
    end
  end
  
% users  
  j=1;
  for i=1:nuser
    if xuser0(i,1)>0
      xuser0(i,2)=j;
      j=j+1;
    end
  end
  nuser=j-1;
  
% movies
  j=1;
  for i=1:nmovie
    if xmovie0(i,1)>0
      xmovie0(i,2)=j;
      j=j+1;
    end
  end
  nmovie=j-1;
  
  
  for i=1:ndata
    iuser  = xdata(i,userIndex);
    imovie = xdata(i,movieIndex);
    xdata(i,userIndex)  = xuser0(iuser,2);
    xdata(i,movieIndex) = xmovie0(imovie,2);
    if mod(i,1000000)==0
      disp(i);
    end
  end
%  disp(xdata);
  disp('Sorting begins');
  xdata0 = sortrows(xdata);
  xdata  = xdata0;
  disp('Sorting done');
%   disp(xdata);
  
  if(whichVersion==1)
      xdata_ub = xdata;
  end
  
  
  return;
  
% ************************************************
function [xdata]=movie_data_txt(sdir,sfile,sdelimit,kernel_param)

  ndata=kernel_param.ndata;
  xdata=zeros(ndata,3);
  
  fid=fopen([sdir,sfile]);
  iline=1;
  while 1
    tline=fgetl(fid);
    if ~ischar(tline)
      break
    end
    [x1,x2,x3,x4]=strread(tline,'%f::%f::%f::%s');
    xdata(iline,1)=x1;
    xdata(iline,2)=x2;
    xdata(iline,3)=x3;
    iline=iline+1;
    if mod(iline,10000)==0
      disp(iline);
    end
  end
  fclose(fid);
  
  xdata=xdata(1:iline-1,:);
  

  xdata=xdata(1:iline-1,:);