## var_est_srvyfrq {#sas_var_est_srvyfrq}
Run variance estimation using the SAS `PROC SURVEYFREQ` procedure for proportional 0/1 indicator.

~~~sas
	%var_est_srvyfrq(idsn=, odsn=, yr=, cty_var=, strt=, clstr=, wght=, prp_ind=, bdown=, 
		ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : the name of the input dataset in the work directory; default: not set;
* `yr` : the year for which the variance estimation is made;
* `cty_var` : the name of the column in the input dataset which contains the country codes;
* `strt` : the name of the column in the input dataset which contains the starta information;
* `clstr` :  the name of the column in the input dataset which contains the cluster information;
* `wght` : the name of the column in the input dataset which contains the weight information;
* `prp_ind` : the name of the column in the input dataset which contains the indicator variable which 
	contains 0 or 1;
* `bdown` : the name of the column in the input dataset which contains the breakdown variable;
* `ilib` : (_option_) input library; default: `ilib` is set to `WORK`.

* `odsn` : a string which is inserted in the starndard output datasets name;

### Returns
* `odsn` : a generic string used for the naming of output datasets; namely, the following datasets are
	created:
		+ `result_&odsn_bdown` : output dataset containig the year, the country, the value 1 (as the 
			value where the indicator takes the value 1), the unique value of the breakdown variable, 
			the value of the indicator, the standard error and the 95% confidence interval;  
		+ `result_&odsn_total` : output dataset containig the year, the country, the value 1 (as the 
		value where the indicator takes the value 1), the value of the indicator, the standard error 
		and the 95% confidence interval;
		
* `olib` : (_option_) output library; default: `olib` is set to `WORK`.

### Example
Run for instance:
~~~sas
	%var_est_srvyfrq (idsn = adat_prep, odsn = srvyfrq, yr= 2014, cty_var= DB020, 
		strt = DB050, clstr = DB030, wght = RB050a, prp_ind = arope, bdown = RB090);
~~~

### See also
[%var_est_mvrg](@ref sas_var_est_mvrg), [%var_mvrg_cmpr](@ref sas_var_mvrg_cmpr).
