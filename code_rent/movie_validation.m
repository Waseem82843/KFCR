function best_param = movie_validation(isubset, Y0, optim_param, validation_param, whichOption)

% inputs
%         isongs        song indeces of training
  
% globals to avoid the copy of large data sets

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% What parameters, we learn in the validation........?
% only input kernel's or output kernel's as well?

  global        xdata;
  global        kernel_param;
  global        whichVersion;
  
  myIterations  = 0;  
  
  nuser         = kernel_param.nuser;
  nmovie        = kernel_param.nmovie;
  ndata         = kernel_param.ndata;  
  
  mtrain = length(isubset);          % Training set

 
 % Initialize the best parameters
     best_param.c    = 0;
     best_param.d    = 0;
     best_param.par1 = 0;
     best_param.par2 = 0;
              
 % We will specify which Kernel is being used         
  switch kernel_param.kernel_type
   case 0
    ip1min  = 0;
    ip1max  = 0;
    ip2min  = 0;
    ip2max  = 0;
    ip1step = 1;
    ip2step = 1;
   case {1,11}   
    ip1min  = kernel_param.par1min;  % min, max and step of par1 and par2
    ip1max  = kernel_param.par1max;
    ip2min  = kernel_param.par2min;
    ip2max  = kernel_param.par2max;
    ip1step = kernel_param.par1step;
    ip2step = kernel_param.par2step;
   case 2
    ip1min  = kernel_param.par1min;
    ip1max  = kernel_param.par1max;
    ip2min  = kernel_param.par2min;
    ip2max  = kernel_param.par2max;
    ip1step = kernel_param.par1step;
    ip2step = kernel_param.par2step;
   
    case {3,33}
        if kernel_param.nrange>1
          dpar = power(kernel_param.par1max/kernel_param.par1min, ...
                    1/(kernel_param.nrange-1));
        else
          dpar  = 1.0;
        end
        
    ip1min  = 1;
    ip1max  = kernel_param.nrange;
    ip2min  = 0;
    ip2max  = 0;
    ip1step = 1;
    ip2step = 1;
  
    case {31,331}
        if kernel_param.nrange>1
          dpar = power(kernel_param.par1max/kernel_param.par1min, ...
                    1/(kernel_param.nrange-1));
        else
          dpar=1.0;
        end
        
%     ip1min  = 1;
%     ip1max  = kernel_param.nrange;
%     ip2min  = kernel_param.par2min;
%     ip2max  = kernel_param.par2max;
%     ip1step = 1;
%     ip2step = kernel_param.par2step;
   
    ip1min  = kernel_param.par1min;
    ip1max  = kernel_param.nrange;
    ip2min  = kernel_param.par2min;
    ip2max  = kernel_param.par2max;
    ip1step = kernel_param.par1step;
    ip2step = kernel_param.par2step;
    
    case {41,441}
        if kernel_param.nrange>1
          dpar= power(kernel_param.par1max/kernel_param.par1min, ...
                    1/(kernel_param.nrange-1));
        else
          dpar=1.0;
        end
        
    ip1min  = 1;
    ip1max  = kernel_param.nrange;
    ip2min  = kernel_param.par2min;
    ip2max  = kernel_param.par2max;
    ip1step = 1;
    ip2step = kernel_param.par2step;
   
   otherwise 
    ip1min  = 1;
    ip1max  = 1;
    ip2min  = 1;
    ip2max  = 1;
    ip1step = 1;
    ip2step = 1;
  end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % number of validation folds
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 % vnfold = 4; % number of validation folds
  vnfold = validation_param.vnfold;        

  vxsel  = floor(rand(mtrain,1) * vnfold)+1;            % Will it nt over-ride the exisitng data (xdata)?
  vxsel  = vxsel-(vxsel>vnfold);
    
  vpredtr = zeros(vnfold,1); % valid
  vpred   = zeros(vnfold,1); % train

  disp('C, D, par1, par2, traning accuracy, validation test accuracy');    

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % scanning the parameter space  
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 xxmax = realmax;           %largest no. 
 
  for ic = kernel_param.cmin:kernel_param.cstep:kernel_param.cmax     % cmax
    for id = kernel_param.dmin:kernel_param.dstep:kernel_param.dmax   % dmax
      for ip1 = ip1min:ip1step:ip1max                                 % ip1max   ?
        for ip2 = ip2min:ip2step:ip2max                               % ip2max   ?
          
          switch kernel_param.kernel_type
           case {3,33}
             dpar1 = kernel_param.par1min*dpar^(ip1-1);
             dpar2 = ip2;
           case 31
             dpar1 = kernel_param.par1min*dpar^(ip1-1);               % where is polynomial?
             dpar2 = ip2;
           case 41
             dpar1 = kernel_param.par1min*dpar^(ip1-1);
             dpar2 = ip2;
           otherwise
             dpar1 = ip1;
             dpar2 = ip2;
          end
 
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          % For each fold
          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          % 1- select the data
          % 2- define movie ranges
          % 3- train the model
          % 4- test the model on the test set
          
          valdData = 1;
          
   for vifold = 1:vnfold
       
            [isubsetvtra,isubsetvtes] = movie_data_select(vifold, ...
                                                          vxsel, ...
                                                          vxsel, ...
                                                          valdData,...
                                                          isubset);
            
%           [xrangesvtra,xmoviesvtra,glm_model_tra] = ...
%                                         movie_ranges(isubsetvtra,kernel_param);
%             
%           [xrangesvtes,xmoviesvtes,glm_model_tes]= ...
%                                         movie_ranges(isubsetvtes,kernel_param);
%               
            % deinfe movie ranges
            [xrangesvtra,xmoviesvtra,glm_model_tra] =  movie_ranges(isubsetvtra);
            
            [xrangesvtes,xmoviesvtes,glm_model_tes] =  movie_ranges(isubsetvtes);
              
                                    
              tic
              disp('validation training');
              
              % change the parameters at each loop              
              kernel_param.ipar1 = dpar1;
              kernel_param.ipar2 = dpar2;
              
              
              [xalpha3]           = movie_train(isubsetvtra, ... % training indices
                                                xrangesvtra, ... % index ranges of users in rank data
                                                xmoviesvtra, ... % movie features
                                                ic, ...          % penalty constant   
                                                id, ...          % penalty constant   ( kernel_param, ...)                                               
                                                optim_param, ...  %????
                                                Y0,...
                                                whichOption);

                [xalpha]  = [xalpha3];
                [xalpha1] = [xalpha3];
                [xalpha2] = [xalpha3];
                [xalpha4] = [xalpha3];       
    
                
% validation training
              disp('validation test on validation training');
              [Zuser] = movie_test(isubsetvtra, ...  % training indices
                                   isubsetvtra, ...  % test indices???
                                   xrangesvtra, ...  % range
                                   xrangesvtra, ...
                                   xmoviesvtra, ...  % movie features
                                   xmoviesvtra, ...
                                   glm_model_tra, ...% averages
                                   Y0, ...
                                   xalpha, ...       % dual variable      %kernel_param);    %????                                 
                                   xalpha1,...
                                   xalpha2,...
                                   xalpha3,...
                                   xalpha4, ...
                                   whichOption, ...
                                   vifold);
                               
              
% counts the proportion the ones predicted correctly    
% ##############################################
  [topNResults, deval] = movie_eval (kernel_param.ieval_type, ...
                                     nuser, ...
                                     isubsetvtra, ...
                                     xrangesvtra, ...
                                     Zuser,...
                                     glm_model_tra);
  
  vpredtr(vifold)      = deval;
              
              
% validation test
    disp('validation test on validation test');
    
    [Zuser]           = movie_test(isubsetvtra, ...
                                   isubsetvtes, ...
                                   xrangesvtra, ...
                                   xrangesvtes, ...
                                   xmoviesvtra, ...
                                   xmoviesvtes, ...
                                   glm_model_tra, ...  %(xmoviesvtra_lm??)
                                   Y0, ...
                                   xalpha, ...    % dual variable      %kernel_param);    %????                                 
                                   xalpha1,...
                                   xalpha2,...
                                   xalpha3,...
                                   xalpha4, ...
                                   whichOption, ...
                                   vifold); 
              
% counts the proportion the ones predicted correctly    
% ##############################################
 [topNResults, deval] = movie_eval( kernel_param.ieval_type, ...
                                    nuser, ...
                                    isubsetvtes, ...
                                    xrangesvtes, ...
                                    Zuser, ...
                                    glm_model_tra);
  vpred(vifold)       = deval;
  

  end % vifold
  
   disp([ic, id, dpar1, dpar2, mean(vpredtr), mean(vpred)]);
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% searching for the best configuration in validation
            mvpred = mean(vpred);
            
            if (kernel_param.ieval_type==0)
                 mvpred = 1-mvpred;
            end
            
            if (mvpred<xxmax)                 % replace the optimal found params in this step
              xxmax       = mvpred;
              xparam.c    = ic;
              xparam.d    = id;
              xparam.par1 = dpar1;
              xparam.par2 = dpar2;
              disp(['The best:',num2str(xxmax)]);
            end
        
        end % ip2
      end % ip1
    end % id
  end %ic

best_param         = xparam;               % best parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% It was already being replaced here, so there is no need to dfo it in the
% main program

kernel_param.ipar1 = best_param.par1;      % param1
kernel_param.ipar2 = best_param.par2;





