denoisedData = denoisedData * scaled_factor;
clearvars

dataMatrix = readmatrix('data_100_121_uc.csv');
numComponents = 2;
scaleFactor = 100;
features = zeros(121, numComponents);

for loc = 1:121
    baseIdx = (loc - 1) * 100;
    sampledRows = randperm(100, 30);
    rowIdx = baseIdx + sampledRows;
    group = dataMatrix(rowIdx, :);

    [~, pcaScore] = pca(group);
    features(loc, :) = pcaScore(1, 1:numComponents);
end

score = features;

% We sample from the PCA-mapped 2D coordinates, so keep the GMM in 2D.
rng(1); % Reproducible fit and sampling
lowestAIC = inf;
bestGMM = [];
gmmOptions = statset('MaxIter', 1000);
gmAIC = zeros(1, 11);

for k = 1:11
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
save('GM_noiseless_pca_uc.mat', 'gm')

% Draw PSO initialization samples from the denoised GMM.
numSamples = 25;
sampleCount = 0;
sampleAttempts = 1;
samples = [];
uniqueSamples = [];

while size(uniqueSamples, 1) < numSamples
    [sample, componentIdx] = random(gm, 1);
    component_ID(1, sampleAttempts) = componentIdx;
    sampleDiscrete = round(sample);
    sampleAttempts = sampleAttempts + 1;
    disp(sample)

    mu_c = gm.mu(componentIdx, :);
    Sigma_c = gm.Sigma(:, :, componentIdx);
    distance = sqrt((sampleDiscrete - mu_c) / inv(Sigma_c) * (sampleDiscrete - mu_c)');

    if distance <= 3
        sampleCount = sampleCount + 1;
        samples(sampleCount, :) = sampleDiscrete;
        uniqueSamples = unique(samples, 'rows');
        disp('looped')
    end
end

figure(2)
hold on
zLevel = 0;
plot3(samples(:, 1), samples(:, 2), zLevel * ones(size(samples, 1), 1), ...
    'x', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', 'r');
