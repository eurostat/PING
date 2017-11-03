## silc_ind_info {#sas_silc_ind_info}
Provide information regarding the definition/construction of EU-SILC indicators. 

~~~sas
	%silc_ind_info(ind, odsn=, _svy_=, _lib_=, _fmt_=, _var_=, _wght_=, _desc_=, olib=WORK,
					cds_varxind=META_VARIABLExINDICATOR, clib=LIBCFG);
~~~

### Arguments
* `ind` : (list of) indicator(s) whose information is requested;
* `cds_varxind, clib` : (_option_) respectively, name and library of the configuration file 
	storing the correspondance table between the various variables and indicators; by default, 
	these parameters are set to the values `&G_PING_VARIABLExINDICATOR` and `&G_PING_LIBCFG` 
	(_e.g._, `META_VARIABLExINDICATOR` and `LIBCFG` resp.); 
	see [%meta_variablexindicator](@ref meta_variablexindicator) for further description.

### Returns
* `odsn` : (_option_) name of the final output dataset created; if not set, a
* `olib` : (_option_) name of the output library used when `odsn` is passed; 
* `_svy_, _lib_` : (_option_) names of the macro variable where to return the (list of) survey(s)
	and library(ies) the indicator(s) in `ind` was (were) developed for;
* `_var_, _fmt_` : (_option_) names of the macro variables where to return, resp., the (list of)
	variable(s)  and its (their) format(s) used for the estimation of the indicator(s) in `ind`;
* `_wght_` : (_option_) name of the macro variable where to return the (list of) weights used
	for the estimation of the indicator(s) in `ind`;
* `_desc_` : (_option_) name of the macro variable where to return the (list of) indicator(s)'
	description(s)/title(s).

### Example
The instructions:

~~~sas
	%let ind=DI01 DI05 DI17;
	%silc_ind_info(&ind, odsn=odsn);
~~~
will store in the dataset `odsn` the following table:
|indicator |   survey  | lib |    EQ_INC20    |    PPP    |    RATE    |    ACTSTA    |    AGE    |    RB090    |    DB100    | weight | description                                            |
|:--------:|:---------:|:---:|:--------------:|:---------:|:----------:|:------------:|:---------:|:-----------:|:-----------:|:------:|:-------------------------------------------------------|  
|   di01   | ECHP-SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ |              |           |             |	    	  | RB050a | Distribution of income by quantiles                    |
|   di05   | ECHP-SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ | fmt1_ACTSTA_ | fmt1_AGE_ | fmt1_RB090_ |	    	  | PE040  | Mean and median income by most frequent activity status|
|   di17   |      SILC | RDB | fmt1_EQ_INC20_ | fmt1_PPP_ | fmt1_RATE_ |	    	  | fmt1_AGE_ | fmt1_RB090_ | fmt1_DB100_ | RB050a | Mean and median income by deg_urb status               |

Also note the specific format of the output macro variables set by the macro, depending on the number
of indicators passed in output, _e.g._:

~~~sas
	%let ind=DI01;
	%let osvy=;
	%let olib=;
	%let ovar=;
	%let ofmt=;
	%let owght=;
	%let odesc=;
	%silc_ind_info(&ind, _wght_=owght, _fmt_=ofmt, _desc_=odesc, _svy_=osvy, _lib_=olib, _var_=ovar);
~~~
will return:
* `osvy=ECHP-SILC`,
* `olib=RDB`,
* `ovar=EQ_INC20 PPP RATE`,
* `ofmt=fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_`,
* `owght=RB050a`,
* `odesc=Distribution of income by quantiles`,

while, if one requests information about two indicators insted of one:

~~~sas
    %let ind=DI01 DI05;
	%silc_ind_info(&ind, _wght_=owght, _fmt_=ofmt, _desc_=odesc, _svy_=osvy, _lib_=olib, _var_=ovar);
~~~
the outputs will take the form of lists between parentheses:
* `osvy=(ECHP-SILC,ECHP-SILC)`,
* `olib=(RDB,RDB)`,
* `ovar=("EQ_INC20 PPP RATE","ACTSTA AGE EQ_INC20 PPP RATE RB090")`,
* `ofmt=("fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_","fmt1_ACTSTA_ fmt1_AGE_ fmt1_EQ_INC20_ fmt1_PPP_ fmt1_RATE_ fmt1_RB090_")`,
* `owght=(RB050a,PE040)`,
* `odesc=("Distribution of income by quantiles","Mean and median income by most frequent activity status")`

### Note
The `cds_varxind` configuration dataset defines the correspondance table between the various 
variables and indicators. See [%meta_variablexindicator](@ref meta_variablexindicator) for more details. 
In practice, the table looks like this:
 indicator |  survey   | lib | AGE | RB090 | ARPTXX | EQ_INC20 | ... | weight | description
:---------:|:---------:|:---:|----:|------:|:------:|:--------:|:---:|:------:|:---------------------------------------------------------
   DI01    | ECHP-SILC | RDB |     |       |        |     1    | ... | RB050a | Distribution of income by quantiles      
   DI02    | ECHP-SILC | RDB |     |       |    1   |		   | ... | RB050a | Distribution of income by different income groups             
   DI03    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by age and gender       
   DI04    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | RB050a | Mean and median income by household type        
   DI05    | ECHP-SILC | RDB |  1  |   1   |        |	  1    | ... | PB040  | Mean and median income by most frequent activity status   
   ...     |    ...    | ... | ... |  ...  |   ...  |    ...   | ... |  ...   | ...

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%silc_db_select](@ref sas_silc_db_select).
