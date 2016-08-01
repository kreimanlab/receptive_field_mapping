function data=notchfilt(data,srate,stopfreq)
%% Notch Filter (Stopband filter)

Fs = srate;              % sampling freq [Hz]
Fn = Fs/2;             % Nyquist   freq [Hz]
W0 = stopfreq;              % notch frequency [Hz]
for nf = 1:length(W0)
    w0 = W0(nf)*pi/Fn;   % notch frequency normalized
    BandWidth = 3;      % -3dB BandWidth [Hz]
    B = BandWidth*pi/Fn;  % normalized bandwidth
    k1 = -cos(w0);  k2 = (1 - tan(B/2))/(1 + tan(B/2));
    b = [1+k2  2*k1*(1+k2)  1+k2];
    a = [2  2*k1*(1+k2)  2*k2];
    % figure();       % look at the frequency response of your filter
    % freqz(b,a);
    % title('sampling frequency 200Hz, notch @ 20HzHz, notch bandwidth 5Hz');
    % z : your signal
    data=filter(b,a,data);
end