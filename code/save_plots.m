function save_plots()
  save_as = @(fig, name) saveas(fig, fullfile('public', name));
  save_as(1, 'Covid-19_incidence_Sweden_SE.png');
  save_as(2, 'Covid-19_incidence_Stockholm_SE.png');
  save_as(3, 'Covid-19_incidence_mean_SE.png');
end
