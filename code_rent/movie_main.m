 
clear;

% !!!!!!!!!!!modification rules !!!!!!!!!!!!!!!!
% #############################################
% program parts between %############
% are data specific, others may work without modification
% Check mmr_validation.m too !!!!!!
% ############################################

% using globals might save memory

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

global u_contextdata

global xdata; 


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

global KXmfull;      % complete user score based movie kernel  (training)


global KYfull;       % rank kernel (Gaussian)
global kernel_param; % control parameters
global whichVersion; % 0= IBMMR,1= UBMMR itembased userbased
global xselector_ub; % for ub cased, we will still keep the org test/train indices
global xselector_ib;
global isValidation;    % flag to sow, if this is val or test
global Clustered;       % 1 = use clusted averages
global currentFold;     % keep track of the number of folds 
global trainOrTest;     %=1, train; =0, test
global versionStart;

% PARAMETERS 
% User oriented or item oriented
% whichVersion          = 0;         %(original one)
  whichVersion          = 1;
  wannaLoadDataAgain    = 1;
  Clustered             = 0; 
  ledaOrLocal           = 0;

  % k-fold cross validation
nrepeat = 1;                % number of the repetation of the full experiment
nfold   = 5;                % number of folds >1
kernel_param.nfold = nfold;

% ilabmode:  labeling mode of multiclass
%               =0 indicators
%               =1 class mean
%               =2 class median
%               =3 tetrahedron
ilabmode = 0;

validation_param.vnfold = 2;  % number folds(>1) in validation
ivalidyn                = 0;  % =0 no validation, =1 validation
totalFolds              = 5;

% result collectors
xresult     = zeros(nrepeat,totalFolds);
xresult01   = zeros(nrepeat,totalFolds);
xresultf    = zeros(nrepeat,totalFolds,3);
xresulttr   = zeros(nrepeat,totalFolds);
nparam      = 4;              % C,D,par1,par2



% Results
  totalVersions     = 3;   % 
  myRecall_top20    = rand(nrepeat,totalVersions,totalFolds)  ;  
  myPrecision_top20 = rand(nrepeat,totalVersions,totalFolds)  ;  
  myF1_top20        = rand(nrepeat,totalVersions,totalFolds)  ;  
  myROC             = rand(nrepeat,totalVersions,totalFolds)  ;  
  myMAE             = rand(nrepeat,totalVersions,totalFolds)  ;  

xbest_param = zeros(nrepeat,totalVersions, totalFolds,nparam);  

% what these parameters mean????
% optimization parameters  
optim_param.niter   = 25;     % maximum iteration
optim_param.normx   = 1;      % normalization within the kernel by this power
optim_param.normy   = 1;      % normalization within the kernel by this power
optim_param.normx2  = 1;      % normalization of duals bound
optim_param.normy2  = 1;      % normalization of duals bound
optim_param.ilabel  = 0;      % 1 explicit labels, 0 implicit labels 
optim_param.ibias   = 0;      % 0 no bias considered, 1 bias is computed 
optim_param.i_l2_l1 = 1;      % =1 l2 norm =0 l1 norm regularization  ................. l2= sqrt(sum of square of input), l1=sum of abs of input


% kernel parameters 
kernel_param.kernel_type  = 11; % 0 linear, 1 polynomial, 3 Gaussian, 11 SWS polynomial
kernel_param.ykernel_type = 3;   % 0 linear, 1 polynomial, 3 Gaussian ................ output kernel
kernel_param.kernel_l1    = 0;   % =0 L2 norm based =1 L1 norm based

% possible parameter ranges scanned in the validation
switch kernel_param.kernel_type
case {1,11}
%% polynomial kernel; par1=degree and par2=constant        
%% ..... k(x,y) = (x.y)^d or (x.y + c)^d
  kernel_param.par1min  = 0;               
  kernel_param.par1max  = 10; 
  kernel_param.par2min  = 0;       % what are these params?
  kernel_param.par2max  = 1.1; 
  kernel_param.par1step = 1; 
  kernel_param.par2step = 0.1; 
case 2
%% sigmoid kernel; par1=factor and par2=constant
  kernel_param.par1min=0.01; 
  kernel_param.par1max=0.1; 
  kernel_param.par2min=0; 
  kernel_param.par2max=0.1; 
  kernel_param.par1step=0.01; 
  kernel_param.par2step=0.01; 
case 3
%% Gaussian kernel; par1=variance(width) 
  kernel_param.par1min=0.01; 
  kernel_param.par1max=0.01; % ~10 
  kernel_param.par2min=0; 
  kernel_param.par2max=0;
  kernel_param.par1step=1; 
  kernel_param.par2step=1; 
  kernel_param.nrange=10; 
case {31,331}
%% PolyGaussian kernel; par1=variance(width) 
  kernel_param.par1min  = 0.01; 
  kernel_param.par1max  = 10; % ~10 
  kernel_param.par2min  = 1.0; 
  kernel_param.par2max  = 5;
  kernel_param.par1step = 0.5; 
  kernel_param.par2step = 0.5; 
  kernel_param.nrange   = 20; 
  kernel_param.dpower   = 1.0;
  kernel_param.spower   = 1.0;
case 41
%% PolyLaplace kernel; par1=variance(width) 
  kernel_param.par1min=0.3; 
  kernel_param.par1max=0.8; % ~10 
  kernel_param.par2min=0; 
  kernel_param.par2max=0;
  kernel_param.par1step=1; 
  kernel_param.par2step=1; 
  kernel_param.nrange=5; 
  kernel_param.dpower=1.0;
otherwise
  kernel_param.par1min=0; 
  kernel_param.par1max=0;  
  kernel_param.par2min=0; 
  kernel_param.par2max=0;
  kernel_param.par1step=1; 
  kernel_param.par2step=1; 
end

kernel_param.ipar1  = kernel_param.par1min;  % degree             %Polynomial Kernel
kernel_param.ipar2  = kernel_param.par2min;  % constant
kernel_param.ipar1y = 13;                    % not used           %Gaussian Sigma?
kernel_param.ipar2y = 0;

disp('ipar1y:');
disp(kernel_param.ipar1y);

% For what Normalization is????

%       ixnorm      type of normalization
%                   -1 no normalization
%                   0 vector-wise normalizatin by L2 norm
%                   1 variable-wise normalizatin by mean and standard deviation
%                   2 normalization by projection onto a ball 
%                   3 vector-wise normalization by L1 norm
%                   4 vector-wise normalization by L_infty norm
%                   5 variable-wise normalization by L1 norm; median +

kernel_param.input_norm = 0;            % normalization type for movie_normalization (only L2 is implemented)
kernel_param.inorm      = 1;            % =0 no normalization =1, normalization by input_norm
kernel_param.norm_par   = -3;           % normalization parameter for case 14
kernel_param.rcenter    = 3;

%%% Value of C, D
%%%%%%%%%%%%%%%%%%
% range for C the trade off parameter between regularization and error
% upper bound on the dual variables
kernel_param.cmin  = 20;
kernel_param.cmax  = 20;
kernel_param.cstep = 0.1;
% range for D the trade off parameter between regularization and error
% lower bound on the dual variables, generally it assumed to be zero
kernel_param.dmin  = 0.0;
kernel_param.dmax  = 0.0;
kernel_param.dstep = 0.5;

%**************************************************
% psubset       = 0.05;    % random subset of the complete ec classes(leaves)
% nsubstring    = 4;       % length of substring in the spectrum kernel
% num_substring = 500;     % average number of substring in a primary sequence

display(['Kernel type:'      ,num2str(kernel_param.kernel_type)]);
display(['norm, L2=1, L1=0:' ,num2str(optim_param.i_l2_l1)]);
display(['normalisation:'    ,num2str(kernel_param.input_norm)]);

% check parameters
if nfold<2
  nfold = 2;
  kernel_param.nfold = 2;  %  vnfold=4; % number of validation folds
end

% load the databases

% ###############################################################
%  X or KX  you may compute within mmr_train.m as demonstrated with
%  general kernels
%  Y or KY  they are similar to the input items
%  Y0
% ###############################################################

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data file
% **** examle spectrum data from UCI repository
%%%%%%%%%%%%%%%%%%%%%%%%%4%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kernel_param.idataset  = 0;  % =0 100K, =1 1M, =2 10M, 3= ft1, 4=ft5
kernel_param.itestmode = 1;  % =0 fixed folds =1, random folds =2, Marlin's strong

switch kernel_param.idataset
  case 0
   nuser        = 4653;  
   nmovie       = 4482;
   ndata        = 40669 ; %nrows

   


 
  if(ledaOrLocal ==0)
    sdir        = 'F:/MS Thesis/Data/Dataset/'; %to change
    resultDir   = 'F:/MS Thesis/Data/Results/'; 
  else      
    sdir        = 'F:/MS Thesis/Data/Dataset/'; %to change
    resultDir   = 'F:/MS Thesis/Data/Results/'; 
  end
  
%   sext_tra     = 'base';
%   sext_tes     = 'test';
%     
%   shead      ='u';
%   stail      = ['a','b'];             %was nt there


%     shead_tra   = 'sml_trainSetFold';
%     shead_tes   = 'sml_testSetFold';   
%     stail       = ['1','2','3','4','5'];    
    
  sfile_full ='user_item_rating.data'; % when we pass .data file here then in  genreReader pass csv file

%     sfile_full ='sml_u.txt';
%      sfile_full ='sml_ratings.dat';
   
%  case 1
%    nuser       = 6040;
%    nmovie      = 3952;                                                                                                                                                                         
%    ndata       = 1000209;
%    
%    if(ledaOrLocal==0)
%        sdir       = 'C:/Users/Musi/Desktop/movie_ml_5//movie_ml/ml_data_1M/';
%    else
%        sdir       = '/export/1/home/mag208r/movie_ml_5/movie_ml/ml_data_1M/';    
%    end
%    
%    sext_tra    = 'train';
%    sext_tes    = 'test';
%    shead       = 'r';                  %?
%    stail       = ['a','b'];            %??
%    sfile_full  = 'ratings.dat';
%    
%  case 2
%    nuser       = 71567;
%    nmovie      = 10681;
%    ndata       = 10000054;
%    
%    if(ledaOrLocal==0)
%        sdir        = 'C:/Users/Musi/Desktop/movie_ml_5/movie_ml/ml_data_10M/';
%    else
%       sdir       = '/export/1/home/mag208r/movie_ml_5/movie_ml/ml_data_10M/';
%    end
%    
%    sext_tra    = 'train';
%    sext_tes    = 'test';
%    shead       = 'r';
%    stail       = ['a','b'];
%    sfile_full  = 'ratings.dat';
%    
%   case 3
%    nuser       = 1214;            % change them
%    nmovie      = 1922;
%    ndata       = 10000054;
%    
%    if(ledaOrLocal==0)
%        sdir        = 'C:/Users/Musi/Desktop/movie_ml_5/movie_ml/ft_data_1/';
%    else
%        sdir       = '/export/1/home/mag208r/movie_ml_5/movie_ml/ft_data_1/';    
%    end
%    sext_tra    = 'train';
%    sext_tes    = 'test';
%    shead       = 'r';
%    
%    shead_tra   = 'ft_trainSetFoldBoth1';
%    shead_tes   = 'ft_testSetFoldBoth1'; 
%    stail       = ['1','2','3','4','5'];   
%    sfile_full  = 'ft_myNorRatingsBoth1.dat';   
%    
%   case 4
%   nuser       = 1016;            % change them
%   nmovie      = 314;
%   ndata       = 10000054;
%    if(ledaOrLocal==0)
%           sdir        = 'C:/Users/Musi/Desktop/movie_ml_5/movie_ml/ft_data_5/';                   
%    else
%            sdir        = '/export/1/home/mag208r/movie_ml_5/movie_ml/ft_data_5/';    
%    end
%   sext_tra    = 'train';
%   sext_tes    = 'test';
%   shead       = 'r';        
    
%    shead_tra   = 'ft_trainSetFoldBoth5';
%    shead_tes   = 'ft_testSetFoldBoth5'; 
%    stail       = ['1','2','3','4','5'];   
%    sfile_full  = 'ft_myNorRatingsBoth5.dat';        
%   
%   case 5
%   nuser       = 1016;            % change them
%   nmovie      = 314;
%   ndata       = 10000054;
%    if(ledaOrLocal==0)
%            sdir        = 'C:/Users/Musi/Desktop/movie_ml_5/movie_ml/nf_data/';                   
%    else
%            sdir        = '/export/1/home/mag208r/movie_ml_5/movie_ml/nf_data/';    
%    end
%   sext_tra    = 'train';
%   sext_tes    = 'test';
%   shead       = 'r';        
    
%    shead_tra   = 'netflixTrainingSet';
%    shead_tes   = 'netflixTrainingSet'; 
%    stail       = ['1','2','3','4','5'];   
%    sfile_full  = 'netflixTrainingSet.dat';        
%    
    
end

%   kernel_param.nuser        = nuser;
%   kernel_param.nmovie       = nmovie;
%   kernel_param.ndata        = ndata;

    kernel_param.ieval_type   = 3;            % =0 hamming, =1 sqrt(L2), =2 L1
  
  
% rank values
%  if (kernel_param.idataset == 2)
%    Y0=[0.5,1,1.5,2,2.5,3,3.5,4,4.5,5]';
%  elseif (kernel_param.idataset == 0|| kernel_param.idataset == 1 || kernel_param.idataset == 5)
    Y0=[1,2,3,4,5,6,7,8,9,10]';
  
    % Y0=[0.25,0.5,0.75,1,1.25,1.5,1.75,2,25,2.5,3.75,3,3.25,3.5,3.75,4,4.25,4.5,4.75,5,5.25,5.5,5.75,6,6.25,6.5,6.75,7,7.25,7.5,7.75,8,8.25,8.5,8.75,9,9.25,9.5,9.75,10]';
%    Y0=[0.5,1,1.5,2,2.5,3,3.5,4,4.5,5]';
%  else
%    Y0=[0.25,0.5,0.75,1,1.25,1.5,1.75,2,25,2.5,3.75,3,3.25,3.5,3.75,4,4.25,4.5,4.75,5]';          
%  end
  
% grid parameters for Y kernel  (for Gaussian kernel)
kernel_param.ymax   =  max(abs(Y0))+1;  % it will be recomputed in movie_ranges
kernel_param.ymin   = -max(abs(Y0))-1;  % it will be recomputed in movie_ranges
kernel_param.yrange = 120;              % it will be recomputed in movie_ranges
kernel_param.ystep  = 0.1;  

% ############################################################
% for ipar1                         (polynomial)
%   for ipar2                       (polynomial)
%     for ipar1y                    (sigma)
%       for nitrations              (for optimization)
%         for folds                 (folds)
%                1) data load, & movie ranges
%                2) movie validation
%                3) movie training (kernel)
%                4) movie test
%                5) evaluation
%
% ############################################################

 
        
        
        
% validation ranges
  for zipar1 = 14:14                   % zipar1?
  for zipar2 = 5:5
      
% input kernel parameters
    switch kernel_param.kernel_type
      case {1,11}
       kernel_param.ipar1 = zipar1;    % input kernel parameters (polynomial), 10, 0.5
       kernel_param.ipar2 = zipar2/10;
      case 2
       kernel_param.ipar1=zipar1/10;
       kernel_param.ipar2=zipar2/200;
      case 3
       kernel_param.ipar1=zipar1/20;
       kernel_param.ipar2=zipar2/10;
      case {31,331}
       kernel_param.ipar1=zipar1/20;
       kernel_param.ipar2=zipar2/10;
     otherwise
       kernel_param.ipar1=zipar1;
       kernel_param.ipar2=zipar2/10;
    end
    disp([zipar1,zipar2/10]);

% output (rank) kernel parameters    
  for iy1=12:12                            % output kernel parameters  
    kernel_param.ipar1y = iy1;             % only one param, SIGMA
    disp('ipar1y:');
    disp(kernel_param.ipar1y);
    
% number iterations in the optimization    % ???? (400, 500,600)
  for iiter=4:4
    optim_param.niter = iiter*100;
    disp('niter:');
    disp(optim_param.niter);

  % display the kernel parameters
  disp(kernel_param);  
     
  
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % nrepeat
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  for irepeat=1:nrepeat      

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Which version ub or ib etc
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  myStart = 1;
  myEnd   = totalVersions;
  
  versionStart = myStart;
  
  for whichVersion=myStart:1:myEnd
    
      wannaLoadDataAgain = 1;
    
%       1= ib
%       2= ub results
%       3= ub
%       4= ub+ib

%     if(myStart==1 && (whichVersion==3 || whichVersion ==4))  % keep the previous data
%         wannaLoadDataAgain =0;

%     end
%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ user base context @@@@@@@@@@@@
     if(whichVersion==1)
     
       disp('Reading user age');
			u_adata = ageReader;                         %to change only user related same as the begin
			
	   disp('Reading body type');
			u_btdata = bodytypeReader;

		disp('Reading user fit');
			u_fdata = fitReader;
		
		disp('Reading user rented for');
			u_rfdata = rentedforReader;

        disp('Reading but size');
           u_btsdata = userbutsizeReader;

        disp('Reading user height');
           u_htdata = userheightReader;
          
        disp('Reading user weigh');
           u_wtdata = userweightReader;
%
    	disp('Reading overall user_context');
           u_contextdata = user_contextReader;
%

      end
%%%%%%%%%%%%%%%%%%%%%%%%%%% end

%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ item base base  @@@@@@@@@@@@
 if (whichVersion==3 ||whichVersion==2)
     
       disp('Reading category');
			cdata = categoryReader; 
      
       disp('Reading item sizes');
            szdata = itemsizeReader;
 disp('Reading overall item context');
          i_contextdata = item_contextReader;
  end 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end

    if (whichVersion==2 || whichVersion>=4)                            % As for this version, we only need to calculate error from the previous predictions
        optim_param.niter = iiter;
    else
        optim_param.niter = iiter * 100;
    end

    if(whichVersion>2 && myStart==1)
        wannaLoadDataAgain = 0;
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nrepeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   foldStart = 1;
   foldEnd   = 1;
   
%  for ifold=foldStart:totalFolds   
   for ifold=foldStart:foldEnd   
      
       currentFold = ifold;
       
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % random fold case, or Marlin strong
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if kernel_param.itestmode==1 || kernel_param.itestmode==2  || kernel_param.itestmode==0 % For fixed folds as well
      
      if(wannaLoadDataAgain==1)
         % preload data table
          [nuser,nmovie,ndata] = movie_data_preload(sdir, sfile_full);             % We load data from the FILE,  [sdir,sfile_full] are concatenated

         % these numbers are not acurate in the description(?)      
          kernel_param.nuser   = nuser;
          kernel_param.nmovie  = nmovie;
          kernel_param.ndata   = ndata;
          disp('items')
          size(nuser)
          disp('nuser')
          size(nmovie)
          disp('data')
          size(ndata)
          
%          

%            input('xdata is defined above')
          disp('data has been loaded ');
          
      end      
  end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
    % Do it only once and then keeo them, fixed  
    % To make sure, both times we have the same indices
    if(whichVersion==myStart && ifold==foldStart && irepeat==1)  
%        if(whichVersion==3 && ifold==1)  
       if kernel_param.itestmode == 1                     % random fold case
             rand('twister',5489);                        % twister is a RNG algorithm
%              rand('twister',sum(100*clock));
            
            xselector      = ceil(nfold*rand(ndata,1));
            xselector_user = ceil(nfold*rand(nuser,1));   
            xselector_ub   = xselector;      
            xselector_ib   = xselector;                   % for using verion=3 directly, we have to use this selector

            disp(size(xselector_ub))
            disp(size(xselector_ib))
            
            disp('xselector is made with folds');
            disp(nfold);
       end            
    end
      
    switch kernel_param.itestmode
   
     % fixed folds     
     case 0
%         % for training set
% %       sfile                       = [shead,num2str(ifold),'.',sext_tra];
%         sfile                       = [shead,stail(ifold),'.',sext_tra];    
%         [nusertr,nmovietr,ndatatr]  = movie_data_preload(sdir,sfile);
%         xdatat                      = xdata;
%         % sfile                     = [shead,num2str(ifold),'.',sext_tes];
%         
%         % for test set
%         sfile                       = [shead,stail(ifold),'.',sext_tes];
%         [nuserte,nmoviete,ndatate]  = movie_data_preload(sdir,sfile);
%         xdata                       = [xdatat;xdata];  % col waise stacking
%         
%         ndata                       = size(xdata,1);
%         nuser                       = max(nuserte,nusertr);
%         nmovie                      = max(nmoviete,nmovietr);
%         kernel_param.nuser          = nuser;
%         kernel_param.nmovie         = nmovie;
%         kernel_param.ndata          = ndata;
%         isubset_tra                 = [1:ndatatr];
%         isubset_tes                 = [1:ndatate]+ndatatr;

% for training set
%         sfile                       = [shead,num2str(ifold),'.',sext_tra];
%         sfile                       = [shead_tra,stail(ifold),'.DAT'];    
%         [nusertr,nmovietr,ndatatr]  = movie_data_preloadFix(sdir,sfile);
%         xdatat                      = xdata;
%         isubset_tra                 = xdata;
%          
%         % sfile                     = [shead,num2str(ifold),'.',sext_tes];
%         
%     
%         
%       % for test set
%         sfile                       = [shead_tes,stail(ifold),'.DAT'];
%         [nuserte,nmoviete,ndatate]  = movie_data_preloadFix(sdir,sfile);
%         isubset_tes                 = xdata;
%         xdata                       = [xdatat;xdata];  % col waise stacking
%                 
%     
%         disp('n data=')
%         disp(size(xdata,1));
%         
% %       ndata                       = size(xdata,1);
% %       nuser                       = max(nuserte,nusertr);
% %       nmovie                      = max(nmoviete,nmovietr);   %????, The ranges have been compressed?
%         
%         ndata                       = size(xdata,1);
%         nuser                       = 943;
%         nmovie                      = 1682;
% 
% 
%         kernel_param.nuser          = nuser;
%         kernel_param.nmovie         = nmovie;
%         kernel_param.ndata          = ndata;
%         
        
       xselector = subSetChoser ([sdir,shead_tes,stail(ifold),'.DATA'], [sdir,shead_tes,stail(ifold),'.DATA'],ifold);
       xselector_user = 0;
       
       [isubset_tra,isubset_tes] = movie_data_select(ifold, ...
                                                     xselector, ...
                                                     xselector_user, ...
                                                     0, ...
                                                     []);
        
     % random folds     
     case 1                 
       
              [isubset_tra,isubset_tes] = movie_data_select(ifold, ...
                                                            xselector, ...
                                                            xselector_user, ...
                                                            0, ...
                                                            []);
         
    end
 

  
%%%%%%%%%%%%%%%%%%%%
% Movie Ranges
%%%%%%%%%%%%%%%%%%%%
% sparse matrices of ranks - user_avarage - movie_average + total_avarege
% % CALLING "MOVIE_RANGE" CLASS

    if (kernel_param.itestmode==1)  % random folds
        trainOrTest =1;
        [xranges_tra, xmovies_tra, glm_model_tra]   = movie_ranges(isubset_tra);
        trainOrTest =0;
        [xranges_tes, xmovies_tes, glm_model_tes]   = movie_ranges(isubset_tes);
    else   % fixed
        trainOrTest =1;
        [xranges_tra, xmovies_tra, glm_model_tra]   = movie_ranges(isubset_tra);   % No fix range can be defined
        trainOrTest =0;
        [xranges_tes, xmovies_tes, glm_model_tes]   = movie_ranges(isubset_tes);
    end

   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% validation to choose the best parameters    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   whichOption = 1;

    disp('Validation');
    
    if ((ivalidyn==1) && (whichVersion ~=2) && (whichVersion <4))
        
      isValidation = 1;   %set flag as 1
      best_param   = movie_validation(isubset_tra, ...
                                      Y0, ...
                                      optim_param, ...
                                      validation_param, ...
                                      whichOption);
    else
      isValidation    = 0;  % set flag as 0
      best_param.c    = kernel_param.cmin;          % Manually Assigned Parameters
      best_param.d    = kernel_param.dmin;
      best_param.par1 = kernel_param.ipar1;
      best_param.par2 = kernel_param.ipar2;
    end
    
    isValidation = 0;
    
    disp('Best parameters found by validation');    % Empirically found best params
    disp(best_param);
    xbest_param(irepeat, whichVersion, ifold,1) = best_param.c;
    xbest_param(irepeat, whichVersion, ifold,2) = best_param.d;
    xbest_param(irepeat, whichVersion, ifold,3) = best_param.par1;
    xbest_param(irepeat, whichVersion, ifold,4) = best_param.par2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% training with the best parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    
    disp('training');

%     whichOption =1;    
%     [xalpha] = movie_train (isubset_tra,  ... % training indeces
%                             xranges_tra,  ... 
%                             xmovies_tra,  ... % movie features
%                             best_param.c, ...
%                             best_param.d, ...
%                             optim_param,  ... % optimization parameters 
%                             Y0, ...           % RANKS
%                             whichOption);     % 1=RATING KERNEL, 2=GENRE KERNEL
    
% 
%     whichOption =2;    
%     [xalpha1] = movie_train (isubset_tra,  ... % training indeces
%                             xranges_tra,  ... 
%                             xmovies_tra,  ... % movie features
%                             best_param.c, ...
%                             best_param.d, ...
%                             optim_param,  ... % optimization parameters 
%                             Y0, ...           % RANKS
%                             whichOption);               % 1=RATING KERNEL, 2=GENRE KERNEL

%     whichOption = 3;    
%     [xalpha2] = movie_train (isubset_tra,  ... % training indeces
%                              xranges_tra,  ... 
%                              xmovies_tra,  ... % movie features
%                              best_param.c, ...
%                              best_param.d, ...
%                              optim_param,  ... % optimization parameters 
%                              Y0, ...           % RANKS
%                              whichOption);               % 1=RATING KERNEL, 2=GENRE KERNEL

   whichOption = 4;    
   trainOrTest = 1;
   [xalpha3]   = movie_train(isubset_tra,  ...  % training indeces
                             xranges_tra,  ... 
                             xmovies_tra,  ... % movie features                             
                             best_param.c, ...
                             best_param.d, ...
                             optim_param,  ... % optimization parameters 
                             Y0, ...           % RANKS
                             whichOption);               % 1=RATING KERNEL, 2=GENRE KERNEL
% Zpred_ub


      
% %    General
    [xalpha]  = [xalpha3];
    [xalpha1] = [xalpha3];
    [xalpha2] = [xalpha3];
    [xalpha4] = [xalpha3];
%       
%     % Simple Rating one       
%     [xalpha1] = [xalpha];
%     [xalpha2] = [xalpha];
%     [xalpha3] = [xalpha];
%     [xalpha4] = [xalpha];
%   
    
% cls transfers the dual variables to the test procedure
% compute test 

% check the train accuracy
    disp('test on training');

% $$$     [Zuser]=movie_test(isubset_tra,isubset_tra,xranges_tra,xranges_tra, ...
% $$$                        xmovies_tra,xmovies_tra,glm_model_tra, ...
% $$$                        Y0,xalpha);  
% $$$                   
% $$$     
% $$$ % counts the proportion the ones predicted correctly    
% $$$ % ######################################
% $$$     deval=movie_eval(kernel_param.ieval_type,nuser,isubset_tra, ...
% $$$                      xranges_tra,Zuser);
% $$$     xresulttr(irepeat,ifold)=deval;
% ######################################     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check the test accuracy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('test on test');
   [ZuserT] = movie_test(isubset_tra, ...  % training set
                        isubset_tes, ...  
                        xranges_tra, ...  % training ranges
                        xranges_tes, ...
                        xmovies_tra, ...  % movie features for training
                        xmovies_tes, ...
                        glm_model_tra,... % total, user and movie averages
                        Y0, ...           % possible rankes  
                        xalpha, ...
                        xalpha1, ...      % dual variables  
                        xalpha2, ... 
                        xalpha3, ...
                        xalpha4, ...
                        whichOption, ...
                        ifold);
                    
% counts the proportion the ones predicted correctly
% ####################################

%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%


   [topNResults, deval] = movie_eval(kernel_param.ieval_type, ...   % type
                                     nuser, ...                     % no. of users 
                                     isubset_tes, ...               % test set   
                                     xranges_tes, ...               % test set range 
                                     ZuserT, ...                    % predictions
                                     glm_model_tra);                % total, user and movie averages
                    
     xresultte(irepeat,ifold)         = deval;                      % MAE etc
     xtopNPrecision_20(irepeat,ifold) = topNResults{3,1}(1);
     xtopNRecall_20(irepeat,ifold)    = topNResults{3,1}(2);
     xtopNF1_20(irepeat,ifold)        = topNResults{3,1}(3);
     xtopNROC(irepeat,ifold)          = topNResults{6,1}(4);        % why I have index 6???

     disp('result');
       
     % Store results for each version as well
     myPrecision_top20 (irepeat, whichVersion,ifold)  = topNResults{3,1}(1);
     myRecall_top20 (irepeat, whichVersion,ifold)     = topNResults{3,1}(2);
     myF1_top20 (irepeat, whichVersion,ifold)         = topNResults{3,1}(3);
     myROC (irepeat, whichVersion,ifold)              = topNResults{6,1}(4);
     myMAE (irepeat, whichVersion,ifold)              = deval;
     

% % ####################################    
%     disp('*** repeatation,fold ***'); 
%     disp([irepeat,ifold]);
%     
%     disp('Result in one fold and one repeatation');
%     disp('Accuracy on train');
%     disp([xresulttr(irepeat,ifold)]);
%     disp('Accuracy on test');
%     disp([xresultte(irepeat,ifold)]);
%     disp('Precision_Top20 on test');
%     disp([xtopNPrecision_20(irepeat,ifold)]);
%     disp('Recall_Top20 on test');
%     disp([xtopNRecall_20(irepeat,ifold)]);
%     disp('F1_Top20 on test');
%     disp([xtopNF1_20(irepeat,ifold)]);
%     disp('ROC on test');
%     disp([xtopNROC(irepeat,ifold)]);


    disp('**************** repeatation, whichVersion, fold ****************'); 
    disp([irepeat,whichVersion,ifold]);
 
    
    disp('Result in one fold and one repeatation');
    disp('Accuracy on train');
    disp(xresulttr(irepeat,ifold));
    disp('Accuracy on test');
    disp(myMAE(irepeat,whichVersion,ifold));
    disp('Precision_Top20 on test');
    disp(myPrecision_top20(irepeat,whichVersion,ifold));
    disp('Recall_Top20 on test');
    disp(myRecall_top20(irepeat,whichVersion,ifold));
    disp('F1_Top20 on test');
    disp(myF1_top20(irepeat,whichVersion,ifold));
    disp('ROC on test');
    disp(myROC(irepeat,whichVersion,ifold));
    
% ####################################  
    

   
  end % ifold
    disp('******************************');
    disp('Result in one repeatation');
    disp('******************************');
    disp('Mean and std of the accuracy on train');
    disp([mean(xresulttr(irepeat,:)),                                      std(xresulttr(irepeat,:))]);
    disp('Mean and std of the accuracy on test');
    disp([mean(myMAE(irepeat,whichVersion,foldStart:foldEnd)),             std(myMAE(irepeat,whichVersion,foldStart:foldEnd))]);
    disp('Mean and std of the precision_Top20 on test');
    disp([mean(myPrecision_top20(irepeat,whichVersion,foldStart:foldEnd)), std(myPrecision_top20(irepeat,whichVersion,foldStart:foldEnd))]);
    disp('Mean and std of the Recall_Top20 on test');
    disp([mean(myRecall_top20(irepeat,whichVersion,foldStart:foldEnd)),    std(myRecall_top20(irepeat,whichVersion,foldStart:foldEnd))]);
    disp('Mean and std of the F1_Top20 on test'); 
    disp([mean(myF1_top20(irepeat,whichVersion,foldStart:foldEnd)),        std(myF1_top20(irepeat,whichVersion,foldStart:foldEnd))]);
    disp('Mean and std of the ROC on test');
    disp([mean(myROC(irepeat,whichVersion,foldStart:foldEnd)),             std(myROC(irepeat,whichVersion,foldStart:foldEnd))]);
  
    
 end % making UB and IB version
 
end % irepeat

  for version = myStart:totalVersions
    disp('**************** Overall result ****************');
    disp('version=');
    disp(version);
    disp('Mean and std of the accuracy on train + error');
    disp([mean(xresulttr(:)),                                          std(std(xresulttr(:))),                                    1-mean(xresulttr(:))]);
    disp('Mean and std of the accuracy on test + error');
    disp([mean(mean(myMAE(:,version,foldStart:foldEnd))),              std(std(myMAE(:,version,foldStart:foldEnd))),              1-mean(mean(myMAE(:,version,foldStart:foldEnd)))]);
    disp('Mean and std of the Precision_top20 on test + error');
    disp([mean(mean(myPrecision_top20(:,version,foldStart:foldEnd))),  std(std(myPrecision_top20(:,version,foldStart:foldEnd))),  1-mean(mean(myPrecision_top20(:,version,foldStart:foldEnd)))]);
    disp('Mean and std of the Recall_top20 on test + error');
    disp([mean(mean(myRecall_top20(:,version,foldStart:foldEnd))),     std(std(myRecall_top20(:,version,foldStart:foldEnd))),     1-mean(mean(myRecall_top20(:,version,foldStart:foldEnd)))]);
    disp('Mean and std of the F1_top20 on test + error');
    disp([mean(mean(myF1_top20(:,version,foldStart:foldEnd))),         std(std(myF1_top20(:,version,foldStart:foldEnd))),         1-mean(mean(myF1_top20(:,version,foldStart:foldEnd)))]);
    disp('Mean and std of the topNROC on test + error');
    disp([mean(mean(myROC(:,version,foldStart:foldEnd))),              std(std(myROC(:,version,foldStart:foldEnd))),              1-mean(mean(myROC(:,version,foldStart:foldEnd)))]);
  end

  
 disp('Average best parameters');
 sfield = fieldnames(best_param);

 outputFileName = [resultDir, 'ResultsForParameterTrainingV1To_', num2str(kernel_param.idataset), '.txt']; 
 file_1 = fopen(outputFileName,'w');

 for version = myStart:totalVersions
     disp('-------------------------------------------------');
    % fprintf(file_1,' ---------------------------------------------- \n');
  %   fprintf(file_1, version);
     fprintf(file_1,'\n');   
     
     disp(version);
     
     
    for i = 1:nparam  
      disp(sfield{i});
      qparam = squeeze(xbest_param(:, version,foldStart:foldEnd,i));
      disp([mean(qparam(:)),std(qparam(:))]);
      
      fprintf(file_1, sfield{i});
      fprintf(file_1,'\n');   
      fprintf(file_1, '%f \t %f',  mean(qparam(:)),std(qparam(:)));
      fprintf(file_1,'\n');
      
      
    end
 end
 
 fclose(file_1);
 
      end % iiter  
      end % iy1
    end %zipar2
    end %zipar1
    
    return
