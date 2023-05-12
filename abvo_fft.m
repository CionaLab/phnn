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

        P2 = abs(Y / L);
        P1 = P2(1:n / 2 + 1);
        P1(2:end - 1) = 2 * P1(2:end - 1);

        P_rel = P1(1:n / 2) / max(P1(1:n / 2));

        f = 0:(Fs / n):(Fs / 2 - Fs / n);
        t = 1 ./ f;

        tab = table(f', t', P_rel, 'VariableNames', ["frequency", "period", "amplitude"]);
        tab = sortrows(tab, "amplitude", 'descend');
        writetable(tab, 'fourier_larva_' + larva + '.csv');

        subplot(1, 2, 1)
        plot(a_sub(:, 1), X)
        xlabel("t/s")
        ylabel("\Delta{}F/F_0")
        set(gca, 'xlim', [0 80])
        %title("aBVO GCaMP recording")
        subplot(1, 2, 2)
        plot(f, P_rel)
        %stem(f, P1(1:n / 2))
        xlabel("Hz")
        ylabel("Relative Amplitude")
        set(gca, 'xlim', [0 5])
        %title("Fourier transform of aBVO GCaMP recording")

        %highpass(X, 0.1, Fs)
        set(gcf, 'position', [0, 0, 1024, 256])

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
