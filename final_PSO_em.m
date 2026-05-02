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
% matrix = data.matrix;
global visitCount;
global matrix_global visitCount currentMethod
global lhs_init grid_init random_init custom_init gaussian_init gaussian_n_init gaussian_hm_init gaussian_pca_init cvt_init
rng(1)
[rows, cols] = size(matrix);

% Objective function (negative for maximization)
fun = @(x) -interpolateMatrixd(matrix, x(1), x(2));

% Swarm size
SwarmSiz = [25];%,50];

% Define your file name
outputFileName = ['exp_MI_fpga_impl_d_para_25.txt'];

% Open the file for writing (will create the file if it doesn't exist)
fileID = fopen(outputFileName, 'w');

% Check if the file opened correctly
if fileID == -1
    error('Failed to open the file for writing.');
end
nvars = 2;
lb = [1, 1];
ub = [cols, rows];
% gm_n = load("GM_noiseless.mat")
% gm_og = load("GM_og.mat")
% gm_hm = load("GM_noiseless_howmany_discrete_impl_d.mat");

% Global matrix for visualization
global matrix_global;
matrix_global = matrix;
local_max = find_im_local_maxima(matrix); % you can define neighbors in 2D grid

% Comparison setup
methods = {'Random Initialization', 'LHS','Gaussian_pca'};%,'Gaussian_howmany','Gaussian_pca'};%{'Random Initialization', 'Gaussian', 'LHS'};%, 'LHS', 'Grid-Based', 'Custom', 'Gaussian','CVT'};
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
                    initialSwarm = []; % MATLAB default initialization
                    
                case 'LHS'
                    initialSwarm = lhsdesign(SwarmSize, nvars);
                    initialSwarm = bsxfun(@times, initialSwarm, ub - lb) + lb;
                    
                case 'Grid-Based'
                    numGridPoints = ceil(sqrt(SwarmSize));
                    gridX = linspace(lb(1), ub(1), numGridPoints);
                    gridY = linspace(lb(2), ub(2), numGridPoints);
                    [X, Y] = meshgrid(gridX, gridY);
                    initialSwarm = [X(:), Y(:)];
                    
                    % Ensure we have exactly SwarmSize particles
                    if size(initialSwarm, 1) > SwarmSize
                        initialSwarm = initialSwarm(randperm(size(initialSwarm, 1), SwarmSize), :);
                    elseif size(initialSwarm, 1) < SwarmSize
                        additionalPoints = SwarmSize - size(initialSwarm, 1);
                        extraSwarm = initialSwarm(randperm(size(initialSwarm, 1), additionalPoints), :);
                        initialSwarm = [initialSwarm; extraSwarm];
                    end
                    
                case 'Custom'
                    known_starting_point = [SwarmSize, SwarmSize];
                    initialSwarm = known_starting_point + randn(SwarmSize, nvars) * 10;
                    initialSwarm = max(initialSwarm, lb);
                    initialSwarm = min(initialSwarm, ub);
                    
                case 'Gaussian'
                    % Gaussian-based initialization

                    
                    pso_init = random(gm_og.gm,SwarmSize);

                    % % Scaling the values in pso_init to the range [0, 9]
                    % min_val = min(pso_init, [], 1); % Minimum values for each column
                    % max_val = max(pso_init, [], 1); % Maximum values for each column
                    % 
                    % % Apply min-max scaling to the range [0, 9]
                    % pso_init_scaled = 0 + (pso_init - min_val) .* (9 - 0) ./ (max_val - min_val);
                    % 
                    % % Discretize the scaled values to integers
                    initialSwarm = round(pso_init + 5);
                case 'Gaussian_n'
                    % Gaussian-based initialization

                    
                    pso_init = random(gm_n.gm,SwarmSize);

                    % % Scaling the values in pso_init to the range [0, 9]
                    % min_val = min(pso_init, [], 1); % Minimum values for each column
                    % max_val = max(pso_init, [], 1); % Maximum values for each column
                    % 
                    % % Apply min-max scaling to the range [0, 9]
                    % pso_init_scaled = 0 + (pso_init - min_val) .* (9 - 0) ./ (max_val - min_val);
                    % 
                    % % Discretize the scaled values to integers
                    initialSwarm = round(pso_init + 5);

                case 'Gaussian_pca'
                    % Gaussian-based initialization

                    
                    pso_init = pcaswarm(gm_pca.gm,SwarmSize);
                    % 
                    % % Scaling the values in pso_init to the range [0, 9]
                    % min_val = min(pso_init, [], 1); % Minimum values for each column
                    % max_val = max(pso_init, [], 1); % Maximum values for each column
                    % 
                    % % Apply min-max scaling to the range [0, 9]
                    % pso_init_scaled = 0 + (pso_init - min_val) .* (9 - 0) ./ (max_val - min_val);
                    % 
                    % % Discretize the scaled values to integers
                    initialSwarm = round(pso_init + 5);

                case 'Gaussian_howmany'
                    % Gaussian-based initialization

                    disp('reached gm_hm');

                    pso_init = pcaswarm(gm_hm.gm,SwarmSize);
                    disp('swarm initialize');

                    % % Scaling the values in pso_init to the range [0, 9]
                    % min_val = min(pso_init, [], 1); % Minimum values for each column
                    % max_val = max(pso_init, [], 1); % Maximum values for each column
                    % 
                    % % Apply min-max scaling to the range [0, 9]
                    % pso_init_scaled = 0 + (pso_init - min_val) .* (9 - 0) ./ (max_val - min_val);
                    % 
                    % Discretize the scaled values to integers
                    initialSwarm = round(pso_init + 5);                    
                   
                case 'CVT'
                    % 6. CVT-Based Initialization
                    initialSwarm = CVTInitialization(matrix, SwarmSize);
            end
            % Define a wrapper function that calls swarmPlot and passes visitCount
            % outputFcnWithVisitCount = @(optimValues, state) swarmPlot(optimValues, state, visitCount);

            
            x_true = [9 9];
            
            for c2 = c2_values
                for I = 1:length(inertia_values)
                    inertiaRange = inertia_values{I};
                    for c1 = c1_values
            
                        % Options setup
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
                        results_saba = [results_saba; ...
                            c1, c2, inertiaRange(1), inertiaRange(2), dist, success];
            
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
    
    % Find nonzero visits and corresponding SNR values
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
    
    % Labels and title
    xlabel('Matrix (t-test) Value');
    ylabel('Visits');
    title("PSO Swarm Visit Distribution (Swarm Size: " + SwarmSize + ")");
    colorbar;
    grid on;
    filename = sprintf('PSO_SwarmSize_t_%d.fig', SwarmSize);
    savefig(filename);
    % Define output PNG file name
    pngFilename = strrep(filename, '.fig', '.png');  % Replace .fig with .png
    
    % Save the figure as PNG
    saveas(gcf, pngFilename);
    
    % Close the figure
    close(gcf);


    % % Analyze and display results
    % fprintf(fileID,'\nComparison of Methods:%s,swarmsize:%d\n',file_name,SwarmSize);
    % fprintf(fileID,'%-20s %-20s %-20s %-20s %-20s %-20s\n', 'Method', 'Average Iterations', 'Average Fitness', 'Average Time (s)', 'Location','Average traces');
    % 
    % uniqueMethods = unique({results.method}, 'stable');
    % allFitness = [];
    % allIterations = [];
    % allLabels = [];
    % 
    % 
    % for i = 1:numel(uniqueMethods)
    %     methodResults = results(strcmp({results.method}, uniqueMethods{i}));
    %     avgIterations = mean([methodResults.iterations]);
    %     avgFitness = mean([methodResults.fitness]);
    %     avgTime = mean([methodResults.time]);
    %     loca = vertcat(methodResults.convergenceLocation);  % Convert to Nx2 if storing coordinates
    % 
    %     % Find the most frequently occurring location
    %     if ~isempty(loca)
    %         [uniqueLocs, ~, idx] = unique(loca, 'rows', 'stable'); % Get unique (x,y) locations
    %         counts = accumarray(idx, 1);  % Count occurrences
    %         [~, maxIdx] = max(counts);    % Find the most frequent location
    %         mostFrequentLoc = uniqueLocs(maxIdx, :);  % Extract the most frequent location
    %     else
    %         mostFrequentLoc = [NaN, NaN];  % Handle empty case
    %     end
    % 
    %     fprintf(fileID, '%-20s %-20.2f %-20.4f %-20.4f %-20s %-20.4f %-20s\n', ...
    %         uniqueMethods{i}, avgIterations, avgFitness, avgTime, ...
    %         mat2str(mostFrequentLoc),avgIterations * SwarmSize * 1000, mat2str(loca));
    %     % Collect data for box plots
    %     allFitness = [allFitness; [methodResults.fitness]'];
    %     allIterations = [allIterations; [methodResults.iterations]'];
    %     allLabels = [allLabels; repmat({uniqueMethods{i}}, numel(methodResults), 1)];
    % end
    % % Extract visited locations and corresponding values
    % disp('Updated visitCount in main method:');
    % disp(visitCount);
    % [row_idx, col_idx] = find(visitCount > 0);
    % numVisits = visitCount(sub2ind(size(visitCount), row_idx, col_idx));
    % gridValues = matrix(sub2ind(size(matrix), row_idx, col_idx));
    % 
    % % Plot visit count vs. matrix values
    % figure;
    % scatter(gridValues, numVisits, 50, 'filled');
    % xlabel('Matrix Value');
    % ylabel('Number of Visits');
    % title('PSO Swarm Visits vs. Grid Values');
    % grid on;
    % Extract visited locations and corresponding values
    % disp('Updated visitCount in main method:');
    % disp(visitCount);
    % 
    % [row_idx, col_idx] = find(visitCount > 0);
    % numVisits = visitCount(sub2ind(size(visitCount), row_idx, col_idx));
    % gridValues = matrix(sub2ind(size(matrix), row_idx, col_idx));
    % 
    % % Plot histogram of visit count vs. matrix values
    % figure;
    % histogram(gridValues, numVisits, 'DisplayStyle', 'tile', 'ShowEmptyBins', 'on');
    % xlabel('Matrix Value');
    % ylabel('Number of Visits');
    % zlabel('Frequency');
    % title('PSO Swarm Visit Distribution');
    % colorbar;
    % grid on;
    % % view(3); % 3D view for better visualization
    % Analyze and display results
    fprintf(fileID,'\nComparison of Methods:%s, swarmsize:%d\n',file_name,SwarmSize);
    % fprintf(fileID,'%-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s\n', ...
    %     'Method', 'Avg Iter', 'Min Iter', 'Max Iter', ...
    %     'Avg Fitness', 'Avg Time (s)', 'Location', 'Avg Traces', 'Min Traces', 'Max Traces');
    % 
    % uniqueMethods = unique({results.method}, 'stable');
    % allFitness = [];
    % allIterations = [];
    % allLabels = [];
    % 
    % for i = 1:numel(uniqueMethods)
    %     methodResults = results(strcmp({results.method}, uniqueMethods{i}));
    %     iterations = [methodResults.iterations];
    %     fitness = [methodResults.fitness];
    %     times = [methodResults.time];
    %     loca = vertcat(methodResults.convergenceLocation);  % Nx2 if storing coordinates
    % 
    %     % Compute stats
    %     avgIterations = mean(iterations);
    %     minIterations = min(iterations);
    %     maxIterations = max(iterations);
    %     avgFitness = mean(fitness);
    %     avgTime = mean(times);
    % 
    %     % Trace calculations (based on iteration count)
    %     avgTraces = avgIterations * SwarmSize * 1000;
    %     minTraces = minIterations * SwarmSize * 1000;
    %     maxTraces = maxIterations * SwarmSize * 1000;
    % 
    %     % Find most frequent convergence location
    %     if ~isempty(loca)
    %         [uniqueLocs, ~, idx] = unique(loca, 'rows', 'stable');
    %         counts = accumarray(idx, 1);
    %         [~, maxIdx] = max(counts);
    %         mostFrequentLoc = uniqueLocs(maxIdx, :);
    %     else
    %         mostFrequentLoc = [NaN, NaN];
    %     end
    % 
    %     % Print results including location list
    %     fprintf(fileID, '%-20s %-20.2f %-20.2f %-20.2f %-20.4f %-20.4f %-20s %-20.2f %-20.2f %-20.2f %-20s\n', ...
    %         uniqueMethods{i}, avgIterations, minIterations, maxIterations, ...
    %         avgFitness, avgTime, mat2str(mostFrequentLoc), ...
    %         avgTraces, minTraces, maxTraces, mat2str(loca));
    % 
    %     % Collect for plots
    %     allFitness = [allFitness; fitness'];
    %     allIterations = [allIterations; iterations'];
    %     allLabels = [allLabels; repmat({uniqueMethods{i}}, numel(methodResults), 1)];
    % end
    uniqueParams = unique([[results.c1]' [results.c2]' ...
                           [results.inertia_low]' [results.inertia_high]'], 'rows');
    
    for k = 1:size(uniqueParams,1)
    
        c1v  = uniqueParams(k,1);
        c2v  = uniqueParams(k,2);
        imin = uniqueParams(k,3);
        imax = uniqueParams(k,4);
    
        % Extract subset for this parameter combination
        subset = results([results.c1] == c1v & ...
                         [results.c2] == c2v & ...
                         [results.inertia_low] == imin & ...
                         [results.inertia_high] == imax);
    
        % Print SAME TABLE HEADER as before
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
    
            % Print EXACT SAME FORMAT as before
            fprintf(fileID,'%-20s %-20.2f %-20.2f %-20.2f %-20.4f %-20.4f %-20s %-20.2f %-20.2f %-20.2f %-20s\n', ...
                uniqMethods{m}, avgIter, minIter, maxIter, ...
                avgFit, avgTime, mat2str(freqLoc), ...
                avgTr, minTr, maxTr,mat2str(locs));
    
        end
    
    end


end

plotInitialSwarmPositions(matrix_global, random_init, gaussian_init, gaussian_n_init,gaussian_pca_init,gaussian_hm_init);

fprintf("Done")
% 
% % Fitness box plot
% figure;
% boxplot(allFitness, allLabels, 'LabelOrientation', 'inline');
% ylabel('Fitness Value');
% title('Comparison of Fitness Values Across Methods');
% 
% % Iterations box plot
% figure;
% boxplot(allIterations, allLabels, 'LabelOrientation', 'inline');
% ylabel('Iterations');
% title('Comparison of Iterations Across Methods');


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
    global lhs_init grid_init random_init custom_init gaussian_init gaussian_n_init cvt_init  gaussian_pca_init  gaussian_hm_init

    stop = false;
 % stop = false;
    numParticles = size(optimValues.swarm, 1);
    if strcmp(state, 'init')
        % Save initial swarm based on method
        switch currentMethod
            case 'Random Initialization'
                random_init = optimValues.swarm;
            case 'LHS'
                lhs_init = optimValues.swarm;
            case 'Grid-Based'
                grid_init = optimValues.swarm;
            case 'Custom'
                custom_init = optimValues.swarm;
            case 'Gaussian'
                gaussian_init = optimValues.swarm;
            case 'Gaussian_n'
                gaussian_n_init = optimValues.swarm;
            case 'Gaussian_pca'
                gaussian_pca_init = optimValues.swarm;
            case 'Gaussian_howmany'
                gaussian_hm_init = optimValues.swarm;

            case 'CVT'
                cvt_init = optimValues.swarm;
        end
    end   

    if strcmp(state, 'iter')
        % Get current swarm positions
        swarmPositions = optimValues.swarm;
        disp(swarmPositions)
        % Round positions to discrete indices and ensure they are valid
        x_idx = round(swarmPositions(:, 1));  % Row index
        y_idx = round(swarmPositions(:, 2));  % Column index

        % Ensure indices are positive integers, and no zero or negative values
        x_idx(x_idx < 1) = 1; 
        y_idx(y_idx < 1) = 1; 
        % 
        % % Ensure the indices are within the bounds of the matrix
        [rows, cols] = size(visitCount);
        % x_idx = min(x_idx, rows);  % Clamp to rows
        % y_idx = min(y_idx, cols);  % Clamp to cols
        % 
        % % Debugging Output
        % fprintf('x_idx = [%s]\n', num2str(x_idx'));
        % fprintf('y_idx = [%s]\n', num2str(y_idx'));

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
        disp('Updated visitCount:');
        disp(visitCount);
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



% CVT-based Initialization Method
function initialSwarm = CVTInitialization(matrix, SwarmSize)

    % Get the size of the matrix
    [rows, cols] = size(matrix);
    
    % Initialize the swarm with random positions
    initialSwarm = [rand(SwarmSize, 1) * cols, rand(SwarmSize, 1) * rows];
    
    % Set a maximum number of iterations for the CVT process
    maxIterations = 50;
    
    for iter = 1:maxIterations
        % Assign each particle to the nearest centroid (Voronoi cell)
        voronoiCellAssignments = assignToCentroids(initialSwarm, initialSwarm);
        
        % Update centroids of the Voronoi cells
        newCentroids = updateCentroids(initialSwarm, voronoiCellAssignments);
        
        % Move particles towards their centroids
        for i = 1:SwarmSize
            initialSwarm(i, :) = initialSwarm(i, :) + 0.1 * (newCentroids(i, :) - initialSwarm(i, :));
        end
    end
    
    % Ensure the particles are within the bounds of the matrix
    initialSwarm(:, 1) = max(min(initialSwarm(:, 1), cols), 1); % Clip x-coordinates
    initialSwarm(:, 2) = max(min(initialSwarm(:, 2), rows), 1); % Clip y-coordinates
end

% Function to assign particles to the nearest centroid (Voronoi cell)
function assignments = assignToCentroids(particles, centroids)
    numParticles = size(particles, 1);
    numCentroids = size(centroids, 1);
    assignments = zeros(numParticles, 1);
    
    for i = 1:numParticles
        % Compute the distance from the particle to each centroid
        distances = sqrt(sum((centroids - repmat(particles(i, :), numCentroids, 1)).^2, 2));
        
        % Assign the particle to the nearest centroid
        [~, assignments(i)] = min(distances);
    end
end

% Function to update the centroids of each Voronoi cell
function centroids = updateCentroids(particles, assignments)
    numCentroids = max(assignments);
    centroids = zeros(numCentroids, 2);
    
    for i = 1:numCentroids
        % Find particles assigned to centroid i
        assignedParticles = particles(assignments == i, :);
        
        if ~isempty(assignedParticles)
            % Compute the mean of the assigned particles to get the new centroid
            centroids(i, :) = mean(assignedParticles, 1);
        end
    end
end

function plotInitialSwarmPositions(matrix_global, random_init, gaussian_init, gaussian_n_init,gaussian_pca_init,gaussian_hm_init)
% plotInitialSwarmPositions - Plots initial positions from 3 initialization methods
%
% Inputs:
%   matrix_global    - Matrix representing the environment
%   random_init      - Initial swarm from Random Initialization (Nx2)
%   gaussian_init    - Initial swarm from Gaussian Initialization (Nx2)
%   gaussian_n_init  - Initial swarm from Gaussian_n Initialization (Nx2)

    figure;
    cla;
    imagesc(matrix_global);
    colorbar;
    hold on;

    % Plot Random Initialization (red dots)
    if ~isempty(random_init)
        plot(random_init(:, 2), random_init(:, 1), 'ro', 'MarkerSize', 15, 'DisplayName', 'Random');
    end

    % Plot Gaussian Initialization (blue triangles)
    if ~isempty(gaussian_init)
        plot(gaussian_init(:, 2), gaussian_init(:, 1), 'kx', 'MarkerSize', 8, 'DisplayName', 'Gaussian');
    end

    % Plot Gaussian_n Initialization (magenta diamonds)
    if ~isempty(gaussian_n_init)
        plot(gaussian_n_init(:, 2), gaussian_n_init(:, 1), 'cs', 'MarkerSize', 8, 'DisplayName', 'Gaussian\_n');
    end
    % Plot Gaussian Initialization (blue triangles)
    if ~isempty(gaussian_pca_init)
        plot(gaussian_pca_init(:, 2), gaussian_pca_init(:, 1), 'rx', 'MarkerSize', 8, 'DisplayName', 'Gaussian\_pca');
    end

    % Plot Gaussian_n Initialization (magenta diamonds)
    if ~isempty(gaussian_hm_init)
        plot(gaussian_hm_init(:, 2), gaussian_hm_init(:, 1), 'rs', 'MarkerSize', 8, 'DisplayName', 'Gaussian\_hm');
    end

    title('Initial Swarm Positions: Random, Gaussian, Gaussian\_n');
    legend('Location', 'bestoutside');
end

function samples = pcaswarm(gm,N)
    %Let's take sample for PSO initilization from the 3 sigma distance of the
    %GM. We need, say 100 sample. 
    count=0;
    tt=1;
    samples=[];
    samples_u=[];
    while size(samples_u,1) < N
        % Sample from the GMM
        [x, compIdx] = random(gm, 1);  % x: 1x2, compIdx: component used
        component_ID(1,tt)=compIdx;
        x_discrete = round(x);
        tt=tt+1;
    
        % Compute Mahalanobis distance from the mean of that component
        mu_c = gm.mu(compIdx, :);
        Sigma_c = gm.Sigma(: , :, compIdx);
        d = sqrt((x_discrete - mu_c) / inv(Sigma_c) * (x_discrete - mu_c)');
        %d=mahal(gm,x_discrete); %Time-complex
        disp('having fun in loop 1')
        disp(d)
        if d <= 3
            disp('having fun in d<3')
            count = count + 1;
            disp(count)
            samples(count, :) = x_discrete; 
            samples_u=unique(samples, 'rows');
        end
    end
end


function local_max = find_im_local_maxima(MI_map)
% FIND_IM_LOCAL_MAXIMA Detect all local maxima in a 2-D MI map.
%
% Input:
%  MI_map : an N x M matrix representing the MI value at each grid location
%
% Output:
%  local_max : K x 2 matrix, each row = [row_index, col_index] of a local maximum
  [rows, cols] = size(MI_map);
  local_max = [];
  for r = 1:rows
    for c = 1:cols
      % Current MI value
      val = MI_map(r,c);
      % Gather neighbor coordinates (8-connected neighborhood)
      r_min = max(1, r-1);
      r_max = min(rows, r+1);
      c_min = max(1, c-1);
      c_max = min(cols, c+1);
      neighbors = MI_map(r_min:r_max, c_min:c_max);
      % Remove the center element to avoid comparing with itself
      neighbors(2,2) = -Inf;
      % Check if current value is strictly greater than all neighbors
      if val > max(neighbors(:))
        local_max = [local_max; r, c];
      end
    end
  end
end