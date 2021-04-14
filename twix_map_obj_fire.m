classdef twix_map_obj_fire < handle %matlab.mixin.Copyable %handle
    properties

%                 flagRemoveOS: 0
%                flagDoAverage: 0
%              flagAverageReps: 0
%              flagAverageSets: 0
        flagIgnoreSeg = true;
%          flagSkipToFirstLine: 0
%           flagRampSampRegrid: 0
%         flagDoRawDataCorrect: 0
%     RawDataCorrectionFactors: []
%                     filename: '/Users/kelvin/Downloads/tmp.dat'
%                     dataType: 'image'
%              softwareVersion: 'vd'
        dataSize = ones(1,16);
        dataDims = {'Col'  'Cha'  'Lin'  'Par'  'Sli'  'Ave'  'Phs'  'Eco'  'Rep'  'Set'  'Seg'  'Ida'  'Idb'  'Idc'  'Idd'  'Ide'};
        sqzSize  = [];
        sqzDims  = {};

        NCol
        NCha
        NLin
        NPar
        NSli
        NAve
        NPhs
        NEco
        NRep
        NSet
        NSeg
        NIda
        NIdb
        NIdc
        NIdd
        NIde
        NAcq

        Lin
        Par
        Sli
        Ave
        Phs
        Eco
        Rep
        Set
        Seg
        Ida
        Idb
        Idc
        Idd
        Ide
        centerCol
        centerLin
        centerPar
        cutOff
%                   coilSelect: [1�12180 double]
%                  ROoffcenter: [1�12180 double]
        timeSinceRF
%                  IsReflected: [1�12180 logical]
%             IsRawDataCorrect: [1�12180 logical]
        slicePos
%                    freeParam: [4�12180 double]
        iceParam
        scancounter
        timestamp
        pmutime
%                  rampSampTrj: []
%                       memPos: [1�12180 double]
%                    evalInfo1: [1�12180 double]
%                    evalInfo2: [1�12180 double]
%                   ixToTarget: [1�12180 double]
%                      ixToRaw: [1�24150 double]
%                 isBrokenFile: 0

        mrdAcq
    end

    methods
        function raw = imageData(obj)
            if obj.flagIgnoreSeg
                NSegUsed = 1;
            else
                NSegUsed = obj.NSeg;
            end

            raw = zeros(obj.NCol, ...
                        obj.NCha, ...
                        obj.NLin, ...
                        obj.NPar, ...
                        obj.NSli, ...
                        obj.NAve, ...
                        obj.NPhs, ...
                        obj.NEco, ...
                        obj.NRep, ...
                        obj.NSet, ...
                            NSegUsed, ...
                        obj.NIda, ...
                        obj.NIdb, ...
                        obj.NIdc, ...
                        obj.NIdd, ...
                        obj.NIde, 'like', complex(single(0)));
            
            for iRO = 1:numel(obj.mrdAcq)
                if obj.flagIgnoreSeg
                    SegUsed = 1;
                else
                    SegUsed = obj.Seg(iRO);
                end
    
                raw(:,            ... %  1: Col
                    :,            ... %  2: Cha
                    obj.Lin(iRO), ... %  3: Lin
                    obj.Par(iRO), ... %  4: Par
                    obj.Sli(iRO), ... %  5: Sli
                    obj.Ave(iRO), ... %  6: Ave
                    obj.Phs(iRO), ... %  7: Phs
                    obj.Eco(iRO), ... %  8: Eco
                    obj.Rep(iRO), ... %  9: Rep
                    obj.Set(iRO), ... % 10: Set
                        SegUsed,  ... % 11: Seg
                    obj.Ida(iRO), ... % 12: Ida
                    obj.Idb(iRO), ... % 13: Idb
                    obj.Idc(iRO), ... % 14: Idc
                    obj.Idd(iRO), ... % 15: Idd
                    obj.Ide(iRO)) ... % 16: Ide
                        = obj.mrdAcq{iRO}.data;
            end
				end

        % Return all k-space data without sorting [RO Cha Lin]
        function ksp = unsorted(obj)
            ksp = cell2mat(permute(cellfun(@(x) x.data, obj.mrdAcq, 'UniformOutput', false), [1 3 2]));
        end

        function obj = setMrdAcq(obj, mrdAcq)
            obj.mrdAcq = mrdAcq;

						% Determine whic
%     .image:         image scan
%     .noise:         for noise scan
%     .phasecor:      phase correction scan
%     .phasestab:     phase stabilization scan
%     .phasestabRef0: phase stab. ref. (MDH_REFPHASESTABSCAN && !MDH_PHASESTABSCAN)
%     .phasestabRef1: phase stab. ref. (MDH_REFPHASESTABSCAN &&  MDH_PHASESTABSCAN)
%     .refscan:       parallel imaging reference scan

            % Loop indices for each (unsorted) line
            obj.Lin              =          cellfun(@(x) x.head.idx.kspace_encode_step_1, mrdAcq) + 1;
            obj.Par              =          cellfun(@(x) x.head.idx.kspace_encode_step_1, mrdAcq) + 1;
            obj.Sli              =          cellfun(@(x) x.head.idx.slice,                mrdAcq) + 1;
            obj.Ave              =          cellfun(@(x) x.head.idx.average,              mrdAcq) + 1;
            obj.Phs              =          cellfun(@(x) x.head.idx.phase,                mrdAcq) + 1;
            obj.Eco              =          cellfun(@(x) x.head.idx.contrast,             mrdAcq) + 1;
            obj.Rep              =          cellfun(@(x) x.head.idx.repetition,           mrdAcq) + 1;
            obj.Set              =          cellfun(@(x) x.head.idx.set,                  mrdAcq) + 1;
            obj.Seg              =          cellfun(@(x) x.head.idx.segment,              mrdAcq) + 1;
            obj.Ida              =          cellfun(@(x) x.head.idx.user(1),              mrdAcq) + 1;
            obj.Idb              =          cellfun(@(x) x.head.idx.user(2),              mrdAcq) + 1;
            obj.Idc              =          cellfun(@(x) x.head.idx.user(3),              mrdAcq) + 1;
            obj.Idd              =          cellfun(@(x) x.head.idx.user(4),              mrdAcq) + 1;
            obj.Ide              =          cellfun(@(x) x.head.idx.user(5),              mrdAcq) + 1;

            obj.scancounter      =          cellfun(@(x) x.head.scan_counter,             mrdAcq);
            obj.timestamp        =          cellfun(@(x) x.head.acquisition_time_stamp,   mrdAcq);
            obj.pmutime          = cell2mat(cellfun(@(x) x.head.physiology_time_stamp',   mrdAcq, 'UniformOutput', false));
            obj.centerCol        =          cellfun(@(x) x.head.center_sample,            mrdAcq);
            obj.centerLin        =          cellfun(@(x) x.head.idx.user(6),              mrdAcq);
            obj.centerPar        =          cellfun(@(x) x.head.idx.user(7),              mrdAcq);
            obj.timeSinceRF      =          cellfun(@(x) x.head.user_int(8),              mrdAcq);
            obj.cutOff           = cell2mat(cellfun(@(x) [x.head.discard_pre; x.head.discard_post], mrdAcq, 'UniformOutput', false));

            % TODO: last 4 rows are the the quaternion, which need to be converted from the slice directions
            obj.slicePos         = cell2mat(cellfun(@(x) x.head.position, mrdAcq, 'UniformOutput', false)');

            obj.iceParam         = zeros(24, numel(mrdAcq));
            obj.iceParam(1:7, :) = cell2mat(cellfun(@(x) x.head.user_int(1:7),   mrdAcq, 'UniformOutput', false)')'; % Parameter 8 (1-indexed) is not converted :/
            obj.iceParam(9:16,:) = cell2mat(cellfun(@(x) x.head.user_float,      mrdAcq, 'UniformOutput', false)')';

            % Maximum size of each dimension
            obj.NCol = size( obj.mrdAcq{1}.data,1);  % Assuming that all readouts have the same size
            obj.NCha = size( obj.mrdAcq{1}.data,2);  % Assuming that all readouts have the same number of coils
            obj.NLin = max(  obj.Lin);
            obj.NPar = max(  obj.Par);
            obj.NSli = max(  obj.Sli);
            obj.NAve = max(  obj.Ave);
            obj.NPhs = max(  obj.Phs);
            obj.NEco = max(  obj.Eco);
            obj.NRep = max(  obj.Rep);
            obj.NSet = max(  obj.Set);
            obj.NSeg = max(  obj.Seg);
            obj.NIda = max(  obj.Ida);
            obj.NIdb = max(  obj.Idb);
            obj.NIdc = max(  obj.Idc);
            obj.NIdd = max(  obj.Idd);
            obj.NIde = max(  obj.Ide);
            obj.NAcq = numel(obj.mrdAcq);

            obj.dataSize = [obj.NCol obj.NCha obj.NLin obj.NPar obj.NSli obj.NAve obj.NPhs obj.NEco obj.NRep obj.NSet obj.NSeg obj.NIda obj.NIdb obj.NIdc obj.NIdd obj.NIde];
            obj.sqzSize  = obj.dataSize(obj.dataSize ~= 1);
            obj.sqzDims  = obj.dataDims(obj.dataSize ~= 1);
        end
    end
end