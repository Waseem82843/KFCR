function [rentedforVector] = rentedforReader

   rentedforVector = [];
    sdir  = 'F:/MS Thesis/Data/Dataset/';       
   
       sfile = 'user_rentedfor_num.csv'; 

  
    
     xdata  = readmatrix([sdir,sfile]);       

    tic;

    ndata  = size(xdata,1)   % 1=rows, 
    fdata  = size(xdata,2)   %  2 =cols
     

     for i=1:ndata
        mov= xdata(i,1);
        decision= xdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:7
              
               if(decision==j)                   
                   rentedforVector(count, j+1) = 1;
               else
                   rentedforVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:7
               if(decision==j)                   
                   rentedforVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:7
               

               if(decision==j)                   
                   rentedforVector(count, j+1) = 1;
               else
                   rentedforVector(count, j+1) = 0;
               end
        end
        
         prevmov= xdata(i,1); 
        end
        end
     end

     toc;
     
 return





