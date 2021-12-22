function outCell = derive_fileds_of_filename(fid)
% This function is designed for deriving fields from a filename given by
% fid, used for displaying the test history UItable in the main test GUI.
% By Huali Zhou, Nov 20,2020
% input: fid, the file that you want to derive information from its name
% output:
%     outCell, a cell that stores seperate fields of the filename
% example:
% fid = open('liumanyun_Non_ACE50_test_default_250_20201117220023.txt',r);
% outCell = derive_fileds_of_filename(fid);
% returns:
% outCell = {liumanyun_Non_ACE50_test_default_250_20201117220023.txt,...
%    liumanyun, Non, ACE50, test, default, 250, 20201117220023.txt };
%--------------------------------------------------------------------------
    filename = fopen(fid);
    filename = filename(max(strfind(filename,'\'))+1:end);
    t = strsplit(filename,'_');
    outCell ={filename};
    for n = 1:length(t)
        outCell = [outCell,t{n}];
    end
end

