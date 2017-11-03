/** 
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
*/ /** \cond */

/* credits: meszama */

%macro var_mvrg_cmpr (idsn0 = 				/* name of the input data set at time T0								(REQ) */
					, yr0 = 				/* year at time T0														(REQ) */
					, idsn1 = 				/* name of the input data set at time T1								(REQ) */
					, yr1 = 				/* year at time T1														(REQ) */
					, cty_var= 				/* name of the variable/column containing the country codes				(REQ) */
					, strt = 				/* name of the variable/column containing the strata infromation		(REQ) */
					, clstr = 				/* name of the variable/column containing the cluster/PSU infromation	(REQ) */
					, prp_ind = 			/* name of the variable/column containing the 0/1 indicator				(REQ) */
					, odsn = 			/* string which is appended to the standard datasets name					(REQ) */
					, ilib=
					, olib=
					);/mindelimiter=',';

	%if ilib= %then %let ilib=WORK;
	%if olib= %then %let olib=WORK;
	
	/* standard error estimation for changes in cross-sectional estimators using the multivariate regression approach */
	data tab;
		merge &ilib..&idsn0(in=u) &ilib..&idsn1(in=v);
		by &cty_var &strt &clstr;
		rot01 = u;
		rot02 = v;
		if num&yr0=. then num&yr0=0;
		if den&yr0=. then den&yr0=0;
		if num&yr1=. then num&yr1=0;
		if den&yr1=. then den&yr1=0;
	run;

	proc glm data = tab;
		by &cty_var;
		class &strt rot01 rot02;
		model num&yr0 den&yr0 num&yr1 den&yr1 = &strt*rot01 &strt*rot02 &strt*rot01*rot02 / nouni noint;
		output out = tabs residual = res_1 res_2 res_3 res_4;
	run;

	data tabs;
		set tabs;
		x_11 = res_1 * res_1; x_22 = res_2 * res_2; x_33 = res_3 * res_3; x_44 = res_4 * res_4;
		x_12 = res_1 * res_2; x_13 = res_1 * res_3; x_14 = res_1 * res_4; x_23 = res_2 * res_3; x_24 = res_2 * res_4; x_34 = res_3 * res_4;
	run;

	proc means data = tabs noprint;
		var x_11 x_22 x_33 x_44 x_12 x_13 x_14 x_23 x_24 x_34 
			g&yr0._1 g&yr0._2 g&yr1._1 g&yr1._2 
			r_&prp_ind._&yr0. r_&prp_ind._&yr1. 
			N&yr0. D&yr0. N&yr0. D&yr1.;
		class &cty_var;
		types &cty_var;
		output out = fin (drop = _type_ _freq_)
			sum(x_11) = x11_ sum(x_22) = x22_ sum(x_33) = x33_ sum(x_44) = x44_
			sum(x_12) = x12_ sum(x_13) = x13_ sum(x_14) = x14_ sum(x_23) = x23_ sum(x_24) = x24_ sum(x_34) = x34_
			max(g&yr0._1) = grad11 max(g&yr0._2) = grad12
			max(g&yr1._1) = grad21 max(g&yr1._2) = grad22
			max(r_&prp_ind._&yr0.) = &prp_ind.&yr0
			max(r_&prp_ind._&yr1.) = &prp_ind.&yr1
			max(N&yr0) = N&yr0._ max(D&yr0) = D&yr0._
			max(N&yr1) = N&yr1._ max(D&yr1) = D&yr1._;
	run;    
	
	data &olib..&odsn (drop=x11_ x22_ x33_ x44_ x12_ x13_ x14_ x24_ x34_ x23_ x24_ x34_ 
					C11 C22 C33 C44 C12 C13 C14 C23 C24 C34 
					grad11 grad12 grad21 grad22 
					N&yr0._ N&yr1._ D&yr0._ D&yr1._ var);
		set fin;
		C11 = N&yr0._ * 1 ;
		C22 = D&yr0._ * 1 ;
		C33 = N&yr1._ * 1 ;
		C44 = D&yr1._ * 1 ;
		C12 = sqrt(N&yr0._) * sqrt(D&yr0._) * x12_ / ( sqrt(x11_) * sqrt(x22_) );
		C13 = sqrt(N&yr0._) * sqrt(N&yr1._) * x13_ / ( sqrt(x11_) * sqrt(x33_) );
		C14 = sqrt(N&yr0._) * sqrt(D&yr1._) * x14_ / ( sqrt(x11_) * sqrt(x44_) );
		C23 = sqrt(D&yr0._) * sqrt(N&yr1._) * x23_ / ( sqrt(x22_) * sqrt(x33_) );
		C24 = sqrt(D&yr0._) * sqrt(D&yr1._) * x24_ / ( sqrt(x22_) * sqrt(x44_) );
		C34 = sqrt(N&yr1._) * sqrt(D&yr1._) * x34_ / ( sqrt(x33_) * sqrt(x44_) );
		var = 10000 * (
			(grad11 * grad11 * C11) + (grad12 * grad12 * C22)  
			+ (grad21 * grad21 * C33) + (grad22 * grad22 * C44) 
			+ 2 * ((grad11 * grad12 * C12) + (grad11 * grad21 * C13) 
				+ (grad11 * grad22 * C14) + (grad12 * grad21 * C23) 
				+ (grad12 * grad22 * C24)  + (grad21 * grad22 * C34))
			);
		std = sqrt(var);
	run;
		
	proc datasets lib = work nolist;
		delete tab tabs fin;
	quit;

%mend var_mvrg_cmpr;

/** \endcond */
