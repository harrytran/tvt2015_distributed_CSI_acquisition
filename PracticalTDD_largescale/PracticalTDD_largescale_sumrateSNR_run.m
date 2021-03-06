% Start timing
tstart = tic;

% Consistency check
if(any(sum((D == 1),2) > 1))
	error('Inconsistency in D. We do not allow for joint processing.');
end

parfor ii_Nnetwork = 1:Nnetworks
	ii_Nnetwork
	
	for ii_Nshadow = 1:Nshadow
		
		for ii_Nsim = 1:Nsim

			% Temporary results storage, so the outer parfor will work with the
			% nested loops
			iter_sumrateSNR_baseline_maxsinr  = zeros(Kr,length(Pt_dBms));
			iter_sumrateSNR_baseline_maxrate  = zeros(Kr,length(Pt_dBms));
			iter_sumrateSNR_baseline_unc      = zeros(Kr,length(Pt_dBms),length(Pr_dBms));
			iter_sumrateSNR_baseline_tdma     = zeros(Kr,length(Pt_dBms),length(Pr_dBms));
			iter_sumrateSNR_maxrate           = zeros(Kr,length(Pt_dBms),length(Pr_dBms));
			iter_sumrateSNR_maxsinr           = zeros(Kr,length(Pt_dBms),length(Pr_dBms));


			% Get channels
			H = networks{ii_Nnetwork}.as_matrix(ii_Nsim,ii_Nshadow);


			% Get current noise realization for the estimators
			estim_signals = raw_estim_signals;
			MS_norm_noise_realizations = raw_estim_signals.MS_norm_noise_realizations; estim_signals.MS_norm_noise_realizations = MS_norm_noise_realizations(:,:,(ii_Nnetwork-1)*Nshadow + (ii_Nshadow-1)*Nsim + ii_Nsim);
			BS_norm_noise_realizations = raw_estim_signals.BS_norm_noise_realizations; estim_signals.BS_norm_noise_realizations = BS_norm_noise_realizations(:,:,(ii_Nnetwork-1)*Nshadow + (ii_Nshadow-1)*Nsim + ii_Nsim);


			% Loop over downlink SNRs
			for ii_SNRd = 1:length(Pt_dBms)

				% Set up power
				Pt = 10^(Pt_dBms(ii_SNRd)/10); sigma2r = 10^(sigma2r_dBm/10);


				% =-=-=-=-=-=-=-=-=-=-=
				% BASELINE PERFORMANCE
				% =-=-=-=-=-=-=-=-=-=-=

				if(sim_params.run_baselines)
					user_rates_e = PracticalTDD_func_MaxRate_perfect_CSI(H,D,Pt,sigma2r,Nd,stop_crit);
					iter_sumrateSNR_baseline_maxrate(:,ii_SNRd) = user_rates_e(:,end);

					user_rates_e = PracticalTDD_func_MaxSINR_perfect_CSI(H,Dsched,Pt,sigma2r,Nd,stop_crit);
					iter_sumrateSNR_baseline_maxsinr(:,ii_SNRd) = user_rates_e(:,end);
				end

				% Loop over uplink SNRs
				for ii_SNRu = 1:length(Pr_dBms)

					% Set up power
					Pr = 10^(Pr_dBms(ii_SNRu)/10); sigma2t = 10^(sigma2t_dBm/10);

					% =-=-=-=-=-=-=-=-=-=-=
					% BASELINE PERFORMANCE
					% =-=-=-=-=-=-=-=-=-=-=

					if(sim_params.run_baselines)
						[iter_sumrateSNR_baseline_tdma(:,ii_SNRd,ii_SNRu), iter_sumrateSNR_baseline_unc(:,ii_SNRd,ii_SNRu)] = PracticalTDD_func_singleuser_noisy_CSI(H,D,Pt,sigma2r,Pr,sigma2t,Nd,stop_crit,estim_signals);
					end
					
					% =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
					% Noisy MaxRate TDD Performance
					% =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

					if(sim_params.run_noisy_maxrate)
						maxrate_rate_e = ...
							PracticalTDD_func_MaxRate_noisy_CSI(H,D,Pt,sigma2r,Pr,sigma2t,Nd,stop_crit, ...
								estim_params,estim_signals,MS_robustification,BS_robustification);
						iter_sumrateSNR_maxrate(:,ii_SNRd,ii_SNRu) = maxrate_rate_e(:,end);
					end

					% =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
					% Noisy MaxSINR TDD Performance
					% =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

					if(sim_params.run_noisy_maxsinr)
						maxsinr_rate_e = ...
							PracticalTDD_func_MaxSINR_noisy_CSI(H,Dsched,Pt,sigma2r,Pr,sigma2t,Nd,stop_crit, ...
								estim_params,estim_signals);
						iter_sumrateSNR_maxsinr(:,ii_SNRd,ii_SNRu) = maxsinr_rate_e(:,end);
					end
				end

			end


			% Store to permanent storage
			if(sim_params.run_baselines)
				sumrateSNR_baseline_unc     (:,:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_baseline_unc;
				sumrateSNR_baseline_tdma    (:,:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_baseline_tdma;
				sumrateSNR_baseline_maxsinr (:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_baseline_maxsinr;
				sumrateSNR_baseline_maxrate (:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_baseline_maxrate;
			end
			if(sim_params.run_noisy_maxrate)
				sumrateSNR_maxrate(:,:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_maxrate;
			end
			if(sim_params.run_noisy_maxsinr)
				sumrateSNR_maxsinr (:,:,:,ii_Nnetwork,ii_Nshadow,ii_Nsim) = iter_sumrateSNR_maxsinr;
			end
		end
	end
end


% Report timing performance
telapsed = toc(tstart);
disp(sprintf('PracticalTDD_sumrateSNR_run: %s', seconds2human(telapsed)));


% House keeping
clear ii_Nsim iter ii_SNRd ii_SNRu user_rates_e maxrate_rate_e;
