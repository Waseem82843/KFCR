
function [xselector] = subSetChoser(trSetFile,tSetFile, fold)

  disp('Locating the index of test and train samples from fixed folds');
  global xdata; 
  global whichVersion;
  
  xselector = [];
  
    sdelimit    =',';
    xdata_tr    = dlmread(trSetFile);        
    xdata_t     = dlmread(tSetFile);  
        
    % all  
    ndata  = size(xdata,1);   
    
    %tr   
    ndata_tr  = size(xdata_tr,1);   
    
    %t  
    ndata_t  = size(xdata_t,1);   
    
    
   for i=1:ndata
       uid = xdata(i,1);
       mid = xdata(i,2);
       rat = xdata(i,3);
  
       if(whichVersion==1)
           temp = uid;
           uid  = mid;
           mid  = temp;
       end
       
       for j=1:ndata_t       
           uid_t = xdata_t(j,1);
           mid_t = xdata_t(j,2);
           rat_t = xdata_t(j,3);
           
           if(uid==uid_t && mid==mid_t && rat==rat_t)
             xselector(i) =  fold;
           end           
       end
   end % end outer for
   
   xselector = xselector';
   return;
   
   