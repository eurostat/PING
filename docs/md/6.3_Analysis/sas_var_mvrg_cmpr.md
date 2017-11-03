## var_mvrg_cmpr {#sas_var_mvrg_cmpr}
Run a standard error estimation for changes between time T0 and T1 in cross-sectional estimators using the 
multivariate regression approach for a proportional 0/1 indicator.

~~~sas
	%var_mvrg_cmpr(idsn0=, yr0=, idsn1=, yr1=, odsn=, 
		cty_var=, strt=, clstr=, prp_ind=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn0` : the name of the input dataset at T0 in the work directory; it is the outdata_&odsn 
	output dataset of the %var_est_mvrg macro;
* `yr0` : the year at time T0 for which the variance previously calculated by the %var_est_mvrg macro;
* `idsn1` : the name of the input dataset at T1 in the work directory; it is the outdata_&odsn 
	output dataset of the %var_est_mvrg macro;
* `yr1` : the year at time T1 for which the variance previously calculated by the %var_est_mvrg macro;
* `cty_var` : the name of the column in the input datasets which contains the country codes;
* `strt` : the name of the column in the input datasets which contains the starta information;
* `clstr` :  the name of the column in the input datasets which contains the cluster/PSU information;
* `prp_ind` : the name of the column in the input datasets which contains the indicator variable which 
	contains 0 or 1;
* `ilib` : (_option_) input library where both datasets `idsn0` and `idsn1` must be stored; default: 
	`ilib` is set to `WORK`.
 
### Returns
* `odsn` : name of the output dataset containig the country code, the indicator value at time T0, at time
	T1, and the standard error of the net change;
* `olib` : (_option_) output library; default: `olib` is set to `WORK`. 

### Example
Run for instance:
	~~~sas
		%var_mvrg_cmpr(idsn0=outdata_mvrgt0, yr0=2014, idsn1=outdata_mvrgt1, yr1=2015, odsn=arope_comparison, 
			cty_var=DB020, strt=DB050, clstr=DB030, prp_ind=arope);
	~~~

### Note
**The macro `%%var_mvrg_cmpr` uses the implementation of variance estimation developed within the context of 
NET-SILC2 by [Osier et al, 2013] following the original algorithm of [Berger and Priam, 2010 and 2016].**

### References
1. Atkinson B., Guio A.-C. and Marlier E. eds (2017): ["Monitoring social inclusion in Europe"](http://ec.europa.eu/eurostat/documents/3217494/8031566/KS-05-14-075-EN-N.pdf/c3a33007-6cf2-4d86-9b9e-d39fd3e5420c).
2. Berger, Y.G. and Priam, R. (2016): ["A simple variance estimator of change for rotating repeated surveys: an application to the EU-SILC household surveys"](https://eprints.soton.ac.uk/347142/).
3. Osier G., Berger Y.  and Goedeme T. (2013): ["Standard error estimation for the EU–SILC indicators of poverty and social exclusion"](http://ec.europa.eu/eurostat/documents/3888793/5855973/KS-RA-13-024-EN.PDF).
4. Berger Y. and Priam R. (2010): ["Estimation of correlations between cross-sectional estimates from repeated surveys: an application to the variance of change"](https://eprints.soton.ac.uk/350430/).
5. Atkinson B. and Marlier E. eds (2010): ["Income and living conditions in Europe"](http://ec.europa.eu/eurostat/documents/3217494/5722557/KS-31-10-555-EN.PDF/e8c0a679-be01-461c-a08b-7eb08a272767).

### See also
[%var_est_mvrg](@ref sas_var_est_mvrg), [%var_est_srvyfrq](@ref sas_var_est_srvyfrq).
