classdef simple_nufft < handle
    % Linting warning suppression:
    %#ok<*INUSD>  Input argument '' might be unused.  If this is OK, consider replacing it by ~
    %#ok<*NASGU>  The value assigned to variable '' might be unused.
    %#ok<*INUSL>  Input argument '' might be unused, although a later one is used.  Ronsider replacing it by ~
    %#ok<*AGROW>  The variable '' appear to change in size on every loop  iteration. Consider preallocating for speed.

    methods
        function process(obj, connection, config, metadata, logging)
            logging.info('Config: \n%s', config);

            % Metadata should be MRD formatted header, but may be a string
            % if it failed conversion earlier
            try
                logging.info("Incoming dataset contains %d encodings", numel(metadata.encoding))
                logging.info("First encoding is of type '%s', with field of view of (%g x %g x %g)mm^3, matrix size of (%g x %g x %g), and %g coils", ...
                    metadata.encoding(1).trajectory, ...
                    metadata.encoding(1).encodedSpace.fieldOfView_mm.x, ...
                    metadata.encoding(1).encodedSpace.fieldOfView_mm.y, ...
                    metadata.encoding(1).encodedSpace.fieldOfView_mm.z, ...
                    metadata.encoding(1).encodedSpace.matrixSize.x, ...
                    metadata.encoding(1).encodedSpace.matrixSize.y, ...
                    metadata.encoding(1).encodedSpace.matrixSize.z, ...
                    metadata.acquisitionSystemInformation.receiverChannels)
            catch
                logging.info("Improperly formatted metadata: \n%s", metadata)
            end


            load("pulseq_metadata/" + config + ".mat");

            msize = floor(param.fov * 10/ param.spatialResolution);

            % TODO: get the correct matrix size from the metadata.
            k_max = max(sqrt(kx(:).^2 + ky(:).^2));
            kx = (kx / k_max) * msize * 2 / 2;
            ky = -(ky / k_max) * msize * 2 / 2;

            N = NUFFT.init(kx, ky, 1, [6, 6], msize*2, msize*2);
            N.W = w;

            % Continuously parse incoming data parsed from MRD messages
            acqGroup = cell(1,0); % ismrmrd.Acquisition;
            try
                while true
                    logging.info("awaiting item")
                    item = next(connection);
                    logging.info("item retrieved")

                    % ----------------------------------------------------------
                    % Raw k-space data messages
                    % ----------------------------------------------------------
                    if isa(item, 'ismrmrd.Acquisition')
                        % Accumulate all imaging readouts in a group
                        if (~item.head.flagIsSet(item.head.FLAGS.ACQ_IS_NOISE_MEASUREMENT)    && ...
                            ~item.head.flagIsSet(item.head.FLAGS.ACQ_IS_PHASECORR_DATA)       && ...
                            ~item.head.flagIsSet(item.head.FLAGS.ACQ_IS_PARALLEL_CALIBRATION)       )
                                acqGroup{end+1} = item;
                        end

                        % When this criteria is met, run process_raw() on the accumulated
                        % data, which returns images that are sent back to the client.
                        %if item.head.flagIsSet(item.head.FLAGS.ACQ_LAST_IN_SLICE)
                        if (mod(item.head.idx.kspace_encode_step_1+1, param.repetitions) == 0)
                            logging.info("Processing a group of k-space data")
                            repetition = floor((item.head.idx.kspace_encode_step_1+1) / param.repetitions);
                            image = obj.process_raw(acqGroup, config, metadata, logging, repetition, N);
                            logging.debug("Sending image to client")
                            connection.send_image(image);
                            acqGroup = {};
                        end
                    elseif isempty(item)
                        break;
                    else
                        logging.error("Unhandled data type: %s", class(item))
                    end
                end
            catch ME
                logging.error(sprintf('%s\nError in %s (%s) (line %d)', ME.message, ME.stack(1).('name'), ME.stack(1).('file'), ME.stack(1).('line')));
            end

            % Process any remaining groups of raw or image data.  This can
            % happen if the trigger condition for these groups are not met.
            % This is also a fallback for handling image data, as the last
            % image in a series is typically not separately flagged.
            if ~isempty(acqGroup)
                logging.info("Processing a group of k-space data (untriggered)")
                image = obj.process_raw(acqGroup, config, metadata, logging, 0, N);
                logging.debug("Sending image to client")
                connection.send_image(image);
                acqGroup = cell(1,0);
            end

            connection.send_close();
            return
        end

        function image = process_raw(obj, group, config, metadata, logging, repetition, N)
            % This function assumes that the set of raw data belongs to a
            % single image.  If there's >1 phases, echos, sets, etc., then
            % either the call to this function from process() needs to be
            % adjusted or this code must be modified.

            % Format data into a single [RO PE cha] array
            data = cell2mat(permute(cellfun(@(x) x.data, group, 'UniformOutput', false), [1 3 2]));
            data = permute(data, [1 3 2]);

            [nsamp, narm, ncoil] = size(data);
            data = reshape(data, nsamp, narm, 1, ncoil);
            image_out = NUFFT.NUFFT_adj(data, N);
            image_out = squeeze(sqrt(sum(abs(image_out) .^ 2, 4))); % Combine the channels; sum of squares.
            [w, h] = size(image_out);

            % crop center FOV.
            image_out = image_out(floor(w/4)+1:floor(3*w/4),floor(h/4)+1:floor(3*h/4));
            im = image_out;
            w = size(im,1); h = size(im,2);

            % scale image out.
            im = im.*(32767./max(im(:)));
            im = round(im);
            im = int16(im);
            im = rot90(im);

            % Create MRD Image object, set image data and (matrix_size, channels, and data_type) in header
            image = ismrmrd.Image(im);

            % Find the center k-space index
            % kspace_encode_step_1 = cellfun(@(x) x.head.idx.kspace_encode_step_1, group);
            % centerLin            = cellfun(@(x) x.head.idx.user(6),              group);
            % centerIdx = find(kspace_encode_step_1 == centerLin, 1);
            % hack to get it to work.
            centerIdx = 4;

            % Copy the relevant AcquisitionHeader fields to ImageHeader
            image.head.fromAcqHead(group{centerIdx}.head);

            % field_of_view is mandatory
            image.head.field_of_view  = single([metadata.encoding(1).reconSpace.fieldOfView_mm.x ...
                                                metadata.encoding(1).reconSpace.fieldOfView_mm.y ...
                                                metadata.encoding(1).reconSpace.fieldOfView_mm.z]);
            image.head.image_index = repetition;

            % Set ISMRMRD Meta Attributes
            meta = struct;
            meta.DataRole               = 'Image';
            meta.ImageProcessingHistory = 'MATLAB';
            meta.WindowCenter           = uint16(16384);
            meta.WindowWidth            = uint16(32768);
            meta.ImageRowDir            = group{centerIdx}.head.read_dir;
            meta.ImageColumnDir         = group{centerIdx}.head.phase_dir;


            % set_attribute_string also updates attribute_string_len
            image = image.set_attribute_string(ismrmrd.Meta.serialize(meta));

        end

    end
end
