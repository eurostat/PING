/** 
## var_est_mvrg {#sas_var_est_mvrg}
Run variance estimation using the multivariate regression approach for proportional 0/1 indicator.

~~~sas
	%var_est_mvrg(idsn=, odsn=, yr=, cty_var=, strt=, clstr=, wght=, prp_ind=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : the name of the input dataset in the work directory; default: not set;
* `yr` : the year for which the variance calculated;
* `cty_var` : the name of the column in the input dataset which contains the country codes;
* `strt` : the name of the column in the input dataset which contains the starta information;
* `clstr` :  the name of the column in the input dataset which contains the cluster/PSU information;
* `wght` : the name of the column in the input dataset which contains the weight information;
* `prp_ind` : the name of the column in the input dataset which contains the indicator variable which 
	contains 0 or 1;
* `ilib` : (_option_) input library; default: `ilib` is set to `WORK`.
 
### Returns
* `odsn` : a generic string used for the naming of output datasets; namely, the following datasets are
	created:
		+ `outdata_&odsn` : output dataset containig all the data is needed to estimate the standard 
			error for an absolute change between two cross-sectional estimators in diffrent years;  
		+ `result_&odsn_total` : output dataset containig the year, the country, the value 1 (as the 
			value where the indicator takes the value 1), the value of the indicator and the standard 
			error;
			
* `olib` : (_option_) output library; default: `olib` is set to `WORK`.

### Example
Run for instance:
	~~~sas
		%var_est_mvrg(idsn = adat_prep, odsn = mvrg, yr = 2014, cty_var= DB020, 
			strt = DB050, clstr = DB030, wght = RB050a, prp_ind = arope);
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
[%var_est_data_prep](@ref sas_var_est_data_prep), [%var_mvrg_cmpr](@ref sas_var_mvrg_cmpr), [%var_est_srvyfrq](@ref sas_var_est_srvyfrq).
*/ /** \cond */

/* credits: meszama */

%macro var_est_mvrg (idsn = 	/* name of the input data set										(REQ) */
					, yr= 		/* year for which the variance is calculated						(REQ) */
					, cty_var= 	/* name of the variable/column containing the country codes			(REQ) */
					, strt = 	/* name of the variable/column containing the strata infromation	(REQ) */
					, clstr = 	/* name of the variable/column containing the cluster infromation	(REQ) */
					, wght = 	/* name of the variable/column containing the weight infromation	(REQ) */
					, prp_ind = /* name of the variable/column containing the 0/1 indicator			(REQ) */
					, odsn = 	/* string which is appended to the standard datasets name			(REQ) */
					, ilib=
					, olib=
					);/mindelimiter=',';

	%if ilib= %then %let ilib=WORK;
	%if olib= %then %let olib=WORK;

	data tab1;
		set &ilib..&idsn; 
		/* fill up the missing values in the for the srs sampling*/
		if missing(&strt) then &strt=-99;
		/*create a dummy variable to count the observations*/
		dmmy=1;
		year=&yr;
	run;

	/*aggregation at PSU/cluster level*/

	proc means data=tab1 noprint;
		var &prp_ind dmmy;
		class &cty_var;
		types &cty_var;
		output out = sortie (drop = _type_ _freq_)
			sum(&prp_ind.) = _&prp_ind._ 
			sum(dmmy) = _dmmy_;
		weight &wght;
	run;    

	data tab1;
		merge tab1 sortie;
		by &cty_var;
	run;

	proc sort data = tab1;
		by &cty_var &strt &clstr;
	run;

	proc means data=tab1 noprint;
		var _&prp_ind._ _dmmy_ &prp_ind. dmmy;
		class &cty_var &strt &clstr;
		types &cty_var*&strt*&clstr;
		output out = sortie (drop = _type_ _freq_)
			max(&prp_ind.) = &prp_ind.
			max(_&prp_ind._) = yt
			max(_dmmy_) = at
			sum(&prp_ind) = num&yr
			sum(dmmy) = den&yr;
		weight &wght;
	run;    

	/* partial derivatives (gradient function) */
	data tab1;
		set sortie;
		r_&prp_ind._&yr = 100 * yt / at;
		g&yr._1 = -1 / at;
		g&yr._2 = yt / (at*at);
		one = 1;
		year = &yr;
	run;

	proc means data=tab1 noprint;
		var one;
		class &cty_var &strt;
		types &cty_var*&strt;
		output out = sortie (drop = _type_ _freq_)
			sum(one) = nh;
	run;    

	data tab1;
		merge tab1 sortie;
		by &cty_var &strt;
	run; 

	/* multivariate regression using the stratum dummies as regressors */
	proc glm data = tab1;
		by &cty_var;
		class &strt;
		model num&yr den&yr = &strt / nouni noint;
		output out = tabs residual = res_1 res_2;
	run;

	/* standard error estimation for the cross-sectional estimator */
	data tabs;
		set tabs;
		if nh~=1 then do;
			x_11 = (nh/(nh-1)) * res_1 * res_1;
			x_22 = (nh/(nh-1)) * res_2 * res_2;
		end;
		else do;
			x_11 = res_1 * res_1;
			x_22 = res_2 * res_2;
		end;
	run;

	proc means data = tabs noprint;
		var x_11 x_22;
		class &cty_var;
		types &cty_var;
		output out = sortie (drop = _type_ _freq_)
			sum(x_11) = N&yr
			sum(x_22) = D&yr;
	run;    

	data &olib..outdata_&odsn;
		merge tabs sortie;
		by &cty_var;
		StdErr= N&yr./D&yr.;
	run;

	proc means data = &olib..outdata_&odsn noprint;
		var r_&prp_ind._&yr. N&yr. D&yr.;
		class &cty_var.;
		types &cty_var.;
		output out = &olib..result_&odsn._total (drop = _type_ _freq_)
			max(year) = year
			max(&prp_ind) = &prp_ind
			max(r_&prp_ind._&yr.) = Percent
			max(StdErr) = StdErr;
	run;

	data &olib..result_&odsn._total;
		retain year &cty_var &prp_ind Percent StdErr;
		set &olib..result_&odsn._total;
		StdErr=sqrt(StdErr);
	run;
		
	proc datasets lib = work nolist;
		delete tab1 tabs sortie;
	quit;

%mend var_est_mvrg;

/** \endcond */
