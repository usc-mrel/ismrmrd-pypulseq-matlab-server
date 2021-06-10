function outStructs = SplitGroupedHeader(inStruct, outTemplate)
    % Split a grouped HDF5 header into a cell array of individual headers

    fields = fieldnames(inStruct);

    % Determine number of measurements.  This is somwhat complicated by the fact
    % that the dimension in which the repeats are store can be inconsistent, if
    % the header parameter has >1 value, e.g.:
    %                    version: [4912×1 uint16]
    %      physiology_time_stamp: [3×4912 uint32]
    sz = size(inStruct.(fields{1}));
    if (~ismatrix(sz))
        error('Could not determine number of measurements from field ''%s'' with size [%s]', fields{1}, num2str(sz, ' %d'))
    end

    if (sz(2) == 1)
        nMeas = sz(1);
    else
        nMeas = sz(2);
    end

    outStructs = repmat({outTemplate}, [1 nMeas]);

    for iField = 1:numel(fields)
        if ~isstruct(inStruct.(fields{iField}))
            for iMeas = 1:nMeas
                sz = size(inStruct.(fields{iField}));
                if (~ismatrix(sz))
                    error('Field ''%s'' has unsupported size [%s]', fields{1}, num2str(sz, ' %d'))
                end

                if (sz(2) == 1)
                    outStructs{iMeas}.(fields{iField}) = inStruct.(fields{iField})(iMeas);
                else
                    outStructs{iMeas}.(fields{iField}) = inStruct.(fields{iField})(:,iMeas)';
                end
            end
        else
            % Not a great generalizable way of doing this :/
            if isfield(inStruct.(fields{iField}), 'kspace_encode_step_1')
                outStructsSub = SplitGroupedHeader(inStruct.(fields{iField}), ismrmrd.EncodingCounters);
                for iMeas = 1:nMeas
                    outStructs{iMeas}.(fields{iField}) = outStructsSub{iMeas};
            end
        end
    end
end
