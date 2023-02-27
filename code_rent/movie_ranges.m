function [xrange,xmovies,glm_model] = movie_ranges(isubset)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Builds 
% - movie feature matrix: xmovies
% - compute the index ranges (starting and end index) for each user:
% xranges
% - compute the total, user, and movie averages: glm_model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inputs:
%     isubset             index set of a subset ( e.g. training) of rank
%     data
% outputs:
%     xrange              starting and end index in xdata for each user
%     xmovies             movie feature matrix, huge but very sparse
%                         it contains the residue rank values after
%                         subtracting the averages of users and movies
%                         it contains the rescaled residues 
%     glm_model           stores the total, user, and movie averages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  global   xdata;
  global   kernel_param;
  global   whichVersion;  
  
  % From original file, user and movie index are given:
  userIndex  = 1;
  movieIndex = 2;
  
%   if whichVersion ==1        % For inverted index, see it
%       userIndex   = 2;
%       movieIndex  = 1;
%   end      

  nuser  = kernel_param.nuser;
  nmovie = kernel_param.nmovie;
  ndata  = kernel_param.ndata;
  
% stores the user index ranges, starting and end index in xdata 
% for each user
  xrange = zeros(nuser,2);  
  mdata  = length(isubset);
  disp(size(isubset))
% put the index/userid of every user taken in the set (train or test) and replace the 0 by a 1 at each position in the xranges vector    
  for ii = 1:mdata
    idata = isubset(ii);
    iuser = xdata(idata,userIndex);                   % get a user
    xrange(iuser,2) = xrange(iuser,2) + 1;            % keep track of the number of users in the training set
  end
  
  % ???
  xrange(:,1) = cumsum(xrange(:,2))-xrange(:,2)+1;    % 1= rows wise, 2 = col wise...each element is mad up of sum of acc of the previous entry
  
% $$$   ydata = xdata(isubset,3)/kernel_param.ymax;
% $$$   ydata = kernel_param.ymax*power(ydata,1);
   
  ydata   = xdata(isubset,3);                                     % Means Rank
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Two way clustering  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  
  
  xmovies = sparse(xdata(isubset,userIndex),xdata(isubset,movieIndex),ydata, ...    % squeeze out the zero elements, USe matrix xdata(isubset,1),xdata(isubset,2),ydata to genarete (nuser x nmovies) sparse matrix
                   nuser,nmovie,mdata)';                                            % space is alloctaed for mdta elements, nuser x nmovie matrix is generated
         
%   twoWayClustering(nmovie,nuser,full(xmovies),mdata);
  
% xmovies(xdata(isubset,1),xdata(isubset,2)) = ydata(k)
% computes total, user, and movie averages
% xmovies first index is movie second is users,    % ???? looking wrong?
% thus the rows are the movie features columns are the user features
  disp('GLM');
  
  % Sparse data matrix
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %     u1, u2, u3.....                            %
  %                                                %
  %  m1                                            %      
  %  m2    % rows are  ... mov feature?            %
  %  m3    % cols are  ... user feature?           %  
  %  .                                             %       
  %  .                                             %  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% =1 multiplicative model, =0 additive model  
  kernel_param.iprod = 0;
  
  if kernel_param.iprod == 1 
    [ix,jx,vx]   = find(xmovies);           % Find indices of nonzero elements
    lvx          = log(vx);
     xmovieslog   = sparse(ix,jx,lvx,nmovie,nuser,mdata);  % why log?
%      xmovieslog   = sparse(ix,jx,lvx,nuser,nmovie,mdata);
    col_sum      = sum(xmovieslog,1);
    row_sum      = sum(xmovieslog,2);
    col_sum_eval = sum(xmovies,1);
  else
    col_sum = sum(xmovies,1);
    row_sum = sum(xmovies,2);
    
%      col_sum = sum(xmovies,2);
%     row_sum = sum(xmovies,1);
    
    col_sum_eval = col_sum;
  end
  
  col_num = sum((xmovies~=0), 1);          % ~= --> Not Equal, if all non-zero, then return matrix of all 1's
  row_num = sum((xmovies~=0), 2);
  
%    col_num = sum((xmovies~=0), 2);          % ~= --> Not Equal, if all non-zero, then return matrix of all 1's
%   row_num = sum((xmovies~=0), 1);
  
   col_num_eval = sum((xmovies~=0), 1);
%   col_num_eval = sum((xmovies~=0), 2);
  
  col_num = col_num + (col_num == 0);      % what it is doing
  row_num = row_num + (row_num == 0);
  col_num_eval =  col_num_eval + (col_num_eval == 0);     

  total_sum = sum(col_sum);
  total_num = sum(col_num);           
  total_sum_eval = sum(col_sum_eval);
  
  % Means of rows, col, and total of the matrixs
  total_mean        = total_sum/total_num;  
  col_mean          = col_sum./col_num;
  row_mean          = row_sum./row_num;
  col_mean_eval     = col_sum_eval./col_num_eval;
  
  if kernel_param.iprod==1
    col_mean   = exp(col_mean);             % e^   ... ?
    row_mean   = exp(row_mean);
    total_mean = exp(total_mean);
  end

      
% productive model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xmovies = rank * geomtric mean of total/ (geometric means of user * geometric mean of  movies)%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if kernel_param.iprod==1
for i=1:mdata
      ii     = isubset(i);
      iuser  = xdata(ii,userIndex);
      imovie = xdata(ii,movieIndex);
      xmovies(imovie,iuser) = total_mean * xmovies(imovie,iuser)/ ...
                              (col_mean(iuser) * row_mean(imovie));
    end
  else
      
% additice model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% xmovies = rank + total avarage - user average - movie average  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% .......... Why we are adding the total_mean, while normalizing????
    for i=1:mdata
      ii     = isubset(i);
      iuser  = xdata(ii,userIndex);
      imovie = xdata(ii,movieIndex);
      
%       disp(iuser);
% disp(imovie);
% disp(',,,,,,,,,,,,,,,,,');

      xmovies(imovie,iuser) = xmovies(imovie,iuser)-col_mean(iuser) ...
                              -row_mean(imovie) + total_mean;


%       xmovies(iuser,imovie) = xmovies(iuser,imovie)-col_mean(imovie) ...
%                               -row_mean(iuser) + total_mean;                    
    end
  end
    
  
% $$$   xmagnitude=max(max(abs(xmovies)));
% $$$   xmovies=0.99*kernel_param.ymax*xmovies/xmagnitude;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the discretized residues of the ranks 
% compute grid  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  ymax   = full(max(max(xmovies)));         % ??
  ymin   = full(min(min(xmovies)));  
  ystep  = kernel_param.ystep;
  
  ymax  = ceil((ymax + ystep)/ystep)*ystep; % Round towards plus infinity.
  ymin  = floor((ymin-ystep)/ystep)*ystep;  % Round towards Negative infinity.  
  if ymax>kernel_param.ymax
    kernel_param.ymax = ymax;               % output kernel comp
  end
  if ymin<kernel_param.ymin
    kernel_param.ymin = ymin;
  end
  
  kernel_param.yrange = (ymax-ymin)/ystep;

  xmovies = round(xmovies/ystep)*ystep;     %?, xmovies initialy have residual, now why this?
  
  glm_model.col_mean        = col_mean;
  glm_model.row_mean        = row_mean;
  glm_model.total_mean      = total_mean;
  glm_model.col_mean_eval   = col_mean_eval;
  
  

