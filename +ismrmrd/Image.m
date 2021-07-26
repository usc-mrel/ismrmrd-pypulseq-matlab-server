% ISMRMRD Image class
classdef Image
    % Class for the MRD Image data structure as described in:
    % https://ismrmrd.github.io/apidocs/1.4.2/class_i_s_m_r_m_r_d_1_1_image.html
    %
    % This class contains 3 components:
    %   - head:             An ImageHeader describing metadata for an
    %   - data:             Image data array
    %   - attribute_string: XML string representation of MetaAttributes
    %
    % Each instance of this class describes a single image and multiple Image
    % objects in a cell array should be used to collect a series of images.
    %
    % A series of "set" functions is provided for each ImageHeader field.
    % These should be used whenever possible in order to ensure valid data type
    % and size for each parameter.  If data is pre-validated by the user and
    % faster performance is required, individual fields can be set directly,
    % bypassing internal data validation.

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
                    obj.data = reshape(complex(dataCplx(1:2:end), dataCplx(2:2:end)), obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                case 'CXDOUBLE'
                    dataCplx = typecast(data_bytes, 'double');
                    obj.data = reshape(complex(dataCplx(1:2:end), dataCplx(2:2:end)), obj.head.matrix_size(1), obj.head.matrix_size(2), obj.head.matrix_size(3), obj.head.channels);
                otherwise
                    error('Unsupported data type %s', ismrmrd.ImageHeader.getMrdDatatypeName(obj.head.data_type))
            end
        end

    end % Methods

end
