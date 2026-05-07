% =========================================================================
%                  GMM_gen.m
% =========================================================================
% AUTHOR:         Dev Mehta
% VERSION:        1.0
% LAST MODIFIED:  2026-05-06
%
% DESCRIPTION:
%   PCA-based preprocessing and denoising of electromagnetic traces using
%   Gaussian Mixture Models. Reduces trace dimensionality, identifies noise
%   components, and generates denoised GMM for PSO initialization.
%
% INPUTS:  Trace data (.csv) with 100 traces per grid location (121 total)
% OUTPUTS: Denoised Gaussian Mixture Model (.mat) for sampling
%
% DEPENDENCIES: Statistics and Machine Learning Toolbox
% =========================================================================

clearvars

% -------------------------------------------------------------------------
% Configuration
% -------------------------------------------------------------------------
inputDir = 'MATLAB_exports';% change it to input_matlab if you want to use the downaloaded data from the box
inputFile = 'data_100_121_impl_d.csv';% change it to appropriate file names
outputDir = 'output_matlab';
outputFile = 'GM_noiseless_pca_impl_d_new.mat';

numGridLocations = 121;
tracesPerLocation = 100;
sampleTracesPerLocation = 30;
numComponents = 2;
scaleFactor = 100;
maxComponentsToTest = 11;
rngSeed = 1;

inputPath = fullfile(inputDir, inputFile);
outputPath = fullfile(outputDir, outputFile);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% -------------------------------------------------------------------------
% Load and reduce traces per grid location
% -------------------------------------------------------------------------
dataMatrix = readmatrix(inputPath);
features = zeros(numGridLocations, numComponents);

for loc = 1:numGridLocations
    baseIdx = (loc - 1) * tracesPerLocation;
    sampledRows = randperm(tracesPerLocation, sampleTracesPerLocation);
    rowIdx = baseIdx + sampledRows;
    group = dataMatrix(rowIdx, :);

    [~, pcaScore] = pca(group);
    features(loc, :) = pcaScore(1, 1:numComponents);
end

score = features;

% -------------------------------------------------------------------------
% Fit GMM models in the 2D PCA space
% -------------------------------------------------------------------------
rng(rngSeed); % Reproducible fit and sampling
lowestAIC = inf;
bestGMM = [];
gmmOptions = statset('MaxIter', 1000);
gmAIC = zeros(1, maxComponentsToTest);

for k = 1:maxComponentsToTest
    gm = fitgmdist(score(:, 1:2), k, ...
        'RegularizationValue', 1e-5, ...
        'Replicates', 5, ...
        'Options', gmmOptions);
    gmAIC(k) = gm.AIC;

    if gm.AIC < lowestAIC
        lowestAIC = gm.AIC;
        bestGMM = gm;
    end
end

% Pick the elbow from the AIC curve.
curvature = diff(gmAIC, 2);
[~, elbowIdx] = min(curvature);
optimalK = elbowIdx + 1;

fitOptions = statset('Display', 'final');
GMModel_final = fitgmdist(score(:, 1:2), optimalK, ...
    'Options', fitOptions, ...
    'CovarianceType', 'full', ...
    'SharedCovariance', false, ...
    'RegularizationValue', 1e-5, ...
    'Replicates', 5);

% This GMM is the denoised model used for sampling.
gm = gmdistribution(GMModel_final.mu, GMModel_final.Sigma, GMModel_final.ComponentProportion);
gmPDF = @(x, y) arrayfun(@(x0, y0) pdf(gm, [x0 y0]), x, y);
figure(1)
fsurf(gmPDF, [-3 3])

[posteriorProbabilities, ~] = posterior(GMModel_final, score(:, 1:2));
[~, noiseCompIdx] = min(GMModel_final.mu);
isSignal = posteriorProbabilities(:, noiseCompIdx(:, 1)) < 0.5;

denoisedData = score(:, 1:2);
denoisedData(~isSignal) = NaN;
denoisedData = fillmissing(denoisedData, 'linear');
denoisedData = denoisedData * scaleFactor;

GMModel_final = fitgmdist(denoisedData, optimalK - 1, ...
    'Options', fitOptions, ...
    'CovarianceType', 'full', ...
    'SharedCovariance', false, ...
    'RegularizationValue', 1e-5, ...
    'Replicates', 5);

gm = gmdistribution(GMModel_final.mu, GMModel_final.Sigma, GMModel_final.ComponentProportion);
gmPDF = @(x, y) arrayfun(@(x0, y0) pdf(gm, [x0 y0]), x, y);
figure(2)
fsurf(gmPDF, [-3 3])

% Persist the final GMM using the configured output location.
save(outputPath, 'gm')