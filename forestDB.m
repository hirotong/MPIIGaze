function tempDB()
%%
clear;
clc;

if exist('myfile.h5', 'file') == 2
  delete('myfile.h5');
end
if exist('mytest.h5', 'file') == 2
  delete('mytest.h5');
end




centers = csvread('centers.txt');

fprintf('File Path Ready!\n');


TOTAL_DATA = 44640;%number of samples

TEST_SIZE= TOTAL_DATA/5;
MAX_PER_PERSON = floor(TOTAL_DATA/15);
CHUNK_SIZE =  floor(MAX_PER_PERSON/15);


TRAIN_SIZE_PER_PERSON = floor( (4*MAX_PER_PERSON)/5) ;

R = 20;
NUM_OF_GROUPS = 140;
WIDTH = 15;
HEIGHT = 9;

MAX_SIZE_PER_GROUP = 1500;


%%% structure allocation %%%
groups(1:140) = struct('centerHor', zeros(1) , 'centerVert', zeros(1), 'index', 0,  'RnearestCenters', int8(zeros(R,1)), 'trainData', [], 'numberOfSamples', zeros(1) );
for i = 1:140
   groups(i).centerHor = centers(i,1);
   groups(i).centerVert = centers(i,2);
   groups(i).trainData = struct('gaze', zeros(2,MAX_SIZE_PER_GROUP), 'headpose', zeros(2, MAX_SIZE_PER_GROUP), 'data', zeros(WIDTH,HEIGHT,1,MAX_SIZE_PER_GROUP)  ) ; 
end




%test
testData=[];
testData.data = zeros(WIDTH,HEIGHT ,1, TEST_SIZE);
testData.gaze = zeros(2, TEST_SIZE);%15*375*2);%zeros(2, total_num*2);
testData.headpose = zeros(2, TEST_SIZE);%15*375*2);%zeros(2, total_num*2);S
testData.nTrees = zeros( R+1, TEST_SIZE);
%testData.confidence = zeros(1, 15*375*2);%zeros(1, total_num*2);
testindex = 0;

%temp
tempData=[];
tempData.data = zeros(WIDTH,HEIGHT ,1, 1*2);%zeros(WIDTH,HEIGHT ,1, total_num*2);
tempData.label = zeros(2, 1*2);%zeros(2, total_num*2);
tempData.headpose = zeros(2, 1*2);%zeros(2, total_num*2);
%tempData.confidence = zeros(1, 1*2);%zeros(1, total_num*2);


minPoseHoriz = 30;
minPoseVert = 30;
maxPoseHoriz = -30;
maxPoseVert = -30;

one = 0;
two = 0;
three = 0;
four = 0;

%Pij lists all p00, p01, p02,...
dirData = dir(pwd);
dirIndex = [dirData.isdir];
Pij = dirData(dirIndex);



%for each Pij...
 for num_Pij=3:length(Pij)
   filepath = strcat(Pij(num_Pij).name, '/'); %'p00/';%'MPIIGaze/';
    
   
  %%% LIST ALL FILES %%%
  dirData = dir(filepath);%path = dir(filepath);
  dirIndex = [dirData.isdir];
  files = {dirData(~dirIndex).name}';

  turn = 1;
  i = 1;


  num_f = randi(length(files), 1,1);
  list1(1) = num_f;
  l_size = 1;

  readname = [filepath, files{num_f}];
  temp = load(readname);   
  num_data = length(temp.filenames(:,1)); 

  l2_size = 0; 
  list2 = [];
  while 1

	if mod(i,CHUNK_SIZE) == 0 || l2_size == num_data

	   while (1)  
	      num_f = randi(length(files), 1,1);
	      if ismember(num_f, list1(1:l_size)) == 0
		 l_size = l_size + 1;
	         list1(l_size) = num_f;
		 l2_size = 0;
		 list2 = [];

		 readname = [filepath, files{num_f}];
           	 temp = load(readname);   
           	 num_data = length(temp.filenames(:,1));
  
		 break;
	      end
           end           
	end

          
	while(1)
	   num_i = randi(num_data,1,1);
	   if ismember(num_i, list2(1:l2_size)) == 0
              l2_size = l2_size + 1;
              list2(l2_size) = num_i;
	      break;
	   end
	end

	% for left
        img = temp.data.left.image(num_i, 14:22, 23:37);
        img = reshape(img, HEIGHT ,WIDTH);
       	tempData.data(:, :, 1, 1) = img'; % filp the image

        
        Lable_left = temp.data.left.gaze(num_i, :)';
        theta = asin((-1)*Lable_left(2));
        phi = atan2((-1)*Lable_left(1), (-1)*Lable_left(3));
        tempData.label(:,1) = [theta; phi];
 
        headpose = temp.data.left.pose(num_i, :);
        M = rodrigues(headpose);
        Zv = M(:,3);
        theta = asin(Zv(2));
        phi = atan2(Zv(1), Zv(3));


        tempData.headpose(:,1) = [theta;phi];  
         
        % for right
        img = temp.data.right.image(num_i, 14:22, 23:37);
        img = reshape(img, HEIGHT ,WIDTH);
        tempData.data(:, :, 1, 2) = double(flip(img, 2))'; % filp the image
	         


        Lable_right = temp.data.right.gaze(num_i,:)';
        theta = asin((-1)*Lable_right(2));
        phi = atan2((-1)*Lable_right(1), (-1)*Lable_right(3));
        tempData.label(:,2) = [theta; (-1)*phi];% flip the direction


        headpose = temp.data.right.pose(num_i, :); 

        M = rodrigues(headpose);
        Zv = M(:,3);
        theta = asin(Zv(2));
       	phi = atan2(Zv(1), Zv(3));
        tempData.headpose(:,2) = [theta; (-1)*phi]; % flip the direction
		
	if turn == 1
		
		%%%%%%%%%%%%%%%
                % TRAINING DATA
                %%%%%%%%%%%%%%%

		%copy left
		groupID = find_nearest_group(tempData.headpose(:,1), groups, NUM_OF_GROUPS);
		groups(groupID).index = groups(groupID).index + 1;
		groups(groupID).trainData.data(:, :,1,groups(groupID).index) = tempData.data(:, :, 1,1);
		groups(groupID).trainData.gaze(:,groups(groupID).index) = tempData.label(:,1);
		groups(groupID).trainData.headpose(:,groups(groupID).index) = tempData.headpose(:,1);
		
		if i == TRAIN_SIZE_PER_PERSON
		   turn = 0;
		i
		end
		i = i + 1;

	end
	if turn == 1
		    
                %copy right
		
		groupID = find_nearest_group(tempData.headpose(:,2), groups, NUM_OF_GROUPS);
		groups(groupID).index = groups(groupID).index + 1;
		groups(groupID).trainData.data(:, :,1,groups(groupID).index) = tempData.data(:, :, 1,2);
		groups(groupID).trainData.gaze(:,groups(groupID).index) = tempData.label(:,2);
		groups(groupID).trainData.headpose(:,groups(groupID).index) = tempData.headpose(:,2);
		if i == TRAIN_SIZE_PER_PERSON
		   turn = 0;
		end
		i = i + 1;

	end

	
	if turn == 0


		%%%%%%%%%%%%%%%
		% TEST DATA
		%%%%%%%%%%%%%%%
		%copy left
		testindex = testindex+1;
		testData.nTrees(1, testindex) = find_nearest_group(tempData.headpose(:,1), groups, NUM_OF_GROUPS);	
		testData.data(:, :, 1, testindex) = tempData.data(:, :, 1,1);
		testData.gaze(:,testindex) = tempData.label(:,1);
		testData.headpose(:,testindex) = tempData.headpose(:,1);
	        if i == MAX_PER_PERSON
		   break;
		end	
		i = i + 1;
	end


	if turn == 0

		%copy right
		testindex = testindex+1;
		testData.nTrees(1, testindex) = find_nearest_group(tempData.headpose(:,2), groups, NUM_OF_GROUPS);
		testData.data(:, :, 1, testindex) = tempData.data(:, :, 1, 2);
		testData.gaze(:,testindex) = tempData.label(:,2);
		testData.headpose(:,testindex) = tempData.headpose(:,2);

		 if i == MAX_PER_PERSON
		   break;
		end	
		i = i + 1;

	end%endif	

    end  % for each person
    
	testindex

    num_Pij

end  % for each pij
fprintf('Saving\n');



%start creating data file for training(HDF5)
fid = H5F.create('myfile.h5');
type_id = H5T.copy('H5T_NATIVE_DOUBLE');
dcpl = 'H5P_DEFAULT';
plist = 'H5P_DEFAULT';



for i = 1:NUM_OF_GROUPS
	
	groups(i).trainData.data = groups(i).trainData.data;%/255; %normalize
	groups(i).trainData.data = single(groups(i).trainData.data); % must be single data, because caffe want
	groups(i).trainData.gaze = single(groups(i).trainData.gaze);	
	groups(i).trainData.headpose = single(groups(i).trainData.headpose);


	grp = H5G.create(fid, strcat('g', num2str(i)) ,plist,plist,plist);


%%%%%% Dataset 1: numx1xHEIGHTxWIDTH image data %%%%	

	

	dims = [WIDTH HEIGHT 1  groups(i).index];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(4,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i), '/data') ,type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,   groups(i).trainData.data(:,:,1,1:groups(i).index) );

	H5D.close(dset);
	H5S.close(space_id);


%%%%%% Dataset 2: numx4 pose and gaze data %%%%	

	dims =  [2 groups(i).index];%[groups(i).index 4];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	%headpose
	dset = H5D.create(grp,strcat('/g', num2str(i),'/headpose'), type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, groups(i).trainData.headpose(:,1:groups(i).index));
	H5D.close(dset);



	%gaze
	dset = H5D.create(grp,strcat('/g', num2str(i),'/gaze'), type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, groups(i).trainData.gaze(:,1:groups(i).index));
	H5D.close(dset);

	H5S.close(space_id);

%%%%%% Dataset 3: headpose-center of each group  %%%%	
	dims = [2 1];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/center'), type_id,space_id,dcpl);	
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,[groups(i).centerHor groups(i).centerVert] );
 
	H5D.close(dset);
	H5S.close(space_id);

%%%%%% Dataset 4: List of R-nearest groups %%%%

	listOfGroupIds = find_R_nearest_groups(groups(i).centerHor, groups(i).centerVert, groups, R, [i], NUM_OF_GROUPS );
	listOfGroupIds = listOfGroupIds(2:length(listOfGroupIds));
	
	dims = [R 1];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/',num2str(R),'_nearestIDs'), type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, listOfGroupIds );
	H5D.close(dset);
	H5S.close(space_id);	


%%%%%% Dataset 5: Number of samples per group %%%%

	dims = [1];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(1,h5_dims,h5_maxdims);

	dset = H5D.create(grp,strcat('/g', num2str(i),'/','samples'), type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, groups(i).index );
	H5D.close(dset);
	H5S.close(space_id);	




end
H5F.close(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% TESTING %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
testData.data = testData.data;%/255; %normalize
testData.data = single(testData.data); % must be single data, because caffe want float type
testData.gaze = single(testData.gaze);
testData.headpose = single(testData.headpose);


fid = H5F.create('mytest.h5');


%%%%%% Dataset 1: numx1xHEIGHTxWIDTH image data %%%%	

	dims = [WIDTH HEIGHT 1 testindex];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(4,h5_dims,h5_maxdims);

	dset = H5D.create(fid, '/data' ,type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,testData.data(:,:,1,1:testindex) );

	H5D.close(dset);
	H5S.close(space_id);




%%%%%% Dataset 2: numx4 pose and gaze data %%%%	

	dims = [2 testindex];%[groups(i).index 4];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	%headpose
	dset = H5D.create(fid, '/headpose', type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, testData.headpose(:,1:testindex));
	H5D.close(dset);

	%gaze
	dset = H5D.create(fid, '/gaze', type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist, testData.gaze(:,1:testindex));

	H5D.close(dset);
	H5S.close(space_id);


%%%%%% Dataset 3: List of R-nearest groups %%%%
	for o = 1:testindex

	   testData.nTrees(1:(R+1), o) =find_R_nearest_groups( groups(testData.nTrees(1,o)).centerHor, groups(testData.nTrees(1,o)).centerVert, groups, R, [testData.nTrees(1,o)], NUM_OF_GROUPS);
	end


	dims = [(R+1) testindex];
	h5_dims = fliplr(dims);
	h5_maxdims = h5_dims;
	space_id = H5S.create_simple(2,h5_dims,h5_maxdims);

	dset = H5D.create(fid, '_nearestIDs', type_id,space_id,dcpl);
	H5D.write(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',plist,  testData.nTrees( 1:(R+1), 1:testindex  )  );
	H5D.close(dset);
	H5S.close(space_id);	

fprintf('done\n\n');	
end











function nearestGroup = find_nearest_group(headpose, groups, NUM_OF_GROUPS)
  minDist = 100;
  nearestGroup = -1;   
  MAX_HORIZONTAL_DIST = 0.7;
  MAX_VERTICAL_DIST = 0.7;

  for i =1:NUM_OF_GROUPS
     distHor = abs(groups(i).centerHor - headpose(1));
     distVert = abs(groups(i).centerVert - headpose(2));
     if  distHor < MAX_HORIZONTAL_DIST && distVert < MAX_VERTICAL_DIST 
	dist =  sqrt( distHor^2 + distVert^2 );
        if  dist < minDist
	   minDist = dist;
	   nearestGroup = i;
	end
     end
  end
  %minDist


end


function listOfGroupIds = find_R_nearest_groups(centerHor, centerVert, groups, timesLeft, listOfGroupIds, NUM_OF_GROUPS)
  minDist = 100;
  nearestGroup = -1;   

  MAX_HORIZONTAL_DIST = 0.5;
  MAX_VERTICAL_DIST = 0.5;

  for i =1:NUM_OF_GROUPS
     if isnt_in_the_list(i, listOfGroupIds) == 1    
     	distHor = abs(groups(i).centerHor - centerHor);
     	distVert = abs(groups(i).centerVert - centerVert);
     	if  distHor < MAX_HORIZONTAL_DIST && distVert < MAX_VERTICAL_DIST 
	   dist =  sqrt( distHor^2 + distVert^2 );
           if  dist < minDist
	      minDist = dist;
	      nearestGroup = i;
	   end
        
	end
     
      end

   end
   
  listOfGroupIds( length(listOfGroupIds)+1 ) = nearestGroup;
  timesLeft = timesLeft - 1;

  if timesLeft > 0
        listOfGroupIds = find_R_nearest_groups(centerHor, centerVert, groups, timesLeft, listOfGroupIds, NUM_OF_GROUPS);
  end

 


end



function out = isnt_in_the_list(currGroup, listOfGroupIds)
   
   out = 1;
   for i = 1:length(listOfGroupIds)
      if currGroup == listOfGroupIds(i)
         out =  0;
        
      end
   end

end





