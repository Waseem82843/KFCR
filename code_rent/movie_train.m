function [xalpha] = movie_train(isubset,xranges,xmovies,...                                
                                 C,D, ...
                                 optim_param,Y0, whichOption)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate kernels and solves the optimization problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inputs:
%     isubset             training indeces
%     xranges             index ranges of users in rank data
%     xmovies             movie features     
%     C                   penalty constant
%     D                   penalty constant ( not used so far)
%     optim_param         optimization parameters
%     Y0                  possible rankes
% output:
%     xalpha              dual variables of the optimization problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have to access to the test feature vector as well, in the case of the 
% KEYWORD & GENRE cases

  disp('Generate kernels');
  [KK] = movie_build_kernel(isubset,xranges,xmovies, Y0,whichOption);
  
  
  disp('Solve optimization problem');
%  tic;
  [xalpha] = movie_solver(KK,isubset,xranges,xmovies,C,D,optim_param, whichOption);
%  disp(toc);
  
  return;
  
  
  
  