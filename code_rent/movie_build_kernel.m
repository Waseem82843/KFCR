function [KK] = movie_build_kernel(isubset,xranges,xmovies, Y0, whichOption)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% computes the full input and output kernels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inputs:
%     isubset           training indeces
%     xranges           user index ranges in xdata
%     xmovies           movie feature matrix    
%  
%     Y0                posible rankes
% outputs:
%     not used
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global cdata; %item category
global szdata; % item size

global i_contextdata;
       
global u_adata; %age
global u_btdata; %body type
global u_fdata; %fit
global u_rfdata; %rented for 
global u_btsdata; %but size 
global u_htdata; % hight
global u_wtdata; %weight

%global u_sdata;  %season

global u_contextdata;

global xdata;    % rank data

  global KXmfull;          
  global KXmcfull;          
  global KXgfull;        
  global KXffull;
global KXmfull;

global KXcfull;   % category kernel 
global KXszfull; % item size kernel

global KXuafull;     % age kernel
global KXubtfull;    % body type kernel
global KXuffull;     %fit kernel
global KXurtfull;    % rented for kernel
global KXubtsfull;   % but size kernel
global KXuhtfull;    % hight kernel
global KXuwtfull;    % weight kernel

%global KXusfull;     % season kernel

global KXu_contextfull;
global KXi_contextfull; 


global KXXfull;        % full input gernel 
global KYfull;         % full output kernel   
global kernel_param;   % kernel parameters
global whichVersion;
  
  nuser  = kernel_param.nuser;
  nmovie = kernel_param.nmovie;  
  KK     =  cell(nuser,1);          % not used so far
  
  ipar1     = kernel_param.ipar1;   % polynomial's
  ipar2     = kernel_param.ipar2;
  ipar1y    = kernel_param.ipar1y;  % gaussian's
  ipar2y    = kernel_param.ipar2y;  
  kernel_l1 = kernel_param.kernel_l1;
  
  disp('outfits');
   disp(size(xmovies));
%     disp('genre');
%   disp(size(gdata));

       ipar1 = 4;
       ipar2 = 0.1;
       kernel_param.kernel_type = 1;   
       
       
 if (whichVersion>=4) % If A is true, B will nt be executed, short circuit OR oprator
% % input kernel  
  KXmfull =  movie_kernel( xmovies,  ... % training feature matrix
                           [],  ...      % second feature matrix for cross kernel
                           ipar1, ...    % kernel fist parameter
                           ipar2, ...    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           kernel_param.kernel_type, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1);                   % na    

                       

                       
 end
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (whichVersion==1  ) % user kernels
  KXmfull =  movie_kernel( xmovies,  ... % training feature matrix
                           [],  ...      % second feature matrix for cross kernel
                           14, ...       % kernel fist parameter
                           0.5, ...      % kernel second parameter
                           1,  ...       % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           11, ...                        % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 
                       
          KXuafull =  movie_kernel( u_adata,  ...     % training feature matrix
                            [],  ...                      % second feature matrix for cross kernel
                            14, ...                    % kernel fist parameter
                            0.5, ...                    % kernel second parameter
                            kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                            kernel_param.input_norm, ...  % type of input normalization, (L2)
                            kernel_param.kernel_type, ... % kernel type, linear, polynomial, Gaussian 
                            kernel_param.norm_par, ...    % na
                            kernel_l1); 
                                 
         KXubtfull =  movie_kernel( u_btdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1);                 
         KXuffull =  movie_kernel( u_fdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 
         KXurtfull =  movie_kernel( u_rfdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 

         KXubtsfull =  movie_kernel( u_btsdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 
      
         KXuhtfull =  movie_kernel( u_htdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 

         KXuwtfull =  movie_kernel( u_wtdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 

         KXu_contextfull =  movie_kernel( u_contextdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 





 end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% user related %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%               
      if ( whichVersion==3 ||whichVersion==2) %item kernels
         KXmfull =  movie_kernel( xmovies,  ... % training feature matrix
                           [],  ...      % second feature matrix for cross kernel
                           14, ...       % kernel fist parameter
                           0.5, ...      % kernel second parameter
                           1,  ...       % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           11, ...                        % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 
      KXcfull =  movie_kernel( cdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1);     

      KXszfull =  movie_kernel( szdata,  ...     % training feature matrix
                           [],  ...                      % second feature matrix for cross kernel
                           14, ...                    % kernel fist parameter
                           0.1, ...                    % kernel second parameter
                           kernel_param.inorm,  ...      % =1 normalization is needed, =0 otherwise
                           kernel_param.input_norm, ...  % type of input normalization, (L2)
                           331, ... % kernel type, linear, polynomial, Gaussian 
                           kernel_param.norm_par, ...    % na
                           kernel_l1); 


                       
     
  KXi_contextfull =  movie_kernel( i_contextdata,  ...     % training feature matrix
                            [],  ...                      % second feature matrix for cross kernel
                            14, ...                    % kernel fist parameter
                            0.5, ...      % kernel second parameter
                            1,  ...       % =1 normalization is needed, =0 otherwise
                            kernel_param.input_norm, ...  % type of input normalization, (L2)
                            11, ...                        % kernel type, linear, polynomial, Gaussian 
                            kernel_param.norm_par, ...    % na
                            kernel_l1);                                          
 
                     
     end               
                       
                            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Multiply kernels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%case 1, simple point wise multiplication
 %// Preallocate matrix to accommodate result




if kernel_param.iprod==1 
   
    if (whichVersion==1 ) %user
 
       KXXfull =(KXmfull).* KXu_contextfull;

       %    KXXfull = (KXmfull) .* (KXuafull).* (KXubtfull) .* (KXuffull) .* (KXurtfull).* (KXuwtull) .* (KXuhtfull) .* (KXubtsfull)    ;
 
 
    end
    
    if (whichVersion ==3 ||whichVersion==2) %item

  KXXfull =  KXmfull .* (KXcfull) .* (KXszfull);
   %  KXXfull =  KXmfull .* (KXcfull).*(KXszfull)

    end
%    if(whichVersion==2)
%      KXXfull =  KXmfull;   
%    end                     

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else
       
 if (whichVersion==1 )
          KXXfull = (KXmfull) + (KXuafull)+ (KXubtfull) + (KXuffull) + (KXurtfull) + (KXuwtfull) + (KXuhtfull) + (KXubtsfull);

      % KXXfull =(KXusfull)
%     KXXfull =(KXmfull)+(KXubtfull)+(KXuffull)+(KXurtfull)+(KXusfull)

 end
 
 if (whichVersion ==3 ||whichVersion==2)
      KXXfull =  (KXmfull) + (KXcfull) + (KXszfull);


 end

end

%  Genre Only
  %    KXXfull  = KXgfull; 
%    KXffull  = KXgfull;
%    KXmcfull = KXgfull;
%    KXmfull  = KXgfull;      

% amazing, if I multiply, two feature vectors of the KKf, like kkf .* kkf
% then the error was less?
% Feature Only
%     KXXfull  = KXffull;
%    KXgfull  = KXffull; 
%    KXmcfull = KXffull;
%    KXmfull  = KXffull;  
  
%  Ratings Only

 %    KXXfull  = KXmfull;
%    KXgfull  = KXmfull; 
%    KXmcfull = KXmfull;
%    KXffull  = KXmfull; 
%   
 %Inner Product only
%    KXXfull  = KXmcfull;
%    KXgfull  = KXmcfull; 
%    KXmfull  = KXmcfull;
%    KXffull  = KXmcfull; 
 
%Kroncker's
%     KXXfull  = KXmkfull;
%    KXgfull  = KXmkfull; 
%    KXmfull  = KXmkfull;
%    KXffull  = KXmkfull; 


% Hybrid
%     disp('Kxf');
%     disp(size(KXffull));
%     disp('Kxm');
%     disp(size(KXmfull));
% 

%   F-R
%      KXXfull = (KXffull) .* (KXmfull); 
  %      KXXfull = (KXffull) + (KXmfull); 
%      KXXfull = (0.2 * KXffull) + (0.8 * KXmfull); 

%   KXXfull = (KXmfull) .* (KXmfull);
%   KXXfull = (KXffull) .* (KXffull);
    
%   R-G-F
%   KXXfull = (1.0 * KXffull) + (1.0 * KXmfull) + (1.0 * KXgfull); 
%     KXXfull = (0.2 * KXffull) .* (0.7 * KXmfull) .* (0.1 * KXgfull); 

  ymax      = kernel_param.ymax;
  ymin      = kernel_param.ymin;
  ystep     = kernel_param.ystep;
  yinterval = ymin:ystep:ymax;    % for (-5:0.1:5) it is [1,2,....,101]
  
% output kernel
  KYfull    = movie_kernel( yinterval', ...
                            [], ...
                            ipar1y, ... %sigma , var of gaussian
                            ipar2y, ... 
                            1, ...
                            -1, ...
                            kernel_param.ykernel_type, ... %^gaussian
                            0, ...
                            0);              % l2 norm based kernel                 
 
  return;
  
  
% ------------------------------------------------------------

% what is input and output kernel


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%To-DO:
%Make output kernel with elements consisting of square of simple
%correlation etc......Think rationally why we need them?

