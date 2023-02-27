function [topNResults, deval] = movie_eval(ieval_type, nuser, isubsett, xrangest, ZuserT, glm_model)
% ieval_type      = 0 hamming
%                 = 1 sqrt(L2)
%                 = 2 L1            


  global xdata;
  global whichVersion;
  
  topNResults = cell(6,1);              % First col, we will store Mean                                        
                                        % (Precision, Recall, F1) Top-10
                                        % (Precision, Recall, F1) Top-15
                                        % (Precision, Recall, F1) Top-20
                                        %  ...
  deval = 0;
  
  % For Normal use
  col_mean   = glm_model.col_mean_eval;      % user averages (Will be used for ROC-computation)
  row_mean   = glm_model.row_mean;           % movie averages
  total_mean = glm_model.total_mean;         % total average
  
    
  switch ieval_type
    case 0
      nall   = 0;
      nright = 0;
      for iu=1:nuser
        if xrangest(iu,2)>0
          iranget = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
          nright  = nright + sum(ZuserT{iu}==xdata(iranget,3));
          nall    = nall + length(iranget);
        end
      end

      if nall==0
        nall=1
      end
      deval = nright/nall;
      
    case 1     % RMSE root mean square error
      nall   = 0;
      nright = 0;
      for iu = 1:nuser
        if xrangest(iu,2)>0
          iranget = isubsett(xrangest(iu,1):xrangest(iu,1)+xrangest(iu,2)-1);
          nright  = nright+sum((ZuserT{iu}-xdata(iranget,3)).^2);
          nall    = nall+length(iranget);
        end
      end
      if nall==0
        nall=1
      end
      deval=sqrt(nright/nall);
      
   % It is for all predictions
   % ZuserT,   contains the prediction made per user per range (xrange)
   % xrangest, contains actual in the 3rd col
   % nuser,    total no. of users
   
    case 2   % MAE mean absolute error
      nall   = 0;
      nright = 0;
      for iu=1:nuser
        if xrangest(iu,2)>0
          iranget = isubsett(xrangest(iu,1):xrangest(iu,1) + xrangest(iu,2) - 1);
          nright  = nright + sum(abs(ZuserT{iu} - xdata(iranget,3)));
          nall    = nall + length(iranget);
        end
      end
      if nall==0
        nall=1
      end
      deval=nright/nall;        
  
      % MAE Per User
%       nall   = 0;      
%       nright = 0;
%       MAEPerUser = 0;
%       for iu=1:nuser
%           nall   = 0;
%           nOne   = 0;
%           nright = 0;
%         if xrangest(iu,2)>0
%           iranget = isubsett(xrangest(iu,1):xrangest(iu,1) + xrangest(iu,2) - 1);
%           nright  = sum(abs(ZuserT{iu} - xdata(iranget,3)));          
%           nOne    = nOne + length(iranget);          
%           nall    = nall + 1;        
%         
%          % Calculate MAE per user
%           MAEPerUser = MAEPerUser + nnright/nOne;
%          end
%       end
%       
%       deval=MAEPerUser/nall;  

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
    % , MAE, ROC, F1, Related  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 3     
      nall   = 0;
      nright = 0;
      for iu=1:nuser
        if xrangest(iu,2)>0
          iranget = isubsett(xrangest(iu,1):xrangest(iu,1) + xrangest(iu,2) - 1);
               
          nright  = nright + sum(abs(ZuserT{iu} - xdata(iranget,3)));
          
%           disp(nright);
          nall    = nall + length(iranget);
        end
      end
      if nall==0
        nall=1;
      end
      deval=nright/nall; 
      
                                
    % It will control the TopN
    control_loop = [10,15,20,25,30,50];        % will run 6 times, and each time with diff calculation
    control_limit = max(size(control_loop));
        
    % Loop for TopN results calculations
    for outer=1:control_limit
        
      % the top-N variables init
      topN_Recall     = 0;        
      topN_Precision  = 0;
      topN_F1         = 0;
      
      % Roc related var init
      TPR = 0;
	  FPR = 0;
	  SPC = 0;
	  PPV = 0;
	  NPV = 0;
	  FDR = 0;
	  MCC = 0;
      ACC = 0;
	  F1  = 0;  
      
    % for all user
    for iu=1:nuser
       if xrangest(iu,2)>0
            
             % These will change for each user
             % Reset them after each user
             predcitedCategpry = false;  
             actualCategpry    = false;  
             TP = 0; TN = 0; FN = 0; FP = 0;  P = 0;  N = 0;      PPrime =0; NPrime =0;       
             TPRForEachUser = 0; FPRForEachUser = 0; PPVForEachUser = 0; NPVForEachUser = 0; 
             FDRForEachUser = 0 ;MCCForEachUser = 0 ;ACCForEachUser = 0 ;SPCForEachUser = 0; 
             topN_RecallForEachUser    = 0;        
             topN_PrecisionForEachUser = 0;
             topN_F1ForEachUser        = 0;
             
             % init variables controlling index etc
             innerLimit = 0;
    
             iranget = isubsett(xrangest(iu,1):xrangest(iu,1) + xrangest(iu,2) - 1);             
               
             % Get a prediction and Get actual rating
             totalPredForOneUser = max(size(ZuserT{iu}));            
             predictedSet        = ZuserT{iu};
             actualSet           = xdata(iranget,3);       

             
             userAvg             = col_mean(iu);
              

                    
             % sort the predictions but store the index             
             [predictedValues, predictedIndices] = sort(predictedSet);

             % define the inner loop end position
             if(outer<6)   
                innerLimit = control_loop(outer);           % 10, 15, 20, 25, 30, and then all                   
                    if (innerLimit > totalPredForOneUser)
                            innerLimit = totalPredForOneUser;                   
                    end       
             else
                     innerLimit = totalPredForOneUser;
             end
                
                % Go throught the predictions made by one user
                 for t = 1:innerLimit                     

                  predicted        = predictedValues(t);             % get the predicted and the actual set 
                  indexForActual   = predictedIndices(t);
                  actual           = actualSet(indexForActual);
                  
                  %predicted = round(predicted);
                  
                  
                  %disp([predicted actual col_mean]);         
                   

                  if predicted >= userAvg
                      predcitedCategpry = true;
                  else
                      predcitedCategpry = false;              
                  end

                  if actual >= userAvg
                      actualCategpry = true;
                  else
                      actualCategpry = false;
                  end

                  % define logic for ROC 
                   if(actualCategpry==true       &&  predcitedCategpry==true)	                 
                      TP = TP+1;  P = P+1; PPrime = PPrime +1;
                   elseif(actualCategpry==true   &&  predcitedCategpry==false)
                      FN = FN+1;  P = P+1; NPrime = NPrime +1;
                   elseif(actualCategpry==false  &&  predcitedCategpry==true)
                      FP = FP+1;  N = N+1; PPrime = PPrime +1;             
                   elseif(actualCategpry==false  &&  predcitedCategpry==false)
                      TN = TN+1;  N = N+1; NPrime = NPrime +1;
                   end            
                 end % end inner for,                
           
                %%%%%%%%%%%%%%%%%%%%%%%%%
                % F1 Related
                %%%%%%%%%%%%%%%%%%%%%%%%%
                
                if(outer<=5)
                if((TP + FN)~=0)
                    topN_RecallForEachUser = TP/(TP + FN);                    
                end
                if((TP + FP)~=0)
                    topN_PrecisionForEachUser = TP/(TP + FP);                  
                end
                
                if((topN_PrecisionForEachUser + topN_RecallForEachUser) ~=0)
                    topN_F1ForEachUser = (2 * topN_PrecisionForEachUser * topN_RecallForEachUser) / ...
                                            (topN_PrecisionForEachUser + topN_RecallForEachUser);                    
                end
   
                %Add to the Final precisions
                topN_Recall       =    topN_Recall + topN_RecallForEachUser;
                topN_Precision    =    topN_Precision + topN_PrecisionForEachUser;
                topN_F1           =    topN_F1 + topN_F1ForEachUser;
                
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%
                % ROC Related
                %%%%%%%%%%%%%%%%%%%%%%%%%
                
              if (outer ==6)
                %Add the ROC related stuff
                %TPR = TP/ P = TP / (TP + FN)
                if(P~=0)
                    TPRForEachUser = TP/ (P);	  	
                TPR = TPR + TPRForEachUser;             
                end
                
                %FPR = FP / N = FP / (FP + TN)
                if(N~=0)
                    FPRForEachUser = FP / (N);
                FPR = FPR + FPRForEachUser;
                end
                
              % ACC = (TP + TN) / (P + N)	
                if((P+N)~=0)
                    ACCForEachUser = (TP + TN) / (P + N);
                ACC = ACC + ACCForEachUser;
                end
                
              % SPC = TN / N = TN / (FP + TN) = 1- FPR	
                if(N~=0)
                    SPCForEachUser = TN / N;
                SPC = SPC + SPCForEachUser;
                end
                
              %PPV = TP / (TP + FP);
                if((TP+FP)~=0)
                    PPVForEachUser = TP / (TP + FP);
                PPV = PPV + PPVForEachUser;
                end
                
              %NPV = TN / (TN + FN)
                if((TN+FN)~=0)
                    NPVForEachUser = TN / (TN + FN);
                NPV = NPV  + NPVForEachUser ;
                end
                
              %FDR = FP / (FP +TP)
                if((FP+TP)~=0)
                    FDRForEachUser = FP / (FP +TP);
                FDR = FDR + FDRForEachUser;
                end
                
              %MCC
                if(((P) *(N)* (PPrime) * (NPrime))~=0)
                        MCCForEachUser = ((TP * TN) - (FP * FN)) / sqrt((P) *(N)* (PPrime) * (NPrime));
                MCC = MCC + MCCForEachUser;
                end
                
              %F1 (2* Precision * Recall) / (Precision+Recall)
                if((PPV + TPR)~=0)
                    F1ForEachUser = 2 * (PPV * TPR)/(PPV + TPR);  	
                F1 = F1 + F1ForEachUser;
                end
                
                end % end if outer=6 (if we want to calculate the roc)        
         
                
                 end % if user has rated some movies
               end % end all users
          
           topNResults{outer,1} = [topNResults{outer,1},  topN_Precision/nuser];
           topNResults{outer,1} = [topNResults{outer,1},  topN_Recall/nuser];
           topNResults{outer,1} = [topNResults{outer,1},  topN_F1/nuser];
           topNResults{outer,1} = [topNResults{outer,1},  TPR/nuser];
         
    end % end outer for
          
    end % end switch
    

  
  
  % isubsett ... is the test set with uid, mid, rank
  % xrangest ... is the range per user
  