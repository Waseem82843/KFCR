function [isubset,isubsett] = movie_data_select(ifold, xselector, xselector_user, valData, valTr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% select the training and test row indeces relative to xdata
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inputs
%     ifold           fold index
%     xselector       random numbers: 1,..,number of folds, to each rank
%                     data
%     xselector_user  random numbers: 1,..,number of folds, to each user
% outputs 
%     isubset         "index" set of training
%     isubsett        index set of test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  global  kernel_param;
  global  xdata;                         % rank data ( user,movie,rank)
  global  whichVersion;
  global  xselector_ub;                 
  global  xdata_ub;
  global  xselector_ib;

  
  switch kernel_param.itestmode
   case 0  % fixed folds
  
    if(valData==0)
     isubsett = find(xselector==ifold);      % test
     isubset  = find(xselector~=ifold);      % training            
    end
    
   case 1                               % random subset of rank data  
     if(valData==0)
       % for version 1
       if(whichVersion==1) 
           isubsett = find(xselector==ifold);      % test
           isubset  = find(xselector~=ifold);      % training     

           disp(isubsett)
           disp(isubset)
         
       % for version 2        
       elseif(whichVersion==2)   
           nPoints = size(xdata,1);     % No. of rows
           xselector = xselector_ub;    % for similar size
          % disp(size(nPoints))
           %disp(xdata_ub)
           %disp(size(xselector_user))
           %disp(xdata)
           %disp(size(xdata))
            
           for i=1:nPoints   
              
          
               
               index = find(xdata_ub(:,2)==xdata(i,1) & xdata_ub(:,1)==xdata(i,2) & xdata_ub(:,3)==xdata(i,3)) ;

             %disp(i)
             %disp(index)
             
     %if(size(xselector_ub(index),1) == 2)
        
      %  disp(i)
     %end
             
                disp(size(xselector(i)))
                disp(size(xselector_ub(index)))
            
                 xselector(i) =  xselector_ub(index); 


           end
           
           xselector_ib = xselector;           
           isubsett     = find(xselector==ifold);      % test
           isubset      = find(xselector~=ifold);      % training    
           
       % for version 3 and 4
       else             
           isubsett = find(xselector_ib==ifold);      % test
           isubset  = find(xselector_ib~=ifold);      % training  
           
       end
       
       %VALIDATION CASE
     else
           isubsett_dum = find(xselector==ifold);      % test
           isubset_dum  = find(xselector~=ifold);      % training  
           isubsett     = valTr(isubsett_dum);
           isubset      = valTr(isubset_dum);
           
     end
     
   case 2                               % random subset of users 
       
% !!!!!!! under construction    
     isubsetuser = find(xselector_user~=ifold);  %??
     mdata       = size(xdata,1);
     xmask       = zeros(mdata,1);
     nu          = length(isubsetuser);

     xrange = zeros(nuser,2);
  
     for idata = 1:mdata
       iu           = xdata(idata,1);                   % a user
       xrange(iu,2) = xrange(iu,2)+1;
     end
  
     xrange(:,1) = cumsum(xrange(:,2))-xrange(:,2)+1;  % cumsum(A,1)--> col wise; cumsum(A,2)--> row wise;
     
     for i=1:nu
       iu      = isubsetuser(i);
       istart  = xrange(iu,1);                      % user id
       nlength = xrange(iu,2);                      % no. of movies seen by that user
       xmask(istart:istart+nlength-1)=1;
     end
     
     isubsett  = find(xmask==0);
     isubset   = find(xmask==1);                    % training set, movies he has seen
  end

  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % random fold are nt that good
  % we iterate over the data and then, put each user's movies into
  % test and training set according to some statistic,
  % e.g. 20% in test and remaining into training
  
  