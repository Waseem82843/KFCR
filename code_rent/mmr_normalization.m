function [XTrain,XTest,opar]=mmr_normalization(ixnorm,XTrain,XTest,ipar)
% function to normalize the input and the output data
% input
%       ixnorm      type of nomrlaization
%                   -1 no normalization
%                   0 vector-wise normalizatin by L2 norm
%                   1 variable-wise normalizatin by mean and standard deviation
%                   2 normalization by projection onto a ball 
%                   3 vector-wise normalization by L1 norm
%                   4 vector-wise normalization by L_infty norm
%                   5 variable-wise normalization by L1 norm; median +
%                     MAD,median of absolute deviation 
%                   6 centralization by median, 
%                     variable-wise normalization by L1 norm;  
%                   10 centralize by mean and normalize by L2 norm
%                   11 centralize by mean
%                   12 centralize by median
%                   13 shift with <ipar> normalization by L2 norm
%      XTrain       Data matrix which will be normalized. It assumed the
%                   rows are the sample vetors and the columns are variables 
%      XTest        Data matrix which will be normalized. It assumed the
%                   rows are the sample vetors and the columns are
%                   variables.
%                   In variable-wise normalization it herites the means
%                   and standard deviation from the XTrain, otherwise it
%                   is normalized independently  
%      ipar         it is considered when ixnorm=2, projection onto ball,
%                   where it is the radius of the ball   
%  output
%      XTrain       Data matrix which is the result of the normalization
%                   of input XTrain. It assumed the rows are the sample
%                   vetors and the columns are variables  
%      XTest        Data matrix which is the result of the normalization
%                   of input XTest. It assumed the rows are the sample
%                   vetors and the columns are variables.
%      opar         the radius in case of ixnorm=2.  
%  
        opar = 0;
        [mtrain,n] = size(XTrain);
        [mtest,n]  = size(XTest);
    
% normaliztion
%          ixnorm=-1;
          switch ixnorm
% element-wise normalization by L2 norm           
           case 0
              n=size(XTrain,2);
              xsum1=sum(XTrain.^2,2);
              xsum1=sqrt(xsum1);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                xsum1=sum(XTest.^2,2);
                xsum1=sqrt(xsum1);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
% variable-wise normalization based on  squared L2 norm              
            case 1
              xmean=mean(XTrain,1);
              xstd=std(XTrain,0,1);
              xstd=xstd+(xstd==0);
              XTrain=(XTrain-ones(mtrain,1)*xmean)./(ones(mtrain,1)*xstd);
              if prod(size(XTest))>1
                XTest=(XTest-ones(mtest,1)*xmean)./(ones(mtest,1)*xstd);
              end
% normalization by projection onto a ball              
           case 2 % stereographic projection
              xmean  = mean(XTrain,1);
              XTrain = XTrain-ones(mtrain,1)*xmean;
              
              xsum1  = sum(XTrain.^2,2);
%            R=max(sqrt(xsum1));
%            R=1;
              R=ipar;
%              R=mean(sqrt(xsum1));
              opar=R;
              xhom=ones(mtrain,1)./(xsum1+R^2);
              xhom2=xsum1-R^2;
            
              XTrain=[2*R^2*XTrain.*(xhom*ones(1,n)),R*xhom2.*xhom];

              if prod(size(XTest))>1
                XTest=XTest-ones(mtest,1)*xmean;
                xsum1=sum(XTest.^2,2);
                xsum1=xsum1;
                xhom=ones(mtest,1)./(xsum1+R^2);
                xhom2=xsum1-R^2;
            
                XTest=[2*R^2*XTest.*(xhom*ones(1,n)),R*xhom2.*xhom];
              end
% element-wise normalization by L1 norm           
           case 3
              n=size(XTrain,2);
              xsum1=sum(abs(XTrain),2);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                xsum1=sum(abs(XTest),2);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
% element-wise normalization by L_infty norm           
           case 4
              n=size(XTrain,2);
              xsum1=max(abs(XTrain),[],2);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1

                xsum1=max(abs(XTest),[],2);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
% variable-wise normalization based on  L1 norm              
            case 5
              xmedian=median(XTrain,1);
              
              xmad=median(abs(XTrain-ones(mtrain,1)*xmedian),1);
              
              xmad=xmad+(xmad==0);
              XTrain=(XTrain-ones(mtrain,1)*xmedian)./(ones(mtrain,1)*xmad);
              if prod(size(XTest))>1
                XTest=(XTest-ones(mtest,1)*xmedian)./(ones(mtest,1)*xmad);
              end
            case 6
              xmedian=median(XTrain,1);
       
              XTrain=(XTrain-ones(mtrain,1)*xmedian);
              
              n=size(XTrain,2);
              xsum1=sum(abs(XTrain),2);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                XTest=(XTest-ones(mtest,1)*xmedian);
                xsum1=sum(abs(XTest),2);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
              
              
           case 10 % centralize+normalize by L2 norm
              [m,n]=size(XTrain);
              xmean=mean(XTrain,1);
              XTrain=XTrain-ones(m,1)*xmean;
            
              xsum1=sum(XTrain.^2,2);
              xsum1=sqrt(xsum1);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                mt=size(XTest,1);
                XTest=XTest-ones(mt,1)*xmean;
              
                xsum1=sum(XTest.^2,2);
                xsum1=sqrt(xsum1);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
           case 11 % centralize by mean
              [m,n]=size(XTrain);
              xmean=mean(XTrain,1);
              XTrain=XTrain-ones(m,1)*xmean;
              if prod(size(XTest))>1
                mt=size(XTest,1);
                XTest=XTest-ones(mt,1)*xmean;
              end
            case 12 % centralize by median
              xmedian=median(XTrain,1);
       
              XTrain=(XTrain-ones(mtrain,1)*xmedian);
              if prod(size(XTest))>1
                XTest=(XTest-ones(mtest,1)*xmedian);
              end
           case 13 % shift by <ipar>+normalize by L2 norm
              [m,n]=size(XTrain);
              XTrain=XTrain+ipar;
            
              xsum1=sum(XTrain.^2,2);
              xsum1=sqrt(xsum1);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                mt=size(XTest,1);
                XTest=XTest+ipar;
              
                xsum1=sum(XTest.^2,2);
                xsum1=sqrt(xsum1);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
           case 14 % shift positives by <ipar> +normalize by L2 norm
              [m,n]=size(XTrain);
              XTrain=XTrain+(XTrain~=0)*ipar;
            
              xsum1=sum(XTrain.^2,2);
              xsum1=sqrt(xsum1);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                mt=size(XTest,1);
                XTest=XTest+(XTest~=0)*ipar;
              
                xsum1=sum(XTest.^2,2);
                xsum1=sqrt(xsum1);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
             
           case 15 % shift positives by <ipar> +normalize by L1 norm
              [m,n]=size(XTrain);
              XTrain=XTrain+(XTrain~=0)*ipar;
            
              xsum1=sum(abs(XTrain),2);
              xsum1=xsum1+(xsum1==0);

              XTrain=XTrain./(xsum1*ones(1,n));

              if prod(size(XTest))>1
                mt=size(XTest,1);
                XTest=XTest+(XTest~=0)*ipar;
              
                xsum1=sum(abs(XTest),2);
                xsum1=xsum1+(xsum1==0);
                XTest=XTest./(xsum1*ones(1,n));
              end
          end

