%% Plot IT load data from three modes and save high-resolution PNG figures
% data1.mat = Training mode
% data2.mat = Inference mode
% data3.mat = IDLE mode
%
% Assumed columns in timeseries data:
%   Time, P_IT, V (pu), Power (MW)

clear; clc; close all;

%% Settings
tStart = 3;
tEnd   = 20;
dt     = 0.001;
tq     = (tStart:dt:tEnd)';

savePath = 'E:\Study\simulink\DC';

fontAxis   = 18;
fontTitle  = 20;
fontLegend = 15;
lineW      = 2.0;

% Slightly zoomed out y-limits will be set automatically with margin
marginFrac = 0.08;

% Colors
c1 = [0.0000 0.4470 0.7410];   % blue
c2 = [0.8500 0.3250 0.0980];   % orange
c3 = [0.4660 0.6740 0.1880];   % green

%% Load files
S1 = load('data1.mat');   % Training mode
S2 = load('data2.mat');   % Inference mode
S3 = load('data3.mat');   % IDLE mode

%% Extract signals
[t1, pit1, v1, pwr1] = extractSignalsFromMatStruct(S1);
[t2, pit2, v2, pwr2] = extractSignalsFromMatStruct(S2);
[t3, pit3, v3, pwr3] = extractSignalsFromMatStruct(S3);

%% Convert P_IT from W to MW
pit1 = pit1 / 1e6;
pit2 = pit2 / 1e6;
pit3 = pit3 / 1e6;

%% Interpolate on common time vector
pit1q = interp1(t1, pit1, tq, 'linear', 'extrap');
pit2q = interp1(t2, pit2, tq, 'linear', 'extrap');
pit3q = interp1(t3, pit3, tq, 'linear', 'extrap');

v1q   = interp1(t1, v1, tq, 'linear', 'extrap');
v2q   = interp1(t2, v2, tq, 'linear', 'extrap');
v3q   = interp1(t3, v3, tq, 'linear', 'extrap');

pwr1q = interp1(t1, pwr1, tq, 'linear', 'extrap');
pwr2q = interp1(t2, pwr2, tq, 'linear', 'extrap');
pwr3q = interp1(t3, pwr3, tq, 'linear', 'extrap');

%% ---------- Figure 1 : P_IT in 3 separate subplots ----------
fig1 = figure('Color','w','Position',[80 80 1300 950]);

subplot(3,1,1)
plot(tq, pit1q, 'Color', c1, 'LineWidth', lineW);
grid on; box on;
xlim([tStart tEnd]);
ylabel('P_{IT} (MW)', 'FontSize', fontAxis, 'FontWeight','bold');
title('Training Mode', 'FontSize', fontTitle, 'FontWeight','bold');
set(gca, 'FontSize', fontAxis, 'LineWidth', 1.2);
applyMargin(gca, pit1q, marginFrac);

subplot(3,1,2)
plot(tq, pit2q, 'Color', c2, 'LineWidth', lineW);
grid on; box on;
xlim([tStart tEnd]);
ylabel('P_{IT} (MW)', 'FontSize', fontAxis, 'FontWeight','bold');
title('Inference Mode', 'FontSize', fontTitle, 'FontWeight','bold');
set(gca, 'FontSize', fontAxis, 'LineWidth', 1.2);
applyMargin(gca, pit2q, marginFrac);

subplot(3,1,3)
plot(tq, pit3q, 'Color', c3, 'LineWidth', lineW);
grid on; box on;
xlim([tStart tEnd]);
xlabel('Time (s)', 'FontSize', fontAxis, 'FontWeight','bold');
ylabel('P_{IT} (MW)', 'FontSize', fontAxis, 'FontWeight','bold');
title('IDLE Mode', 'FontSize', fontTitle, 'FontWeight','bold');
set(gca, 'FontSize', fontAxis, 'LineWidth', 1.2);
applyMargin(gca, pit3q, marginFrac);

sgtitle('P_{IT} Comparison for Three Modes', 'FontSize', 22, 'FontWeight','bold');

%% Save Figure 1
exportgraphics(fig1, fullfile(savePath, 'P_IT_Comparison_Three_Modes.png'), 'Resolution', 600);

%% ---------- Figure 2 : Voltage and Power ----------
fig2 = figure('Color','w','Position',[120 100 1300 850]);

subplot(2,1,1)
plot(tq, v1q, 'Color', c1, 'LineWidth', lineW); hold on;
plot(tq, v2q, 'Color', c2, 'LineWidth', lineW);
plot(tq, v3q, 'Color', c3, 'LineWidth', lineW);
grid on; box on;
xlim([tStart tEnd]);
ylabel('V (pu)', 'FontSize', fontAxis, 'FontWeight','bold');
title('Voltage During FIDVR', 'FontSize', fontTitle, 'FontWeight','bold');
legend('Training Mode','Inference Mode','IDLE Mode', ...
    'FontSize', fontLegend, 'Location', 'best');
set(gca, 'FontSize', fontAxis, 'LineWidth', 1.2);
applyMargin(gca, [v1q; v2q; v3q], marginFrac);

subplot(2,1,2)
plot(tq, pwr1q, 'Color', c1, 'LineWidth', lineW); hold on;
plot(tq, pwr2q, 'Color', c2, 'LineWidth', lineW);
plot(tq, pwr3q, 'Color', c3, 'LineWidth', lineW);
grid on; box on;
xlim([tStart tEnd]);
xlabel('Time (s)', 'FontSize', fontAxis, 'FontWeight','bold');
ylabel('Power (MW)', 'FontSize', fontAxis, 'FontWeight','bold');
title('Power During FIDVR', 'FontSize', fontTitle, 'FontWeight','bold');
legend('Training Mode','Inference Mode','IDLE Mode', ...
    'FontSize', fontLegend, 'Location', 'best');
set(gca, 'FontSize', fontAxis, 'LineWidth', 1.2);
applyMargin(gca, [pwr1q; pwr2q; pwr3q], marginFrac);



%% Save Figure 2
exportgraphics(fig2, fullfile(savePath, 'Voltage_Power_Comparison_Three_Modes.png'), 'Resolution', 600);

disp('Figures saved successfully.');

%% ================= Local functions =================
function [t, pit, vpu, pwr] = extractSignalsFromMatStruct(S)
    vars = fieldnames(S);
    obj  = S.(vars{1});

    if isa(obj, 'Simulink.SimulationOutput')
        props = properties(obj);
        tsFound = false;
        for k = 1:numel(props)
            candidate = obj.(props{k});
            if isa(candidate, 'timeseries')
                ts = candidate;
                tsFound = true;
                break;
            end
        end
        if ~tsFound
            error('No timeseries found inside SimulationOutput.');
        end

    elseif isa(obj, 'timeseries')
        ts = obj;

    elseif isstruct(obj)
        fn = fieldnames(obj);
        tsFound = false;
        for k = 1:numel(fn)
            candidate = obj.(fn{k});
            if isa(candidate, 'timeseries')
                ts = candidate;
                tsFound = true;
                break;
            end
        end
        if ~tsFound
            error('No timeseries found in MAT file structure.');
        end
    else
        error('Unsupported MAT-file content format.');
    end

    t = ts.Time(:);
    D = ts.Data;

    if size(D,1) ~= numel(t) && size(D,2) == numel(t)
        D = D.';
    end

    if size(D,2) < 3
        error('Timeseries data must have at least 3 columns: P_IT, V, Power.');
    end

    pit = D(:,1);
    vpu = D(:,2);
    pwr = D(:,3);
end

function applyMargin(ax, y, marginFrac)
    y = y(:);
    y = y(isfinite(y));

    if isempty(y)
        return;
    end

    ymin = min(y);
    ymax = max(y);

    if ymax == ymin
        delta = max(abs(ymax)*0.05, 1e-3);
        ylim(ax, [ymin-delta, ymax+delta]);
    else
        margin = marginFrac * (ymax - ymin);
        ylim(ax, [ymin-margin, ymax+margin]);
    end
end