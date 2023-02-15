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
            acqGroup = cell(1,0);
            while true
                meas = next(conn);
                if isa(meas, 'ismrmrd.Acquisition')

                    % Ignore non-imaging data
                    if ~(meas.head.flagIsSet(meas.head.FLAGS.ACQ_IS_NOISE_MEASUREMENT) || ...
                            meas.head.flagIsSet(meas.head.FLAGS.ACQ_IS_PHASECORR_DATA))
                            acqGroup{end+1} = meas;
                            % append(group, meas.head, meas.traj(:), meas.data(:));
                    end

                    if meas.head.flagIsSet(meas.head.FLAGS.ACQ_LAST_IN_SLICE)
                        break
                    end
                else
                    break
                end
            end

            
           ksp = cell2mat(permute(cellfun(@(x) x.data, acqGroup, 'UniformOutput', false), [1 3 2]));
           % ksp = reshape([group.data{:}],encoding_x,num_coils,encoding_y);
           ksp = permute(ksp,[1 3 2]);
           ksp = fftshift(ifft(fftshift(ksp,1),[],1),1);
           im = ksp;
           %{
           removing for this simple test since pulseq doesn't update this
           info and it is cropping incorrectly.
           ind1 = floor((encoding_x - recon_x)/2)+1;
           ind2 = floor((encoding_x - recon_x)/2)+recon_x;
           im = ksp(ind1:ind2,:,:);
           %}

           im = fftshift(ifft(fftshift(im,2),[],2),2);
           im = sqrt(sum(abs(im).^2,3));

           im = im.*(32768./max(im(:)));
           im = round(im);
           im = int16(im);
           
           image = ismrmrd.Image(im);

           
           % find the center Idx fto set the output meta attributes.
           kspace_encode_step_1 = cellfun(@(x) x.head.idx.kspace_encode_step_1, acqGroup);
           centerLin            = cellfun(@(x) x.head.idx.user(6),              acqGroup);
           centerIdx = find(kspace_encode_step_1 == centerLin, 1);
           
           % field_of_view is mandatory
           image.head.field_of_view  = single([metadata.encoding(1).reconSpace.fieldOfView_mm.x ...
                                                metadata.encoding(1).reconSpace.fieldOfView_mm.y ...
                                                metadata.encoding(1).reconSpace.fieldOfView_mm.z]);

            % Set ISMRMRD Meta Attributes
            meta = struct;
            meta.DataRole               = 'Image';
            meta.ImageProcessingHistory = 'MATLAB';
            meta.WindowCenter           = uint16(16384);
            meta.WindowWidth            = uint16(32768);
            meta.ImageRowDir            = acqGroup{centerIdx}.head.read_dir;
            meta.ImageColumnDir         = acqGroup{centerIdx}.head.phase_dir;
            
            % set_attribute_string also updates attribute_string_len
            image = image.set_attribute_string(ismrmrd.Meta.serialize(meta));

           conn.send_image(image);
           conn.send_close();
        end
    end
end
