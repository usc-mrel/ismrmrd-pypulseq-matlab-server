classdef EncodingCounters
    % Class for encoding counters in the MRD ImageHeader as described at:
    % https://ismrmrd.github.io/apidocs/1.4.2/struct_i_s_m_r_m_r_d_1_1_i_s_m_r_m_r_d___encoding_counters.html
    %
    % A series of "set" functions should be used whenever possible in order to
    % ensure valid data type and size for each parameter.  These functions are
    % intentionally not part of the set handlers to improve performance when a
    % large amount of pre-validated data is being converted.

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
        % Set handlers for each property to ensure correct type and size
        % Ideally, these would be the actual set handler (e.g. set.slice())
        % so the size/type is strictly enforced, but MATLAB has a significant
        % performance overhead for set handlers.  The deserialize() function
        % in AcquisitionHeader should bypass these for performance reasons
        % when receiving large amounts of data.  In all other cases, these
        % functions should be used via the Acquisition class to prevent
        % inadvertent errors.
        function obj = set_kspace_encode_step_1(  obj, val),  if obj.ValidateSize(val, [1  1], 'kspace_encode_step_1'),   obj.kspace_encode_step_1   = uint16(val); end,  end
        function obj = set_kspace_encode_step_2(  obj, val),  if obj.ValidateSize(val, [1  1], 'kspace_encode_step_2'),   obj.kspace_encode_step_2   = uint16(val); end,  end
        function obj = set_average(               obj, val),  if obj.ValidateSize(val, [1  1], 'average'),                obj.average                = uint16(val); end,  end
        function obj = set_slice(                 obj, val),  if obj.ValidateSize(val, [1  1], 'slice'),                  obj.slice                  = uint16(val); end,  end
        function obj = set_contrast(              obj, val),  if obj.ValidateSize(val, [1  1], 'contrast'),               obj.contrast               = uint16(val); end,  end
        function obj = set_phase(                 obj, val),  if obj.ValidateSize(val, [1  1], 'phase'),                  obj.phase                  = uint16(val); end,  end
        function obj = set_repetition(            obj, val),  if obj.ValidateSize(val, [1  1], 'repetition'),             obj.repetition             = uint16(val); end,  end
        function obj = set_set(                   obj, val),  if obj.ValidateSize(val, [1  1], 'set'),                    obj.set                    = uint16(val); end,  end
        function obj = set_user(                  obj, val),  if obj.ValidateSize(val, [1  8], 'user'),                   obj.user                   = uint16(val); end,  end

        % Convert to basic struct
        % This is used by built-in HDF5 functions.  Overloaded from the built-in
        % struct(obj) function to avoid warnings, but may be modified in the future
        function s = struct(obj)
            publicProperties = properties(obj);
            s = struct();
            for fi = 1:numel(publicProperties)
                s.(publicProperties{fi}) = obj.(publicProperties{fi}); 
            end
        end
    end
end