% Plot Covid-19 incidence and vaccination status for Stockholm and Sweden
%
% Example:
%     generate_plots();
%
%     % Or provide the tables with data explicitly
%     [T, V] = download_and_import_data();
%     generate_plots(T, V);
function [incidence, vaccinations] = generate_plots(incidence, vaccinations)
    if nargin == 0
        [incidence, vaccinations] = download_and_import_data();
    end
    
    time_range = [datetime('2021-06-28') ...
                  next_monday(max(datetime('today'), datetime('2021-12-31')))];

    % Place some common arguments to the plot functions in a cell array
    plot_data = { time_range  incidence  vaccinations };

    figure(1);
    [t1, y1] = plot_Covid_for_region('sweden', plot_data{:});

    figure(2);
    [t2, y2] = plot_Covid_for_region('stockholm', plot_data{:});

    figure(3);
    plot_mean_incidence(time_range, {'sweden' t1 y1}, {'stockholm' t2 y2});
end

function [t, ym] = plot_Covid_for_region(region_key, t_range, T1, V1)
    %subplot(211);
    [t, ym] = plot_incidence_of_Covid_19(T1, region_key, t_range);
    %subplot(212);
    %plot_vaccination_against_Covid_19(V1, region_key, t_range);
end

function [t, ym] = plot_incidence_of_Covid_19(T1, region_key, t_range)
    region = region_data(region_key);
    dt_range = datetime(["2021-06-28" "2021-09-20"]);
    L1 = { ...
      datetime({'2021-06-28' '2021-09-06'})' [25 800]'-5 'k--', ...
      dt_range' 770*[1 1]' 'r--', ...    
    };
    t = T1.t;

    y = T1.(region.label_1);
    w = weekday(t);
    idx_mon = w == 2;
    idx_tue = w == 3;
    idx_wday = w == 4 | w == 5 |w == 6;
    idx_wend = w == 1 | w == 7;
    y1 = y; y1(idx_wend) = deal(nan); y1(idx_mon) = deal(nan);
    ym = movmean(y1, 7, 'omitnan');
    plot_fmt = { 'markersize',12, 'linewidth', 1.5 };
    semilogy(...
        L1{:}, ...
        T1.t(idx_mon), y(idx_mon), '.', ...
        T1.t(idx_tue), y(idx_tue), '.', ...
        T1.t(idx_wday), y(idx_wday), '.', ...
        T1.t, ym, ...
        repmat(datetime("2021-11-01"), 1, 2), [10 1000], '--', ...
        plot_fmt{:});

    if strcmp(region_key, 'stockholm')
        L2 = { datetime({'2021-11-15' '2021-12-19'})' [95 880]'-5 'k--' };
        hold on
        semilogy(L2{:}, plot_fmt{:});
        hold off
    end

    legend(...
        'slope guessed', ...
        'peak value', ...
        'Mondays', ...
        'Tuesdays', ...
        'Wed-Fri', ...
        '7-d mean, Tu-Fr', ...
        'location', 'northwest');

    set_limits_etc_for_incidence_plots(t_range, region.name);
end

function [ym, idx] = extract_incidence(T, region_key)
    region = region_data(region_key);
    t = T.t;

    y = T.(region.label_1);
    w = weekday(t);
    idx = struct('mon',  w == 2, ...
                 'tue',  w == 3, ...
                 'wday', w == 4 | w == 5 | w == 6, ...
                 'wend', w == 1 | w == 7);   
             
    y1 = NaN(size(y));
    y1([idx.tue | idx.wday]) = y([idx.tue | idx.wday]);
    ym = movmean(y1, 7, 'omitnan');
end


function plot_vaccination_against_Covid_19(V1, region_key, t_range)
    region = region_data(region_key);
    V1.region == region.label_2;
    [idx1, idx2] = deal(ans & V1.status == 'Minst 1 dos', ...
                        ans & V1.status == 'Färdigvaccinerade');
    V1_1 = V1(idx1,:); V1_2 = V1(idx2,:);
    pop_fraction_above_17 = (region.population-region.pop_18)/region.population;
    d1 = { [0 52], 100 * pop_fraction_above_17 * [1 1], '--k' };
    plot(V1_1.v, 100*V1_1.n/region.population, '.-', ...
         V1_2.v, 100*V1_2.n/region.population, '.-', ...
         d1{:}, ...
         'markersize', 12);

    ylim([0 100]);

    week_ISO = @(d) week(d)-1;
    xlim(week_ISO(t_range));

    title(sprintf('Vaccinations for %s', region.name));
    legend('Minst 1 dos', 'Färdigvaccinerade', 'Population over 18', ...
           'location', 'northwest')
    xlabel('Week');
    ylabel('Fraction of population [%]');
    grid on
end


function plot_mean_incidence(t_range, varargin)
    [plot_args, legend_args] = deal({});
    for C = varargin
        [label, t, y] = deal(C{1}{:});
        plot_args = [plot_args {t} {y}];
        legend_args = [legend_args {label}];
    end
    semilogy(plot_args{:});
    legend(legend_args);
    set_limits_etc_for_incidence_plots(t_range, '...');
end

function set_limits_etc_for_incidence_plots(t_range, region_name)
    title(sprintf('Covid-19 incidence, %s, (generated %s UTC)', region_name, datestr(now(), 31)));
    set_figure_size(gcf(), 1600, 500);

    xlim(t_range);
    t_days = t_range(1):t_range(2);
    t_mondays = t_days(weekday(t_days) == 2);
    xticks(t_mondays);
    xtickformat('MM-dd');

    ylabel('Confirmed cases / million people / day');
    yticks([10 20 50 100 200 500 1000]);
    ylim(); ylim([10 max(1000, ans(2))]);

    grid on;
end

function set_figure_size(fig, width, height)
  p = get(fig, 'position');
  set(fig, 'position', [p(1:2) [width height]]);
end

%% Get date of _next_ monday w.r.t to 't' (a datetime object)
function y = next_monday(t)
    days = t + (1:7);
    idx_mon = find(weekday(days) == 2, 1, 'first');
    assert(numel(idx_mon) == 1);
    y = days(idx_mon);
end
