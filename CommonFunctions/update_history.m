function update_history(obj)
%This function is designed for adding a new rocord in the test history mat
%file, which can be used for displaying the test history UItable in the main test GUI.
% By Huali Zhou, Jan 12,2021
task = class(obj);
matName = ['.\History\',task,'.mat'];
if exist(matName,'file')
    load(matName);
else
    data = {};
end
fileds = fieldnames(obj.basicInfo);
temp = {};
for n=1:length(fileds)
    key = fileds{n};
    if ~strcmp(key,'resultFID')
        value = obj.basicInfo.(key);
        temp = [temp,value];
    end
end
if isprop(obj,'srt')
    temp =[temp, obj.srt];
elseif isprop(obj,'score')
    temp =[temp, obj.score];
elseif isprop(obj.procedureObj,'geomeanLast')
    temp =[temp, obj.procedureObj.geomeanLast];
end
filename = fopen(obj.basicInfo.resultFID);
filename = filename(max(strfind(filename,'\'))+1:end);
temp = [task,temp, filename]; % last one is filename
data = [temp; data];
save(matName,'data');

end

