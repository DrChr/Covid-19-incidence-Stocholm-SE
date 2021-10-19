%% Download and import some recent Covid-19 data from Folkhälsomyndigheten
%
% Downloads tables regarding Covid-19 incidence and vaccinations as the MATLAB
% tables 'T' and 'V' respectively.
%
% The optional arguments 'url_1' and 'url_v' can be given to specify
% from where to dowload the incidence and vaccination data,
% respectively.
%
% Example:
%    [T, V] = download_and_import_data();
%
%    % For debugging the processing step
%    [~, ~, T0, V0] = download_and_import_data();  % Triggers download
%    % Pass in donwloaded data to be processed (again, e.g. for debugging)
%    [T, V] = download_and_import_data(T0, V0);
%
function [T1, V1, T0, V0] = download_and_import_data(url_i, url_v)
    if ~exist('url_i', 'var'), url_i = []; end
    if ~exist('url_v', 'var'), url_v = []; end
    
    url_i = util.use_default_if_empty(url_i, default_URL().incidence_etc);
    url_v = util.use_default_if_empty(url_v, default_URL().vaccinations);

    T0 = download_and_load_as_table(url_i, 'FHM-incidence-etc.xlsx');
    V0 = download_and_load_as_table(url_v, 'FHM-vaccinations.xlsx', 'Sheet', 2);

    T1 = process_incidence_table(T0);
    head(T1)

    V1 = process_vaccinations_table(V0);
    head(V1)
end

function T1 = process_incidence_table(T0)
    %              Needed               To be renamed to this
    var_names = { 'Statistikdatum'     't'
                  'Totalt_antal_fall'  'totalt'
                  'Stockholm'          []
                };
    T1 = T0(:, var_names(:,1));
    to_rename = ~cellfun(@isempty, var_names(:, 2));
    T1 = renamevars(T1, var_names(to_rename, 1), var_names(to_rename, 2));
    T1 = T1(T1.t > datetime('2021-01-01'),:);

    % Helper function to get and scale population of a region
    pop_M = @(region_key) region_data(region_key).population / 1e6;

    T1.totalt = T1.totalt / pop_M('sweden');
    T1.Stockholm = T1.Stockholm / pop_M('stockholm');
end

function V = process_vaccinations_table(V0)
    hack_to_get_week_number = @(Y, W) 52*(str2double(Y)-2021) + str2double(W);

    v = cellfun(hack_to_get_week_number, V0.('År'), V0.Vecka);
    n = V0.('Antal vaccinerade');
    region = categorical(V0.Region);
    status = categorical(V0.Vaccinationsstatus);

    % Names of table variables are set from the names of the input variables
    V = table(region, status, v, n);
end
    
function S = default_URL()
    S.incidence_etc = 'https://www.arcgis.com/sharing/rest/content/items/b5e7488e117749c19881cce45db13f7e/data';
    S.vaccinations = 'https://fohm.maps.arcgis.com/sharing/rest/content/items/fc749115877443d29c2a49ea9eca77e9/data';
end


% Download a workbook from 'url' and save as 'file', and then read it
% as a MATLAB table. Any additional arguments are passed on to
% 'readtable()'.
function T = download_and_load_as_table(url, file, varargin)
    if istable(url)
        T = url;
    else
        fprintf('Reading from %s to %s\n', url, file);
        websave(file, url);
        T = readtable(file, varargin{:}, 'VariableNamingRule', 'preserve');
    end
end


