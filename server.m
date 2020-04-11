classdef server < handle
    
    % Created by Alexander Fyrdahl <alexander.fyrdahl@gmail.com>
    
    properties
        port = [];
        tcpHandle = [];
        log = [];
    end

    methods
        function obj = server(port,log)
            log.info('Initializing server on port %d', port);
            obj.port = port;
            obj.log = log;
        end

        function serve(obj)
            obj.log.info('Serving...');
            while true
                try
                    obj.tcpHandle = tcpip('0.0.0.0', obj.port, 'NetworkRole', 'server', 'InputBufferSize', 2^20, 'OutputBufferSize', 2^20);  %#ok<TNMLP>  Consider moving toolbox function TCPIP out of the loop for better performance
                    obj.log.info('Waiting for client to connect to this host on port : %d', obj.port);
                    fopen(obj.tcpHandle);
                    obj.log.info('Accepting connection from: %s:%d', obj.tcpHandle.RemoteHost, obj.tcpHandle.RemotePort);
                    handle(obj);
                    flushoutput(obj.tcpHandle);
                    fclose(obj.tcpHandle);
                    obj.tcpHandle = [];
                catch
                    if ~isempty(obj.tcpHandle)
                        fclose(obj.tcpHandle);
                        obj.tcpHandle = [];
                    end
                end
            end
        end

        function handle(obj)
            try
                conn = connection(obj.tcpHandle, obj.log);
                config = next(conn);
                image = simplefft.process(conn,config,parameters,obj.log);
                metadata = next(conn);

                try
                    metadata = ismrmrd.xml.deserialize(metadata);
                    if ~isempty(metadata.acquisitionSystemInformation.systemFieldStrength_T)
                        obj.log.info("Data is from a %s %s at %1.1fT", metadata.acquisitionSystemInformation.systemVendor, metadata.acquisitionSystemInformation.systemModel, metadata.acquisitionSystemInformation.systemFieldStrength_T)
                    end
                catch
                    obj.log.info("Metadata is not a valid MRD XML structure.  Passing on metadata as text")
                end
            catch ME
                    obj.log.error('[%s:%d] %s', ME.stack(2).name, ME.stack(2).line, ME.message);
                    rethrow(ME);
                end
            end

        function delete(obj)
            if ~isempty(obj.tcpHandle)
                fclose(obj.tcpHandle);
                obj.tcpHandle = [];
            end
        end
        
    end
    
end
