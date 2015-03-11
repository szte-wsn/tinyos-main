function [x,fval] = processData(fileName)
    if(nargin == 0) 
        fileName = 'testData.txt';
    end
    [firstArray, secondArray, distance, unKnownMotesID, moteArray, Fix,Unknown,sizeFix] = fileReader(fileName);
    %size(Fix(:,:),2) %mote numbers. In first row has the mote IDs, second x, third y, fourth z
    %n = size(Distances(:,:),2) %first mote ID, second mote ID, distance
    unKnownMotesData = zeros(3,size(unKnownMotesID,2));
    start = unKnownMotesData;
    options = optimoptions('fsolve','Display','iter');
    1000000;
    [x,fval]= fsolve(@(unKnownMotesData)goodnessFunction(unKnownMotesData, unKnownMotesID, firstArray, secondArray, distance), start, options);
    x;
end