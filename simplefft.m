classdef simplefft < handle
    
    % Created by Alexander Fyrdahl <alexander.fyrdahl@gmail.com>
    
    methods (Static)

        function image = process(conn,config,metadata,log)
           log.info('Reconstructing %s\n',config);

            try
                log.info('Metadata is %s\n', ismrmrd.xml.serialize(metadata));
                encoding_x = metadata.encoding.encodedSpace.matrixSize.x;
                encoding_y = metadata.encoding.encodedSpace.matrixSize.y;
                recon_x    = metadata.encoding.reconSpace.matrixSize.x;
                recon_y    = metadata.encoding.reconSpace.matrixSize.y;
                num_coils  = metadata.acquisitionSystemInformation.receiverChannels;
            catch
                disp("Error deserializing XML header");
            end

            group = ismrmrd.Acquisition;
            while true
                meas = next(conn);
                if isa(meas, 'ismrmrd.Acquisition')

                    % Ignore non-imaging data
                    if ~(meas.head.flagIsSet(meas.head.FLAGS.ACQ_IS_NOISE_MEASUREMENT) || ...
                            meas.head.flagIsSet(meas.head.FLAGS.ACQ_IS_PHASECORR_DATA))
                        append(group, meas.head, meas.traj{:}, meas.data{:});
                    end

                    if meas.head.flagIsSet(meas.head.FLAGS.ACQ_LAST_IN_SLICE)
                        break
                    end
                else
                    break
                end
            end

           ksp = reshape([group.data{:}],encoding_x,num_coils,encoding_y);
           ksp = permute(ksp,[1 3 2]);
           ksp = fftshift(ifft(fftshift(ksp,1),[],1),1);

           ind1 = floor((encoding_x - recon_x)/2)+1;
           ind2 = floor((encoding_x - recon_x)/2)+recon_x;
           im = ksp(ind1:ind2,:,:);

           im = fftshift(ifft(fftshift(im,2),[],2),2);
           im = sqrt(sum(abs(im).^2,3));

           im = im.*(32768./max(im(:)));
           im = round(im);
           im = int16(im);

           image = ismrmrd.Image();

           image.head_.matrix_size(1) = uint16(recon_x);
           image.head_.matrix_size(2) = uint16(recon_y);
           image.head_.matrix_size(3) = uint16(1);
           image.head_.channels = uint16(1);
           image.head_.data_type = uint16(2);

           meta = ismrmrd.Meta();
           meta.DataRole = 'Image';
           meta.WindowCenter = 16384;
           meta.WindowWidth = 32768;
           image.attribute_string_ = serialize(meta);
           image.head_.attribute_string_len = uint32(length(image.attribute_string_));

           image.data_ = im;

           conn.send_image(image);
           conn.send_close();
        end
    end
end
