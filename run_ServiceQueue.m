% Script that runs a ServiceQueue simulation many times and plots a
% histogram

%% Set up

% Set up to run 100 samples of the queue.
n_samples = 100;

% Each sample is run up to a maximum time of 1000.
max_time = 1000;

% Record how many customers are in the system at the end of each sample.
NInSystemSamples = cell([1, n_samples]);

%% Run the queue simulation

% The statistics seem to come out a little weird if the log interval is too
% short, apparently because the log entries are not independent enough.  So
% the log interval should be long enough for several arrival and departure
% events happen.
for sample_num = 1:n_samples
    q = ServiceQueue(LogInterval=10);
    q.schedule_event(Arrival(1, Customer(1)));
    run_until(q, max_time);
    % Pull out samples of the number of customers in the queue system. Each
    % sample run of the queue results in a column of samples of customer
    % counts, because tables like q.Log allow easy extraction of whole
    % columns like this.
    NInSystemSamples{sample_num} = q.Log.NWaiting + q.Log.NInService;
end

% Join all the samples. "vertcat" is short for "vertical concatenate",
% meaning it joins a bunch of arrays vertically, which in this case results
% in one tall column.
NInSystem = vertcat(NInSystemSamples{:});

% MATLAB-ism: When you pull multiple items from a cell array, the result is
% a "comma-separated list" rather than some kind of array.  Thus, the above
% means
%
%    NInSystem = horzcat(NInSystemSamples{1}, NInSystemSamples{2}, ...)
%
% which horizontally concatenates all the lists of numbers in
% NInSystemSamples.
%
% This is roughly equivalent to "splatting" in Python, which looks like
% f(*args).

%% Make a picture

% Make a figure with one set of axes.
fig = figure();
t = tiledlayout(fig,1,1);
ax = nexttile(t);

% MATLAB-ism: Once you've created a picture, you can use "hold on" to cause
% further plotting function to work with the same picture rather than
% create a new one.
hold(ax, 'on');

% Start with a histogram.  The result is an empirical PDF, that is, the
% area of the bar at horizontal index n is proportional to the fraction of
% samples for which there were n customers in the system.
h = histogram(ax, NInSystem, Normalization="probability", BinMethod="integers");

% For comparison, plot the theoretical results for a M/M/1 queue.
% The agreement isn't all that good unless you run for a long time, say
% max_time = 10,000 units, and LogInterval is large, say 10.
rho = q.ArrivalRate / q.DepartureRate;
P0 = 1 - rho;
nMax = 10;
ns = 0:nMax;
P = zeros([1, nMax+1]);
P(1) = P0;
for n = 1:nMax
    P(1+n) = P0 * rho^n;
end
plot(ax, ns, P, 'o', MarkerEdgeColor='k', MarkerFaceColor='r');

% Easiest way I've found to save a figure as a PDF file
exportgraphics(fig, "Service queue histogram.pdf");