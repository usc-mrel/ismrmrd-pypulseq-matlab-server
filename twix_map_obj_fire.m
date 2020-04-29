classdef twix_map_obj_fire < handle %matlab.mixin.Copyable %handle
    properties

%                 flagRemoveOS: 0
%                flagDoAverage: 0
%              flagAverageReps: 0
%              flagAverageSets: 0
%                flagIgnoreSeg: 0
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
                        obj.NSeg, ...
                        obj.NIda, ...
                        obj.NIdb, ...
                        obj.NIdc, ...
                        obj.NIdd, ...
                        obj.NIde, 'like', complex(single(0)));
            
            for iRO = 1:numel(obj.mrdAcq.data)
                raw(:,                                               ... %  1: Col
                    :,                                               ... %  2: Cha
                    obj.mrdAcq.head.idx.kspace_encode_step_1(iRO)+1, ... %  3: Lin
                    obj.mrdAcq.head.idx.kspace_encode_step_2(iRO)+1, ... %  4: Par
                    obj.mrdAcq.head.idx.slice(iRO)+1,                ... %  5: Sli
                    obj.mrdAcq.head.idx.average(iRO)+1,              ... %  6: Ave
                    obj.mrdAcq.head.idx.phase(iRO)+1,                ... %  7: Phs
                    obj.mrdAcq.head.idx.contrast(iRO)+1,             ... %  8: Eco
                    obj.mrdAcq.head.idx.repetition(iRO)+1,           ... %  9: Rep
                    obj.mrdAcq.head.idx.set(iRO)+1,                  ... % 10: Set
                    obj.mrdAcq.head.idx.segment(iRO)+1,              ... % 11: Seg
                    obj.mrdAcq.head.idx.user(1,iRO)+1,               ... % 12: Ida
                    obj.mrdAcq.head.idx.user(2,iRO)+1,               ... % 13: Idb
                    obj.mrdAcq.head.idx.user(3,iRO)+1,               ... % 14: Idc
                    obj.mrdAcq.head.idx.user(4,iRO)+1,               ... % 15: Idd
                    obj.mrdAcq.head.idx.user(5,iRO)+1)               ... % 16: Ide
                        = obj.mrdAcq.data{iRO};
            end
        end

        function ksp = unsorted(obj)
            ksp = cat(3, obj.mrdAcq.data{:});
        end

        function obj = setMrdAcq(obj, mrdAcq)
            obj.mrdAcq = mrdAcq;

            % Maximum size of each dimension
            obj.NCol = size( obj.mrdAcq.data{1},1);  % Assuming that all readouts have the same size
            obj.NCha = size( obj.mrdAcq.data{1},2);  % Assuming that all readouts have the same number of coils
            obj.NLin = max(  obj.mrdAcq.head.idx.kspace_encode_step_1) + 1;
            obj.NPar = max(  obj.mrdAcq.head.idx.kspace_encode_step_2) + 1;
            obj.NSli = max(  obj.mrdAcq.head.idx.slice)                + 1;
            obj.NAve = max(  obj.mrdAcq.head.idx.average)              + 1;
            obj.NPhs = max(  obj.mrdAcq.head.idx.phase)                + 1;
            obj.NEco = max(  obj.mrdAcq.head.idx.contrast)             + 1;
            obj.NRep = max(  obj.mrdAcq.head.idx.repetition)           + 1;
            obj.NSet = max(  obj.mrdAcq.head.idx.set)                  + 1;
            obj.NSeg = max(  obj.mrdAcq.head.idx.segment)              + 1;
            obj.NIda = max(  obj.mrdAcq.head.idx.user(1,:))            + 1;
            obj.NIdb = max(  obj.mrdAcq.head.idx.user(2,:))            + 1;
            obj.NIdc = max(  obj.mrdAcq.head.idx.user(3,:))            + 1;
            obj.NIdd = max(  obj.mrdAcq.head.idx.user(4,:))            + 1;
            obj.NIde = max(  obj.mrdAcq.head.idx.user(5,:))            + 1;
            obj.NAcq = numel(obj.mrdAcq.data);			

            obj.dataSize = [obj.NCol obj.NCha obj.NLin obj.NPar obj.NSli obj.NAve obj.NPhs obj.NEco obj.NRep obj.NSet obj.NSeg obj.NIda obj.NIdb obj.NIdc obj.NIdd obj.NIde];
            obj.sqzSize  = obj.dataSize(obj.dataSize ~= 1);
            obj.sqzDims  = obj.dataDims(obj.dataSize ~= 1);

            % Loop indices for each (unsorted) line
            obj.Lin = mrdAcq.head.idx.kspace_encode_step_1 + 1;
            obj.Par = mrdAcq.head.idx.kspace_encode_step_2 + 1;
            obj.Sli = mrdAcq.head.idx.slice                + 1;
            obj.Ave = mrdAcq.head.idx.average              + 1;
            obj.Phs = mrdAcq.head.idx.phase                + 1;
            obj.Eco = mrdAcq.head.idx.contrast             + 1;
            obj.Rep = mrdAcq.head.idx.repetition           + 1;
            obj.Set = mrdAcq.head.idx.set                  + 1;
            obj.Seg = mrdAcq.head.idx.segment              + 1;
            obj.Ida = mrdAcq.head.idx.user(1,:)            + 1;
            obj.Idb = mrdAcq.head.idx.user(2,:)            + 1;
            obj.Idc = mrdAcq.head.idx.user(3,:)            + 1;
            obj.Idd = mrdAcq.head.idx.user(4,:)            + 1;
            obj.Ide = mrdAcq.head.idx.user(5,:)            + 1;

            obj.centerCol = mrdAcq.head.center_sample;
            obj.centerLin = mrdAcq.head.idx.user(6,:);
            obj.centerPar = mrdAcq.head.idx.user(7,:);
            obj.cutOff    = cat(1, mrdAcq.head.discard_pre, mrdAcq.head.discard_post);

            obj.timeSinceRF = mrdAcq.head.user_int(8,:);

            obj.slicePos    = cat(1, mrdAcq.head.position); % TODO: last 4 rows are the the quaternion, which need to be converted from the slice directions
            
            obj.iceParam = zeros(24, size(mrdAcq.head.user_int,2));
            obj.iceParam(1:7, :) = mrdAcq.head.user_int(1:7,:); % Parameter 8 (1-indexed) is not converted :/
            obj.iceParam(9:16,:) = mrdAcq.head.user_float;

            obj.scancounter = mrdAcq.head.scan_counter;
            obj.timestamp   = mrdAcq.head.acquisition_time_stamp;
            obj.pmutime     = mrdAcq.head.physiology_time_stamp;
        end
    end
end