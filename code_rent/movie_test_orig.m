function [Zuser]=movie_test_orig(isubset,isubsett,xranges,xrangest, ...
                                 xmovies,xmoviest,glm_model,Y0,xalpha, xalpha1, xalpha2, xalpha3, xalpha4, whichOption, ifold)
                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computes the predicted rank for the (user,movie) pairs occuring in the test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs: 
%     isubset           indeces of the training items in xdata
%     isubsett          indeces of the test items in xdata
%     xranges           start and end indecs of movies for each users in
%                       training
%     xrangest          start and end indecs of movies for each users in
%                       test
%     xmovies           matrix of movie features in training  
%     xmoviest          matrix of movie features in test, not used (??)
%     glm_model         total, user and movie averages in training
%     Y0                possible ranks, not used
%     xalpha            collection of the dual variables computed in the
%                       training
% Outputs:
%     Zuser             cell array, cells are indexed by user index and
%                       contains the rank predictions for each movies
%                       from the test 

% t, for test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  global   xdata;               % (user,movie,rank)
  global   KXmfull;             % full input kernel (rat)
  global   KXmcfull;            % full input kernel (rat corr)
  global   KXgfull;             % full input kernel for genre
  global   KXffull;             % full input kernel for genre
  global   KXXfull;             % all inputs
  global   KYfull;              % full output kernel
  global   kernel_param;        % parameters  
  global   whichVersion;  
  global   isValidation;        % 1 = yes, it is validation
  
  global   Clustered;           % 1 = use clusted averages
  global   trainOrTest; 
  global   currentFold; 
  global   myResiduals;         % xmovies
  
  % For test
  global   Zpred_ub;            % for storing user oriented predictions;
  global   myPredictions_ub; 
  global   myPredictions_ib; 
  global   usersWhichHaveSeenThisMovie_test_ub;
  global   totalMoviesRatedByThisUser_test_ib;
  global   MAX_Movie_Support;    % Pwer Movie   
  global   MAX_User_Support;    % Power User
  
  % For validation
  global   Zpred_ub_val;         % for storing user oriented predictions;
  global   myPredictions_ub_val; 
  global   myPredictions_ib_val; 
  global   usersWhichHaveSeenThisMovie_test_ub_val;
  
  % for cold-start scenario etc. checking
  global thisUserHasRatedTotalMovies_ib;
  global thisUserHasRatedTheFollowingMovies_ib;
  global thisMovieHasBeenRatedByTotalUsers_ub;
  
  global myConfidence_ib;
  global myConfidence_ub;
  
  % TO ARTIFICIALLY CREATE NEW USER PROBLEM
  % Movies rated by an active user
%    RATED_MOVIES = 1;

       
     
     global TheseAreColdStartUsers;
    
       
  if(Clustered ==1)
       % load the saved files
      fullName = ['probe_x', '_', num2str(kernel_param.idataset), '_', num2str(trainOrTest), '_' num2str(currentFold)]
      load (fullName, 'CM');      %CL
  end
     
  % From original file, user and movie index are given:
  userIndex  = 1;
  movieIndex = 2;
  
  nuser  = kernel_param.nuser;
  nmovie = kernel_param.nmovie;

  ipar1  = kernel_param.ipar1;
  ipar2  = kernel_param.ipar2;
  ipar1y = kernel_param.ipar1y;
  ipar2y = kernel_param.ipar2y;
  
  Zuser  = cell(nuser,1);              % collection of the prediction for each user
  ZConfidence  = cell(nuser,1);
  
  % At version=1, create some global variables
  if(whichVersion==1 && ifold==1 && isValidation==0)
      usersWhichHaveSeenThisMovie_test_ub       = cell(nuser,1,5);     
      thisMovieHasBeenRatedByTotalUsers_ub      = cell(nuser,1,5);        % For detecting cold-start problems etc
      myPredictions_ub                          = cell(5); 
      myPredictions_ib                          = cell(5); 
      myConfidence_ub                           = cell(5); 
      myConfidence_ib                           = cell(5); 
      Zpred_ub                                  = cell(5);
      MAX_Movie_Support                         = 0;
      MAX_User_Support                          = 0;
  end
  
  if(whichVersion==1 && ifold==1 && isValidation==1)
      usersWhichHaveSeenThisMovie_test_ub_val       = cell(nuser,1,5);     
      thisMovieHasBeenRatedByTotalUsers_ub_val      = cell(nuser,1,5);     % For detecting cold-start problems etc
      myPredictions_ub_val                          = cell(5); 
      myPredictions_ib_val                          = cell(5);  
      myConfidence_ub_val                           = cell(5); 
      myConfidence_ib_val                           = cell(5); 
      zPred_ub_val                                  = cell(5);
  end
  
     % to get some info for version 3, to detect the cold-start problems
     % etc
    if(whichVersion==2 && ifold==1 && isValidation==0)      
        thisUserHasRatedTotalMovies_ib          = cell(nuser,1,5);           % For detecting cold-start problems etc.
      
        thisUserHasRatedTheFollowingMovies_ib   = cell(nuser,1,5);
        totalMoviesRatedByThisUser_test_ib      = cell(nuser,1,5);
        nuser;
    end    

  
  col_mean   = glm_model.col_mean;      % user averages
  row_mean   = glm_model.row_mean;      % movie averages
  total_mean = glm_model.total_mean;    % total average
  
  ymax  = kernel_param.ymax;            % parameters to rescale the rank
  ymin  = kernel_param.ymin;
  ystep = kernel_param.ystep;
  
  trmse = 0;
  tame  = 0;
  titem = 0;

  % All Cold-start objects
  totalSize_ColdStartObjects = max(size(TheseAreColdStartUsers));

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for iu=1:nuser                        % for each user
  
       user_Avg = col_mean(iu);
         
      %if(0>4)
      if xranges(iu,2)>0                  % user has training items  ..... else go to "New User Problem"  
      if xrangest(iu,2)>0                 % user has test items
        istart      = xranges(iu,1);       
        ilength     = xranges(iu,2);
        dummyIrange = istart:istart+ilength-1;              
        
        irange_Index = dummyIrange;
        irange       = isubset(irange_Index);        
        ixrange      = xdata(irange, movieIndex);       % training movies seen by the user  ?????????????????%               
        
          
%       get 2nd col, and rows defined by the vector ([]) in first arg               
        
%                         input('let us read the xmovies');
        iyrange   = full(xmovies(ixrange,iu))  ;        % corresponding ranks-averages  (%Convert sparse matrix to full matrix.)  , pick the corresponind rows of that user      
%                         input('after rounding the iyrange xmovies');
        iyrange   = round(1 + (iyrange-ymin)/ystep) ;   % transform real values into indecices (index of the values)        
%                         input('yinterval');
        yinterval = [ymin:ystep:ymax]'  ;                                                                                                                                                                                                                                           
%                         input('round(yinterval)');
        yinterval = round(1+(yinterval-ymin)/ystep) ;   % convert them into index (e.g. for -5 to 5 with 0.1 step, it is 1,2,3 ... 101) (index of the interval)
%                         input('max(size(yinterval))');
        yrange    = max(size(yinterval))  ;             % e.g. 101
%                         input('done');
        
        % In this step, we read the ratings (residual) rated by the user,
        % which ll give us a lot of small guassian in the index defined by
        % (1,2,3...101) and index defined by the user ratings (iyrange-ymin)/ystep.        
        KY        = KYfull(iyrange,yinterval);          % read the user specific output subkernel   
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Read the test movies (INverted Case: TEST USER)        
        % I need to get some of the test movie/user information as well
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
        iranget   = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
        ixranget  = xdata(iranget,movieIndex);          % Test movies (for version=3), test user for version=1
        
        % loop through each of it (ixranget), and store the required info
         if(whichVersion==1 && isValidation==0)
           usersWhichHaveSeenThisMovie_test_ub{iu,ifold}       = ixranget;
           thisMovieHasBeenRatedByTotalUsers_ub{iu,ifold}      = size(irange,1);     %*****MOVIE_SUPPORT*****
               if(MAX_Movie_Support < size(irange,1))
                   MAX_Movie_Support = size(irange,1)
               end
         end
         
         if(whichVersion==1 && isValidation==1)
           usersWhichHaveSeenThisMovie_test_ub_val{iu,ifold}   = ixranget;
         end
         
         if(whichVersion==2 && isValidation==0)
           thisUserHasRatedTotalMovies_ib{iu,ifold}          = size(irange,1);        %*****USER_SUPPORT*****
           thisUserHasRatedTheFollowingMovies_ib{iu,ifold}   = ixrange;
           totalMoviesRatedByThisUser_test_ib{iu,ifold}      = ixranget;
              if(MAX_User_Support < size(irange,1))
                   MAX_User_Support = size(irange,1)
               end
         end
         
%         if(iu==1)
%             disp('ixrange')
%             disp(ixrange)
%             disp('ixrangst')
%             disp(ixranget)
%         end

        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
% % % MM
% shld nt the first step be different for Feature and
% genre? .... we have access to test features as well?
% check and discuss this
% again????????????????????????????????????????????????????????????????

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%         if(whichOption==1)          
%           % read the user specific input kernel (mov seen by user)     ...INTERSECTION?     
%             KXm  = KXmfull(ixrange,ixranget);                 
%           % compute prediction by the maximum margin principle
%             Z  = (KY'.*repmat(xalpha(istart:istart+ilength-1)',[yrange,1]))*(KXm);
%           % compute those which maximizes the margin (give max of each col)
%             [zpre,spre]   = max(Z,[],1);                                           %  [Y,I] = MAX(X) returns the indices of the maximum values in vector I...here col wise            
%           % compute the real rank-averages        
%             zpre  = (spre-1)*ystep+ymin;                                           %  GRID STUFF
%             npre  = length(zpre);
%             
%         elseif (whichOption==2)     
%         % It Is looking Wrong??????????????????????????????????????????????
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
%           KXg  = KXgfull(ixrange,ixranget);       % read the user specific input kernel (mov seen by user)
%           Z1 = (KY'.*repmat(xalpha1(istart:istart+ilength-1)',[yrange,1]))*(KXg);        
%           [zpre1,spre1] = max(Z1,[],1);                                          %  [Y,I] = MAX(X) returns the indices of the maximum values in vector I...here col wise
%           zpre1 = (spre1-1)*ystep+ymin;
%           npre = length(zpre1);
%           
%         elseif (whichOption==3)
%           KXf  = KXffull(ixrange,ixranget);       % read the user specific input kernel (mov seen by user)
%           Z2 = (KY'.*repmat(xalpha2(istart:istart+ilength-1)',[yrange,1]))*(KXf);        
%           [zpre2,spre2] = max(Z2,[],1);                                          %  [Y,I] = MAX(X) returns the indices of the maximum values in vector I...here col wise
%           zpre2 = (spre2-1)*ystep+ymin;
%           npr = length(zpre2);
%           
%         elseif (whichOption==4)


          KXX   = KXXfull(ixrange,ixranget);                                %  read the user specific input kernel (mov seen by user)
%                 input('xlpaha');
          size(xalpha3(irange_Index)');
%                 input('xlpaha rep');
          size(repmat(xalpha3(irange_Index)',[yrange,1]));
%                 input('kkx');
          size(KXX);
%                 input('ky');
          size(KY');
%                 input('zpre3,spre3');
          
          Z3       = (KY'.*repmat(xalpha3(irange_Index)',[yrange,1]))*(KXX);        
 
          loopCounter = 1;
          for loopCounter = 1:1
             
              [zpre3,spre3]  = max(Z3,[],1) ; %  [Y,I] = MAX(X) returns the indices of the maximum values in vector I...here col wise   
    %           [zpre3,spre3]  = mean(Z3) ; 
    %            input('finding the max');
              
               zpre3_temp   = (spre3-1)*ystep+ymin;               
               if(loopCounter==1)
                    zpre3 = (spre3-1)*ystep+ymin;
               else
                    zpre3 =  zpre3 + (spre3-1)*ystep+ymin;
               end
          end
          
%                 input('zpre3');
          npre           = length(zpre3);
          
          ZConfidence    = Z3;                                                       % assign the matrix to the Cell var          
          
%         elseif (whichOption==5) 
%           KXmc = KXmcfull(ixrange,ixranget);          % read the user specific input kernel (mov seen by user)       
%           Z4 = (KY'.*repmat(xalpha4(istart:istart+ilength-1)',[yrange,1]))*(KXmc);        
%           [zpre4,spre4] = max(Z4,[],1);
%           zpre4 = (spre4-1)*ystep+ymin;
%           npre = length(zpre4);
%         end  


%           disp('z');
%           disp(size(Z));  
%           disp('z1');                  % diff dimensions
%           disp(size(Z1));

%         disp('max');
%         disp(zpre);
  
%         disp('zpre');
%         disp(zpre);
        
   % mean value correction, add averages to the prediction 
%           disp('z');
%           disp(size(npre));           % it was same dimensional 1
%           disp('z1');
%           disp(size(npre1));


     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     % Add normalization factors
      if kernel_param.iprod==1
          for i=1:npre
            im  = ixranget(i);   % test movie index   
           
               movie_Avg  = row_mean(im);
               total_Avg  = total_mean;             
             
             if(whichOption==1)
                zpre(i)=zpre(i)*user_Avg*movie_Avg/total_Avg;
             elseif (whichOption==2)           
                zpre1(i)= zpre1(i)*user_Avg*movie_Avg/total_Avg;                
             elseif (whichOption==3)
                zpre2(i)= zpre2(i)*user_Avg*movie_Avg/total_Avg;           
             elseif (whichOption==4)
                zpre3(i)= zpre3(i)*user_Avg*movie_Avg/total_Avg;                
             elseif (whichOption==5)
                zpre4(i)= zpre4(i)*user_Avg*movie_Avg/total_Avg;
             end
          end % end for

      else
          
          for i=1:npre
              im  = ixranget(i);   % test movie index           
            
               movie_Avg  = row_mean(im);
               total_Avg  = total_mean;                       
             
               if(whichOption==1)
                   zpre(i)=zpre(i)+user_Avg+movie_Avg-total_Avg;
                elseif (whichOption==2)
                    zpre1(i) = zpre1(i)+user_Avg+movie_Avg - total_Avg;
                elseif (whichOption==3)
                     zpre2(i) = zpre2(i)+user_Avg+movie_Avg - total_Avg;
                elseif (whichOption==4)
                     zpre3(i) = zpre3(i)+user_Avg+movie_Avg - total_Avg;
                elseif (whichOption==5)
                      zpre4(i) = zpre4(i)+user_Avg+movie_Avg - total_Avg;    
               end
          end % end for
      end % end if else
      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % There can be a probablistic way of combining
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        myConfidence{iu} = ZConfidence;             % each col of the matrix, contains confidence value for a rank
        
          if(whichOption==1)
            Zuser{iu} = zpre';                      % store the prediction for the user
          elseif (whichOption==2)
            Zuser{iu} = zpre1';                     % store the prediction for the user
          elseif (whichOption==3)
            Zuser{iu} = zpre2';                      % store the prediction for the user
          elseif (whichOption==4)
            Zuser{iu} = zpre3';                      % store the prediction for the user
          elseif (whichOption==5)
            Zuser{iu} = zpre4';                      % store the prediction for the user         
          end
      end % user have some test items

    else % if user dont have any training movies 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NEW USER PROBLEM
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Think of adding something here, like bayesian approach, etc.
    % I must have a heading saying, solving new user problem.
    % if there is no training item for the user then the averages give the
    % prediction

       if xrangest(iu,2)>0   
         iranget   = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
         ixranget  = xdata(iranget,movieIndex);
        
         if(whichVersion==1 && isValidation==0)
           usersWhichHaveSeenThisMovie_test_ub{iu,ifold} = ixranget;
         end
        
         if(whichVersion==1 && isValidation==1)
           usersWhichHaveSeenThisMovie_test_ub_val{iu,ifold} = ixranget;
         end
        
         if(whichVersion==2 && isValidation==0)
           thisUserHasRatedTotalMovies_ib{iu,ifold}            = 0;   % row wise?
           thisUserHasRatedTheFollowingMovies_ib{iu,ifold}     = 0;
           totalMoviesRatedByThisUser_test_ib{iu,ifold}        = ixranget;
         end
         
           zpre  = zeros(1,length(iranget));
           npre  = length(zpre);
        
       for i=1:npre            
           im                   = ixranget(i);   % test movie index             
           movie_Avg            = row_mean(im);     
           total_Avg            = total_mean;                  
             
           zpre(i)              = user_Avg + movie_Avg - total_Avg;
       end
        
         % We store no confidence for this predicion
              myConfidence{iu} = 0;  
              
       end
              Zuser{iu} = zpre';                   % each index of the cell can store array of values
    
            
              
  end % end if else user has some training items

    
% % compute partial RMSE and AME errors and report them
%     trmse  = trmse + sum((xdata(iranget,3)-zpre').^2);
%     tame   = tame +  sum(abs(xdata(iranget,3)-zpre'));
%     titem  = titem + length(zpre);
%     if mod(iu,1000)==0
%       disp(iu);
%       disp([sqrt(trmse/titem),tame/titem]);
%     end
  end % end for all users

  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Version == 1,2 (UB)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % For inverted case,
  % Here I will make the predcitions for the original case like 
  % (UID, [Sorted Movies], [Predictions]);
    
  if((whichVersion == 1) && (isValidation==0))
      Zpred_ub{ifold} = Zuser;
      myConfidence_ib{ifold} = myConfidence;
  end    
  
  if(whichVersion == 1 && isValidation==1)  
    Zpred_ub_val{ifold} = Zuser;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Version == 1,2 (UB)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % For Version two, make predictions in the format required for evaluation
  
  if (whichVersion==2 && isValidation== 0)
       
  previous_Pred         = Zpred_ub{ifold};
  ubPred                = cell(nuser,1);   
  dummyConfidence_ub    = cell(nuser,1);  
  myConfidence_ub{ifold} = myConfidence;
  tempConfidence_ib      = myConfidence_ib{ifold}; 
  tempConfidence_ub      = myConfidence_ub{ifold}; 
  
  dummyPred             = [];
  temp                  = 1;
%   
% 
    for iu=1:nuser
        % IDs of the movies a user has seen in the test set (org)
        iranget   = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
         ixranget  = xdata(iranget,movieIndex);   
         
%         confidenceForOneUser_ib   = tempConfidence_ib{iu};
     
        
       for mid=1:nmovie  
               %To find, if this user has seen this movie (org)
               
               dumMid = find(ixranget==mid  );
               
%                confidenceForOneMovie_ub        = tempConfidence_ub{mid};
%                oneMovieConfidenceForThisUser   = confidenceForOneUser_ib(:,mid);             % think if it will be the same mid?
       
            if(dumMid>0)
%              mid
               userIDs = usersWhichHaveSeenThisMovie_test_ub{mid,ifold};                          
         
%                     ixranget
%                     mid          
%                     iu     
%                     userIDs            
%                 
                dumUid  = find(userIDs==iu);
        
             if(dumUid>0)  
%                   dumUid
%                   userIDs
%                   mid
%                   Zpred_ub{mid}
% %                
%                  disp(iu);
                  onePred         = previous_Pred{mid}(dumUid);
%                   disp( onePred);
                  dummyPred(temp) = onePred;
                  temp            = temp + 1;
                  
                  
%                   disp( mid);

%                  
%                   
                   
%                   disp(dummyPred);
%                   disp(temp);
%                   
%                   oneUserConfidenceForThisMovie   = confidenceForOneMovie_ub(:,mid);             % think if it will be the same mid?
                  
             end
             end
        end          
         ubPred{iu} = dummyPred';
%        disp('dummmy pred')
%        dummyPred'
         dummyPred = [];
         temp      = 1;   
         
    end
        
    % Store the UB predictions for the next iteration
     myPredictions_ub{ifold}  = ubPred;     
     Zuser  = ubPred;                     %for return
     size(ubPred{1});
  end
  
  % For VALIDATION
  if (whichVersion==2 && isValidation== 1)
  previous_Pred  = Zpred_ub_val{ifold};
  ubPred         = cell(nuser,1);   
  dummyPred      = [];
  temp           = 1;

    for iu=1:nuser
        % IDs of the movies a user has seen in the test set (org)
        iranget   = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
        ixranget  = xdata(iranget,movieIndex);   
              
%         ixranget
        
       for mid=1:nmovie  
               %To find, if this user has seen this movie (org)
               dumMid = find(ixranget==mid);

            if(dumMid>0)
%              mid
               userIDs = usersWhichHaveSeenThisMovie_test_ub_val{mid,ifold};                          
         
%                     ixranget
%                     mid          
%                     iu     
%                     userIDs            
%                 
                dumUid  = find(userIDs==iu);
        
             if(dumUid>0)  
%                     dumUid
%                   userIDs
%                   mid
%                   Zpred_ub{mid}
% %                   
                  onePred         = previous_Pred{mid}(dumUid);
                  dummyPred(temp) = onePred;
                  temp            = temp + 1;
             end
             end
        end          
         ubPred{iu} = dummyPred';
%          disp('dummmy pred')
%          dummyPred'
         dummyPred = [];
         temp      = 1;
    
    end
        
    % Store the UB predictions for the next iteration
     myPredictions_ub_val{ifold}  = ubPred;     
     Zuser  = ubPred;                                       %for return
     size(ubPred{1})
  end
 
 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Version ==3 (IB)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if( whichVersion==3 && isValidation==0)  
      myPredictions_ib{ifold}  = Zuser;  
      size(Zuser{1})
  end
  
  if( whichVersion==3 && isValidation==1)  
      myPredictions_ib_val{ifold}  = Zuser;  
      size(Zuser{1})
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Version ==4 (IB + Ub)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  X10  = 100;
  X5   = 50;
  
  if (whichVersion>=4) 
      
      if(isValidation==0)
          pred_ub                           = myPredictions_ub{ifold};
          pred_ib                           = myPredictions_ib{ifold};      
          tempConfidence_ib                 = myConfidence_ib{ifold};
           
          support_ib                        = thisUserHasRatedTotalMovies_ib(:,ifold)  ;         % all rows of the first "()" returns a cell array
          support_ub                        = thisMovieHasBeenRatedByTotalUsers_ub(:,ifold);     
          prob_support_ib                   = thisUserHasRatedTotalMovies_ib(:,ifold)  ;         % all rows of the first "()" returns a cell array
          prob_support_ub                   = thisMovieHasBeenRatedByTotalUsers_ub(:,ifold);     
      
          moviesSetForCurrentUser_ib        = thisUserHasRatedTheFollowingMovies_ib(:,ifold);
          moviesSetForCurrentUser_test_ib   = totalMoviesRatedByThisUser_test_ib(:,ifold);
     
      else
          pred_ub = myPredictions_ub_val{ifold};
          pred_ib = myPredictions_ib_val{ifold};   
      end  

  
  for iu=1:nuser  
        
     % Get predictions made from both into a temp variable
      tempPredictions_ib = (pred_ib{iu}); 
      tempPredictions_ub = (pred_ub{iu});
      finalPredictions   = [];                         % It will be reset automatically after each version call 

            if(whichVersion==4)
%               Zuser{iu} = (0.1* pred_ub{iu}) + (0.9* pred_ib{iu});
                Zuser{iu} = (0.5* pred_ub{iu}) + (0.5* pred_ib{iu});
            
%               Zuser{iu} = (pred_ub{iu});
%               size(pred_ub{iu})
%               disp(pred_ub{iu});                  
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Hack for the Hybrd approach
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % support_ib = no. of movies rated by this user
                % support_ub = no. of users, which have rated this movie
                
%                  elseif (whichVersion==5) 
%                      
%                      prob_support_ib           = support_ib{iu}/MAX_Movie_Support;    
%                      confidenceForOneUser_ib   = tempConfidence_ib{iu};
%                           
%                       if (support_ib{iu} <X5 )                    
%                            %go through each of the movie                       
%                            moviesSet  = moviesSetForCurrentUser_test_ib{iu};
%                            totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       
% 
%                                for x=1:totalPredictionsForThisUser
%                                            mid  =  moviesSet(x);                  % get a mid
%                                            
%                                            prob_support_ub{x} = support_ub{x}/MAX_User_Support;
%                                            
%                                            if(support_ub{x}<50)                 % how many users have rated this movie                   
%                                               onePred   =  tempPredictions_ub(x);                                  
%                                            
%                                            elseif(support_ub{x}>70)
%                                               onePred   = 0.9 *  tempPredictions_ub(x) + 0.1 * tempPredictions_ib(x);                                                                  
%                                            
%                                            elseif(support_ub{x}>80)
%                                               onePred   = 0.9 *  tempPredictions_ub(x) + 0.1 * tempPredictions_ib(x);                                                                  
%                                            
%                                            elseif(support_ub{x}>100)
%                                               onePred   = 0.8 *  tempPredictions_ub(x) + 0.2 * tempPredictions_ib(x);                                                                  
%                                            
%                                            elseif(support_ub{x}>150)
%                                               onePred   = tempPredictions_ub(x) + tempPredictions_ib(x);                                                                  
%                                            
%                                            else
%                                               onePred   =  tempPredictions_ib(x);                                  
%                                            end  
%                                            
%                                            finalPredictions(x) = onePred;
%                                            
%                                end % end for                  
%                             Zuser{iu}  = finalPredictions';     
%                       else
%                           
%                           % fine, as when the support_ib is very small, it
%                           % employes we have the new user problem, in whoch
%                           % the user-based will fail
%                           
%                           Zuser{iu} =  tempPredictions_ib;
%                           
%                       end
                      
                 elseif (whichVersion==5) 
                     
                     prob_support_ib                = support_ib{iu}/MAX_Movie_Support;    
                     confidenceForOneUser_ib        = tempConfidence_ib{iu};
                     confidenceForOneUser_size_ib   = size(confidenceForOneUser_ib,2);
                          
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                           mid  =  moviesSet(x);                          % get a mid
                                           
                                           if(x<=confidenceForOneUser_size_ib)
                                               oneMovieConfidenceForThisUser  = confidenceForOneUser_ib(:,x);  % think if it will be the same mid?
                                               oneMovieConfidenceForThisUser = sort(oneMovieConfidenceForThisUser);
                                               tempLength = size(oneMovieConfidenceForThisUser,1);

                                               c1= oneMovieConfidenceForThisUser(tempLength);
                                               c2= oneMovieConfidenceForThisUser(tempLength-1);

                                               if((c1-c2)>0.0001)                                               
                                                onePred   =  tempPredictions_ib(x);                                  
                                               else
                                                onePred   =  tempPredictions_ub(x);                                  
                                               end
                                           else
                                               onePred   =  tempPredictions_ib(x);                                  
                                           end
                                           
                                           finalPredictions(x) = onePred;
                                           
                               end % end for                  
                            Zuser{iu}  = finalPredictions';     
                 

            elseif (whichVersion==6) 
                     
                     prob_support_ib{iu} = support_ib{iu}/MAX_Movie_Support;                       
                                     
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                           mid  =  moviesSet(x);                  % get a mid
                                           
                                           prob_support_ub{x} = support_ub{x}/MAX_User_Support;
                                           
                                           if(prob_support_ib{iu}+ 0.2 > prob_support_ub{x} )                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ib(x);                                  
                                           else
                                              onePred   =  tempPredictions_ub(x);                                  
                                           end
                                           
                                           finalPredictions(x) = onePred;
                                           
                               end % end for  
                               
                            Zuser{iu}  = finalPredictions';                  
                                                                                 
                       
                 elseif (whichVersion==7)
                    if (support_ib{iu} <X5 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>30)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                    end
                    
                 elseif (whichVersion==8)
                        if (support_ib{iu} <X5 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>40)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                        
                 elseif (whichVersion==9)
                      if (support_ib{iu} <X5 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>50)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                      
                                  
                 elseif (whichVersion==10)
                      if (support_ib{iu} <X5 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                % get a mid
                                      
                                        if(support_ub{x}>80)                 % how many users have rated this movie                   
                                              onePred   =  0.9 * tempPredictions_ub(x) + 0.1 * tempPredictions_ib(x);                                                                    
                                        else
                                              onePred   =  0.9 * tempPredictions_ib(x) + 0.1 * tempPredictions_ub(x);                                                                    
                                        end
                                           
                                        finalPredictions(x) = onePred;
                               
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else                          
                        Zuser{iu} =  0.9 * tempPredictions_ib +  0.1 * tempPredictions_ub;
                      end
                                  
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  
                 elseif (whichVersion==11)
                      if (support_ib{iu} <X10 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>5)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                                  
                 elseif (whichVersion==12)
                      if (support_ib{iu} <X10 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>20)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                                  
                 elseif (whichVersion==13)
                      if (support_ib{iu} <X10 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>30)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                                  
                 elseif (whichVersion==14)
                      if (support_ib{iu} <X10 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>40)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                                  
                  elseif (whichVersion==15)
                      if (support_ib{iu} <X10 )                    
                           %go through each of the movie                       
                           moviesSet  = moviesSetForCurrentUser_test_ib{iu};
                           totalPredictionsForThisUser = size(moviesSet,1);               % These have the movies, which shld be stored in the same way                       

                               for x=1:totalPredictionsForThisUser
                                        mid  =  moviesSet(x);                   % get a mid
                                           if(support_ub{x}>70)                 % how many users have rated this movie                   
                                              onePred   =  tempPredictions_ub(x);                                  
                                           else
                                              onePred   =  tempPredictions_ib(x);                                  
                                           end                   
                               finalPredictions(x) = onePred;
                               end % end for                  
                            Zuser{iu}  = finalPredictions';   
                      else
                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                      
                  elseif (whichVersion==16)
                      if (support_ib{iu} <X5 )                    
                        Zuser{iu} =  tempPredictions_ub;
                      else                          
                        Zuser{iu} =  tempPredictions_ib;
                      end                      
                      
                  elseif (whichVersion==17)
                      if (support_ib{iu} <X10 )                    
                        Zuser{iu} =  tempPredictions_ub;
                      else                          
                        Zuser{iu} =  tempPredictions_ib;
                      end
                  
                  elseif (whichVersion==18)
                      if (support_ib{iu} <X5 )                    
                        Zuser{iu} =  tempPredictions_ib;
                      else                          
                        Zuser{iu} =  tempPredictions_ub;
                      end
                      
                      
                  elseif (whichVersion==19)
                      if (support_ib{iu} <X10 )                    
                        Zuser{iu} =  tempPredictions_ib;
                      else                          
                        Zuser{iu} =  tempPredictions_ub;
                      end
                  
                      
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
%                 elseif (whichVersion==6)
%                        Zuser{iu} = (0.3* pred_ub{iu}) + (0.7* pred_ib{iu});
%                 elseif (whichVersion==7)
%                        Zuser{iu} = (0.4* pred_ub{iu}) + (0.6* pred_ib{iu});
%                 elseif (whichVersion==8)
%                        Zuser{iu} = (0.5* pred_ub{iu}) + (0.5* pred_ib{iu});
%                 elseif (whichVersion==9)
%                        Zuser{iu} = (0.6* pred_ub{iu}) + (0.4* pred_ib{iu});
%                 end
               end
    end
  end % for version>=4
  
  
return;

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % what about new movie problem?
  % a movie is new, how you ll predict that?
  % movie feature vector ll be very small
  % So we can use the Feature vector consisting of the keywords there.
  
  
  