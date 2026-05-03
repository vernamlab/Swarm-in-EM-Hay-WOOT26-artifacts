% final_PSO_em_clean.m
% Cleaned copy of final_PSO_em.m — minor formatting and debug-print cleanup only.

close all;
clc;

% Load the matrix from the .mat file
file_name = 'MI_impl_d.mat';
% file_name = 'uc_t_heatmap.mat';
gm_pca = load("GM_noiseless_pca_impl_d.mat");

c2_values = [0.8 1.2 1.5 1.8];
c1_values = [1.0 1.5 1.8];
inertia_values = {[0.5 0.7], [0.7 0.9]};

data = load(file_name);
matrix = data.MI_masked_smooth;

global visitCount;
global matrix_global visitCount currentMethod
global lhs_init random_init gaussian_pca_init

rng(1)
[rows, cols] = size(matrix);

% Objective function (negative for maximization)
fun = @(x) -interpolateMatrixd(matrix, x(1), x(2));

% Swarm size
SwarmSiz = [25];

% Define your file name
outputFileName = ['exp_MI_fpga_impl_d_para_25.txt'];
fileID = fopen(outputFileName, 'w');
if fileID == -1
    error('Failed to open the file for writing.');
end

nvars = 2;
lb = [1, 1];
ub = [cols, rows];

% Global matrix for visualization
global matrix_global;
matrix_global = matrix;
local_max = find_im_local_maxima(matrix);

% Comparison setup
methods = {'Random Initialization', 'LHS','Gaussian_pca'};
numTrials = 10; % Number of trials for statistical comparison
results = repmat(struct('method', '', 'iterations', 0, 'fitness', 0, 'time', 0, ...
    'convergenceLocation', [], 'c1', 0, 'c2', 0, 'inertia_low', 0, 'inertia_high', 0), ...
    numel(methods) * numTrials * numel(c1_values) * numel(c2_values) * numel(inertia_values), 1);

% Counter for storing results
resultIdx = 1;

for pok = 1:numel(SwarmSiz)
    SwarmSize = SwarmSiz(pok);
    visitCount = zeros(size(matrix)); % Initialize visit count matrix

    for m = 1:numel(methods)
        for trial = 1:numTrials
            rng(trial); % Ensure reproducibility

            % Select initialization method
            switch methods{m}
                case 'Random Initialization'
                    initialSwarm = [];
                case 'LHS'
                    initialSwarm = lhsdesign(SwarmSize, nvars);
                    initialSwarm = bsxfun(@times, initialSwarm, ub - lb) + lb;
                case 'Gaussian_pca'
                    pso_init = pcaswarm(gm_pca.gm,SwarmSize);
                    initialSwarm = round(pso_init + 5);
            end

            x_true = [9 9];

            for c2 = c2_values
                for I = 1:length(inertia_values)
                    inertiaRange = inertia_values{I};
                    for c1 = c1_values

                        options = optimoptions('particleswarm', ...
                            'SwarmSize', SwarmSize, ...
                            'MaxIterations', 40, ...
                            'MaxStallIterations', 2, ...
                            'InertiaRange', inertiaRange, ...
                            'SelfAdjustmentWeight', c1, ...
                            'SocialAdjustmentWeight', c2, ...
                            'FunctionTolerance', 1e-3, ...
                            'Display', 'off', ...
                            'OutputFcn', @swarmPlot );

                        global currentMethod
                        currentMethod = methods{m};

                        if ~isempty(initialSwarm)
                            options = optimoptions(options, 'InitialSwarmMatrix', initialSwarm);
                        end

                        % Run optimization
                        tic;
                        [x_opt, fval, ~, output, points] = particleswarm(fun, nvars, lb, ub, options);
                        elapsedTime = toc;

                        dist = min(vecnorm(x_opt - local_max, 2, 2));
                        success = dist < 8.2;

                        % Save results
                        results_saba = [results_saba; c1, c2, inertiaRange(1), inertiaRange(2), dist, success];

                        % Store into main results structure
                        results(resultIdx).method = methods{m};
                        results(resultIdx).iterations = output.iterations;
                        results(resultIdx).fitness = -fval;
                        results(resultIdx).time = elapsedTime;
                        results(resultIdx).convergenceLocation = round(x_opt);
                        results(resultIdx).c1 = c1;
                        results(resultIdx).c2 = c2;
                        results(resultIdx).inertia_low = inertiaRange(1);
                        results(resultIdx).inertia_high = inertiaRange(2);
                        resultIdx = resultIdx + 1;

                    end
                end
            end

        end

    end
    disp('Updated visitCount in main method:');
    disp(visitCount);

    % Find nonzero visits and corresponding values
    [row_idx, col_idx] = find(visitCount > 0);
    numVisits = visitCount(sub2ind(size(visitCount), row_idx, col_idx));
    gridValues = matrix(sub2ind(size(matrix), row_idx, col_idx));

    % Define histogram bin edges
    binEdges = linspace(min(gridValues), max(gridValues), 20); % Adjust bin count as needed

    % Compute weighted bin counts
    binIndices = discretize(gridValues, binEdges);
    weightedCounts = accumarray(binIndices(~isnan(binIndices)), numVisits(~isnan(binIndices)), [], @sum);

    % Plot histogram
    figure;
    histogram('BinEdges', binEdges, 'BinCounts', weightedCounts, 'EdgeColor', 'black', 'FaceAlpha', 0.7);

    xlabel('Matrix (t-test) Value');
    ylabel('Visits');
    title("PSO Swarm Visit Distribution (Swarm Size: " + SwarmSize + ")");
    colorbar;
    grid on;
    filename = sprintf('PSO_SwarmSize_t_%d.fig', SwarmSize);
    savefig(filename);
    pngFilename = strrep(filename, '.fig', '.png');
    saveas(gcf, pngFilename);
    close(gcf);

    % Analyze and display results
    fprintf(fileID,'\nComparison of Methods:%s, swarmsize:%d\n',file_name,SwarmSize);

    uniqueParams = unique([[results.c1]' [results.c2]' ...
                           [results.inertia_low]' [results.inertia_high]'], 'rows');
    
    for k = 1:size(uniqueParams,1)

        c1v  = uniqueParams(k,1);
        c2v  = uniqueParams(k,2);
        imin = uniqueParams(k,3);
        imax = uniqueParams(k,4);

        subset = results([results.c1] == c1v & ...
                         [results.c2] == c2v & ...
                         [results.inertia_low] == imin & ...
                         [results.inertia_high] == imax);

        fprintf(fileID,'\n===== Parameters: c1=%.2f, c2=%.2f, Imin=%.2f, Imax=%.2f =====\n', ...
            c1v, c2v, imin, imax);

        fprintf(fileID,'%-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s\n', ...
            'Method', 'Avg Iter', 'Min Iter', 'Max Iter', ...
            'Avg Fitness', 'Avg Time (s)', 'Location', ...
            'Avg Traces', 'Min Traces', 'Max Traces','locations');

        uniqMethods = unique({subset.method}, 'stable');

        for m = 1:numel(uniqMethods)

            mRes = subset(strcmp({subset.method}, uniqMethods{m}));

            it = [mRes.iterations];
            fit = [mRes.fitness];
            tm  = [mRes.time];
            locs = vertcat(mRes.convergenceLocation);

            % Stats
            avgIter = mean(it);
            minIter = min(it);
            maxIter = max(it);
            avgFit  = mean(fit);
            avgTime = mean(tm);

            avgTr  = avgIter * SwarmSize * 1000;
            minTr  = minIter * SwarmSize * 1000;
            maxTr  = maxIter * SwarmSize * 1000;

            % Most frequent location
            if ~isempty(locs)
                [uL,~,idx] = unique(locs,'rows','stable');
                counts = accumarray(idx,1);
                [~,mx] = max(counts);
                freqLoc = uL(mx,:);
            else
                freqLoc = [NaN NaN];
            end

            fprintf(fileID,'%-20s %-20.2f %-20.2f %-20.2f %-20.4f %-20.4f %-20s %-20.2f %-20.2f %-20.2f %-20s\n', ...
                uniqMethods{m}, avgIter, minIter, maxIter, ...
                avgFit, avgTime, mat2str(freqLoc), ...
                avgTr, minTr, maxTr,mat2str(locs));

        end

    end


end

plotInitialSwarmPositions(matrix_global, random_init, lhs_init, gaussian_pca_init);

fprintf("Done")

% Interpolation function
function value = interpolateMatrix(matrix, x, y)
    x = max(1, min(size(matrix, 1), x));
    y = max(1, min(size(matrix, 2), y));
    value = interp2(matrix, y, x, 'linear');
end

function value = interpolateMatrixd(matrix, x, y)
    % Round positions to the nearest integers
    x = round(x);
    y = round(y);

    % Ensure the indices are within the matrix boundaries
    x = max(1, min(size(matrix, 1), x));
    y = max(1, min(size(matrix, 2), y));

    % Get the matrix value at the rounded position
    value = matrix(x, y);
end


function stop = swarmPlot(optimValues, state)
    global matrix_global visitCount currentMethod
    global lhs_init random_init gaussian_pca_init

    stop = false;

    numParticles = size(optimValues.swarm, 1);
    if strcmp(state, 'init')
        % Save initial swarm based on method
        switch currentMethod
            case 'Random Initialization'
                random_init = optimValues.swarm;
            case 'LHS'
                lhs_init = optimValues.swarm;
            case 'Gaussian_pca'
                gaussian_pca_init = optimValues.swarm;
        end
    end   

    if strcmp(state, 'iter')
        % Get current swarm positions
        swarmPositions = optimValues.swarm;

        % Round positions to discrete indices and ensure they are valid
        x_idx = round(swarmPositions(:, 1));  % Row index
        y_idx = round(swarmPositions(:, 2));  % Column index

        % Ensure indices are positive integers
        x_idx(x_idx < 1) = 1; 
        y_idx(y_idx < 1) = 1; 

        [rows, cols] = size(visitCount);

        % Update visit count safely
        for i = 1:length(x_idx)
            if x_idx(i) >= 1 && y_idx(i) >= 1 && x_idx(i) <= rows && y_idx(i) <= cols
                visitCount(x_idx(i), y_idx(i)) = visitCount(x_idx(i), y_idx(i)) + 1;
            else
                warning('Index out of bounds: x_idx=%d, y_idx=%d', x_idx(i), y_idx(i));
            end
        end
        gifFilename = sprintf('pso_visualization_10_%d.gif', numParticles);
        frameDelay = 0.1; % Time delay between frames

        % Visualization
        cla;
        imagesc(matrix_global);
        colorbar;
        hold on;
        plot(optimValues.swarm(:, 2), optimValues.swarm(:, 1), 'r.', 'MarkerSize', 15);
        plot(optimValues.bestx(2), optimValues.bestx(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);
        title(sprintf('Iteration: %d', optimValues.iteration));
        drawnow;

        % Capture frame for GIF
        frame = getframe(gcf);
        img = frame2im(frame);
        [imind, cm] = rgb2ind(img, 256);
        if optimValues.iteration == 1
            imwrite(imind, cm, gifFilename, 'gif', 'Loopcount', inf, 'DelayTime', frameDelay);
        else
            imwrite(imind, cm, gifFilename, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
        end
    end
end


function plotInitialSwarmPositions(matrix_global, random_init, lhs_init, gaussian_pca_init)
    figure;
    cla;
    imagesc(matrix_global);
    colorbar;
    hold on;
    if ~isempty(random_init)
        plot(random_init(:, 2), random_init(:, 1), 'ro', 'MarkerSize', 15, 'DisplayName', 'Random');
    end
    if ~isempty(lhs_init)
        plot(lhs_init(:, 2), lhs_init(:, 1), 'kx', 'MarkerSize', 8, 'DisplayName', 'LHS');
    end
    if ~isempty(gaussian_pca_init)
        plot(gaussian_pca_init(:, 2), gaussian_pca_init(:, 1), 'rx', 'MarkerSize', 8, 'DisplayName', 'Gaussian_pca');
    end
    title('Initial Swarm Positions: Random, LHS, Gaussian_pca');
    legend('Location', 'bestoutside');
end

function samples = pcaswarm(gm,N)
    % Sample from GMM with Mahalanobis-distance filter to keep points near components
    samples = [];
    while size(samples,1) < N
        [x, compIdx] = random(gm, 1);
        x_discrete = round(x);
        mu_c = gm.mu(compIdx, :);
        Sigma_c = gm.Sigma(: , :, compIdx);
        d = sqrt((x_discrete - mu_c) / inv(Sigma_c) * (x_discrete - mu_c)');
        if d <= 3
            samples = unique([samples; x_discrete], 'rows');
        end
    end
end

function local_max = find_im_local_maxima(MI_map)
  [rows, cols] = size(MI_map);
  local_max = [];
  for r = 1:rows
    for c = 1:cols
      val = MI_map(r,c);
      r_min = max(1, r-1);
      r_max = min(rows, r+1);
      c_min = max(1, c-1);
      c_max = min(cols, c+1);
      neighbors = MI_map(r_min:r_max, c_min:c_max);
      neighbors(2,2) = -Inf;
      if val > max(neighbors(:))
        local_max = [local_max; r, c];
      end
    end
  end
end
