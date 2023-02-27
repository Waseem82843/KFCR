function [itemcontextVector] = item_contextReader
 categoryVector = [];
  itemsizeVector = [];

         
% ////////////////// category reader ///////////////////

    sdir1  = 'F:/MS Thesis/Data/Dataset/';       
  
       sfile1 = 'item_category_num.csv'; 

     ctgdata  = readmatrix([sdir1,sfile1]); 


 % .////////////////// Item Size reader //////////////////////////

      
        sdir2  = 'F:/MS Thesis/Data/Dataset/';       
  
       sfile2 = 'item_size_num.csv'; 

     sizdata  = readmatrix([sdir2,sfile2]); 

%      /////////////////// Item Category Context////////////////////

 
 tic;

     ndata  = size(ctgdata,1);   % 1=rows, 
    fdata  = size(ctgdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= ctgdata(i,1);
        fit= ctgdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:55
              
               if(fit==j)                   
                   categoryVector(count, j+1) = 1;
               else
                   categoryVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:55
               if(fit==j)                   
                   categoryVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov) 
            count=count+1;
        for j=0:55
               

               if(fit==j)                   
                   categoryVector(count, j+1) = 1;
               else
                   categoryVector(count, j+1) = 0;
               end
        end
        
         prevmov= ctgdata(i,1); 
        end
        end
     end
   

     %///////////////////////// item size Reader /////////////////////

     ndata  = size(sizdata,1);   % 1=rows, 
    fdata  = size(sizdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= sizdata(i,1);
        fit= sizdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:43
              
               if(fit==j)                   
                   itemsizeVector(count, j+1) = 1;
               else
                   itemsizeVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:43
               if(fit==j)                   
                   itemsizeVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov) 
            count=count+1;
        for j=0:43
               

               if(fit==j)                   
                   itemsizeVector(count, j+1) = 1;
               else
                   itemsizeVector(count, j+1) = 0;
               end
        end
        
         prevmov= sizdata(i,1); 
        end
        end
     end
  disp(size(itemsizeVector,1));
  disp(size(itemsizeVector,2));
   
   itemcontextVector= [categoryVector, itemsizeVector];
     
     
     
     
     
     toc;

return

