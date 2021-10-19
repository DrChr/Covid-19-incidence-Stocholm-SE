%% Return data for a region in a struct.
%
% Notes: Illustrate use of persistent variable. E.g. useful for data
% that's time consuming to create, e.g. loaded from disk.
%
% Note: Think twice before using this approach unless e.g.:
% - Data is constant
% - "Global" access is ok
% - No need to mock/substitute the data during testing.
% - Consider if/how/when data on disk might change
%
% Caveat: Must e.g. 'clear' this function to reinitialise the cached data.
% Caveat: If data is re
function region = region_data(key)
    region = select_region(key);
end

function data = select_region(key)
    persistent Cache
    if isempty(Cache)
        Cache = init_region_data();
    end
    data = Cache.(key);
end

% Consider using 'containers.Map()' instead when not returning a
% struct for each key.
function S = init_region_data()
    D = { ... % key     name         label_1     label_2      Pop.     pop.18
          'sweden'     "Sweden"     "totalt"    "| Sverige |" 10.35e6  2.37e6 ; ...
          'stockholm'  "Stockholm"  "Stockholm" "Stockholm"    2.38e6  0.55e6 ; ...
        };

    for C = D'                          % Note the transpose operator!
        [key, name, label_1, label_2, pop, pop_18] = deal(C{:});
        S.(key) = struct('name',    name, ...
                         'label_1', label_1, ...
                         'label_2', label_2, ...
                         'population', pop, ...
                         'pop_18',  pop_18);
    end
end
