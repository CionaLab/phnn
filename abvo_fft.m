close all;

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Name", "Interval", "Code"];
opts.VariableTypes = ["string", "double", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Name", "Code"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Name", "Code"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "Interval", "ThousandsSeparator", ",");

% Import the data
files = readtable("fourier_files.csv", opts);

for i= 1:height(files)
    if (files{i, 3} ~= "")
        prefix = files{i, 1};
        larva = files{i, 3};

        a = readmatrix(prefix + ".csv");

        %a_sub = a(a(:, 1) > 100 & a(:, 1) < 160, :);
        a_sub = a;

        L = height(a_sub);

        frame = files{i, 2};
        Fs = 1000 / frame;

        %X = a_sub(: , 2) - mean(a_sub(:, 2));
        X = a_sub(: , 3);

        n = 2^nextpow2(L);
        Y = fft(X, n);

        [Xc, lags] = xcorr(X, 80, "coef");
        Yc = fft(Xc, n);

        P_rel = calculateP_rel(Y, L, n);

        Pc_rel = calculateP_rel(Yc, L, n);

        f = 0:(Fs / n):(Fs / 2 - Fs / n);
        t = 1 ./ f;

        tab = table(f', t', Pc_rel, 'VariableNames', ["frequency", "period", "amplitude"]);
        tab = sortrows(tab, "amplitude", 'descend');
        writetable(tab, 'fourier_larva_' + larva + '.csv');

        fig = figure();

        subplot(2, 2, 1)
        plot(a_sub(:, 1), X)
        xlabel("t/s")
        ylabel("\Delta{}F/F_0")
        set(gca, 'xlim', [0 80])
        title("s(t)")

        subplot(2, 2, 2)
        plot(f, P_rel)
        xlabel("Hz")
        ylabel("dB")
        set(gca, 'xlim', [0 5])
        set(gca, 'ylim', [-40 0])
        title("fft(s)")

        subplot(2, 2, 3)
        vcrit = sqrt(2) * erfinv(0.95);
        lconf = -vcrit / sqrt(L);
        upconf = vcrit / sqrt(L);
        stem(lags, Xc, 'filled')
        hold on
        plot(lags, [lconf; upconf] * ones(size(lags)), 'r')
        hold off
        xlabel("Lag")
        ylabel("ACF")
        set(gca, 'xlim', [0 80])
        set(gca, 'ylim', [-0.5 1.05])
        title("\rho{}(s)")

        subplot(2, 2, 4)
        plot(f, Pc_rel)
        xlabel("Hz")
        ylabel("dB")
        title("fft(\rho{})")
        set(gca, 'xlim', [0 5])
        set(gca, 'ylim', [-40 0])

        %highpass(X, 0.1, Fs)
        set(fig, 'position', [0, 0, 400, 300])

        exportgraphics(fig, 'fourier_larva_' + larva + '.png', 'Resolution', 300)
    end
end

%%
function P_rel = calculateP_rel(Y, L, n)
    P2 = abs(Y / L);
    P1 = P2(1:n / 2 + 1);
    P1(2:end - 1) = 2 * P1(2:end - 1);

    P_rel = pow2db(P1(1:n / 2));
end
