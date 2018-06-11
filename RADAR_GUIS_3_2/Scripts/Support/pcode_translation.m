function [fout] = pcode_translation(fin, t, stn)  
% This function takes a file name that includes a pathcode and translates to an actual file name using the time
% and station code inputs.
%
% INPUTS
%
% fin: A filename of part of a filename that includes a path code. 
% The path code is a character string used to define the directory structure for data storage.  
% In the path code definition
% --datestr codes surrounded by square brackets [] are used for time-related folder names
% --The string XXXX is used in place of the site code
%
% t:  The time in MATLAB datenum format
% 
% stn:  Four letter station code (optional)
%
%
% EXAMPLE  
% pcode_translation('[XXXX]/meas_[mmm]/[yyyy]_[mm]/',datenum([2012 11 1 0 0 0]), 'CBBT')
%   translates to 'CBBT/meas_Nov/2012_11/'


% uses unique character & that is not allowed in paths to identify codes in the path code    
            try   
                fin   = strrep(fin,'[yyyy]',datestr((t),'yyyy'));
            end
            try
                fin = strrep(fin,'[yy]',datestr((t),'yy'));
            end
            try
                fin = strrep(fin,'[mm]', datestr((t),'mm'));
            end
            try
                fin = strrep(fin,'[mmm]', datestr((t),'mmm'));
            end
            try
                fin = strrep(fin,'[dd]',datestr((t),'dd'));
            end
            try 
                fin = strrep(fin,'[HH]',datestr((t),'HH'));
            end
            try
                fin = strrep(fin,'[MM]',datestr((t),'MM'));
            end        
            try
                fin = strrep(fin,'[XXXX]',stn);
            end
            
            fout = fin;
