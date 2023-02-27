function [contextVector] = user_contextReader

 rentedforVector = [];
  ageVector = [];
  bodyVector = [];
  fitVector = [];
  userweightVector = [];
  userheightVector = [];
  butsizeVector = [];
  contextVector = [];

  
  %      ///////// reading rentedfor comtext //////////
 
    sdir1  = 'F:/MS Thesis/Data/Dataset/';       
  
       sfile1 = 'user_rentedfor_num.csv'; 

     xdata  = readmatrix([sdir1,sfile1]); 

     
%      /////////////////// reading usr age context   ////////////////////


    sdir2  = 'F:/MS Thesis/Data/Dataset/';       
   
       sfile2 = 'user_age.csv'; 

  
    
     gdata  = readmatrix([sdir2,sfile2]); 


    %///////////////////////// reading body type context /////////////////
  

     sdir3  = 'F:/MS Thesis/Data/Dataset/';       
   
       sfile3 = 'user_body_type_num.csv'; 

  
    
     btdata  = readmatrix([sdir3,sfile3]);


     %////////////////////////// reading fit context ////////////////////////////
  
      sdir4 =  'F:/MS Thesis/Data/Dataset/';       
       sfile4 = 'user_fit_num.csv';

       ftdata  = readmatrix  ([sdir4,sfile4]); 


        %////////////////////////// reading weight context ////////////////////////////
  
      sdir5 =  'F:/MS Thesis/Data/Dataset/';       
       sfile5 = 'user_weight_num.csv';

       wtdata  = readmatrix  ([sdir5,sfile5]); 


        %////////////////////////// reading height context ////////////////////////////
  
      sdir6 =  'F:/MS Thesis/Data/Dataset/';       
       sfile6 = 'user_height_num.csv';

       htdata  = readmatrix  ([sdir6,sfile6]);

       %////////////////////////// reading butsize context ////////////////////////////
  
      sdir7 =  'F:/MS Thesis/Data/Dataset/';       
       sfile7 = 'user_but_size_num.csv';

       btdata  = readmatrix  ([sdir7,sfile7]);

    tic;

%/////////////////////////// rent for /////////////////////////////////
   ndata  = size(xdata,1)   % 1=rows, 
    fdata  = size(xdata,2)   %  2 =cols
     

     for i=1:ndata
        mov= xdata(i,1);
        rentfor= xdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:7
              
               if(rentfor==j)                   
                   rentedforVector(count, j+1) = 1;
               else
                   rentedforVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:7
               if(rentfor==j)                   
                   rentedforVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:7
               

               if(rentfor==j)                   
                   rentedforVector(count, j+1) = 1;
               else
                   rentedforVector(count, j+1) = 0;
               end
        end
        
         prevmov= xdata(i,1); 
        end
        end
     end

%////////////////////////////// age ///////////////////////////////////////
      

    tic;

    ndata  = size(gdata,1);   % 1=rows, 
    fdata  = size(gdata,2);   %  2 =cols
  

     for i=1:ndata
        mov= gdata(i,1);
        age= gdata(i,2);
        
        for j=1:58

               if(age==j)                   
                   ageVector(i, j) = 1;
               else
                   ageVector(i, j) = 0;
               end
           end
     end
    
   
   %////////////////////////////////   body type   ////////////////////////////////////  
   
   ndata  = size(btdata,1);   % 1=rows, 
    fdata  = size(btdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= btdata(i,1);
        decision= btdata(i,2);
        
        
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
       
         prevmov= btdata(i,1); 
        end
        end
        
     end
   
   
% /////////////////////// Fit Reader ///////////////////


    ndata  = size(ftdata,1);   % 1=rows, 
    fdata  = size(ftdata,2);   %  2 =cols
     

    for i=1:ndata
        mov= ftdata(i,1);
        fit= ftdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:2
              
               if(fit==j)                   
                   fitVector(count, j+1) = 1;
               else
                   fitVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:2
               if(fit==j)                   
                   fitVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov) 
            count=count+1;
        for j=0:2
               

               if(fit==j)                   
                   fitVector(count, j+1) = 1;
               else
                   fitVector(count, j+1) = 0;
               end
        end
        
         prevmov= ftdata(i,1); 
        end
        end
     end

 %//////////////////////////// Weight reader //////////////////////////////
     

     ndata  = size(wtdata,1);   % 1=rows, 
    fdata  = size(wtdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= wtdata(i,1);
        decision= wtdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:112
              
               if(decision==j)                   
                   userweightVector(count, j+1) = 1;
               else
                   userweightVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:112
               if(decision==j)                   
                   userweightVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:112
               

               if(decision==j)                   
                   userweightVector(count, j+1) = 1;
               else
                   userweightVector(count, j+1) = 0;
               end
        end
        
         prevmov= wtdata(i,1); 
        end
        end
     end
     
    % ///////////////////////// Height reader //////////////////////////

     ndata  = size(htdata,1);   % 1=rows, 
    fdata  = size(htdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= htdata(i,1);
        decision= htdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:17
              
               if(decision==j)                   
                   userheightVector(count, j+1) = 1;
               else
                   userheightVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:17
               if(decision==j)                   
                   userheightVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:17
               

               if(decision==j)                   
                   userheightVector(count, j+1) = 1;
               else
                   userheightVector(count, j+1) = 0;
               end
        end
        
         prevmov= htdata(i,1); 
        end
        end
     end

     % //////////////////// But Size reader ////////////////////////////

     ndata  = size(btdata,1);   % 1=rows, 
    fdata  = size(btdata,2);   %  2 =cols
     

     for i=1:ndata
        mov= btdata(i,1);
        decision= btdata(i,2);
        
        
        if(i==1)
            count=1;
        for j=0:57
              
               if(decision==j)                   
                   butsizeVector(count, j+1) = 1;
               else
                   butsizeVector(count, j+1) = 0;
               end
               prevmov= mov;
        end    
        else    
         
        if(prevmov==mov)
         for j=0:57
               if(decision==j)                   
                   butsizeVector(count, j+1) = 1;
               end
         end

         
        end   
       
        if(prevmov~=mov)
            count=count+1;
        for j=0:57
               

               if(decision==j)                   
                   butsizeVector(count, j+1) = 1;
               else
                   butsizeVector(count, j+1) = 0;
               end
        end
        
         prevmov= btdata(i,1); 
        end
        end
     end
   

contextVector = [rentedforVector,ageVector,userheightVector,userweightVector,butsizeVector,bodyVector]
   
     toc;
     
 return





