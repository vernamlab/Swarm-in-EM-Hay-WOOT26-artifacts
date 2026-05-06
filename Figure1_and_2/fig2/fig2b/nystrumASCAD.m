clear all
target_ratio = 1.0;
tolerance = 0.05;
N = 700;
mu = [0, 0];
noiseVar = 6;
signalVar = 25;
totalVar = signalVar + noiseVar;

rho = 0.4;  % You can adjust this
off_diag = rho * sqrt(totalVar);
Sigma = [sqrt(totalVar), off_diag; off_diag, sqrt(totalVar)];

% Generate data
X = mvnrnd(mu, Sigma, N);

% Compute pairwise distances and kernel
D2 = pdist2(X, X, 'euclidean').^2;
upperD2 = D2(triu(true(N), 1));
medianDist2 = median(upperD2);

% Manually adjust bandwidth to meet target_ratio
data_std = mean(std(X));
target_bandwidth = target_ratio * data_std;

% Compute kernel matrix
K = exp(-D2 / (2 * target_bandwidth^2));
diag_K = diag(diag(K));
offdiag_ratio = norm(K - diag_K, 'fro') / norm(K, 'fro');




% Add noise with increasing sigma
sigmas = linspace(0, 6, 200);
mi_vals = zeros(size(sigmas));

for i = 1:length(sigmas)
    sigma = sigmas(i);
    noise = sigma * randn(N, 2);
    X_noisy = X + noise;
    X1 = X_noisy(:, 1);
    X2 = X_noisy(:, 2);
    rho = corr(X1, X2);

    % Theoretical MI for bivariate Gaussian
    mi_vals(i) = -0.5 * log(1 - rho^2);
    %%%MRE
    % Compute kernel matrices for X1 and X2
    % Kx = exp(-pdist2(X1, X1).^2 / (2 * target_bandwidth^2));
    % Ky = exp(-pdist2(X2, X2).^2 / (2 * target_bandwidth^2));
    bw_x = median(pdist2(X1, X1).^2, 'all')^0.5;
    bw_y = median(pdist2(X2, X2).^2, 'all')^0.5;

    Kx = exp(-pdist2(X1, X1).^2 / (2 * bw_x^2));
    Ky = exp(-pdist2(X2, X2).^2 / (2 * bw_y^2));
    Kxy = Kx .* Ky;

    % Normalize each kernel matrix (trace normalization)
    Kx = Kx / trace(Kx);
    Ky = Ky / trace(Ky);
    Kxy = Kxy / trace(Kxy);

    % Rényi entropy order
    alpha = 1.01;  % Slightly >1 to approximate Shannon entropy

    % Matrix-based entropies
    Hx = (1 / (1 - alpha)) * log(trace(Kx^alpha));
    Hy = (1 / (1 - alpha)) * log(trace(Ky^alpha));
    Hxy = (1 / (1 - alpha)) * log(trace(Kxy^alpha));

    % Mutual Information
    mi_vals_r(i) = real(Hx + Hy - Hxy);
    %% nystrum 
    X1 = reshape(X1, [], 1);   % ensure it's N×1
    X2 = reshape(X2, [], 1);   % same for X2
    % === Estimate bandwidths (keep this step) ===
    bw_x = sqrt(median(pdist2(X1, X1).^2, 'all'));
    bw_y = sqrt(median(pdist2(X2, X2).^2, 'all'));
    % === Construct kernel struct ===
    kernel_x.type = 'rbf'; kernel_x.para = bw_x^2;
    kernel_y.type = 'rbf'; kernel_y.para = bw_y^2;
    
    % === Compute Nyström-approximated kernels ===
    m = 100; % Number of landmark points, tune this
    Kx = INys(kernel_x, X1(:), m, 'k');   % Ensure X1 is Nx1
    Ky = INys(kernel_y, X2(:), m, 'k');   % Ensure X2 is Nx1
    Kxy = Kx .* Ky;
    
    % === Normalize (trace-normalization) ===
    Kx = Kx / trace(Kx);
    Ky = Ky / trace(Ky);
    Kxy = Kxy / trace(Kxy);
    
    % === Matrix-based Renyi entropy and MI ===
    Hx = (1 / (1 - alpha)) * log(trace(Kx^alpha));
    Hy = (1 / (1 - alpha)) * log(trace(Ky^alpha));
    Hxy = (1 / (1 - alpha)) * log(trace(Kxy^alpha));
    
    mi_vals_nystrom(i) =real(Hx + Hy - Hxy);
end

plot(sigmas, mi_vals)
hold on
plot(sigmas, mi_vals_r)
hold on
plot(sigmas, mi_vals_nystrom)
xlabel('\sigma (noise std)')
ylabel('MI')
title('MI vs. Gaussian noise level')
legend('Analytical', 'MBRE (Rényi)', 'MBRE (Nyström) with 100 samples')