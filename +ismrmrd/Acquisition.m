classdef Acquisition
    % Class for the MRD Acquisition data structure as described in:
    % https://ismrmrd.github.io/apidocs/1.4.2/struct_i_s_m_r_m_r_d_1_1_i_s_m_r_m_r_d___acquisition.html
    %
    % This class contains 3 components:
    %   - head: An AcquisitionHeader describing metadata for a readout
    %   - traj: k-space trajectory for the readout
    %   - data: complex raw readout data
    %
    % Each instance of this class describes a single readout acquisition and
    % multiple Acquisition objects in a cell array should be used to collect a
    % series of multiple readouts.
    %
    % A series of "set" functions is provided for each AcquisitionHeader field.
    % These should be used whenever possible in order to ensure valid data type
    % and size for each parameter.  If data is pre-validated by the user and
    % faster performance is required, individual fields can be set directly,
    % bypassing internal data validation.

    properties
        head = ismrmrd.AcquisitionHeader;
        traj = single([]);
        data = single([]);
    end

    methods
        % Constructor
        function obj = Acquisition(arg1, traj, data)
            switch nargin
                case 0
                    % Empty acquisition
                case 1
                    if isa(arg1,'ismrmrd.Acquisition')
                        % Already formatted Acquisition object
                        obj = arg1;
                    elseif isa(arg1,'ismrmrd.AcquisitionHeader')
                        % Just the header
                        obj.head = arg1;
                        obj.initializeData();
                    else
                        % Unknown type
                        error('Unsupported constructor with input class %s', class(arg))
                    end
                case 3
                    % Constructor with head, traj, data
                    obj.head = arg1;

                    if isempty(traj)
                        obj.traj = single([]);
                    else
                        dims = [obj.head.trajectory_dimensions obj.head.number_of_samples];
                        if (prod(dims) ~= numel(traj))
                            error('Trajectory data has %d elements, which must be equal to trajectory_dimensions (%d) * number_of_samples (%d)', numel(traj), dims(1), dims(2))
                        end
                        obj.traj = reshape(traj, dims);
                    end

                    if isempty(data)
                        obj.data = [];
                    else
                        if isreal(data)
                            data = complex(data(1:2:end), data(2:2:end));
                        end
                        dims = [obj.head.number_of_samples obj.head.active_channels];
                        if (prod(dims) ~= numel(data))
                            error('Acquisition data has %d elements, which must be equal to number_of_samples (%d) * active_channels (%d)', numel(data), dims(1), dims(2))
                        end
                        obj.data = reshape(data, dims);
                    end
                otherwise
                    error('Constructor must have 0, 1, or 3 arguments.');
            end
        end

        % Set handlers with data validation
        function obj = set_version(                  obj, val),  obj.head     = obj.head.set_version(                  val );  end
        function obj = set_flags(                    obj, val),  obj.head     = obj.head.set_flags(                    val );  end
        function obj = set_measurement_uid(          obj, val),  obj.head     = obj.head.set_measurement_uid(          val );  end
        function obj = set_scan_counter(             obj, val),  obj.head     = obj.head.set_scan_counter(             val );  end
        function obj = set_acquisition_time_stamp(   obj, val),  obj.head     = obj.head.set_acquisition_time_stamp(   val );  end
        function obj = set_physiology_time_stamp(    obj, val),  obj.head     = obj.head.set_physiology_time_stamp(    val );  end
        function obj = set_number_of_samples(        obj, val),  obj.head     = obj.head.set_number_of_samples(        val );  end
        function obj = set_available_channels(       obj, val),  obj.head     = obj.head.set_available_channels(       val );  end
        function obj = set_active_channels(          obj, val),  obj.head     = obj.head.set_active_channels(          val );  end
        function obj = set_channel_mask(             obj, val),  obj.head     = obj.head.set_channel_mask(             val );  end
        function obj = set_discard_pre(              obj, val),  obj.head     = obj.head.set_discard_pre(              val );  end
        function obj = set_discard_post(             obj, val),  obj.head     = obj.head.set_discard_post(             val );  end
        function obj = set_center_sample(            obj, val),  obj.head     = obj.head.set_center_sample(            val );  end
        function obj = set_encoding_space_ref(       obj, val),  obj.head     = obj.head.set_encoding_space_ref(       val );  end
        function obj = set_trajectory_dimensions(    obj, val),  obj.head     = obj.head.set_trajectory_dimensions(    val );  end
        function obj = set_sample_time_us(           obj, val),  obj.head     = obj.head.set_sample_time_us(           val );  end
        function obj = set_position(                 obj, val),  obj.head     = obj.head.set_position(                 val );  end
        function obj = set_read_dir(                 obj, val),  obj.head     = obj.head.set_read_dir(                 val );  end
        function obj = set_phase_dir(                obj, val),  obj.head     = obj.head.set_phase_dir(                val );  end
        function obj = set_slice_dir(                obj, val),  obj.head     = obj.head.set_slice_dir(                val );  end
        function obj = set_patient_table_position(   obj, val),  obj.head     = obj.head.set_patient_table_position(   val );  end
        function obj = set_user_int(                 obj, val),  obj.head     = obj.head.set_user_int(                 val );  end
        function obj = set_user_float(               obj, val),  obj.head     = obj.head.set_user_float(               val );  end
        function obj = set_idx_kspace_encode_step_1( obj, val),  obj.head.idx = obj.head.idx.set_kspace_encode_step_1( val );  end
        function obj = set_idx_kspace_encode_step_2( obj, val),  obj.head.idx = obj.head.idx.set_kspace_encode_step_2( val );  end
        function obj = set_idx_average(              obj, val),  obj.head.idx = obj.head.idx.set_average(              val );  end
        function obj = set_idx_slice(                obj, val),  obj.head.idx = obj.head.idx.set_slice(                val );  end
        function obj = set_idx_contrast(             obj, val),  obj.head.idx = obj.head.idx.set_contrast(             val );  end
        function obj = set_idx_phase(                obj, val),  obj.head.idx = obj.head.idx.set_phase(                val );  end
        function obj = set_idx_repetition(           obj, val),  obj.head.idx = obj.head.idx.set_repetition(           val );  end
        function obj = set_idx_set(                  obj, val),  obj.head.idx = obj.head.idx.set_set(                  val );  end
        function obj = set_idx_user(                 obj, val),  obj.head.idx = obj.head.idx.set_user(                 val );  end

        % Serialize complex data into interleaved real/imag single pairs
        function out = serializeData(obj)
            dim  = size(obj.data);
            out = zeros([2*prod(dim) 1], 'single');
            out(1:2:end) = real(reshape(obj.data, prod(dim), 1));
            out(2:2:end) = imag(reshape(obj.data, prod(dim), 1));
        end
    end % methods

    methods(Access = private)
        function obj = initializeData(obj)
            obj.data = complex(zeros(obj.head.number_of_samples,     obj.head.active_channels,   'single'));
            obj.traj =         zeros(obj.head.trajectory_dimensions, obj.head.number_of_samples, 'single');
        end
    end

end