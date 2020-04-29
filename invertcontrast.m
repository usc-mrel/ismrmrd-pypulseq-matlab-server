classdef invertcontrast < handle
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

            % Continuously parse incoming data parsed from MRD messages
            acqGroup = []; %ismrmrd.Acquisition;
            imgGroup = []; %ismrmrd.Image;
            try
                while true
                    item = next(connection);

                    % ----------------------------------------------------------
                    % Raw k-space data messages
                    % ----------------------------------------------------------
                    if isa(item, 'ismrmrd.Acquisition')
                        % Accumulate all imaging readouts in a group
                        if (~item.head.flagIsSet(item.head.FLAGS.ACQ_IS_NOISE_MEASUREMENT) && ...
                            ~item.head.flagIsSet(item.head.FLAGS.ACQ_IS_PHASECORR_DATA))

                            if isempty(acqGroup)
                                acqGroup = ismrmrd.Acquisition(item.head, item.traj, item.data);
                            else
                                append(acqGroup, item.head, item.traj{:}, item.data{:});
                            end
                        end

                        % When this criteria is met, run process_raw() on the accumulated
                        % data, which returns images that are sent back to the client.
                        if item.head.flagIsSet(item.head.FLAGS.ACQ_LAST_IN_MEASUREMENT)
                            logging.info("Processing a group of k-space data")
                            image = obj.process_raw(acqGroup, config, metadata, logging);
                            logging.debug("Sending image to client")
                            connection.send_image(image);
                            acqGroup = [];
                        end

                    % ----------------------------------------------------------
                    % Image data messages
                    % ----------------------------------------------------------
                    elseif isa(item, 'ismrmrd.Image')
                        % TODO: example for which images to keep/discard
                        if true
                            % TODO: This has also not been implemented in the ismrmrd library...
                            append(imgGroup, item.head_, item.data_, item.attribute_string_);
                        end

                        % When this criteria is met, run process_group() on the accumulated
                        % data, which returns images that are sent back to the client.
                        % TODO: logic for grouping images
                        if false
                            logging.info("Processing a group of images")
                            image = obj.process_image(imgGroup, config, metadata, logging);
                            logging.debug("Sending image to client")
                            connection.send_image(image);
                            imgGroup = [];
                        end

                    elseif isempty(item)
                        break;

                    else
                        logging.error("Unhandled data type: %s", class(item))
                    end
                end
            end

            % Process any remaining groups of raw or image data.  This can 
            % happen if the trigger condition for these groups are not met.
            % This is also a fallback for handling image data, as the last
            % image in a series is typically not separately flagged.
            if ~isempty(acqGroup)
                logging.info("Processing a group of k-space data (untriggered)")
                image = obj.process_raw(acqGroup, config, metadata, logging);
                logging.debug("Sending image to client")
                connection.send_image(image);
                acqGroup = [];
            end

            if ~isempty(imgGroup)
                logging.info("Processing a group of images (untriggered)")
                image = obj.process_image(imgGroup, config, metadata, logging);
                logging.debug("Sending image to client")
                connection.send_image(image);
                imgGroup = [];
            end

            connection.send_close();
            return
        end

        function image = process_raw(obj, group, config, metadata, logging)
            % Format data into a single [RO PE cha] array
            ksp = cat(3, group.data{:});
            ksp = permute(ksp, [1 3 2]);

            % Fourier Transform
            img = fftshift(fft2(ifftshift(ksp)));

            % Sum of squares coil combination
            img = sqrt(sum(abs(img).^2,3));

            % Remove phase oversampling
            img = img(round(size(img,1)/4+1):round(size(img,1)*3/4),:);
            logging.debug("Image data is size %d x %d after coil combine and phase oversampling removal", size(img))
        
            % Normalize and convert to short (int16)
            img = img .* (32767./max(img(:)));
            img = int16(round(img));

            % Invert image contrast
            img = int16(abs(32767-img));

            % Format as ISMRMRD image data
            image = ismrmrd.Image();

            image.data_ = img;

            % In MATLAB's ISMRMD toolbox, header information is not updated after setting image data
            image.head_.matrix_size(1) = uint16(size(img,1));
            image.head_.matrix_size(2) = uint16(size(img,2));
            image.head_.matrix_size(3) = uint16(size(img,3));
            image.head_.channels       = uint16(1);
            image.head_.data_type      = uint16(ismrmrd.ImageHeader.DATA_TYPE.SHORT);
            image.head_.image_index    = uint16(1);  % This field is mandatory

            % Set ISMRMRD Meta Attributes
            meta = ismrmrd.Meta();
            meta.DataRole     = 'Image';
            meta.WindowCenter = 16384;
            meta.WindowWidth  = 32768;

            image.attribute_string_ = serialize(meta);
            image.head_.attribute_string_len = uint32(length(image.attribute_string_));
        end
    end
end
