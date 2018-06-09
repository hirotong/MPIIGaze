function forest_algorithm()

clear all;
clc;

addpath /home/trakis/Downloads/MPIIGaze/Data/%@tree

R = 5;
HEIGHT = 9;
WIDTH = 15;



%%%%%%%%%% Open HDF5 training file %%%%%%%%%%
fid = H5F.open('myfile.h5', 'H5F_ACC_RDONLY', 'H5P_DEFAULT');






samplesInTree = zeros(140);

for i = 1:140 %for each tree


	samplesInTree(i) = 0;
	%%%%%%%%%% Start with the central group %%%%%%%%%%
	grpID = H5G.open(fid, strcat('/g',num2str(i)) );

	curr_rnearestID      = H5D.open(grpID, '5_nearestIDs');
	curr_centerID        = H5D.open(grpID, 'center');
	curr_imgsID          = H5D.open(grpID, 'data');
	curr_gazesID 	= H5D.open(grpID, 'gaze');
	curr_posesID		= H5D.open(grpID, 'headpose');

	curr_rnearest = H5D.read(curr_rnearestID);
	curr_center   = H5D.read(curr_centerID);
	curr_imgs     = H5D.read(curr_imgsID);
	curr_gazes    = H5D.read(curr_gazesID);
	curr_poses    = H5D.read(curr_posesID);

	samplesInGroup = length( curr_imgs(:,1,1,1) );
	contribOfGroup = ceil( sqrt( samplesInGroup ) );




	%treeGazes(i, :, :) = zeros(1, samplesInTree(i), 2);
	%treePoses(i, :, :) = zeros(1, samplesInTree(i), 2);
	%treeImgs (i, :, :, :) =  zeros(1, samplesInTree(i)  ,1, 2);

	j = 1;
	while j <= contribOfGroup

		samplesInTree(i) = samplesInTree(i) + 1;
		random = randi(samplesInGroup,1,1);
		treeImgs (i, samplesInTree(i), :, :) =  curr_imgs( random  ,1, :, :);
		treeGazes(i, samplesInTree(i), :) = curr_gazes( random, :);%, :);
		treePoses(i, samplesInTree(i), :) = curr_poses( random, :);
		
		j = j + 1;		

	end



	%%%%%%%% Now, continue with the R-nearest %%%%%%%%%

	for k = 1:R 
			
		localGrpID  = H5G.open(fid, strcat('/g', num2str( curr_rnearest(k))   )); 

		tempImgID  = H5D.open( localGrpID,  strcat('/g', num2str( curr_rnearest(k) ), '/data') );
		tempPoseID = H5D.open( localGrpID,  strcat('/g', num2str( curr_rnearest(k) ), '/headpose') );
		tempGazeID = H5D.open( localGrpID,  strcat('/g', num2str( curr_rnearest(k) ), '/gaze') );
	
		tempImgs = H5D.read( tempImgID );
		tempPoses = H5D.read( tempPoseID );
		tempGazes = H5D.read( tempGazeID );

		samplesInGroup = length( tempImgs(:,1,1,1) );
		contribOfGroup = ceil( sqrt( samplesInGroup ) );
		j = 1;
		while j <= contribOfGroup

			samplesInTree(i) = samplesInTree(i) + 1;
			random = randi(samplesInGroup,1,1);
			treeImgs (i, samplesInTree(i), :, :) =  tempImgs( random  ,1, :, :);
			treeGazes(i, samplesInTree(i), :) = tempGazes( random, :);%, :);
			treePoses(i, samplesInTree(i), :) = tempPoses( random, :);
		
			j = j + 1;		

		end

		H5D.close( tempImgID );
		H5D.close( tempPoseID);
		H5D.close( tempGazeID);

		H5G.close( localGrpID ) ;

	end


	
end



	%%%%%%%% Now that we created each tree's data, lets implement the algorithm %%%%%%%%%
	% - am really thankful to http://tinevez.github.io/matlab-tree/index.html
	%
	% - Each node:
	%      a) is named '(px1,px2), thres'
	%      b) has variable name: node(k)  
	%	
	% - node(k) can have:
	%      a) parent node(k/2 ) 		
	%      b) left child(2k)
	%      c) right child(2k+1)
	% - Leaves can have:
	%      d) left 2d gaze angle
	%      e) right 2d gaze angle	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	
	% xtise mono 6 gia logous oikonomias. Meta vgale tin if
	for i = 1:140 
	   
	   if i == 128 || i == 32 || i == 129 || i == 91 || i == 130 || i == 126
	      
	      trees(i) = tree(strcat('RegressionTree_', num2str(i) ));
	      trees(i) = buildRegressionTree( samplesInTree(i), treeImgs(i,:,:,:),  treeGazes(i,:,:), HEIGHT, WIDTH, trees(i), 1 );
	
	      disp(trees(i).tostring);
           end

	end

%%%% end of training %%%%	
	
	






	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%% T E S T   P H A S E %%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%% Open HDF5 test file %%%%%%%%%%
	fid2 = H5F.open('mytest.h5', 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

	test_rnearestID      = H5D.open(fid2, '_nearestIDs');
	test_imgsID          = H5D.open(fid2, 'data');
	test_gazesID 	     = H5D.open(fid2, 'gaze');
	test_posesID	     = H5D.open(fid2, 'headpose');

	test_rnearest = H5D.read(test_rnearestID);
	test_imgs     = H5D.read(test_imgsID);
	test_gazes    = H5D.read(test_gazesID);
	test_poses    = H5D.read(test_posesID);

	ntestsamples = length( test_imgs(:,1,1,1) );
	%for j = 1:ntestsamples
	   
	   gaze_predict = [0 0]';  
	   for k = 1:(R+1)%each samples, run the R+1 trees
	  	
	   	gaze_predict = gaze_predict + testSampleInTree(trees(test_rnearest(1,k)), 1, test_imgs(1,1,:,:), test_gazes(1,:) );
		gaze_predict
	  	test_gazes(1,:)
		%testSampleInTree(trees(test_rnearest(1,k)), 1, test_imgs(1,1,:,:), test_gazes(1,:) );

	   end
	   gaze_predict = gaze_predict/(R+1)


	
	H5D.close(test_rnearestID);
	H5D.close(test_imgsID);
	H5D.close(test_gazesID);
	H5D.close(test_posesID);
	 
	H5F.close(fid2);

	%%%%%%%%% Close Central Group %%%%%%%%%%%%%%%%%%
	H5D.close(curr_rnearestID);
	H5D.close(curr_centerID);
	H5D.close(curr_imgsID);
	H5D.close(curr_gazesID);
	H5D.close(curr_posesID);

	H5G.close(grpID);
H5F.close(fid);

end


function val = testSampleInTree(tree, node, test_img, gaze )
   val = [100000 100000];	


   if tree.isleaf(node) 
      val = sscanf(tree.get(node),'(%f,%f)');
	
   else
     
      %'Samples:29,px1(1,2)-px2(5,7)>=3'
      % data(1) = samples
      % data(2) = px1Vert
      % data(3) = px1Hor
      % data(4) = px2Vert
      % data(5) = px2Hor
      % data(6) = thres

      data= sscanf(tree.get(node),'Samples:%f,px1(%f,%f)-px2(%f,%f)>=%f');
      childs = tree.getchildren(node);
      if abs(test_img(1,1,data(2),data(3)) - test_img(1,1,data(4),data(5))) >= data(6)
	  abs(test_img(1,1,data(2),data(3)) - test_img(1,1,data(4),data(5)))
         val = testSampleInTree(tree,childs(2) , test_img, gaze );
      else
	  abs(test_img(1,1,data(2),data(3)) - test_img(1,1,data(4),data(5)))
         val = testSampleInTree(tree, childs(1), test_img, gaze );
      end
      
   end


end



function trees = buildRegressionTree( fatherSize, treeImgs,  treeGazes, HEIGHT, WIDTH, trees, node_i)

	turn = 1;
	MAX_DEPTH = 100;
	stackindex = 0;



		
	ltree_tempGazes = zeros(fatherSize,2);
	rtree_tempGazes = zeros(fatherSize,2);
	lImgs = zeros(fatherSize);
	rImgs = zeros(fatherSize);

	final_rImgs = zeros(fatherSize);
	final_lImgs = zeros(fatherSize);

	%%% recursion staff %%%
	savedSize = zeros(MAX_DEPTH);
	savedNode = zeros(MAX_DEPTH);
	currPtrs = zeros(fatherSize);
	savePtrs = zeros(MAX_DEPTH, fatherSize) ;
	currPtrs(1) = 1;
	for i = 2:fatherSize
	   currPtrs(i) = currPtrs(i-1) + 1;
	end

   turn = 1;
   while 1 %3
	%for each node
	minSquareError = 10000; % a huge value
	minPx1_vert =    10000; % something random here
	minPx1_hor =     10000; % also here
	minPx2_vert=     10000; % and here..
	minPx2_hor =     10000; % and here 
	bestThres  =     10000; % ah, and here

	for px1_vert = 1:HEIGHT		
	   for px1_hor = 1:WIDTH
	   	% sorry for the huge equations below
		% these equations are made in order to prevent 2 pixels
		% to be examined twice
		for px2_vert = ( px1_vert + floor(px1_hor/WIDTH)  ):HEIGHT
		  for px2_hor = (1 + mod( px1_hor, WIDTH )):WIDTH
                    if  sqrt( (px1_vert -px2_vert)^2+(px1_hor-px2_hor)^2) < 6.5             
		     for thres = 1:50
			
			

			l = 0;
			r = 0;			
			meanLeftGaze = [0 0];
			meanRightGaze = [0 0];
			for j = 1:fatherSize
			   	                    
			   if  abs(treeImgs(1, currPtrs(j), px1_vert, px1_hor) - treeImgs(1, currPtrs(j),px2_vert, px2_hor))  < thres 
			      %left child

			      l = l + 1;
			      ltree_tempGazes( l ) = treeGazes(1, currPtrs(j) );
			      lImgs(l) = currPtrs(j); 
			       				      
			      
			      meanLeftGaze(1) = meanLeftGaze(1) + treeGazes(1,currPtrs(j),1);%,:);
			      meanLeftGaze(2) = meanLeftGaze(2) + treeGazes(1,currPtrs(j),2);%,:);	
			  
	
			   else
			      %right child

			      r = r + 1;
			      rtree_tempGazes(r) = treeGazes(1,currPtrs(j) );
			      rImgs(r) = currPtrs(j);  				      
			      
			      meanRightGaze(1) = meanRightGaze(1) + treeGazes(1,currPtrs(j),1);%,:);
			      meanRightGaze(2) = meanRightGaze(2) + treeGazes(1,currPtrs(j),2);
			   end
			end
	
			meanLeftGaze = meanLeftGaze  / l;
			meanRightGaze = meanRightGaze/ r;

			squareError = 0;
			for j = 1:r
			   squareError=squareError + (meanRightGaze(1)-rtree_tempGazes(j,1))^2 + (meanRightGaze(2)-rtree_tempGazes(j,2))^2;	
			end
			for j = 1:l
			   squareError=squareError + (meanLeftGaze(1)-ltree_tempGazes(j,1) )^2 + (meanLeftGaze(2)-ltree_tempGazes(j,2))^2;	
			end
		
			if squareError < minSquareError
			   minSquareError = squareError;			
			   minPx1_vert =    px1_vert; % something random here
			   minPx1_hor =     px1_hor; % also here
			   minPx2_vert=     px2_vert; % and here..
			   minPx2_hor =     px2_hor; % and here
			   bestThres  =     thres;
			   
			   
			   for o = 1:r
			      final_rImgs(o) = rImgs(o);%%%%%%%%%%%%
			   end

			   for o = 1:l
			      final_lImgs(o) = lImgs(o);%%%%%%%%%%%%
			   end				

			   ltree.size = l;
			   rtree.size = r;
			   if node_i == 2
			       ltree.size 
			   rtree.size 
			   end		
                           rtree.meanGaze = meanRightGaze;
			   ltree.meanGaze = meanLeftGaze;
			end
 			 		 	
		     end%thres
		    end%end if < 6.5
		
		   end%px2_hor
		end%px2_vers
 	
	   end	
		
        end

	%%%%%% Recursion starts here %%%%%	
	if (ltree.size > 0 && rtree.size > 0)
  	   turn = 1;
 
           trees=trees.set(node_i,strcat('Samples:',num2str(fatherSize),',px1(', num2str(minPx1_vert),',',num2str(minPx1_hor),')-','px2(',num2str(minPx2_vert),',',num2str(minPx2_hor),')>=', num2str(bestThres) ));  



	   [trees lnode] = trees.addnode(node_i, strcat('(', num2str(ltree.meanGaze(1)), ',', num2str(ltree.meanGaze(2)), ')'));
	   [trees rnode] = trees.addnode(node_i, strcat('(', num2str(rtree.meanGaze (1)), ',', num2str(rtree.meanGaze (2)), ')'));

	      % start saving the left brother
	      
	      stackindex = stackindex + 1;
	      fprintf('push:\n');
	      savedSize(stackindex) = ltree.size;
	      %savedSize(stackindex)
	      savedNode(stackindex) = lnode;
		lnode
	      for o = 1:ltree.size
	         savePtrs(stackindex,o) = final_lImgs(o);
	      end

	      %%%   prepare data for right son %%%
	      node_i = rnode;
	      fatherSize = rtree.size;
	      for o = 1:rtree.size
		 currPtrs(o) = final_rImgs(o);
	      end	

	else %2
	   if stackindex == 0 
	         break;
	   end 
	   %%%   prepare next iteration data %%%  
	   fprintf('pop:\n'); 
	   fatherSize = savedSize(stackindex);
	   node_i = savedNode(stackindex);
 		node_i
	   for o = 1:fatherSize
	      currPtrs(o) = savePtrs(stackindex,o);
	   end
	   stackindex = stackindex - 1;	

	   if turn 
	      turn = 0;
	   else%1 
	      
	   end%1
	end %2	
	%stackindex
	%turn
   end %3


end
