function [firstArray, secondArray, distance, unKnownMotesID, moteArray, Fix, Distances, sizeFix] = fileReader(fileName)
    fileID = fopen(fileName,'r');
    tline = fgets(fileID); %read mote ids
    moteArray = zeros(4,size(str2num(tline),2)); % 4 x moteNumber array size
    moteArray(1,:) = str2num(tline); %first row moteIDs
    tline = fgets(fileID); %read Distances mote ids
    unKnownMotesID = str2num(tline);
    sizeFix = fscanf(fileID,'%f', 1);
    Fix = fscanf(fileID,'%f %f %f %f', [4 sizeFix]);
    Distances = fscanf(fileID,'%f %f %f', [3 Inf]);
    for i=1:size(Fix,2)
        [row column] = find(moteArray(1,:) == Fix(1,i)); %sor, oszlop
        if isempty(column) == 0 %not empty
            moteArray(2:4,i) = Fix(2:4,column);
        end
    end
    firstArray = zeros(4,size(Distances,2));
    secondArray = zeros(4,size(Distances,2));
    Distances(2,:)
    for i=1:size(moteArray,2)
        [row column] = find(Distances(1,:) == moteArray(1,i)); %sor, oszlop
        if isempty(column) == 0
            for j=1:size(column,2)
                firstArray(:,column(j)) = moteArray(:,i);
            end
        end
        [row column] = find(Distances(2,:) == moteArray(1,i)); %sor, oszlop
        if isempty(column) == 0
            for j=1:size(column,2)
                secondArray(:,column(j)) = moteArray(:,i);
            end
        end
    end
    firstArray;
    secondArray;
    distance = Distances(3,:);
end