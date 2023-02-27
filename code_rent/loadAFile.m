
function   loadAFile

sdelimit ='\t';

 myFile = 'F:/MS Thesis/Data/Dataset/user_item_rating.data';
 fid    = fopen(myFile); 
 f      =  load (myFile);
 xdata  = dlmread(myFile,sdelimit);  


