% Image
classdef Image

    % Properties
    properties

        head_ = ismrmrd.ImageHeader;
        data_ = [];
        attribute_string_ = [];

    end % Properties

    % Methods
    methods

        function obj = set.head_(obj,v)
            obj.head_ = v;
        end

        function obj = set.data_(obj,v)
            obj.data_ = single(complex(v));
        end

        function b = isFlagSet(obj,flag)
            bitflag = ismrmrd.FlagBit(flag);
            b = bitflag.isSet(obj.head_.flag);
        end

        function obj = setFlag(obj,flag)
            bitflag = ismrmrd.FlagBit(flag);
            obj.head_.flag = bitor(obj.head_.flag, bitflag.bitmask_);
        end

        % Convert data from uint8 data stream into appropriate data type and 
        % shape, based on already set ImageHeader
        function obj = deserializeData(obj, data_bytes)
            switch (ismrmrd.ImageHeader.getMrdDatatypeName(obj.head_.data_type))
                case 'USHORT'
                    obj.data_ = reshape(typecast(data_bytes, 'uint16'),   obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'SHORT'
                    obj.data_ = reshape(typecast(data_bytes, 'int16'),    obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'UINT'
                    obj.data_ = reshape(typecast(data_bytes, 'uint32'),   obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'INT'
                    obj.data_ = reshape(typecast(data_bytes, 'int32'),    obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'FLOAT'
                    obj.data_ = reshape(typecast(data_bytes, 'single'),   obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'DOUBLE'
                    obj.data_ = reshape(typecast(data_bytes, 'double'),   obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'CXFLOAT'
                    data = typecast(data_bytes, 'single');
                    obj.data_ = reshape(data(1:2:end) + 1j*data(2:2:end), obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                case 'CXDOUBLE'
                    data = typecast(data_bytes, 'double');
                    obj.data_ = reshape(data(1:2:end) + 1j*data(2:2:end), obj.head_.matrix_size(1), obj.head_.matrix_size(2), obj.head_.matrix_size(3), obj.head_.channels);
                otherwise
                    error('Unrecognized data type %s', obj.head_.data_type)
            end
        end

    end % Methods

end
