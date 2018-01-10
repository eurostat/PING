## gini {#sas_gini}
Compute the Gini index of a set of observations. 

~~~sas
	%gini(dsn, var, weight=, _gini_=, method=, issorted=no, lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference with continuous observations;
* `var` : variable of the input dataset `dsn` on which the Gini index will be computed;
* `weight` : (_option_) weight (frequencies), either a variable in `dsn` to use to weight 
	the values of `var`, or a constant value; default: `weight=1`, _i.e._ it is not used;
* `method` : (_option_) method used to compute the Gini index; it can be: `LAEKEN`, or 
	`CANONICAL`; default: `LAEKEN`, _i.e._ the formula used for computing the Gini index 
	(which is 100* Gini coefficient) as:

        gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1)
* `issorted` : (_option_) boolean flag (`yes/no`) set when the input data is already sorted;
	default: `issorted=no`, and the input will be sorted;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
`_gini_` : name of the macro variable storing the value of the Gini index.

### Examples
Considering the following datasets `gini10_1`:
Obs| x
---|---
 A | 2 
 A | 2 
 A | 2 
 B | 3 
 B | 3 
and `gini10_2`;
Obs| x | w
---|---|---
 A | 2 | 3
 B | 3 | 2
both calls to the macro:

~~~sas
	%let gini=;
	%gini(gini10_1, x, _gini_=gini);
	%gini(gini10_2, x, weight=w, _gini_=gini);
~~~
actually return the Gini index: `gini=10`.

Run macro `%%_example_gini` for examples.

### Note
The default `LAEKEN` method implements the approach of Alfons & Templ. In short, this means 
that the macro `%%gini` runs the following `DATA` step over already sorted data:

~~~sas
		DATA _null_;
			SET &lib..&dsn end=__last;
			retain swt swtvar swt2var swtvarcw ss 0;
			xwgh = &weight * &x;
			ss + 1;
			swt + &weight;
			swtvar + xwgh;
			swt2var + &weight * xwgh;
			swtvarcw + swt * xwgh;
			if __last then
			do;
				gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
				call symput("&_gini_",gini);
			end;
		run;
~~~

### References
1. Gastwirth, J. L. (1972). ["The estimation of the Lorenz curve and Gini index"](http://www.jstor.org/stable/1937992), The Review of Economics and Statistics, 306-316.
2. Templ, M. and Alfons, A. (2011): ["Variance Estimation of Indicators on Social Exclusion and Poverty using the R Package laeken"](https://cran.r-project.org/web/packages/laeken/vignettes/laeken-variance.pdf).
3. Yitzhaki, S. and  Schechtman, E. (2012): ["More than a dozen alternative ways of spelling Gini"](http://dx.doi.org/10.1007/978-1-4614-4720-7_2).
4. Alfons, A. and Templ, M. (2014): ["Estimation of social exclusion indicators from complex surveys: The R package laeken"](https://cran.r-project.org/web/packages/laeken/vignettes/laeken-intro.pdf).
5. Creedy, J. (2015): ["A note on computing the Gini inequality measure with weighted data"](http://www.victoria.ac.nz/sacl/about/cpf/publications/pdfs/2015-pubs/WP03_2015_Gini_Inequality.pdf).
6. Web link on [Gini Coefficient of inequality](http://www.statsdirect.com/help/default.htm#nonparametric_methods/gini.htm).

### See also
[%silc_income_gini](@ref sas_silc_income_gini), [%income_components_gini](@ref sas_income_components_gini).
