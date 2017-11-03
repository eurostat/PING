/** 
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
*/ /** \cond */

/* credits: meszama */

%macro var_est_srvyfrq(idsn = 	/* name of the input data set										(REQ) */
					, yr= 		/* the year for which the calculation is made						(REQ) */
					, cty_var= 	/* name of the variable/column containing the country codes			(REQ) */
					, strt = 	/* name of the variable/column containing the strata infromation	(REQ) */
					, clstr = 	/* name of the variable/column containing the cluster infromation	(REQ) */
					, wght = 	/* name of the variable/column containing the weight infromation	(REQ) */
					, prp_ind = /* name of the variable/column containing the 0/1 indicator			(REQ) */
					, bdown = 	/* name of the variable/column containing the breakdown information	(REQ) */
					, odsn = 	/* string which is appended to the standard datasets name			(REQ) */
					, ilib=
					, olib=
					);/mindelimiter=',';

	%if ilib= %then %let ilib=WORK;
	%if olib= %then %let olib=WORK;

	/*%if %sysfunc(exist(allres)) %then %do;
		proc datasets lib = work nolist;
			delete allres;
		quit;
	%end; */

	/* create the list of countries in the dataset*/
	proc sql ;
		select distinct &cty_var into :cty_lst 
		separated by ' ' 
		from &ilib..&idsn;
	quit;

	%let Ncty=1;
	%let cty=%scan(&cty_lst,&Ncty);

	%do %while(&cty ne);
		
		/* extract country data one by one */	
		DATA &cty._data; 
			set &ilib..&idsn;
			if &cty_var= "&cty.";
		RUN;

		/* check if all the values in the strata var is missing */
		Proc sql;
			Select &strt into :var1
			from &cty._data;
		Quit;
		%let nm=%sysfunc(sum(&var1,0));
		%put number of non-missing in &strt.: &nm.;
		
		/* run the variance estimation */ 
		proc surveyfreq data=&cty._data;
			TABLE &prp_ind * &bdown/ cl clwt var row col deff;
			by &cty_var;
			ods output Crosstabs=&cty._&prp_ind.;
			%if &nm ne 0 %then %do; STRATA &strt; %end;
			CLUSTER &clstr;
			WEIGHT &wght;
		run;
		
		/* put all results together */
		proc append base=allres data=&cty._&prp_ind.;
		run;
		
		proc datasets lib = work nolist;
			delete &cty._&prp_ind. &cty._data;
		quit;

		%let Ncty=%eval(&Ncty+1);
		%let cty=%scan(&cty_lst,&Ncty);
	%end;

	/* create output datasets */
	data &olib..result_&odsn._bdown;
		retain year &cty_var &prp_ind &bdown ColPercent ColStdErr ColLowerCL ColUpperCL;
		set allres;
		year=&yr;
		if &prp_ind.=1 and find(F_&bdown.,'total','i') le 0;
		keep year &cty_var &prp_ind &bdown ColPercent ColStdErr ColLowerCL ColUpperCL;
	run;

	data &olib..result_&odsn._total;
		retain year &cty_var &prp_ind Percent StdErr LowerCL UpperCL;
		set allres;
		year=&yr;
		if &prp_ind.=1 and find(F_&bdown.,'total','i') ge 1;
		keep year &cty_var &prp_ind Percent StdErr LowerCL UpperCL;
	run;
		
	proc datasets lib = work nolist;
		delete allres;
	quit;

%mend var_est_srvyfrq;

/** \endcond */