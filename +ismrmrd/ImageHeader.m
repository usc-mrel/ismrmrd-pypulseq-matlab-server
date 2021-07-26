% ISMRMRD ImageHeader class
classdef ImageHeader
    properties
        version                = zeros(1,1,'uint16');  % First unsigned int indicates the version
        data_type              = zeros(1,1,'uint16');  % e.g. unsigned short, float, complex float, etc.
        flags                  = zeros(1,1,'uint64');  % bit field with flags
        measurement_uid        = zeros(1,1,'uint32');  % Unique ID for the measurement
        matrix_size            = zeros(1,3,'uint16');  % Pixels in the 3 spatial dimensions
        field_of_view          = zeros(1,3,'single');  % Size (in mm) of the 3 spatial dimensions
        channels               = zeros(1,1,'uint16');  % Number of receive channels
        position               = zeros(1,3,'single');  % Three-dimensional spatial offsets from isocenter
        read_dir               = zeros(1,3,'single');  % Directional cosines of the readout/frequency encoding
        phase_dir              = zeros(1,3,'single');  % Directional cosines of the phase encoding
        slice_dir              = zeros(1,3,'single');  % Directional cosines of the slice
        patient_table_position = zeros(1,3,'single');  % Patient table off-center
        average                = zeros(1,1,'uint16');  % e.g. signal average number
        slice                  = zeros(1,1,'uint16');  % e.g. imaging slice number
        contrast               = zeros(1,1,'uint16');  % e.g. echo number in multi-echo
        phase                  = zeros(1,1,'uint16');  % e.g. cardiac phase number
        repetition             = zeros(1,1,'uint16');  % e.g. dynamic number for dynamic scanning
        set                    = zeros(1,1,'uint16');  % e.g. flow encodning set
        acquisition_time_stamp = zeros(1,1,'uint32');  % Acquisition clock
        physiology_time_stamp  = zeros(1,3,'uint32');  % Physiology time stamps, e.g. ecg, breathing, etc.
        image_type             = zeros(1,1,'uint16');  % e.g. magnitude, phase, complex, real, imag, etc.
        image_index            = zeros(1,1,'uint16');  % e.g. image number in series of images
        image_series_index     = zeros(1,1,'uint16');  % e.g. series number
        user_int               = zeros(1,8, 'int32');  % Free user parameters
        user_float             = zeros(1,8,'single');  % Free user parameters
        attribute_string_len   = zeros(1,1,'uint32');  % Length (bytes) of MetaAttribute text
    end

    properties(Constant)
        FLAGS = struct( ...
            'IMAGE_IS_NAVIGATION_DATA',  1, ...
            'IMAGE_USER1',              57, ...
            'IMAGE_USER2',              58, ...
            'IMAGE_USER3',              59, ...
            'IMAGE_USER4',              60, ...
            'IMAGE_USER5',              61, ...
            'IMAGE_USER6',              62, ...
            'IMAGE_USER7',              63, ...
            'IMAGE_USER8',              64);

        DATA_TYPE = struct( ...
            'USHORT',   uint16(1), ...
            'SHORT',    uint16(2), ...
            'UINT',     uint16(3), ...
            'INT',      uint16(4), ...
            'FLOAT',    uint16(5), ...
            'DOUBLE',   uint16(6), ...
            'CXFLOAT',  uint16(7), ...
            'CXDOUBLE', uint16(8));

        IMAGE_TYPE = struct( ...
            'MAGNITUDE', uint16(1), ...
            'PHASE',     uint16(2), ...
            'REAL',      uint16(3), ...
            'IMAG',      uint16(4), ...
            'COMPLEX',   uint16(5));

    end
    
    methods (Static)
        % Convert MRD data_type enum (e.g. 1) into readable name (e.g. USHORT)
        function dtype = getMrdDatatypeName(data_type)
            names = fieldnames(ismrmrd.ImageHeader.DATA_TYPE);
            for i = 1:numel(names)
                if (ismrmrd.ImageHeader.DATA_TYPE.(names{i}) == data_type)
                    dtype = names{i};
                    return
                end
            end
            error('Unrecognized data type %s', data_type)
        end

        % Get size of an data_type (e.g. USHORT) in bytes (e.g. 2)
        function bytes = getDatatypeSize(data_type)
            switch (ismrmrd.ImageHeader.getMrdDatatypeName(data_type))
                case 'USHORT'
                    bytes = 2;
                case 'SHORT'
                    bytes = 2;
                case 'UINT'
                    bytes = 4;
                case 'INT'
                    bytes = 4;
                case 'FLOAT'
                    bytes = 4;
                case 'DOUBLE'
                    bytes = 8;
                case 'CXFLOAT'
                    bytes = 8;
                case 'CXDOUBLE'
                    bytes = 16;
                otherwise
                    error('Unrecognized data type %s', ismrmrd.ImageHeader.getMrdDatatypeName(data_type))
            end
        end

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
        function obj = ImageHeader(arg)
            switch nargin
                case 0
                    % Empty header
                case 1
                    if isa(arg, 'ismrmrd.ImageHeader')
                        % Already formatted ImageHeader object
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
        function obj = set.version(               obj, val),  if obj.ValidateSize(val, [1 1], 'version'),                obj.version                = uint16(val); end,  end
        function obj = set.data_type(             obj, val),  if obj.ValidateSize(val, [1 1], 'data_type'),              obj.data_type              = uint16(val); end,  end
        function obj = set.flags(                 obj, val),  if obj.ValidateSize(val, [1 1], 'flags'),                  obj.flags                  = uint64(val); end,  end
        function obj = set.measurement_uid(       obj, val),  if obj.ValidateSize(val, [1 1], 'measurement_uid'),        obj.measurement_uid        = uint32(val); end,  end
        function obj = set.matrix_size(           obj, val),  if obj.ValidateSize(val, [1 3], 'matrix_size'),            obj.matrix_size            = uint16(val); end,  end
        function obj = set.field_of_view(         obj, val),  if obj.ValidateSize(val, [1 3], 'field_of_view'),          obj.field_of_view          = single(val); end,  end
        function obj = set.channels(              obj, val),  if obj.ValidateSize(val, [1 1], 'channels'),               obj.channels               = uint16(val); end,  end
        function obj = set.position(              obj, val),  if obj.ValidateSize(val, [1 3], 'position'),               obj.position               = single(val); end,  end
        function obj = set.read_dir(              obj, val),  if obj.ValidateSize(val, [1 3], 'read_dir'),               obj.read_dir               = single(val); end,  end
        function obj = set.phase_dir(             obj, val),  if obj.ValidateSize(val, [1 3], 'phase_dir'),              obj.phase_dir              = single(val); end,  end
        function obj = set.slice_dir(             obj, val),  if obj.ValidateSize(val, [1 3], 'slice_dir'),              obj.slice_dir              = single(val); end,  end
        function obj = set.patient_table_position(obj, val),  if obj.ValidateSize(val, [1 3], 'patient_table_position'), obj.patient_table_position = single(val); end,  end
        function obj = set.average(               obj, val),  if obj.ValidateSize(val, [1 1], 'average'),                obj.average                = uint16(val); end,  end
        function obj = set.slice(                 obj, val),  if obj.ValidateSize(val, [1 1], 'slice'),                  obj.slice                  = uint16(val); end,  end
        function obj = set.contrast(              obj, val),  if obj.ValidateSize(val, [1 1], 'contrast'),               obj.contrast               = uint16(val); end,  end
        function obj = set.phase(                 obj, val),  if obj.ValidateSize(val, [1 1], 'phase'),                  obj.phase                  = uint16(val); end,  end
        function obj = set.repetition(            obj, val),  if obj.ValidateSize(val, [1 1], 'repetition'),             obj.repetition             = uint16(val); end,  end
        function obj = set.set(                   obj, val),  if obj.ValidateSize(val, [1 1], 'set'),                    obj.set                    = uint16(val); end,  end
        function obj = set.acquisition_time_stamp(obj, val),  if obj.ValidateSize(val, [1 1], 'acquisition_time_stamp'), obj.acquisition_time_stamp = uint32(val); end,  end
        function obj = set.physiology_time_stamp( obj, val),  if obj.ValidateSize(val, [1 3], 'physiology_time_stamp'),  obj.physiology_time_stamp  = uint32(val); end,  end
        function obj = set.image_type(            obj, val),  if obj.ValidateSize(val, [1 1], 'image_type'),             obj.image_type             = uint16(val); end,  end
        function obj = set.image_index(           obj, val),  if obj.ValidateSize(val, [1 1], 'image_index'),            obj.image_index            = uint16(val); end,  end
        function obj = set.image_series_index(    obj, val),  if obj.ValidateSize(val, [1 1], 'image_series_index'),     obj.image_series_index     = uint16(val); end,  end
        function obj = set.user_int(              obj, val),  if obj.ValidateSize(val, [1 8], 'user_int'),               obj.user_int               =  int32(val); end,  end
        function obj = set.user_float(            obj, val),  if obj.ValidateSize(val, [1 8], 'user_float'),             obj.user_float             = single(val); end,  end
        function obj = set.attribute_string_len(  obj, val),  if obj.ValidateSize(val, [1 1], 'attribute_string_len'),   obj.attribute_string_len   = uint32(val); end,  end

        % Convert from the byte array of the C-struct memory layout for an ISMRMRD ImageHeader
        function obj = deserialize(obj, bytes)
            if (numel(bytes) ~= 198)
                error('Serialized ImageHeader is %d bytes -- should be 198', numel(bytes))
            end

            if ~isrow(bytes)
                bytes = bytes';
            end

            obj.version                = typecast(bytes(1:2),     'uint16');
            obj.data_type              = typecast(bytes(3:4),     'uint16');
            obj.flags                  = typecast(bytes(5:12),    'uint64');
            obj.measurement_uid        = typecast(bytes(13:16),   'uint32');
            obj.matrix_size            = typecast(bytes(17:22),   'uint16');
            obj.field_of_view          = typecast(bytes(23:34),   'single');
            obj.channels               = typecast(bytes(35:36),   'uint16');
            obj.position               = typecast(bytes(37:48),   'single');
            obj.read_dir               = typecast(bytes(49:60),   'single');
            obj.phase_dir              = typecast(bytes(61:72),   'single');
            obj.slice_dir              = typecast(bytes(73:84),   'single');
            obj.patient_table_position = typecast(bytes(85:96),   'single');
            obj.average                = typecast(bytes(97:98),   'uint16');
            obj.slice                  = typecast(bytes(99:100),  'uint16');
            obj.contrast               = typecast(bytes(101:102), 'uint16');
            obj.phase                  = typecast(bytes(103:104), 'uint16');
            obj.repetition             = typecast(bytes(105:106), 'uint16');
            obj.set                    = typecast(bytes(107:108), 'uint16');
            obj.acquisition_time_stamp = typecast(bytes(109:112), 'uint32');
            obj.physiology_time_stamp  = typecast(bytes(113:124), 'uint32');
            obj.image_type             = typecast(bytes(125:126), 'uint16');
            obj.image_index            = typecast(bytes(127:128), 'uint16');
            obj.image_series_index     = typecast(bytes(129:130), 'uint16');
            obj.user_int               = typecast(bytes(131:162), 'uint32');
            obj.user_float             = typecast(bytes(163:194), 'single');
            obj.attribute_string_len   = typecast(bytes(195:198), 'uint32');
        end

        % Convert to the byte array of the C-struct memory layout for an ISMRMRD ImageHeader
        function bytes = serialize(obj)
            bytes = cat(2, typecast(obj.version                ,'uint8'), ...
                           typecast(obj.data_type              ,'uint8'), ...
                           typecast(obj.flags                  ,'uint8'), ...
                           typecast(obj.measurement_uid        ,'uint8'), ...
                           typecast(obj.matrix_size            ,'uint8'), ...
                           typecast(obj.field_of_view          ,'uint8'), ...
                           typecast(obj.channels               ,'uint8'), ...
                           typecast(obj.position               ,'uint8'), ...
                           typecast(obj.read_dir               ,'uint8'), ...
                           typecast(obj.phase_dir              ,'uint8'), ...
                           typecast(obj.slice_dir              ,'uint8'), ...
                           typecast(obj.patient_table_position ,'uint8'), ...
                           typecast(obj.average                ,'uint8'), ...
                           typecast(obj.slice                  ,'uint8'), ...
                           typecast(obj.contrast               ,'uint8'), ...
                           typecast(obj.phase                  ,'uint8'), ...
                           typecast(obj.repetition             ,'uint8'), ...
                           typecast(obj.set                    ,'uint8'), ...
                           typecast(obj.acquisition_time_stamp ,'uint8'), ...
                           typecast(obj.physiology_time_stamp  ,'uint8'), ...
                           typecast(obj.image_type             ,'uint8'), ...
                           typecast(obj.image_index            ,'uint8'), ...
                           typecast(obj.image_series_index     ,'uint8'), ...
                           typecast(obj.user_int               ,'uint8'), ...
                           typecast(obj.user_float             ,'uint8'), ...
                           typecast(obj.attribute_string_len   ,'uint8'));

            if (numel(bytes) ~= 198)
                error('Serialized ImageHeader is %d bytes instead of 198 bytes', numel(bytes));
            end
        end

        % Populate ImageHeader fields from AcquisitionHeader
        function obj = fromAcqHead(obj, acqHead)
            if ~isa(acqHead, 'ismrmrd.AcquisitionHeader')
                error('Input must be an ismrmrd.AcquisitionHeader');
            end

            % Defaults, to be updated by the user
            obj.image_type             = obj.IMAGE_TYPE.MAGNITUDE;
            obj.image_index            = 1;
            obj.image_series_index     = 0;

            % % These fields are not translated from the raw header, but filled in during image creation by fromArray
            % obj.data_type            = 
            % obj.matrix_size          = 
            % obj.channels             = 

            % % This is mandatory, but must be filled in from the XML header, not from the acquisition header
            % obj.field_of_view        = 

            obj.version                = acqHead.version;
            obj.flags                  = acqHead.flags;
            obj.measurement_uid        = acqHead.measurement_uid;
            obj.position               = acqHead.position;
            obj.read_dir               = acqHead.read_dir;
            obj.phase_dir              = acqHead.phase_dir;
            obj.slice_dir              = acqHead.slice_dir;
            obj.patient_table_position = acqHead.patient_table_position;
            obj.average                = acqHead.idx.average;
            obj.slice                  = acqHead.idx.slice;
            obj.contrast               = acqHead.idx.contrast;
            obj.phase                  = acqHead.idx.phase;
            obj.repetition             = acqHead.idx.repetition;
            obj.set                    = acqHead.idx.set;
            obj.acquisition_time_stamp = acqHead.acquisition_time_stamp;
            obj.physiology_time_stamp  = acqHead.physiology_time_stamp;
            obj.user_float             = acqHead.user_float;
            obj.user_int               = acqHead.user_int;
        end

        % Check if a flag is set to true
        % Input can be a bit index or a name listed in ismrmrd.ImageHeader.FLAGS
        function ret = flagIsSet(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.ImageHeader.FLAGS char or a bit index.'); 
            end
 
            ret = bitget(obj.flags, b);
        end

        % Set a flag to true
        % Input can be a bit index or a name listed in ismrmrd.ImageHeader.FLAGS
        function obj = flagSet(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.ImageHeader.FLAGS char or a bit index.'); 
            end

            obj.flags = bitset(obj.flags, b);
        end

        % Set a flag to false
        % Input can be a bit index or a name listed in ismrmrd.ImageHeader.FLAGS
        function obj = flagClear(obj, flag)
            if isa(flag, 'char')
                b = obj.FLAGS.(flag);
            elseif (flag>0)
                b = uint64(flag);
            else
                error('Flag must be a ismrmrd.ImageHeader.FLAGS char or a bit index.'); 
            end

            obj.flags = bitset(obj.flags, b, 0);
        end

        % Clear all flags
        function obj = flagClearAll(obj)
            obj.flags = zeros(1, 1,'uint64');
        end

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
    end % methods
end
