%% Code to plot results from FieldTrip TFR cluster-based permutation analysis
%
% An alternative visualization for the results of FieldTrip cluster-based
% permutation analysis on time-frequency data. The code avoids opacity alpha 
% masking by using custom color scales. Information about the cluster
% contribution of each individual sensor is outsourced to a 2D sensor net
% layout with 4 graded point sizes obtained by median splits. You can
% specify different plotting parameters below.
%
% Requires:
% - FieldTrip toolbox, freely available under https://www.fieldtriptoolbox.org/download/
% - cbrewer2, freely available under https://de.mathworks.com/matlabcentral/fileexchange/58350-cbrewer2
% - sensor net layout of your EEG net (e.g. .sfp-file); must be compatible with FieldTrip
% - output struct of cluster statistic from ft_freqstatistics in a .mat file
%
% Please ensure that your cluster statistics structure is named 'stat'. 
% If it has a different name, update it accordingly in the "load data" 
% section below.
%
% References
% Lowe, S. (2025). cbrewer2 (https://github.com/scottclowe/cbrewer2), GitHub.
% Oostenveld, R., Fries, P., Maris, E., Schoffelen, J.-M. (2011). FieldTrip: Open source software for advanced analysis of MEG, EEG, and invasive electrophysiological data. Computational Intelligence and Neuroscience, 2011, 156869, doi:10.1155/2011/156869.
%
% Karl-Philipp Floesch (2025), University of Konstanz
% David Schubring (2021), University of Konstanz
% 05/2025
% karl-philipp.floesch@uni-konstanz.de

%% set defaults
restoredefaultpath

opts.ftPath       = 'PATH TO FIELDTRIP TOOLBOX';
opts.cbrewer2Path = 'PATH TO cbrewer2 FOLDER';
opts.netLayout    = 'PATH TO NET LAYOUT';
opts.dataPath     = 'PATH TO CLUSTER DATA (.mat)';

addpath(opts.cbrewer2Path)
addpath(opts.ftPath)
ft_defaults

%% load data

inLoad = load(opts.dataPath);
clusterStat = inLoad.stat; % name of cluster statistics struct

clear inLoad

%% PLEASE SET PLOTTING PARAMETERS

plotcfg.negPosClust     = 'neg'; % plot negative or positive cluster; or 'pos'
plotcfg.Tstat           = 'mean'; % plot mean cluster t-value; or 'sum'
plotcfg.Tscale          = 3; % min/max absolute t-value on color scale; depends on chosen Tstat, e.g. 3 for 'mean' and 1000 for 'sum'
plotcfg.ClusterNo       = 1; % which cluster to plot; you can also choose multiple, e.g. [1 2]
plotcfg.yscale          = 'lin'; % linear ('lin') or log ('log') scale of y axis
plotcfg.highlightSize   = 28; % point size for highlighting significant cluster sensors

% It is strongly recommended to always plot and interpret the whole
% cluster, but you can also specify time and frequency ranges for
% plotting.
plotcfg.time            = []; % in seconds, e.g. [.5 1]
plotcfg.freq            = []; % in Hz, e.g. [8 20]

%% PLOT

figure('units','normalized','outerposition',[0 0 1 1])
tiledlayout(3,4,"TileSpacing","compact")

% t-statistic freq x time, aggregated over sensors
nexttile([3 3])

clusterPlot = clusterStat;

% select time and frequency range
if ~isempty(plotcfg.time)
    cfg             = [];
    cfg.latency     = plotcfg.time;

    clusterPlot = ft_selectdata(cfg,clusterPlot);
end

if ~isempty(plotcfg.freq)
    cfg             = [];
    cfg.frequency   = plotcfg.freq;

    clusterPlot = ft_selectdata(cfg,clusterPlot);
end

dataMat = clusterPlot.stat;

% select significant data points from cluster
if strcmp(plotcfg.negPosClust,'neg') % negative cluster

    clusterPlot.negclusterslabelmat(~ismember(clusterPlot.negclusterslabelmat,plotcfg.ClusterNo)) = 0;
    clusterPlot.negclusterslabelmat(ismember(clusterPlot.negclusterslabelmat,plotcfg.ClusterNo)) = 1;
    [ClustChans,~,~] = find(clusterPlot.negclusterslabelmat == 1);
    dataMat(clusterPlot.negclusterslabelmat == 0) = NaN;
    
    % get sensor contributions
    statChan = find(any(clusterPlot.negclusterslabelmat,2:3));
    statChanCount = sum(clusterPlot.negclusterslabelmat(statChan,:),2);

elseif strcmp(plotcfg.negPosClust,'pos')  % positive cluster

    clusterPlot.posclusterslabelmat(~ismember(clusterPlot.posclusterslabelmat,plotcfg.ClusterNo)) = 0;
    clusterPlot.posclusterslabelmat(ismember(clusterPlot.posclusterslabelmat,plotcfg.ClusterNo)) = 1;
    [ClustChans,~,~] = find(clusterPlot.posclusterslabelmat == 1);
    dataMat(clusterPlot.posclusterslabelmat == 0) = NaN;

    % get sensor contributions
    statChan = find(any(clusterPlot.posclusterslabelmat,2:3));
    statChanCount = sum(clusterPlot.posclusterslabelmat(statChan,:),2);

end

if strcmp(plotcfg.Tstat, 'mean')
    % standardize cluster t-value by dividing sum of t-values by number of
    % significant sensors
    dataMat = squeeze(sum(permute(dataMat(unique(ClustChans),:,:),[1 3 2]),1,"omitnan"))./length(unique(ClustChans)); 
    barlabel = 'standardized cluster t-value';

elseif strcmp(plotcfg.Tstat, 'sum')
    % use sum of t-values
    dataMat = squeeze(sum(permute(dataMat(unique(ClustChans),:,:),[1 3 2]),1,"omitnan"));
    barlabel = 'summed cluster t-value';

end

idx = find(dataMat == 0); % find non-significant data points

% smooth data with gaussian filter
dataMat = smoothdata2(dataMat,"gaussian");

% remove non-significant points
dataMat(idx) = 0;

% make color scale
ncol = 1000;
if strcmp(plotcfg.negPosClust,'neg')
    dataMat(dataMat >= 0) = NaN;
    colmap = jet(ncol); colVec = [20 100];
    colormap(colmap(floor(colVec(1)/256*ncol):ceil(colVec(2)/256*ncol),:));

elseif strcmp(plotcfg.negPosClust,'pos')
    dataMat(dataMat <= 0) = NaN;
    colmap = cbrewer2('OrRd',ncol); colVec = [1 256];
    colormap(colmap(floor(colVec(1)/256*ncol):ceil(colVec(2)/256*ncol),:));

end

% plot
contourf(clusterPlot.time*1000,clusterPlot.freq,dataMat',40,'linecolor','none','edgecolor','none')
set(gcf,'color','w')

% color bar
hc = colorbar;

if strcmp(plotcfg.negPosClust,'neg')
    set(hc,"Limits",[-plotcfg.Tscale 0])
    clim([-plotcfg.Tscale 0])
elseif strcmp(plotcfg.negPosClust,'pos')
    set(hc,"Limits",[0 plotcfg.Tscale])
    clim([0 plotcfg.Tscale])
end

set(hc, 'FontSize', 24)
hc.Label.String = barlabel;

% axes
ax = gca;
set(ax,'xcolor',hex2rgb('#262626'),'ycolor',hex2rgb('#262626'))
ax.LineWidth = 2;
ax.FontSize = 30;
ax.FontName = 'Helvetica';
ax.FontWeight = 'bold';
ax.YLabel.Visible = 'on';
ax.XLabel.Visible = 'on';
% ax.XTickLabel(1:2:length(ax.XTickLabel)-1) = {''}; % remove labels every X steps

if strcmp(plotcfg.yscale,'log'); yscale log; end

xlh = xlabel ('Time (ms)','FontSize',30, 'FontWeight','bold','FontName','Helvetica','Color',hex2rgb('#262626'));
ylh = ylabel('Frequency (Hz)','FontSize',30, 'FontWeight','bold','FontName','Helvetica','Color',hex2rgb('#262626'));

title('Time x Frequency, aggregated over cluster sensors','FontSize',30)

% graded point size using median splits
MedianSplit = median(statChanCount);
statChanLow = statChanCount <= MedianSplit;
statChanHigh = statChanCount > MedianSplit;

MedianSplitLow = median(statChanCount(statChanLow));
statChanLow1 = statChan(statChanCount <= MedianSplitLow);
statChanLow2 = statChan(statChanCount > MedianSplitLow & statChanCount <= MedianSplit);

MedianSplitHigh = median(statChanCount(statChanHigh));
statChanHigh1 = statChan(statChanCount <= MedianSplitHigh & statChanCount > MedianSplit);
statChanHigh2 = statChan(statChanCount > MedianSplitHigh);

stepstatChanLow1 = statChanLow1(ismember(statChanLow1,statChan));
stepstatChanLow2 = statChanLow2(ismember(statChanLow2,statChan));
stepstatChanHigh1 = statChanHigh1(ismember(statChanHigh1,statChan));
stepstatChanHigh2 = statChanHigh2(ismember(statChanHigh2,statChan));

% plot sensor contribution on sensor net layout
nexttile(8)
title('Sensor contributions','FontSize',24)

cfg                    = [];
cfg.layout             = opts.netLayout;
cfg.figure             = 'gcf';
cfg.comment            = 'no';
plotLayout = ft_prepare_layout(cfg);

opts.plotchans = find(ismember(plotLayout.label,clusterPlot.label)); % exclude channels not present in cluster statistics struct
stepstatChanHigh2 = find(ismember(plotLayout.label,clusterPlot.label(stepstatChanHigh2))); % find highlighted channel labels in imported net layout
stepstatChanHigh1 = find(ismember(plotLayout.label,clusterPlot.label(stepstatChanHigh1)));
stepstatChanLow2 = find(ismember(plotLayout.label,clusterPlot.label(stepstatChanLow2)));
stepstatChanLow1 = find(ismember(plotLayout.label,clusterPlot.label(stepstatChanLow1)));

% plot stack of layouts
ft_plot_layout(plotLayout,'chanindx',opts.plotchans,'label','no','box','no','pointsymbol','o','pointcolor','k','pointsize',4)
ft_plot_layout(plotLayout,'chanindx',stepstatChanHigh2,'label','no','box','no','pointsymbol','.','pointcolor','k','pointsize',plotcfg.highlightSize)
ft_plot_layout(plotLayout,'chanindx',stepstatChanHigh1,'label','no','box','no','pointsymbol','.','pointcolor','k','pointsize',plotcfg.highlightSize/1.5)
ft_plot_layout(plotLayout,'chanindx',stepstatChanLow2,'label','no','box','no','pointsymbol','.','pointcolor','k','pointsize',plotcfg.highlightSize/2)
ft_plot_layout(plotLayout,'chanindx',stepstatChanLow1,'label','no','box','no','pointsymbol','.','pointcolor','k','pointsize',plotcfg.highlightSize/2.25)
