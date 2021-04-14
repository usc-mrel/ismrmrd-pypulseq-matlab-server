classdef Acquisition

    properties
        head = ismrmrd.AcquisitionHeader;
        traj = [];
        data = [];
    end

    methods

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
                        obj.traj = [];
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