classdef Waveform < handle
    % Class for the MRD Waveform data structure as described in:
    % https://ismrmrd.github.io/apidocs/1.4.2/struct_i_s_m_r_m_r_d_1_1_i_s_m_r_m_r_d___waveform.html
    %
    % This class contains 2 components:
    %   - head: A WaveformHeader describing metadata for a waveform
    %   - data: waveform data array
    %
    % Each instance of this class describes a single waveform and multiple
    % Waveform objects in a cell array should be used to collect a series of
    % multiple readouts.
    %
    % A series of "set" functions is provided for each WaveformHeader field.
    % These should be used whenever possible in order to ensure valid data type
    % and size for each parameter.  If data is pre-validated by the user and
    % faster performance is required, individual fields can be set directly,
    % bypassing internal data validation.

    properties
        head = ismrmrd.WaveformHeader;
        data = [];
    end

    methods
        % Constructor
        function obj = Waveform(arg1, data)
            switch nargin
                case 0
                    % Empty waveform
                case 1
                    % One argument constructor
                    if isa(arg1, 'ismrmrd.Waveform')
                        % Already formatted Waveform object
                        obj = arg1;
                    elseif isa(arg1,'ismrmrd.WaveformHeader')
                        % Just the header
                        obj.head = arg1;
                        obj.initializeData();
                    else
                        % Unknown type
                        error('Unsupported constructor with input class %s', class(arg))
                    end
                case 2
                    % Constructor with head and data
                    obj.head = arg1;

                    if isempty(data)
                        obj.data = [];
                    else
                        data = typecast(data, 'uint32');
                        dims = [obj.head.number_of_samples obj.head.channels];
                        if (prod(dims) ~= numel(data))
                            error('Waveform data has %d elements, which must be equal to number_of_samples (%d) * channels (%d)', numel(data), dims(1), dims(2))
                        end
                        obj.data = reshape(data, dims);
                    end
            otherwise
                error('Constructor must have 0, 1, or 2 arguments.');
            end
        end

        % Set handlers with data validation
        function obj = set_version(           obj, val),  obj.head = obj.head.set_version(           val );  end
        function obj = set_flags(             obj, val),  obj.head = obj.head.set_flags(             val );  end
        function obj = set_measurement_uid(   obj, val),  obj.head = obj.head.set_measurement_uid(   val );  end
        function obj = set_scan_counter(      obj, val),  obj.head = obj.head.set_scan_counter(      val );  end
        function obj = set_time_stamp(        obj, val),  obj.head = obj.head.set_time_stamp(        val );  end
        function obj = set_number_of_samples( obj, val),  obj.head = obj.head.set_number_of_samples( val );  end
        function obj = set_channels(          obj, val),  obj.head = obj.head.set_channels(          val );  end
        function obj = set_sample_time_us(    obj, val),  obj.head = obj.head.set_sample_time_us(    val );  end
        function obj = set_waveform_id(       obj, val),  obj.head = obj.head.set_waveform_id(       val );  end
    end
    
    methods(Access = private)
        function initializeData(obj)
            obj.data = zeros(obj.head.number_of_samples, obj.head.channels, 'uint32');
        end
    end

end
