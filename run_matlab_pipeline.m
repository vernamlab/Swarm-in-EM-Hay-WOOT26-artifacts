% Run MATLAB artifact pipeline in non-interactive batch mode.
% Usage (batch): matlab -batch "run_matlab_pipeline"

clc;
fprintf('Starting MATLAB pipeline...\n');

if ~exist('output_matlab', 'dir')
    mkdir('output_matlab');
end

set(0, 'DefaultFigureVisible', 'off');

% Run GMM generation first.
run('GMM_gen.m');

% Then run PSO using generated GMM and latest MI export.
clear inputFile
run('PSO.m');

fprintf('MATLAB pipeline finished successfully.\n');
