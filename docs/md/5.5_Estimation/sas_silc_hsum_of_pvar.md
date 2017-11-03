## silc_hsum_of_pvar {#sas_silc_hsum_of_pvar}
Sum P varibale by row and  columns

~~~sas
	%silc_hsum_of_pvar(yyyy, odsn=,ds=,var=,rvar=,ovar=,by=,lib=pdb, olib=WORK);
~~~
		   				
### Arguments
* `yyyy` : reference year;  
* `odsn` : a output dataset;
* `ds`   : type of input dataset ;
* `var`  : name of variable on which the sum is calculated;
* `by`   : list of variables used for GROUP BY condition in SQL statement; by default: empty, _i.e._ `PB010 PB020 PHID` is used;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `pdb` is used;
  
### Returns
* `odsn` : (_option_) name of the output dataset (in `WORK` library);by default: empty, _i.e._ `hsum` is used;
* `ovar` :  sum variable ;by default: empty, _i.e._ `hsum` is used;
* `rvar` :  sumrow P  variables ;by default: empty, _i.e._ `Ptot` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is used;
	is used.

### Examples
Let us consider the test dataset #45:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a
:----:|:-----:|----------:--------:|---------
 BE   | 2015  |   3310   |   10    |   10 
 BE   | 2015  |   3311   |   10    |   10 
 BE   | 2015  |   3312   |   10    |   10 
 BE   | 2015  |   4434   |   20	   |   20 


and run the macro:
	
~~~sas
	%silc_hsum_of_pvar();
~~~
which updates QUANTILE with the following table:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a | QUINTILE |    QUANTILE
:----:|:-----:|:--------:|:-------:|:------:|:--------:|:------------:
  BE  |	2015  |	  3310	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  3311	 |   10	   |  10	|     1    |  QUINTILE  1

 
Run macro `%%_example_income_quantile` for more examples.

### Notes
1. In short, the macro runs the following `PROC SORT` procedure:

~~~sas
	PROC SQL noprint;
		CREATE TABLE &olib..&_dsn AS 
		SELECT
			input.*,		    
			%if %macro_isblank(Pvar) EQ 0 %then %do;
				 sum(&_Pvar,0) as Ptot,
			%end;
			sum(calculated Ptot) as &ovar
		FROM Ppdb.&Pds as input 
		GROUP BY &_by;
	 QUIT;
~~~

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
