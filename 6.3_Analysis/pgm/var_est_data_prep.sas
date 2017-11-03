/** 
## var_est_data_prep {#sas_var_est_data_prep}
Run variance estimation using the SAS proc surveyfreq procedure for proportional 0/1 indicator.

~~~sas
	%var_est_data_prep (idsn =, odsn =, cty_var=, bd_var=, wght_var =, strt_var =, 
		srs_sos_clstr_var =, sts_clstr_var =, ind_cond_t =, ind_cond_f =, ind_name =, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : the name of the input dataset in the work directory; default: not set;
* `cty_var` : the name of the column in the input dataset which contains the country codes;
* `bd_var` : the name of the column in the input dataset which contains the breakdown variable;
* `wght_var` :  the name of the column in the input dataset which contains the weight information;
* `strt_var` : the name of the column in the input dataset which contains the strata information for the 
	stratified one- and two-stage sampling;
* `srs_sos_clstr_var` : the name of the column in the input dataset which contains the cluster information for 
	the simple random and stratified one-satge sampling;
* `sts_clstr_var` : the name of the column in the input dataset which contains the cluster information for the 
	stratified two-stage sampling;
* `ind_cond_t` : character string describing the condition when the indicator variable take the true value (1);
* `ind_cond_f` : character string describing the condition when the indicator variable take the false value (0);
* `ind_name` : the name of the column in the output dataset which contains the calculated 0/1 inidicator variable;
* `ilib` : (_option_) input library; default: `ilib` is set to `WORK`.

### Returns
* `odsn` : name of the output dataset name; it will contain the country, the breakdown variable, the weight 
	variable (`wght`), the strata variable (`start`), the cluster variable (`clstr`), and the indicator 
	variable (named as defined in the input parameter `ind_name`) which takes only 1 or 0;  
* `olib` : (_option_) output library; default: `olib` is set to `WORK`.

### Example
Run for instance:
~~~sas
	%var_est_data_prep (idsn = adat, odsn = adat_prep, cty_var= DB020, bd_var= RB090, wght_var = RB050a, 
		strt_var = DB050, srs_sos_clstr_var = DB030, sts_clstr_var = DB060, 
		ind_cond_t = "AROPE>0", ind_cond_f = "AROPE=0", ind_name = arope);
~~~

### See also
[%var_est_data_prep_cond](@ref sas_var_est_data_prep_cond).
*/ /** \cond */

/* credits: meszama */

%macro var_est_data_prep (idsn = 
						, cty_var= 
						, bd_var=
						, wght_var = 
						, strt_var = 
						, srs_sos_clstr_var = 
						, sts_clstr_var = 
						, ind_cond_t = 
						, ind_cond_f = 
						, ind_name = 
						, odsn =
						, ilib=
						, olib=
						);

	%if ilib= %then %let ilib=WORK;
	%if olib= %then %let olib=WORK;
						
	data tmp_adat;
		set &ilib..&idsn;
		prp_indicator = .;
		IF (%sysfunc(dequote(&ind_cond_t))) THEN prp_indicator = 1 ;
		IF (%sysfunc(dequote(&ind_cond_f))) THEN prp_indicator = 0 ; 
	run;

	%let felt_srs=%var_est_data_prep_cond(SMPL=srs, CTY_VAR=&cty_var, WGHT_VAR=&wght_var, 
		STRT_VAR=&strt_var, SRS_SOS_CLSTR_VAR=&srs_sos_clstr_var, STS_CLSTR_VAR=&sts_clstr_var);
	%let felt_sos=%var_est_data_prep_cond(SMPL=sos, CTY_VAR=&cty_var, WGHT_VAR=&wght_var,
		STRT_VAR=&strt_var, SRS_SOS_CLSTR_VAR=&srs_sos_clstr_var, STS_CLSTR_VAR=&sts_clstr_var);
	%let felt_sts=%var_est_data_prep_cond(SMPL=sts, CTY_VAR=&cty_var, WGHT_VAR=&wght_var, 
		STRT_VAR=&strt_var, SRS_SOS_CLSTR_VAR=&srs_sos_clstr_var, STS_CLSTR_VAR=&sts_clstr_var);

	data tmp2_adat;
		set tmp_adat;
		clstr = .;
		wght = .;
		strt = .;
		&felt_srs;
		&felt_sos;
		&felt_sts;
	run;

	data &olib..&odsn(rename=(prp_indicator=&ind_name));
		set tmp2_adat(keep= &cty_var &bd_var wght strt clstr prp_indicator);
	run;
	
	proc datasets lib = work nolist;
		delete tmp_adat tmp2_adat;
	quit;

%mend var_est_data_prep;

/** \endcond */