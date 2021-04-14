classdef server < handle

    properties
        port      = [];
        tcpHandle = [];
        log       = [];
    end

    methods
        function obj = server(port,log)
            log.info('Initializing server on port %d', port);
            obj.port = port;
            obj.log = log;
        end

        function serve(obj)
            while true
                try
                    obj.tcpHandle = tcpip('0.0.0.0',          obj.port, ...
                                          'NetworkRole',      'server', ...
                                          'InputBufferSize',  32 * 2^20 , ...
                                          'OutputBufferSize', 32 * 2^20, ...
                                          'Timeout',          3000);  %#ok<TNMLP>  Consider moving toolbox function TCPIP out of the loop for better performance
                    obj.log.info('Waiting for client to connect to this host on port : %d', obj.port);
                    fopen(obj.tcpHandle);
                    obj.log.info('Accepting connection from: %s:%d', obj.tcpHandle.RemoteHost, obj.tcpHandle.RemotePort);
                    handle(obj);
                    flushoutput(obj.tcpHandle);
                    fclose(obj.tcpHandle);
                    delete(obj.tcpHandle);
                    obj.tcpHandle = [];
                catch ME
                    if ~isempty(obj.tcpHandle)
                        fclose(obj.tcpHandle);
                        delete(obj.tcpHandle);
                        obj.tcpHandle = [];
                    end

                    obj.log.error(sprintf('%s\nError in %s (%s) (line %d)', ME.message, ME.stack(1).('name'), ME.stack(1).('file'), ME.stack(1).('line')));
                end
                pause(1)
            end
        end

        function handle(obj)
            try
                conn = connection(obj.tcpHandle, obj.log);
                config = next(conn);
                metadata = next(conn);

                try
                    metadata = ismrmrd.xml.deserialize(metadata);
                    if ~isempty(metadata.acquisitionSystemInformation.systemFieldStrength_T)
                        obj.log.info("Data is from a %s %s at %1.1fT", metadata.acquisitionSystemInformation.systemVendor, metadata.acquisitionSystemInformation.systemModel, metadata.acquisitionSystemInformation.systemFieldStrength_T)
                    end
                catch
                    obj.log.info("Metadata is not a valid MRD XML structure.  Passing on metadata as text")
                end

                % Decide what program to use based on config
                % As a shortcut, we accept the file name as text too.
                if strcmpi(config, "simplefft")
                    obj.log.info("Starting simplefft processing based on config")
                    recon = simplefft;
                elseif strcmpi(config, "invertcontrast")
                    obj.log.info("Starting invertcontrast processing based on config")
                    recon = invertcontrast;
                elseif strcmpi(config, "mapvbvd")
                    obj.log.info("Starting mapvbvd processing based on config")
                    recon = fire_mapVBVD;
                else
                    if exist(config, 'class')
                        obj.log.info("Starting %s processing based on config", config)
                        eval(['recon = ' config ';'])
                    else
                        obj.log.info("Unknown config '%s'.  Falling back to 'invertcontrast'", config)
                        recon = invertcontrast;
                    end
                end
                recon.process(conn, config, metadata, obj.log);

            catch ME
                obj.log.error('[%s:%d] %s', ME.stack(2).name, ME.stack(2).line, ME.message);
                rethrow(ME);
            end
        end

        function delete(obj)
            if ~isempty(obj.tcpHandle)
                fclose(obj.tcpHandle);
                delete(obj.tcpHandle);
                obj.tcpHandle = [];
            end
        end

    end

end
