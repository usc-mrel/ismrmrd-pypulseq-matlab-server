% ISMRMRD Image class
classdef Image

    properties
        head             = ismrmrd.ImageHeader;
        data             = [];
        attribute_string = '';
    end

    methods
        % Constructor
        function obj = Image(arg)
            switch nargin
                case 0
                    % Empty image
                case 1
                    if isa(arg, 'ismrmrd.Image')
                        % Already formatted Image object
                        obj = arg;
                    elseif isa(arg, 'ismrmrd.ImageHeader')
                        % Just the header
                        obj.head = arg;
                    elseif isnumeric(arg)
                        % From an input MATLAB image data array, set the data_ field and as much of head_ as possible
                        obj = fromArray(obj, arg);
                    else
                        % Unknown type
                        error('Unsupported constructor with input class %s', class(arg))
                    end
                otherwise
                    error('Constructor must have 0 or 1 arguments.')
            end
        end

        % Set attribute_string and update its length in head_
        function obj = set.attribute_string(obj, val)
            d = dbstack;
            if (numel(d) < 2) || ~strcmp(d(2).name, 'Image.set_attribute_string')
                warning('Use function set_attribute_string() instead to also update attribute_string_len');
            end

            if ~ischar(val)
                error('attribute_string must be a char')
            end
            obj.attribute_string = val;
%             obj.head.attribute_string_len = length(val);
        end

        % Set attribute_string and update its length in head_
        function obj = set_attribute_string(obj, val)
            if ~ischar(val)
                error('attribute_string must be a char')
            end
            obj.attribute_string = val;
            obj.head.attribute_string_len = length(val);
        end


        % From an input MATLAB image data array, set the data_ field and as much of head_ as possible
        function obj = fromArray(obj, data)
            switch (class(data))
                case 'uint16'
                    obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.USHORT;
                case 'int16'
                    obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.SHORT;
                case 'uint32'
                    obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.UINT;
                case 'single'
                    if isreal(data)
                        obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.FLOAT;
                    else
                        obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.CXFLOAT;
                    end
                case 'double'
                    if isreal(data)
                        obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.DOUBLE;
                    else
                        obj.head.data_type = ismrmrd.ImageHeader.DATA_TYPE.CXDOUBLE;
                    end
                otherwise
                    error('Unsupported data class: %s', class(data))
            end

            obj.head.matrix_size(1) = size(data,1);
            obj.head.matrix_size(2) = size(data,2);
            obj.head.matrix_size(3) = size(data,3);
            obj.head.channels       = size(data,4);
            obj.data                = data;
        end

        % Convert image data from uint8 data stream into appropriate data type and shape, based on already set ImageHeader
        function obj = deserializeImageData(obj, data_bytes)
            switch (ismrmrd.ImageHeader.getMrdDatatypeName(obj.head.data_type))
                case 'USHORT'
                    obj.data = reshape(typecast(data_bytes, 'uint16'),   obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'SHORT'
                    obj.data = reshape(typecast(data_bytes, 'int16'),    obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'UINT'
                    obj.data = reshape(typecast(data_bytes, 'uint32'),   obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'INT'
                    obj.data = reshape(typecast(data_bytes, 'int32'),    obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'FLOAT'
                    obj.data = reshape(typecast(data_bytes, 'single'),   obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'DOUBLE'
                    obj.data = reshape(typecast(data_bytes, 'double'),   obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'CXFLOAT'
                    dataCplx = typecast(data_bytes, 'single');
                    obj.data = reshape(dataCplx(1:2:end) + 1j*dataCplx(2:2:end), obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'CXDOUBLE'
                    dataCplx = typecast(data_bytes, 'double');
                    obj.data = reshape(dataCplx(1:2:end) + 1j*dataCplx(2:2:end), obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                otherwise
                    error('Unsupported data type %s', ismrmrd.ImageHeader.getMrdDatatypeName(obj.head.data_type))
            end
        end

    end % Methods

end
