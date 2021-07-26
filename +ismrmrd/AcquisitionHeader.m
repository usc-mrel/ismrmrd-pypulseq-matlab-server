classdef AcquisitionHeader
    % Class for the MRD AcquisitionHeader data structure as described in:
    % https://ismrmrd.github.io/apidocs/1.4.2/struct_i_s_m_r_m_r_d_1_1_i_s_m_r_m_r_d___acquisition_header.html
    %
    % A series of "set" functions should be used whenever possible in order to
    % ensure valid data type and size for each parameter.  These functions are
    % intentionally not part of the set handlers to improve performance when a
    % large amount of pre-validated data is being converted.
    %
    % serialize() and deserialize() functions are provided to convert this data
    % structure to/from a byte string used during streaming/networking.

    properties
        version                   = zeros(1, 1,'uint16');     % First unsigned int indicates the version
        flags                     = zeros(1, 1,'uint64');     % bit field with flags
        measurement_uid           = zeros(1, 1,'uint32');     % Unique ID for the measurement
        scan_counter              = zeros(1, 1,'uint32');     % Current acquisition number in the measurement
        acquisition_time_stamp    = zeros(1, 1,'uint32');     % Acquisition clock
        physiology_time_stamp     = zeros(1, 3,'uint32');     % Physiology time stamps, e.g. ecg, breathing, etc.
        number_of_samples         = zeros(1, 1,'uint16');     % Number of samples acquired
        available_channels        = zeros(1, 1,'uint16');     % Available coils
        active_channels           = zeros(1, 1,'uint16');     % Active coils on current acquisiton
        channel_mask              = zeros(1,16,'uint64');     % Mask to indicate which channels are active. Support for 1024 channels
        discard_pre               = zeros(1, 1,'uint16');     % Samples to be discarded at the beginning of acquisition
        discard_post              = zeros(1, 1,'uint16');     % Samples to be discarded at the end of acquisition
        center_sample             = zeros(1, 1,'uint16');     % Sample at the center of k-space
        encoding_space_ref        = zeros(1, 1,'uint16');     % Reference to an encoding space, typically only one per acquisition
        trajectory_dimensions     = zeros(1, 1,'uint16');     % Indicates the dimensionality of the trajectory vector (0 means no trajectory)
        sample_time_us            = zeros(1, 1,'single');     % Time between samples in micro seconds, sampling BW
        position                  = zeros(1, 3,'single');     % Three-dimensional spatial offsets from isocenter
        read_dir                  = zeros(1, 3,'single');     % Directional cosines of the readout/frequency encoding
        phase_dir                 = zeros(1, 3,'single');     % Directional cosines of the phase encoding
        slice_dir                 = zeros(1, 3,'single');     % Directional cosines of the slice
        patient_table_position    = zeros(1, 3,'single');     % Patient table off-center
        idx                       = ismrmrd.EncodingCounters; % Encoding loop counters
        user_int                  = zeros(1, 8,'uint32');     % Free user parameters
        user_float                = zeros(1, 8,'single');     % Free user parameters
    end

    properties(Constant)
        FLAGS = struct( ...
            'ACQ_FIRST_IN_ENCODE_STEP1',                1, ...
            'ACQ_LAST_IN_ENCODE_STEP1',                 2, ...
            'ACQ_FIRST_IN_ENCODE_STEP2',                3, ...
            'ACQ_LAST_IN_ENCODE_STEP2',                 4, ...
            'ACQ_FIRST_IN_AVERAGE',                     5, ...
            'ACQ_LAST_IN_AVERAGE',                      6, ...
            'ACQ_FIRST_IN_SLICE',                       7, ...
            'ACQ_LAST_IN_SLICE',                        8, ...
            'ACQ_FIRST_IN_CONTRAST',                    9, ...
            'ACQ_LAST_IN_CONTRAST',                    10, ...
            'ACQ_FIRST_IN_PHASE',                      11, ...
            'ACQ_LAST_IN_PHASE',                       12, ...
            'ACQ_FIRST_IN_REPETITION',                 13, ...
            'ACQ_LAST_IN_REPETITION',                  14, ...
            'ACQ_FIRST_IN_SET',                        15, ...
            'ACQ_LAST_IN_SET',                         16, ...
            'ACQ_FIRST_IN_SEGMENT',                    17, ...
            'ACQ_LAST_IN_SEGMENT',                     18, ...
            'ACQ_IS_NOISE_MEASUREMENT',                19, ...
            'ACQ_IS_PARALLEL_CALIBRATION',             20, ...
            'ACQ_IS_PARALLEL_CALIBRATION_AND_IMAGING', 21, ...
            'ACQ_IS_REVERSE',                          22, ...
            'ACQ_IS_NAVIGATION_DATA',                  23, ...
            'ACQ_IS_PHASECORR_DATA',                   24, ...
            'ACQ_LAST_IN_MEASUREMENT',                 25, ...
            'ACQ_IS_HPFEEDBACK_DATA',                  26, ...
            'ACQ_IS_DUMMYSCAN_DATA',                   27, ...
            'ACQ_IS_RTFEEDBACK_DATA',                  28, ...
            'ACQ_IS_SURFACECOILCORRECTIONSCAN_DATA',   29, ...
            'ACQ_USER1',                               57, ...
            'ACQ_USER2',                               58, ...
            'ACQ_USER3',                               59, ...
            'ACQ_USER4',                               60, ...
            'ACQ_USER5',                               61, ...
            'ACQ_USER6',                               62, ...
            'ACQ_USER7',                               63, ...
            'ACQ_USER8',                               64);
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
        % Constructor
        function obj = AcquisitionHeader(arg)
            switch nargin
                case 0
                    % Empty header
                case 1
                    if isa(arg,'ismrmrd.AcquisitionHeader')
                        % Already formatted AcquistionHeader object
                        obj = arg;
                    elseif isa(arg,'uint8')
                        % Byte array (e.g. from serialized data)
                        obj = deserialize(obj,arg);
                    else
                        % Unknown type
                        error('Unsupported constructor with input class %s', class(arg))
                    end
                otherwise
                    error('Constructor must have 0 or 1 arguments.')
            end
        end

        % Set handlers for each property to ensure correct type and size
        % Ideally, these would be the actual set handler (e.g. set.version())
        % so the size/type is strictly enforced, but MATLAB has a significant
        % performance overhead for set handlers.  The deserialize() function
        % should bypass these for performance reasons when receiving large
        % amounts of data.  In all other cases, these functions should be used
        % via the Acquisition class to prevent inadvertent errors.
        function obj = set_version(               obj, val),  if obj.ValidateSize(val, [1  1], 'version'),                obj.version                = uint16(val); end,  end
        function obj = set_flags(                 obj, val),  if obj.ValidateSize(val, [1  1], 'flags'),                  obj.flags                  = uint64(val); end,  end
        function obj = set_measurement_uid(       obj, val),  if obj.ValidateSize(val, [1  1], 'measurement_uid'),        obj.measurement_uid        = uint32(val); end,  end
        function obj = set_scan_counter(          obj, val),  if obj.ValidateSize(val, [1  1], 'scan_counter'),           obj.scan_counter           = uint32(val); end,  end
        function obj = set_acquisition_time_stamp(obj, val),  if obj.ValidateSize(val, [1  1], 'acquisition_time_stamp'), obj.acquisition_time_stamp = uint32(val); end,  end
        function obj = set_physiology_time_stamp( obj, val),  if obj.ValidateSize(val, [1  3], 'physiology_time_stamp'),  obj.physiology_time_stamp  = uint32(val); end,  end
        function obj = set_number_of_samples(     obj, val),  if obj.ValidateSize(val, [1  1], 'number_of_samples'),      obj.number_of_samples      = uint16(val); end,  end
        function obj = set_available_channels(    obj, val),  if obj.ValidateSize(val, [1  1], 'available_channels'),     obj.available_channels     = uint16(val); end,  end
        function obj = set_active_channels(       obj, val),  if obj.ValidateSize(val, [1  1], 'active_channels'),        obj.active_channels        = uint16(val); end,  end
        function obj = set_channel_mask(          obj, val),  if obj.ValidateSize(val, [1 16], 'channel_mask'),           obj.channel_mask           = uint64(val); end,  end
        function obj = set_discard_pre(           obj, val),  if obj.ValidateSize(val, [1  1], 'discard_pre'),            obj.discard_pre            = uint16(val); end,  end
        function obj = set_discard_post(          obj, val),  if obj.ValidateSize(val, [1  1], 'discard_post'),           obj.discard_post           = uint16(val); end,  end
        function obj = set_center_sample(         obj, val),  if obj.ValidateSize(val, [1  1], 'center_sample'),          obj.center_sample          = uint16(val); end,  end
        function obj = set_encoding_space_ref(    obj, val),  if obj.ValidateSize(val, [1  1], 'encoding_space_ref'),     obj.encoding_space_ref     = uint16(val); end,  end
        function obj = set_trajectory_dimensions( obj, val),  if obj.ValidateSize(val, [1  1], 'trajectory_dimensions'),  obj.trajectory_dimensions  = uint16(val); end,  end
        function obj = set_sample_time_us(        obj, val),  if obj.ValidateSize(val, [1  1], 'sample_time_us'),         obj.sample_time_us         = single(val); end,  end
        function obj = set_position(              obj, val),  if obj.ValidateSize(val, [1  3], 'position'),               obj.position               = single(val); end,  end
        function obj = set_read_dir(              obj, val),  if obj.ValidateSize(val, [1  3], 'read_dir'),               obj.read_dir               = single(val); end,  end
        function obj = set_phase_dir(             obj, val),  if obj.ValidateSize(val, [1  3], 'phase_dir'),              obj.phase_dir              = single(val); end,  end
        function obj = set_slice_dir(             obj, val),  if obj.ValidateSize(val, [1  3], 'slice_dir'),              obj.slice_dir              = single(val); end,  end
        function obj = set_patient_table_position(obj, val),  if obj.ValidateSize(val, [1  3], 'patient_table_position'), obj.patient_table_position = single(val); end,  end
        function obj = set_user_int(              obj, val),  if obj.ValidateSize(val, [1  8], 'user_int'),               obj.user_int               =  int32(val); end,  end
        function obj = set_user_float(            obj, val),  if obj.ValidateSize(val, [1  8], 'user_float'),             obj.user_float             = single(val); end,  end
        % Note: The set handles for the idx fields are handled in the EncodingCounters class

        % Convert from the byte array of the C-struct memory layout for an ISMRMRD AcquisitionHeader
        function obj = deserialize(obj, bytes)
            if (numel(bytes) ~= 340)
                error('Serialized AcquisitionHeader is %d bytes -- should be 340', numel(bytes))
            end

            if ~isrow(bytes)
                bytes = bytes';
            end

            obj.version                  = typecast(bytes(  1:  2), 'uint16');  % First unsigned int indicates the version
            obj.flags                    = typecast(bytes(  3: 10), 'uint64');  % bit field with flags
            obj.measurement_uid          = typecast(bytes( 11: 14), 'uint32');  % Unique ID for the measurement
            obj.scan_counter             = typecast(bytes( 15: 18), 'uint32');  % Current acquisition number in the measurement
            obj.acquisition_time_stamp   = typecast(bytes( 19: 22), 'uint32');  % Acquisition clock
            obj.physiology_time_stamp    = typecast(bytes( 23: 34), 'uint32');  % Physiology time stamps, e.g. ecg, breating, etc.
            obj.number_of_samples        = typecast(bytes( 35: 36), 'uint16');  % Number of samples acquired
            obj.available_channels       = typecast(bytes( 37: 38), 'uint16');  % Available coils
            obj.active_channels          = typecast(bytes( 39: 40), 'uint16');  % Active coils on current acquisiton
            obj.channel_mask             = typecast(bytes( 41:168), 'uint64');  % Mask to indicate which channels are active. Support for 1024 channels
            obj.discard_pre              = typecast(bytes(169:170), 'uint16');  % Samples to be discarded at the beginning of acquisition
            obj.discard_post             = typecast(bytes(171:172), 'uint16');  % Samples to be discarded at the end of acquisition
            obj.center_sample            = typecast(bytes(173:174), 'uint16');  % Sample at the center of k-space
            obj.encoding_space_ref       = typecast(bytes(175:176), 'uint16');  % Reference to an encoding space, typically only one per acquisition
            obj.trajectory_dimensions    = typecast(bytes(177:178), 'uint16');  % Indicates the dimensionality of the trajectory vector (0 means no trajectory)
            obj.sample_time_us           = typecast(bytes(179:182), 'single');  % Time between samples in micro seconds, sampling BW
            obj.position                 = typecast(bytes(183:194), 'single');  % Three-dimensional spatial offsets from isocenter
            obj.read_dir                 = typecast(bytes(195:206), 'single');  % Directional cosines of the readout/frequency encoding
            obj.phase_dir                = typecast(bytes(207:218), 'single');  % Directional cosines of the phase encoding
            obj.slice_dir                = typecast(bytes(219:230), 'single');  % Directional cosines of the slice
            obj.patient_table_position   = typecast(bytes(231:242), 'single');  % Patient table off-center
            obj.idx.kspace_encode_step_1 = typecast(bytes(243:244), 'uint16');  % phase encoding line number
            obj.idx.kspace_encode_step_2 = typecast(bytes(245:246), 'uint16');  % partition encodning number
            obj.idx.average              = typecast(bytes(247:248), 'uint16');  % signal average number
            obj.idx.slice                = typecast(bytes(249:250), 'uint16');  % imaging slice number
            obj.idx.contrast             = typecast(bytes(251:252), 'uint16');  % echo number in multi-echo
            obj.idx.phase                = typecast(bytes(253:254), 'uint16');  % cardiac phase number
            obj.idx.repetition           = typecast(bytes(255:256), 'uint16');  % dynamic number for dynamic scanning
            obj.idx.set                  = typecast(bytes(257:258), 'uint16');  % flow encoding set
            obj.idx.segment              = typecast(bytes(259:260), 'uint16');  % segment number for segmented acquisition
            obj.idx.user                 = typecast(bytes(261:276), 'uint16');  % Free user parameters
            obj.user_int                 = typecast(bytes(277:308), 'int32' );  % Free user parameters
            obj.user_float               = typecast(bytes(309:340), 'single');  % Free user parameters
        end

        % Convert to the byte array of the C-struct memory layout for an ISMRMRD AcquisitionHeader
        function bytes = serialize(obj)
            % Convert to an ISMRMRD AcquisitionHeader to a byte array
            % This conforms to the memory layout of the C-struct

            bytes = cat(2, typecast(obj.version                  ,'uint8'), ...
                           typecast(obj.flags                    ,'uint8'), ...
                           typecast(obj.measurement_uid          ,'uint8'), ...
                           typecast(obj.scan_counter             ,'uint8'), ...
                           typecast(obj.acquisition_time_stamp   ,'uint8'), ...
                           typecast(obj.physiology_time_stamp    ,'uint8'), ...
                           typecast(obj.number_of_samples        ,'uint8'), ...
                           typecast(obj.available_channels       ,'uint8'), ...
                           typecast(obj.active_channels          ,'uint8'), ...
                           typecast(obj.channel_mask             ,'uint8'), ...
                           typecast(obj.discard_pre              ,'uint8'), ...
                           typecast(obj.discard_post             ,'uint8'), ...
                           typecast(obj.center_sample            ,'uint8'), ...
                           typecast(obj.encoding_space_ref       ,'uint8'), ...
                           typecast(obj.trajectory_dimensions    ,'uint8'), ...
                           typecast(obj.sample_time_us           ,'uint8'), ...
                           typecast(obj.position                 ,'uint8'), ...
                           typecast(obj.read_dir                 ,'uint8'), ...
                           typecast(obj.phase_dir                ,'uint8'), ...
                           typecast(obj.slice_dir                ,'uint8'), ...
                           typecast(obj.patient_table_position   ,'uint8'), ...
                           typecast(obj.idx.kspace_encode_step_1 ,'uint8'), ...
                           typecast(obj.idx.kspace_encode_step_2 ,'uint8'), ...
                           typecast(obj.idx.average              ,'uint8'), ...
                           typecast(obj.idx.slice                ,'uint8'), ...
                           typecast(obj.idx.contrast             ,'uint8'), ...
                           typecast(obj.idx.phase                ,'uint8'), ...
                           typecast(obj.idx.repetition           ,'uint8'), ...
                           typecast(obj.idx.set                  ,'uint8'), ...
                           typecast(obj.idx.segment              ,'uint8'), ...
                           typecast(obj.idx.user                 ,'uint8'), ...
                           typecast(obj.user_int                 ,'uint8'), ...
                           typecast(obj.user_float               ,'uint8'));

            if (numel(bytes) ~= 340)
                error('Serialized Acquisitionheader is %d bytes instead of 340 bytes', numel(bytes));
            end
        end

        % Check if a flag is set to true
        % Input can be a bit index or a name listed in ismrmrd.AcquisitionHeader.FLAGS
        function ret = flagIsSet(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.AcquisitionHeader.FLAGS char or a bit index.'); 
            end

            ret = bitget(obj.flags, b);
        end

        % Set a flag to true
        % Input can be a bit index or a name listed in ismrmrd.AcquisitionHeader.FLAGS
        function obj = flagSet(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.AcquisitionHeader.FLAGS char or a bit index.'); 
            end

            obj.flags = bitset(obj.flags, b);
        end

        % Set a flag to false
        % Input can be a bit index or a name listed in ismrmrd.AcquisitionHeader.FLAGS
        function obj = flagClear(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.AcquisitionHeader.FLAGS char or a bit index.'); 
            end

            obj.flags = bitset(obj.flags, b, 0);
        end

        % Clear all flags
        function obj = flagClearAll(obj)
            obj.flags = zeros(1, 1,'uint64');
        end

        % Get cell array with names of all active flags
        function cFlags = getFlags(obj)
            flagnames = fieldnames(obj.FLAGS);
            cFlags = flagnames(cellfun(@(x) logical(obj.flagIsSet(x)), flagnames));
        end

        % Convert to basic struct
        % This is used by built-in HDF5 functions.  Overloaded from the built-in
        % struct(obj) function to avoid warnings, but may be modified in the future
        function s = struct(obj)
            publicProperties = properties(obj);
            s = struct();
            for fi = 1:numel(publicProperties)
                if strcmp(publicProperties{fi}, 'FLAGS')
                    continue
                end
                s.(publicProperties{fi}) = obj.(publicProperties{fi});
            end

            % Explicit handling of idx (EncodingCounters)
            s.idx = struct(s.idx);
        end
    end
end
