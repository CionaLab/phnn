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

        P2 = abs(Y / L);
        P1 = P2(1:n / 2 + 1);
        P1(2:end - 1) = 2 * P1(2:end - 1);

        P_rel = pow2db((P1(1: n / 2)));

        P2c = abs(Yc / L);
        P1c = P2c(1:n / 2 + 1);
        P1c(2:end - 1) = 2 * P1c(2:end - 1);

        Pc_rel = pow2db((P1c(1: n / 2)));

        f = 0:(Fs / n):(Fs / 2 - Fs / n);
        t = 1 ./ f;

        tab = table(f', t', P_rel, 'VariableNames', ["frequency", "period", "amplitude"]);
        tab = sortrows(tab, "amplitude", 'descend');
        writetable(tab, 'fourier_larva_' + larva + '.csv');

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
        set(gca, 'ylim', [-65 0])
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
        ylabel("Correlation")
        set(gca, 'xlim', [0 80])
        set(gca, 'ylim', [-0.5 1.05])
        title("ACF(s)")

        subplot(2, 2, 4)
        plot(f, Pc_rel)
        xlabel("Hz")
        ylabel("dB")
        title("fft(ACF(s))")
        set(gca, 'xlim', [0 5])
        set(gca, 'ylim', [-65 0])

        set(gcf, 'position', [0, 0, 512 * 2, 256 * 2])

        saveas(gcf, 'fourier_larva_' + larva + '.png')
    end
end

%subplot(2, 1, 1)
%plot(a_sub(:, 1), a_sub(:, 3))
%xlabel("t/s")
%ylabel("\Delta{}F/F_0")
%title("aaIN GCaMP recording")
%subplot(2, 1, 2)
%plot(f, abs(Y))
%xlim([0 0.5])
%xlabel("Hz")
%ylabel("Propotion")
%title("Fourier transform of aBVO GCaMP recording")
