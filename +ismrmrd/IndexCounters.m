classdef IndexCounters
    properties
        kspace_encode_step_1 = zeros(1, 1,'uint16'); % e.g. line number
        kspace_encode_step_2 = zeros(1, 1,'uint16'); % e.g. partition number
        average              = zeros(1, 1,'uint16'); % e.g. signal average number
        slice                = zeros(1, 1,'uint16'); % e.g. imaging slice number
        contrast             = zeros(1, 1,'uint16'); % e.g. echo number in multi-echo
        phase                = zeros(1, 1,'uint16'); % e.g. cardiac phase number
        repetition           = zeros(1, 1,'uint16'); % e.g. dynamic number for dynamic scanning
        set                  = zeros(1, 1,'uint16'); % e.g. flow encoding set
        segment              = zeros(1, 1,'uint16'); % e.g. segment number for segmented imaging
        user                 = zeros(1, 8,'uint16'); % e.g. Free user parameters
    end

    methods (Static)
        % Helper function to validate the size of inputs before setting properties
        function isValid = ValidateSize(val, sz, name)
            isValid = (ismatrix(val)) && all(size(val) == sz);
            if ~isValid
                error('%s must be shape [%s]', name, num2str(sz));
            end
        end
    end % methods (Static)

    methods
        function obj = set.kspace_encode_step_1(  obj, val),  if obj.ValidateSize(val, [1  1], 'kspace_encode_step_1'),   obj.kspace_encode_step_1   = uint16(val); end,  end
        function obj = set.kspace_encode_step_2(  obj, val),  if obj.ValidateSize(val, [1  1], 'kspace_encode_step_2'),   obj.kspace_encode_step_2   = uint16(val); end,  end
        function obj = set.average(               obj, val),  if obj.ValidateSize(val, [1  1], 'average'),                obj.average                = uint16(val); end,  end
        function obj = set.slice(                 obj, val),  if obj.ValidateSize(val, [1  1], 'slice'),                  obj.slice                  = uint16(val); end,  end
        function obj = set.contrast(              obj, val),  if obj.ValidateSize(val, [1  1], 'contrast'),               obj.contrast               = uint16(val); end,  end
        function obj = set.phase(                 obj, val),  if obj.ValidateSize(val, [1  1], 'phase'),                  obj.phase                  = uint16(val); end,  end
        function obj = set.repetition(            obj, val),  if obj.ValidateSize(val, [1  1], 'repetition'),             obj.repetition             = uint16(val); end,  end
        function obj = set.set(                   obj, val),  if obj.ValidateSize(val, [1  1], 'set'),                    obj.set                    = uint16(val); end,  end
        function obj = set.user(                  obj, val),  if obj.ValidateSize(val, [1  8], 'user'),                   obj.user                   = uint16(val); end,  end
    end
end