function [K] = movie_kernel(Xtrain1,Xtrain2,ipar1,ipar2,inorm,input_norm,kernel_type,norm_par,kernel_l1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% normalize and compute a kernel for training and cross kernel for two sets
% of sources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inputs: 
%       Xtrain1     training feature matrix
%       Xtrain2     second feature matrix for cross kernel  ??
%       ipar1       kernel fist parameter see below  
%       ipar2       kernel second parameter
%       inorm       =1 normalization is needed, =0 otherwise
%       input_norm  type of input normalization, only l2 norm is
%                   implemented 
%       kernel_type kernel type, linear, polynomial, Gaussian 
%       norm_par    not used
%       kernel_l1   not_used
%       
% outputs:
%       K         normalized kernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
   global kernel_param;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  disp('Linear kernel');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  mtrain1 = size(Xtrain1,1);
  nw      = size(Xtrain1,2);
  
  if prod(size(Xtrain2))>0        % is the second source given ? ...It gives the no. of the elements in a matrix (ie, the product of size (rows, cols) of a matrix
    mtrain2 = size(Xtrain2,1);    % 1= rows, 2 =cols
    d1      = sum(Xtrain1.^2,2);  % sum(,1) sum along all rows , sum(,2) along colms
    d2      = sum(Xtrain2.^2,2);
    K       = Xtrain1*Xtrain2';  
    K_Inner = Xtrain1*Xtrain2';  
  else                            % base case
    mtrain2  = mtrain1;
    d1       = sum(Xtrain1.^2,2);
    d2       = d1;    
    
    disp('Xtrain1');
    disp(size(Xtrain1));    
    K        = Xtrain1*Xtrain1';  % Simply a dot product ...i.e. K = A.A'
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  disp('Normalization:');  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if inorm == 1
    switch input_norm
     case 0                             % row wise by L2 norm
      if prod(size(Xtrain2))>0
        xnorm1 = sum(Xtrain1.^2,2);
        xnorm1 = sqrt(xnorm1);
        xnorm1 = xnorm1+(xnorm1==0);
        xnorm2 = sum(Xtrain2.^2,2);
        xnorm2 = sqrt(xnorm2);
        xnorm2 = xnorm2+(xnorm2==0);        
        K  = K./(xnorm1*xnorm2');
        d1 = ones(mtrain1,1);            % (rows, cols)
        d2 = ones(mtrain2,1);
      else           
          
        % What is going on here? ...looking normalization of diagonal
        % components only?
        
        d = sqrt(diag(K));
        %disp('value of ddddddd')% ??? (K is a matrix obtained by dot product of xtrain)
        d = d+(d==0);       % avoid divison by zer
        K = K./(d*d');
       %K = movie_kernel_norm_l2(K);
        d1 = ones(mtrain1,1);
        d2 = d1;
      end
    end
  end
  
  % dd' creats   [r_{m_1,u_1}^2 
  %               r_{m_2,u_2}^2 
  %               r_{m_3,u_3}^2 
  %               .............  ] m x m
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  disp('Nonlinear kernel:');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  switch kernel_type
    case 0
    
    %%%%%%%%%%%%%%%    
    % polynomial
    %%%%%%%%%%%%%%%
    case 1         
      K=(K+ipar2).^ipar1;                 % k =<input, input> --> k=(<>+ par2)^par1 ...<> has been computed above
      if prod(size(Xtrain2)) == 0
        d = sqrt(diag(K));                % normalixation of the diagonal entries
        d = d+(d==0);                     % avoid divison by zero
        K = K./(d*d');
%       K=movie_kernel_norm_l2(K);
      end

    case 11    
        SW  = 1-(Xtrain1>0);
        SWF = kernel_param.nuser - (SW * SW');  % org        
        K = K ./(SWF + (SWF==0)) ;              % avoid division by zero
      
        % First Normalization
        d = sqrt(diag(K));                     
        d = d+(d==0);      
        K = K./(d*d');
        
       %Rest is the same (Second Normalization)
        K=(K+ipar2).^ipar1;                 % k =<input, input> --> k=(<>+ par2)^par1 ...<> has been computed above
        if prod(size(Xtrain2)) == 0
           d = sqrt(diag(K));                % normalixation of the diagonal entries
           d = d+(d==0);                     % avoid divison by zero
           K = K./(d*d');
        end
        
    %%%%%%%%%%%%%%%    
    % 
    %%%%%%%%%%%%%%%
    
    case 22
       K=(K+ipar2).^ipar1;                % k =<input, input> --> k=(<>+ par2)^par1 ...<> has been computed above
      if prod(size(Xtrain2)) == 0
        d = sqrt(diag(K));                % normalixation of the diagonal entries
        d = d+(d==0);                     % avoid divison by zero
        K = K./(d*d');
        K = K .* K;
      end
        
    case 2 % sigmoid
      K = tanh(ipar1*K+ipar2);
      
    %%%%%%%%%%%%%%%
    % Gaussian                                           % Output kernel
    %%%%%%%%%%%%%%%
    % it is nt looking standard guassian???
    case 3  
      K = d1*ones(1,mtrain2) + ones(mtrain1,1)*d2'-2*K;  % d1* ones(1,..) is extending d1 col wise, initailly we have one col for d1; now we have mtrain cols for d1
      K = exp(-K/ipar1);                                 % ipar1 = sigma
      
    case 33        
        SW  = 1-(Xtrain1>0);
        SWF = kernel_param.nuser - (SW * SW');            
        K   = K ./(SWF + (SWF==0)) ;          % avoid division by zero  
        
              % First Normalization
        d = sqrt(diag(K));                     
        d = d+(d==0);      
        K = K./(d*d'); 
        
        K = d1*ones(1,mtrain2) + ones(mtrain1,1)*d2'-2*K;  % d1* ones(1,..) is extending d1 col wise, initailly we have one col for d1; now we have mtrain cols for d1
        K = exp(-K/ipar1);  
          
    case 4   % Inner Product
%        K = K;
%        K = K/kernel_param.nuser;                       % divided by the
%        number of users?????? (Also error increases if we do so?)
    case 5

      % Kronecker Delta
      disp('came to make kronckers');                    % Why it does not work, ask???
      
      K=ones(1682,1682);
      K_rows = size(K,1);
      K_cols = size(K,2);            
      
%       for i=1:K_rows
%          if(i>100 && mod(i,100)==0)
%             disp(i);
%          end         
%           for j=1:K_cols
%             if(i==j)
%                 K(i,j)=1;
%             else
%                 K(i,j)=0;
%             end
%          end
%       end  
        
        
    case 44   % Inner Product
      K = K/kernel_param.nuser;                          % divided by the number of users??????
      K = K .* K;
    case 31  % PolyGauss
      K = d1*ones(1,mtrain2)+ones(mtrain1,1)*d2'-2*K;
      K = K-K.*(K<0);
      K = sqrt(K);
      K = exp(-K.^ipar2/ipar1);
    
     case 331  % PolyGauss    
        SW  = 1-(Xtrain1>0);
        SWF = kernel_param.nuser - (SW * SW');            
        K   = K ./(SWF + (SWF==0)) ;          % avoid division by zero  
        
              % First Normalization
        d = sqrt(diag(K));                     
        d = d+(d==0);      
        K = K./(d*d');
        
        K   = d1*ones(1,mtrain2)+ones(mtrain1,1)*d2'-2*K;
        K   = K-K.*(K<0);
        K   = sqrt(K);
%       K   = exp(-K.^ipar2/ipar1);
        K   = exp(-K.^ipar2/(2*(ipar1^2)));
    
      
    case 41  % PolyLaplace
      K = d1*ones(1,mtrain2)+ones(mtrain1,1)*d2'-2*K;
      K = exp(-K.^ipar2/ipar1);                           % l1 norm
      
    case 51  % Exponent
      K = d1*ones(1,mtrain2)+ones(mtrain1,1)*d2'-2*K;
      K = exp(-K.^ipar2/(2*(ipar1^2)));                           % l1 norm
      
    case 551  % PolyLaplace        l1 morm
      SW  = 1-(Xtrain1>0);
      SWF = kernel_param.nuser - (SW * SW');            
      K   = K ./(SWF + (SWF==0)) ;          % avoid division by zero  
        
      % First Normalization
      d = sqrt(diag(K));                     
      d = d+(d==0);      
      K = K./(d*d');
        
      K = d1*ones(1,mtrain2)+ones(mtrain1,1)*d2'-2*K;
      K = exp(-K.^ipar2/(2*(ipar1^2)));  
      
  end

  return;

  
%----------------------------------------------------
% function K=movie_kernel_norm_l2(K)
%   
%   d = sqrt(diag(K));
%   d = d+(d==0);       % avoid divison by zero
%   K = K./(d*d');
%   
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  function noOfUsersWhoSawAMovie (Xtrain1)
%    
%    rows = size(Xtrain1,1);
%    cols = size(Xtrain1,2);   
%    
%    for i=1:rows          %movies
%        for j=i: rows
%       
%                 
%        end
%    end
%         
