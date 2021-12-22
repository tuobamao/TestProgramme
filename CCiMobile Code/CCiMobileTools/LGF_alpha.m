% LGF_alpha: Calculate Loudness Growth Function alpha factor.
% function alpha = LGF_alpha(Q, BaseLevel, SaturationLevel, fzero_options)
% This process is equivalent to an inverse, however the
% LGF function is transcendental and so this direct inverse is not possible.
% Warning: the while loop may not terminate for unusual input values.
% Find an interval that contains a zero crossing of LGF_Q_diff.
% fzero works much better if we give it this interval.
% We start with log_alpha chosen to give a positive value of LGF_Q_diff
% for sensible values of Q, BaseLevel, SaturationLevel,
% and then increment it until we see a sign change.
% We use log_alpha instead of alpha to make the search easier:
% a plot of Q vs log(alpha) changes much more smoothly than Q vs alpha.
function alpha = LGF_alpha(Q, BaseLevel, SaturationLevel)

    log_alpha = 0;
    while 1
        log_alpha = log_alpha + 1;
        Q_diff	= LGF_Q_diff(log_alpha, Q, BaseLevel, SaturationLevel);
        if (Q_diff < 0)
            break;
        end
    end
    interval = [(log_alpha - 1)  log_alpha];

    % Find the zero crossing of LGF_Q_diff:
    Matlab_version = sscanf(version, '%f', 1);
    if Matlab_version <= 5.2
        log_alpha = fzero('LGF_Q_diff', interval, [], 0, Q, BaseLevel, SaturationLevel);
    else
        opt.Display = 'off';
        opt.TolX = [];
        log_alpha = fzero('LGF_Q_diff', interval, opt, Q, BaseLevel, SaturationLevel);
    end

    alpha = exp(log_alpha);