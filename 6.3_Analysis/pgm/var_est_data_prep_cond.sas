/** 
## var_est_data_prep_cond {#sas_var_est_data_prep_cond}
Create the static conditions that can be used in the macro [%var_est_data_prep](@ref sas_var_est_data_prep) 
for the different sampling techniques. 

~~~sas
	%var_est_data_prep_cond(smpl =, cty_var =, wght_var=, 
		strt_var=, srs_sos_clstr_var =, sts_clstr_var = );
~~~

### Arguments
* `smpl` : 3 character length string defining the sampling techniques: 
		+ `srs` - simple random sampling,
		+ `sos` - stratified one-stage sampling,
		+ `sts` - stratified two-stage sampling;

* `cty_var` : the name of the column in the input dataset which contains the country codes;
* `wght_var` :  the name of the column in the input dataset which contains the weight information;
* `strt_var` : the name of the column in the input dataset which contains the strata information for the 
	`sos` and `sts` sampling;
* `srs_sos_clstr_var` : the name of the column in the input dataset which contains the cluster information 
	for the `srs` and `sos` sampling;
* `sts_clstr_var` : the name of the column in the input dataset which contains the cluster information for 
	the `sts` sampling.
 
### Returns
A string containing the correct variables as strata and cluster for the list of countries based on the 
sampling type. 

### Examples
Run for instance:
~~~sas
	%var_est_data_prep_cond(smpl = srs , cty_var = DB020, wght_var= RB050a, srs_sos_clstr_var = DB030);
~~~

### See also
[%var_est_data_prep](@ref sas_var_est_data_prep).
*/ /** \cond */

/* credits: meszama */

%macro var_est_data_prep_cond(smpl = 
							, cty_var = 
							, wght_var= 
							, strt_var= 
							, srs_sos_clstr_var = 
							, sts_clstr_var = 
							);

	%let srs_cty=DK IS MT NO SE;
	%let sos_cty=CH CY EE FI LU LT SK DE AT;
	%let sts_cty=ES SI LV NL PT IT CZ BG IE PL UK EL RO HU BE HR FR;

	%if &smpl= srs %then %let cty_lst = &srs_cty;
	%else %if &smpl= sos %then %let cty_lst = &sos_cty;
	%else %if &smpl= sts %then %let cty_lst = &sts_cty;

	%let cond=IF ;
	%do i=1 %to %eval(%list_length(&cty_lst)-1);
		%let cond = &cond. %quote(&cty_var.) = "%scan(&cty_lst, &i)" OR; 
	%end;

	%if &smpl= srs %then 
		%do; 
			%let cond = &cond. %quote(&cty_var.) =  "%scan(&cty_lst, %list_length(&cty_lst))" THEN DO%str(;) clstr = %quote(&srs_sos_clstr_var)%str(;) wght = %quote(&wght_var)%str(;) END;
		%end;
	%else %if &smpl= sos %then 
		%do; 
			%let cond = &cond. %quote(&cty_var.) =  "%scan(&cty_lst, %list_length(&cty_lst))" THEN DO%str(;) clstr = &srs_sos_clstr_var%str(;) wght = &wght_var%str(;) strt = &strt_var%str(;) END;
		%end;
	%else %if &smpl= sts %then 
		%do; 
			%let cond = &cond. %quote(&cty_var.) =  "%scan(&cty_lst, %list_length(&cty_lst))" THEN DO%str(;) clstr = &sts_clstr_var%str(;) wght = &wght_var%str(;) strt = &strt_var%str(;) END;
		%end;

	%quote(&cond)

%mend var_est_data_prep_cond;
