function [xalpha]=movie_solver(KK,isubset,xranges,xmovies,C,D,optim_param, whichOption)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% solves the maximum margin based optimization problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input: 
%       KK          kernel, not used, golbal variables used instead of
%       isubset     index of training items
%       xranges     index ranges of training movies for all users in xdata
%       xmovies     movie feature vectors in training
%       C           penalty constant
%       D           penalty constant, not used
%       optim_param   optimization parameters   
%       whichOption   which kernel to generate? 1=rating, 2= genre,
%                     3=bag-of-words
% Output:
%       xalpha      contains the optimal dual solution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  global xdata;         % (user,movie,rank) 
  global KXmfull;       % full input kernel  for rat
  global KXmcfull;      % full input kernel  for rat (corr)
  global KXgfull;       % full input kernel  for genre
  global KXffull;       % full input kernel  for features
  global KXXfull;       % full input kernel for all 
  global KYfull;        % full output kernel
  global kernel_param;  % parameters
  
  global whichVersion;  
  
  % From original file, user and movie index are given:
  userIndex  = 1;
  movieIndex = 2;
  
%   if whichVersion ==1        % For inverted index, see it
%       userIndex   = 2;
%       movieIndex  = 1;
%   end   
  
  tic;
  
  nuser  = kernel_param.nuser;
  nmovie = kernel_param.nmovie;
  ndata  = length(isubset);
  
  ymax   = kernel_param.ymax;
  ymin   = kernel_param.ymin;
  ystep  = kernel_param.ystep;
  
  xnuser = zeros(nuser,1);
  
  niter  = optim_param.niter;
%  niter=25;


 disp(size(nuser));
 disp(size( nmovie));
 disp(size( xranges));
 disp(size( xdata));
 disp(size( KXXfull));
 


  disp('Preparing the solver input');
  
% collects in lmovies the indeces of all occurances of every movie 
  lmovies  = cell(nmovie);
  xnmovies = zeros(nmovie,1);
  for ii=1:ndata
    i                = isubset(ii);
    imovie           = xdata(i,movieIndex);
    xnmovies(imovie) = xnmovies(imovie)+1;
  end

  for imovie=1:nmovie
    lmovies{imovie}  = zeros(xnmovies(imovie),1);
  end
  
  xpmovies=ones(nmovie,1);
  
  for ii=1:ndata    
    i                                 = isubset(ii);
    imovie                            = xdata(i,movieIndex);
    lmovies{imovie}(xpmovies(imovie)) = ii;
    xpmovies(imovie)                  = xpmovies(imovie)+1;
  end

% reweighting margin and slacks  
%  xmargin_movie=power(1+sum(abs(xmovies),2),0.1);
%  xmargin_user=power(1+sum(abs(xmovies),1),0.1)';
% $$$   xmargin_movie=log(1+sum(abs(xmovies),2));
% $$$   xmargin_user=log(1+sum(abs(xmovies),1))';
% $$$   xsum_movie=sum(xmovies~=0,2);
% $$$   xsum_user=sum(xmovies~=0,1)';
% $$$ % margin reweighting original was =1 for all users  
% $$$   xweight_user=ndata*xmargin_user/(xmargin_user'*xsum_user);
% $$$ % slack reweighting original was =C for all movies  
% $$$   xweight_movie=ndata*xmargin_movie/(xmargin_movie'*xsum_movie);

% assume uniform weighting
  xweight_user=ones(nuser,1);
  xweight_movie=ones(nmovie,1)*C;
% vector of dual variables  
  xalpha=zeros(ndata,1);
% line search variable  
  tau=0;
% index of the nonzero item in the solution of the subproblem for each movie  
  ixalpha_star=zeros(nmovie,3);
% previous gradient  
  xnabla0_prev=zeros(ndata,1);
% initialization of previous gradient
  for iu=1:nuser
    istart=xranges(iu,1);
    nlength=xranges(iu,2);
    if nlength>0
        xnabla0_prev(istart:istart+nlength-1)=-xweight_user(iu);
    end
  end
  
  disp('Solving optimization problem'); 
% conditional gradient iteration
  for it=1:niter
% current gradient
    xnabla0=zeros(ndata,1);
%    tic;
% compute the gradient user wise
    for iu=1:nuser      
      istart=xranges(iu,1);     % movie index starts for user iu
      nlength=xranges(iu,2);    % movie index ends for user iu
      if nlength>0              % is there any movie ranked by the user
        xnabla0_prev_s=xnabla0_prev(istart:istart+nlength-1);
        iuser_index=find(ixalpha_star(:,2)==iu);
        if length(iuser_index)>0
          imovies    = ixalpha_star(iuser_index,3);
          irange     = isubset(istart:istart+nlength-1);
          ixrange    = xdata(irange,movieIndex);
          ixsubrange = xdata(irange(imovies),movieIndex);

          iyrange    = full(xmovies(ixrange,iu));
          iyrange    = round(1+(iyrange-ymin)/ystep);

          iysubrange = full(xmovies(ixsubrange,iu));
          iysubrange = round(1+(iysubrange-ymin)/ystep);

          if(whichOption ==1)
            KKX = KXmfull(ixrange,ixsubrange);  % read user related input subkernel
          %elseif(whichOption ==2)
           % KKX = KXgfull(ixrange,ixsubrange);  % read user related input subkernel
          %elseif(whichOption ==3)
           % KKX = KXffull(ixrange,ixsubrange);  % read user related input subkernel
          elseif(whichOption ==4)
            KKX = KXXfull(ixrange,ixsubrange);  % read user related input subkernel
          else
            KKX = KXmcfull(ixrange,ixsubrange);  % read user related input subkernel
              
          end
          
          KKY           = KYfull(iyrange,iysubrange);   % read user related output subkernel
          KKZ           = KKX.*KKY;                     % tensor product of input and output
          xnabla_star   = C*KKZ*xweight_movie(imovies); 
% compute new gradient based on the soultion of the subproblem and the
% previous gradient
          xnabla0(istart:istart+nlength-1)=xnabla0(istart:istart+nlength-1)+ ...
              tau*xnabla_star;
        end  
        xnabla0(istart:istart+nlength-1)=xnabla0(istart:istart+nlength-1)+ ...
            (1-tau)*xnabla0_prev_s-tau;
      end
    end
% save the user specific gradient      
    xnabla0_prev = xnabla0;
%    disp(toc);
    
% find optimum solution for the subproblems
    ixalpha_star = zeros(nmovie,3);  % index of nonzero items of the solution
%    tic;
% for each movie enumerate the corresponding constraints    
    for imovie = 1:nmovie        
      iusers = lmovies{imovie};   % occurances of the movie imovie 
      if length(iusers)>0
%        disp([imovie,max(iusers)]);
% find the minimum component of the gradient
          [vm,im] = min(xnabla0(iusers));     
% collect the position in the gradient with minimum value           
          imall   = find(xnabla0(iusers)==vm);
% choose one randomly          
          imp = round(rand(1)*length(imall)); 
          if imp==0
            imp=1;
          end
          im = imall(imp);
% if the minimum component is negative then there is nonzero item in the
% solution
          if vm<0           
            iglob=iusers(im);
            ixalpha_star(imovie,1)=iglob;
% binary search for user index corresponding to the minimum value
            iuser  = ceil(nuser/2);
            ibegin = 1;
            iend   = nuser;
            istat  = 1;
            while istat==1
              istart = xranges(iuser,1);
              nlength = xranges(iuser,2);
              if iglob>=istart
                if iglob<istart+nlength
% store the user with minimum value and the index for the movie 
                  ixalpha_star(imovie,2) = iuser;
                  ixalpha_star(imovie,3) = iglob-istart+1;
                  istat=0;
                else
                  ibegin = iuser;
                  iuser  = round((ibegin+iend)/2);
                  if iuser==ibegin
                    iuser = iend;
                  end
                end
              else 
                iend = iuser;
                iuser=round((ibegin+iend)/2);
                if iuser==iend
                  iuser=ibegin;
                end
              end
            end
          end
      end
       if mod(im,1000)==0
%        disp([it,im]);
       end
    end
%    disp(toc);
% line search: 
% find best convex combination (tau) of the solution of the subproblem and
% the old solution
    
%    tic;
    xdelta=-xalpha;
    for imovie=1:nmovie
      if ixalpha_star(imovie,1)>0
        xdelta(ixalpha_star(imovie,1))=xdelta(ixalpha_star(imovie,1))+ ...
            C*xweight_movie(imovie);
      end
    end
%    xnumerator=-sum(xnabla0.*xdelta)+sum(xdelta);
    xnumerator=-sum(xnabla0.*xdelta);
    xdenominator=0;
    for iu=1:nuser
      istart  = xranges(iu,1);
      nlength = xranges(iu,2);
      if nlength>0
        xdeltas = xdelta(istart:istart+nlength-1);
        inzero  = find(xdeltas);
        if length(inzero)>0
          irange=isubset(istart:istart+nlength-1);
           ixsubrange = xdata(irange(inzero),movieIndex);
           ixsubrange = xdata(irange(inzero),userIndex);
          iysubrange = full(xmovies(ixsubrange,iu));
          
          iysubrange = round(1+(iysubrange-ymin)/ystep);
          
          if(whichOption==1)
            KKX = KXmfull(ixsubrange,ixsubrange);
          %elseif(whichOption==2)
           % KKX = KXgfull(ixsubrange,ixsubrange);
          %elseif(whichOption==3)
           % KKX = KXffull(ixsubrange,ixsubrange);
          elseif(whichOption==4)
            
            KKX = KXXfull(ixsubrange,ixsubrange);
          else
            KKX = KXmcfull(ixsubrange,ixsubrange);
          end
          
          KKY = KYfull(iysubrange,iysubrange);
          KKZ = KKX.*KKY;
          
%          xdenompart=xdeltas(inzero)'*KKZ*xdeltas(inzero);
% $$$           if prod(size(xdenompart))~=1
% $$$             disp(xdenompart);
% $$$           end
          xdenominator = xdenominator+xdeltas(inzero)'*KKZ*xdeltas(inzero);
        end
      end
      if mod(iu,1000)==0
%        disp([it,iu]);
      end
    end
    
    try
      tau = xnumerator/xdenominator;
    catch
      disp([xnumerator,xdenominator]);
    end
    
    if tau<0
      tau=0;
    end
    if tau>1
      tau=1;
    end
% update the solution    
    xalpha = xalpha+tau*xdelta;
%    disp(toc);
    
    if mod(it,100)==0
      xerr = sqrt(sum((tau*xdelta).^2));
%      disp([it,tau,xerr,-xnumerator]);
      disp(sprintf('%4d, %6.4f, %8.2f, %10.2f',it,tau,xerr,-xnumerator));
    end
  end
  
  disp('Solution time:');
  disp(toc);
  
  return;
                 