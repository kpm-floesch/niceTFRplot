# niceTFRplot
An alternative visualization for the results of FieldTrip cluster-based permutation analysis on time-frequency data. The code avoids opacity alpha masking by using custom color scales. Information about the cluster contribution of each individual sensor is outsourced to a 2D sensor net layout with 4 graded point sizes obtained by median splits.

Please cite as: Flösch, K.-P. (2025). niceTFRplot (https://github.com/kpm-floesch/niceTFRplot), GitHub.

## Requires
- FieldTrip toolbox, freely available under https://www.fieldtriptoolbox.org/download/
- cbrewer2, freely available under https://de.mathworks.com/matlabcentral/fileexchange/58350-cbrewer2
- sensor net layout of your EEG net (e.g., .sfp-file); must be compatible with FieldTrip
- output struct of cluster statistic from ft_freqstatistics in a .mat file


## References
- Lowe, S. (2025). cbrewer2 (https://github.com/scottclowe/cbrewer2), GitHub.
- Oostenveld, R., Fries, P., Maris, E., Schoffelen, J.-M. (2011). FieldTrip: Open source software for advanced analysis of MEG, EEG, and invasive electrophysiological data. Computational Intelligence and Neuroscience, 2011, 156869, doi:10.1155/2011/156869.
