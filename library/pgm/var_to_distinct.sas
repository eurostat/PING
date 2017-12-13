/** 
## var_to_distinct {#sas_var_to_distinct}
Create a macro variable for each distinct value of a given variable in a dataset.

~~~sas
	%var_to_distinct(dsn, var, oname=, _count_=, lib=WORK);
~~~

### Arguments
* `dsn` : ; 
* `var` : ;
* `oname` : (_option_);
* `lib` : (_option_).
* `global` : (_option_) boolean flag (`yes/no`) set declare the created macro variables as
	global;

### Returns
* `_count_` : (_option_).

### References
1. Hemedinger, C. (2012): ["Implement BY processing for your entire SAS program"](http://blogs.sas.com/content/sasdummy/2012/03/20/sas-program-by-processing/).

### See also
[%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: grazzja, grillma */

%macro var_to_distinct(dsn
				, var
				, oname=
				, _count_=
				, global=
				, lib=
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(oname) %then 	%let oname=varVal;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i
		_count;

	/* retrieve the total count of distinct values */
	PROC SQL noprint;
  		SELECT strip(put(count(DISTINCT &var),15.)) 
		INTO :_count 
		FROM &lib..&dsn;
  	quit;

	%if "&global"="YES" %then %do;
		%do _i=1 %to &_count;
			%global &oname.&_i;
		%end;
	%end;

	/* create macro vars with values */
	PROC SQL noprint;
		SELECT DISTINCT &var 
		INTO :&oname.1- :&oname.&_count
		FROM &lib..&dsn;
	quit;

	%if not %macro_isblank(_count_) %then %do;
		data _null_;
			call symput("&_count_", &_count);
		run;
	%end;
%mend var_to_distinct;

%macro _example_var_to_distinct;
	%if %symexist(G_PING_SETUPPATH) EQ 0 %then %do; 
        %if %symexist(G_PING_ROOTPATH) EQ 0 %then %do;	
			%put WARNING: !!! PING environment not set - Impossible to run &sysmacroname !!!;
			%put WARNING: !!! Set global variable G_PING_ROOTPATH to your PING install path !!!;
			%goto exit;
		%end;
		%else %do;
        	%let G_PING_SETUPPATH=&G_PING_ROOTPATH./PING; 
        	%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
        	%_default_setup_;
		%end;
    %end;

	%exit:
%mend _example_var_to_distinct;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_to_distinct; 
*/

/** \endcond */

