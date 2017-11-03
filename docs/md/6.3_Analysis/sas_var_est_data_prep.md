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
