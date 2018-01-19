/** 
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
[%income_components_gini](@ref sas_income_components_gini).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro gini(dsn				/* Name of the input dataset 								(REQ) */
			, x				/* Variable on which the Gini index is computed 			(REQ) */
			, _gini_=		/* Name of the output macro variable storing the Gini index (REQ) */
			, weight=1		/* Weight/frequency defined as a variable OR a constant 	(OPT) */
			, method=		/* Method used to compute the Gini index 					(OPT) */
			, issorted=no	/* Boolean flag set when input data are already sorted 		(OPT) */
			, lib=			/* Input library 											(OPT) */		
			);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* check that the method is accepted */
	%local METHODS 	/* dummy selection */
		SEP			/* arbitrary separator */	
		ans;		/* temporary test variable */
	%let SEP=%str( );
	%let METHODS=LAEKEN CANONICAL; /* list of possible methods for GINI calculation */

	/* _GINI_ : check/set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_gini_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _GINI_ not set !!!) %then
		%goto exit;

	/* DSN/LIB : check/set */
	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input dataset %upcase(&dsn) not found !!!)) %then
		%goto exit;

	/* METHOD : check/set */
	%if %macro_isblank(method) %then 	%let method=LAEKEN;
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&method), type=CHAR, set=&METHODS) NE 0, mac=&_mac,		
			txt=%quote(!!! Input parameter %upcase(&method) not defined as a Gini estimation method !!!)) %then
		%goto exit;

	/* ISSORTED : check/set */
	%if %macro_isblank(issorted) %then 	%let issorted=NO;
	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&issorted), type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for input boolean flag ISSORTED !!!)) %then
		%goto exit;
		 	
	/* X : check that the variables used in the calculation exist */
	%ds_isempty(&dsn, var=&x, _ans_=ans, lib=&lib);
	%if %macro_isblank(ans) or &ans=1
		/* %error_handle(ErrorInputParameter, 
			%macro_isblank(ans) or &_ans=1,		
			txt=!!! Variable %upcase(&x) does not exist (or is empty) in dataset &idsn !!!) */ %then
		%goto exit;

	/* WEIGHT : check/set */
	%if %datatyp(&weight)^=NUMERIC %then %do; 
		%ds_isempty(&dsn, var=&weight, _ans_=ans, lib=&lib);
		/* note that ds_isempty also checks that the variable exists (if it does not, it returns
		* an empty variable _ans) */
		%if %macro_isblank(ans) or &ans=1 %then
			%goto exit;
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local;
	%let tmp=TMP&_mac;

	%if %upcase("&issorted") = "NO" %then %do;
		/* check that indeed some variables were passed for sorting */
		PROC SORT DATA=&lib..&dsn OUT=&tmp;
			BY &x;
		run;
	%end;
	%else 
		%let tmp=&lib..&dsn; /* do nothing: just pass the name */

	%if %upcase("&method")="LAEKEN" %then %do;
		DATA _null_;
			SET &tmp end=__last;
			retain swt swtvar swt2var swtvarcw ss 0;
			xwgh = &weight * &x;
			ss + 1;
			swt + &weight;				/* sum of weigths */
			swtvar + xwgh;				/* weigthed sum of x */
			swt2var + &weight * xwgh;	
			swtvarcw + swt * xwgh;
			if __last then
			do;
				gini = 100 * (( 2 * swtvarcw - swt2var ) / ( swt * swtvar ) - 1);
				call symput("&_gini_",gini);
			end;
		run;
	%end;
	%else %if %upcase("&method")="CANONICAL" %then %do; 
		DATA &tmp (KEEP=gini);
			if _N_ = 1 then do UNTIL (last);
				SET &tmp end=last;
				swt + &weight ;
				swtey + (&weight*&x) ;
			end;
			SET &tmp end=eof;
			if _N_ = 1 then do;
				prewt = 0 ;
				preey = 0 ;
				up = 0 ;
				sum = 0 ;
			end;
			cwt + &weight ;
			cwtey + (&x*&weight) ;
			pcwt = cwt / swt * 100 ;
			pcwtey = cwtey / swtey * 100 ;
			up=(pcwt-prewt) * (pcwtey+preey);
			sum + up ;
			prewt = pcwt ;
			preey = pcwtey ;
			retain prewt preey ;
			if eof then do;
				gini = 100 - (sum / 100) ;
				call symput("&_gini_",gini);
			output;
			end;
		run;
	%end;

	%work_clean(&tmp);	

	%exit:
%mend gini;

%macro _example_gini;
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

	data gini0;
		p="A"; x=1; output;
		p="B"; x=1; output;
		p="C"; x=1; output;
		p="D"; x=1; output;
		p="E"; x=1; output;
		p="F"; x=1; output;
		p="G"; x=1; output;
	run;

	data gini71_1;
		p="A"; x=1; output;
		p="B"; x=1; output;
		p="C"; x=1; output;
		p="D"; x=1; output;
		p="E"; x=1; output;
		p="F"; x=1; output;
		p="G"; x=1; output;
		p="H"; x=10; output;
		p="I"; x=33; output;
		p="J"; x=50; output;
	run;

	data gini71_2;
		p="A"; x=1;  w=7; output;
		p="B"; x=10; w=1; output;
		p="C"; x=33; w=1; output;
		p="D"; x=50; w=1; output;
	run;

	data gini21_1;
		p="A"; x=5; output;
		p="B"; x=5; output;
		p="C"; x=5; output;
		p="D"; x=10; output;
		p="E"; x=10; output;
		p="F"; x=10; output;
		p="G"; x=10; output;
		p="H"; x=15; output;
		p="I"; x=15; output;
		p="J"; x=15; output;
	run;

	data gini21_2;
		p="A"; x=5; w=3; output;
		p="B"; x=10; w=4; output;
		p="C"; x=15; w=3; output;
	run;

	data gini10;
		p="A"; x=2; w=3; output;
		p="C"; x=3; w=2; output;
	run;

	%local gini ogini;

	%put (i) Dummy test: default values do not exist in dataset;
	%let method=Marinastyle;
	%gini(gini0, x, _gini_=gini, method=&method);
	%if %macro_isblank(gini) %then 		%put OK: TEST PASSED - Method %upcase(&method) recognised as wrong method;
	%else 								%put ERROR: TEST FAILED - Method %upcase(&method) NOT recognised as wrong method;

	%put (ii) Test Gini index of uniform distribution: gini0;
	%gini(gini0, x, _gini_=gini);
	%let ogini=0;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for uniform gini0 dataset;
	%else 						%put ERROR: TEST FAILED - Wrong Gini index &gini returned for uniform gini0 dataset;

	%put (iii) Test Gini index of another distribution: gini71_1, no weight;
	%gini(gini71_1, x, _gini_=gini, issorted=YES);
	%let ogini=71;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini71_1 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini71_1 datase;

	%put (iv) Test Gini index of same distribution: gini71_2, with weight;
	%gini(gini71_2, x, weight=w, _gini_=gini);
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini71_2 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini71_2 datase;

	%put (v) Test Gini index of another distribution: gini21_1, no weight;
	%gini(gini21_1, x, _gini_=gini);
	%let ogini=21;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini21_1 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini21_1 datase;

	%put (vi) Test Gini index of same distribution: gini21_2, with weight;
	%gini(gini21_2, x, weight=w, _gini_=gini);
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini21_2 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini21_2 datase;

	%put (vii) Test Gini index of another distribution: gini10, with weight;
	%gini(gini10, x, weight=w, _gini_=gini);
	%let ogini=10;
	%if &gini EQ &ogini %then 		%put OK: TEST PASSED - Gini index &ogini returned for gini10 dataset;
	%else 							%put ERROR: TEST FAILED - Wrong Gini index &gini returned for gini10 datase;

	%put;
	
	%work_clean(gini0);	
	%work_clean(gini10);	
	%work_clean(gini71_1);	
	%work_clean(gini71_2);	
	%work_clean(gini21_1);	
	%work_clean(gini21_2);	

	%exit:
%mend _example_gini;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_gini; 
*/

/** \endcond */

