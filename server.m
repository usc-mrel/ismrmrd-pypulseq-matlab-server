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
						obj.tcpHandle = tcpip('0.0.0.0', obj.port, 'NetworkRole', 'server', 'InputBufferSize', 2^20, 'OutputBufferSize', 2^20);
            while true
                try
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
                    pause(1);
                end
            end
        end

        function handle(obj)
            try
                conn = connection(obj.tcpHandle);
                config = next(conn);
                parameters = next(conn);
                image = simplefft.process(conn,config,parameters,obj.log);
                obj.log.info('Image done, sending!');
                send_image(conn,image);
                write_gadget_message_close(conn);
                obj.log.info('Sending done!\n');
            catch ME
                if strcmp(ME.identifier,'Iterator:StopIteration')
                    if ~isempty(obj.tcpHandle)
                        fclose(obj.tcpHandle);
                        obj.tcpHandle = [];
                    end
                else
                    obj.log.error(ME);
                    rethrow(ME);
                end
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
