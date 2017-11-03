## silc_income_quantile {#sas_silc_income_quantile}
Quantiles of an income distribution for specific year.

~~~sas
	%silc_income_quantile(idsn, var,by, label=,breakdowns=,weight=,weighted=, odsn=,lib=WORK, olib=WORK);
~~~
		   				
### Arguments
* `idsn` : a dataset reference;
* `var`  :  name of variable on which the quantiles are calculated;
* `by`   :  number of quantiles to calculate ( 10, 100,5,etc. ) ;
* `label`:  type  of quantiles to calculate  ( decile, percentile, quintile, etc.) ;
* `weight` : (_option_) name  of weight variables;default: RB050a ;
* `weighted`:(_option_) boolean variable( YES/NO) ;default: YES ; 
* `breakdowns`  : (_option_) breakdowns variables  ; 	default: DB010 DB020;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
  
### Returns
* `odsn` : (_option_) name of the output dataset (in `WORK` library);
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Examples
Let us consider the test dataset #45:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a
:----:|:-----:|---------:|--------:|--------:
 BE   | 2015  |   3310   |   10    |   10 
 BE   | 2015  |   3311   |   10    |   10 
 BE   | 2015  |   3312   |   10    |   10 
 BE   | 2015  |   4434   |   20	   |   20 
 BE   | 2015  |   4435   |   20	   |   20 
 BE   | 2015  |   4455   |   20	   |   20 
 BE   | 2015  |   55667  |   20	   |   20 
 IT   | 2015  |  999998  |   10	   |   10 
 IT   | 2015  |  999999  |   10	   |   10 
 IT   | 2015  |  999900  |   10	   |   10 
 IT   | 2015  |  777777  |   20	   |   20 
 IT   | 2015  |  777790  |   20	   |   20 
 IT   | 2015  |  555578  |   20	   |   20 
 IT   | 2015  |  778900  |   20	   |   20 

and run the macro:
	
~~~sas
	%silc_income_quantile(_DSTEST45, EQ_INC20,5,QUINTILE,weight=RB050a);
~~~
which updates QUANTILE with the following table:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a | QUINTILE |    QUANTILE
:----:|:-----:|:--------:|:-------:|:------:|:--------:|:------------:
  BE  |	2015  |	  3310	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  3311	 |   10	   |  10	|     1    |  QUINTILE  1
  BE  |	2015  |	  4435	 |   10	   |  20	| 	  1    |  QUINTILE  1
  BE  |	2015  |	  4434	 |   20	   |  20	|     2    |  QUINTILE  2
  BE  |	2015  |	  4455	 |   30	   |  20    |     3    |  QUINTILE  3
  BE  |	2015  |	 55667	 |   40	   |  20    | 	  4    |  QUINTILE  4
  BE  |	2015  |	  3312	 |   60	   |  10    |	  5    |  QUINTILE  5
  IT  |	2015  |	999998	 |   10	   |  10    |	  1    |  QUINTILE  1  
  IT  |	2015  |	555578	 |   20	   |  20	|     1    |  QUINTILE  1
  IT  |	2015  |	777777	 |   30	   |  20	|     2    |  QUINTILE  2
  IT  |	2015  |	777790	 |   30	   |  20    |     2    |  QUINTILE  2
  IT  |	2015  |	999999	 |   50	   |  10	|     4    |  QUINTILE  4
  IT  |	2015  |	999900	 |   50	   |  10	|     4    |  QUINTILE  4
  IT  |	2015  |	778900	 |   50	   |  20	|     4    |  QUINTILE  4
 
Run macro `%%_example_silc_income_quantile` for more examples.

### Notes
1. In short, the macro runs the following `PROC SORT` procedure:

~~~sas
	PROC UNIVARIATE data=&ilib..&idsn noprint;
	     var &var;
		 by &breakdowns;
		 weight &weight; 
	     output out=WORK.&_idsn pctlpre=P_ pctlpts=&nquant to 100 by &nquant;
	RUN; 
where depend on &by:
      nquant=%sysevalf(100/&by)
~~~

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[SORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000057941.htm).
