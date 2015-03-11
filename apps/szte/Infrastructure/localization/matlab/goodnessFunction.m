function F = goodnessFunction(unKnownMotesData, unKnownMotesID, M1, M2, d)
  unKnownMotesData;
  for i=1:size(unKnownMotesID,2)
    [row column] = find(M1(1,:) == unKnownMotesID(i)); %sor, oszlop
    for j=1:size(column,2)
        M1(2:4,column(j)) = unKnownMotesData(:,i);
    end
    [row column] = find(M2(1,:) == unKnownMotesID(i)); %sor, oszlop
    for j=1:size(column,2)
        M2(2:4,column(j)) = unKnownMotesData(:,i);  
    end
  end
  M1;
  M2;
  F = zeros(size(M1,2),1);
  for i=1:size(M1,2)
      s = (M1(2,i) - M2(2,i))^2 + (M1(3,i) - M2(3,i))^2 + (M1(4,i) - M2(4,i))^2 - d(i);
      F(i,1) = s;
  end
  F;
 % F = f1+f2+f3;
end