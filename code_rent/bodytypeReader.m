function [bodytypeVector] = bodytypeReader

   bodytypeVector = [];
    sdir  = 'F:/MS Thesis/Data/Dataset/';       
   
       sfile = 'user_body_type_num.csv'; 

  
    
     xdata  = dlmread([sdir,sfile]);       

    tic;

    ndata  = size(xdata,1);   % 1=rows, 
    fdata  = size(xdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= xdata(i,1);
        decision= xdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:6
              
               if(decision==j)                   
                   bodytypeVector(count, j+1) = 1;
               else
                   bodytypeVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:6
               if(decision==j)                   
                   bodytypeVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:6
               

               if(decision==j)                   
                   bodytypeVector(count, j+1) = 1;
               else
                   bodytypeVector(count, j+1) = 0;
               end
        end
        
         prevmov= xdata(i,1); 
        end
        end
     end
  disp(size(bodytypeVector,1));
  disp(size(bodytypeVector,2));
     toc;
     
 return





