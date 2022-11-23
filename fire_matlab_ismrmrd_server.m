function fire_matlab_ismrmrd_server(varargin)
    % addpath('mex');
    if(isOctave)
        javaaddpath('/usr/share/java/xercesImpl.jar');
        javaaddpath('/usr/share/java/xml-apis.jar');
        pkg load instrument-control
    end

    if nargin < 1
        port = 9002; 
    else
        port = varargin{1};
    end
    
    if nargin < 2
        logfile = '';
    else
        logfile = varargin{2};
    end

    if nargin < 3
        savedata = false;
    else
        savedata = varargin{3};
    end

    if nargin < 4
        savedataFolder = '';
    else
        savedataFolder = varargin{4};
    end

    log = logging.createLog(logfile);
    ismrmrd_server = server(port, log, savedata, savedataFolder);
    serve(ismrmrd_server);

end
