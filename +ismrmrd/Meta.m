classdef Meta
    methods (Static)
        function xml = serialize(s)
            % Take a struct and turn it in to an XML-formatted MetaAttribute
            % Each struct field comprises a "meta" attribute with a "name" equal to 
            % its field name and a value equal to its field value.  Numeric or cell
            % arrays are supported.
            docNode = javaObject('org.apache.xerces.dom.DocumentImpl');
            docNode.appendChild (docNode.createElement('ismrmrdMeta'));
            docRootNode = docNode.getDocumentElement;

            fields = fieldnames(s);

            for iField = 1:numel(fields)
                if ~isempty(fields{iField})
                    % Flag to discard this MetaAttribute if it contains invalid values
                    isGood = true;

                    val = s.(fields{iField});

                    if isempty(val)
                        continue
                    end

                    metaNode = docNode.createElement('meta');
                    nameNode = docNode.createElement('name');
                    nameNode.appendChild(docNode.createTextNode(fields{iField}));
                    metaNode.appendChild(nameNode);

                    % Turn scalars and numerical arrays into cell arrays
                    if ~iscell(val)
                        if ~isscalar(val) && ~ischar(val)
                            val = num2cell(val);
                        else
                            val = {val};
                        end
                    end

                    for iVal = 1:numel(val)
                        valueNode = docNode.createElement('value');
                        % chars are stored directly
                        if ischar(val{iVal})
                            valueNode.appendChild(docNode.createTextNode(val{iVal}));

                        % logicals are stored as 'true' or 'false'
                        elseif islogical(val{iVal})
                            if val{iVal}
                                valueNode.appendChild(docNode.createTextNode('true'));
                            else
                                valueNode.appendChild(docNode.createTextNode('false'));
                            end

                        % integers are stored without decimals
                        elseif isinteger(val{iVal})
                            valueNode.appendChild(docNode.createTextNode(int2str(val{iVal})));

                        % all other numerics (double/singles) are stored with 16 decimals
                        elseif isnumeric(val{iVal})
                            valueNode.appendChild(docNode.createTextNode(num2str(val{iVal}, ' %.16f')));

                        else
                            warning('Unsupported class of type %s for Meta field %s', class(val{iVal}), fields{iField})
                            isGood = false;
                            continue
                        end
                        metaNode.appendChild(valueNode);
                    end
                    if isGood
                        docRootNode.appendChild(metaNode);
                    end
                end
            end
            xml = char(xmlwrite(docNode));
        end
    end % methods (Static)
end
