/**
## var_to_clist {#sas_var_to_clist}
Return the observations of a given variable in a dataset into a formatted (_e.g._, parentheses-enclosed, 
comma-separated and/or quote-enhanced) list of strings.

~~~sas
	%var_to_clist(dsn, var, by=, _varclst_=, distinct=no, mark=%str(%"), sep=%str(,), lib=WORK);
~~~

### Arguments
* `dsn` : a dataset reference;
* `var` : either a field name, or the position of a field name in, in `dsn`, whose values (observations) 
	will be converted into a list;
* `by` : (_option_) a variable to further split the dataset into subsets (using [%ds_split](@ref sas_ds_split)), 
	one for each value of `by` prior to extract the observations; the final list (see `_varclst_`)
	is obtained as the concatenation of the different extractions obtained for each subset, in the order
	of appearance of `by` values in the dataset `dsn`; `by` must differ from `var`; default: empty,
	_i.e._ `by` is not used;
* `distinct` : (_option_) boolean flag (`yes/no`) set to return in the list only distinct values
	from `var` variable; in practice, runs a SQL `SELECT DISTINCT` process prior to the values'
	extraction; default: `no`, _i.e._ all values are returned;
* `na_rm` : (_option_) boolean flag (`yes/no`) set to remove missing (NA) values from the observations;
	default: `na_rm=yes`, therefore all missing (`.` or ' ') values will be discarded in the output
	list;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep= %%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details; note in particular the use of `mark=_EMPTY_` to actually set `mark=%%quote()`;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`_varclst_` : name of the macro variable used to store the output formatted list, _i.e._ the list 
	of (comma-separated) main observations in between quotes.

### Examples
Let us consider the test dataset #32 in `WORK.dsn`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5
then running the macro:
	
~~~sas
	%let ctry=;
	%var_to_clist(_dstest32, geo, _varclst_=ctry);
	%var_to_clist(_dstest32,   1, _varclst_=ctry);
~~~
will both return: `ctry=("BE","AT","BG","LU","FR","IT")`, while:

~~~sas
	%let val=;
	%var_to_clist(_dstest32, value, _varclst_=val, distinct=yes, lib=WORK);
~~~	
will return: `val=("0","0.1","0.2","0.3","0.4","0.5")`. Let us know consider the table `_dstest3`:
| color | value |
|:-----:|------:|
|  blue |   1   |
|  blue |   2   |
|  blue |   3   |
| green |   3   |
| green |   4   |
|  red  |   2   |
|  red  |   3   |
|  red  |   4   |

it is possible to retrieve the observations  by variable using the following instructions:

~~~sas
	%let val1=;
	%var_to_clist(_dstest3, value, by = color, _varclst_=val1, mark=_EMPTY_);
~~~
which returns the list `val1=(1 2 3,3 4,2 3 4)` of `value` observations for distinct `color` 
observations (say it otherwise: the first sequence of numbers is the list of `value` observations 
for `blue`, ibid the second for `green`, ibid the third for `red`), and:

~~~sas
	%let val2=;
	%var_to_clist(_dstest3, color, by = value, _varclst_=val2);
~~~
which returns the list `val2=("blue","blue red","blue green red","green red")` of `color` observations 
for distinct `value` observations.

Run macro `%%_example_var_to_clist` for more examples.

### Note
The option `by` is not available for the macro [%var_to_list](@ref sas_var_to_list) which `var_to_clist`
derives from. 

### See also
[%var_to_list](@ref sas_var_to_list), [%clist_to_var](@ref sas_clist_to_var), [%var_info](@ref sas_var_info), 
[%list_quote](@ref sas_list_quote), [%ds_split](@ref sas_ds_split).
*/ /** \cond */

/* credits: gjacopo, marinapippi */

%macro var_to_clist(dsn			/* Input dataset 														(REQ) */
				, var 			/* Name of the variable in the input dataset 							(REQ) */ 
			    , _varclst_=	/* Name of the output formatted list of observations in input variable 	(REQ) */
				, by = 
				, distinct= 	/* Distinc clause 														(OPT) */
				, na_rm=		/* Boolean flag set to remove missing (NA) values from the observations (OPT) */
				, mark=			/* Character/string used to quote items in the input list 				(OPT) */
				, sep=			/* Character/string used as list separator 								(OPT) */
				, lib=			/* Input library 														(OPT) */
				);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local REP		/* arbitrarily chosen replacement of list separator */
		SEP;

	/* VAR, _VARCLST_: checking */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Output parameter VAR not set !!!))
			or %error_handle(ErrorOutputParameter, 
				%macro_isblank(_varclst_) EQ 1, mac=&_mac,		
				txt=%quote(!!! Output parameter _VARCLST_ not set !!!)) %then
		%goto exit;

	/* BY: check exitence/compatibility */
	%if not	%macro_isblank(by) %then %do;
		%if %error_handle(ErrorInputParameter, 
				&var EQ &by, mac=&_mac,		/* note: we dont test the case VAR is passed as a position... */
				txt=%quote(!!! Fields VAR and BY must differ !!!))
				or %error_handle(ErrorInputParameter, 
					%var_check(&dsn, &by, lib=&lib) NE 0, mac=&_mac,		
					txt=%quote(!!! Field %upcase(&by) not found in dataset %upcase(&dsn) !!!)) %then
			%goto exit;
	%end;

	/*%if %macro_isblank(mark) %then %let mark=%str(%");
	%if %macro_isblank(sep) %then %let sep=%str(,);*/

	/* SEP, REP: setting */
	%let SEP=%quote( );
	%if %symexist(G_PING_UNLIKELY_CHAR) %then 		%let REP=%quote(&G_PING_UNLIKELY_CHAR);
	%else											%let REP=$;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local __varlst 	/* intermediary unformatted list used by var_to_list */
		__varclst;  /* intermediary formatted list used by list_quote */

	%if %macro_isblank(by) %then %do;
		%var_to_list(&dsn, &var, _varlst_=__varlst, distinct=&distinct, na_rm=&na_rm, sep=&REP, lib=&lib);
	%end;
	%else %do;
		%local _i
			_odsn
			_tmpdsn
			_tmpvarlst
			_count;
		%ds_split(&dsn, var=&by, oname=TMP_&_mac, _odsn_=_odsn, ilib=&lib, olib=WORK);
		%let _count=%list_length(&_odsn);
		%do _i=1 %to &_count;
			%let _tmpdsn=%scan(&_odsn, &_i);
			%var_to_list(&_tmpdsn, &var, _varlst_=_tmpvarlst, distinct=&distinct, na_rm=&na_rm, sep=&SEP, lib=&lib);
			%if %macro_isblank(__varlst) %then 		%let __varlst = &_tmpvarlst;
			%else 									%let __varlst = &__varlst.&REP.&_tmpvarlst;
			%work_clean(&_tmpdsn);
		%end;
	%end;

	/* transform back into a quoted list; note the inversion of parameters sep/REP */
	%let __varclst=(%list_quote(&__varlst, mark=&mark, sep=&REP, rep=&sep));

	/* set the output variable (whose name is &_varclst_) to the value of __varclist */
	%let &_varclst_=&__varclst;
	/*data _null_;
		call symput("&_varclst_",%nrbquote(&__varclist));
	run;*/

	%exit:
%mend var_to_clist;


%macro _example_var_to_clist;
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

	%local a ctry octry val oval;

	%put;
	%put (i) Retrieve the empty variable A from _dstest1...;
	%_dstest1;
	%var_to_clist(_dstest1, A, _varclst_=a);
	%if %macro_isblank(a) %then %put OK: TEST PASSED - Empty list retrieved from empty in _dstest1;
	%else 						%put ERROR: TEST FAILED - Wrong list returned from empty in _dstest1;

	%_dstest32; /* create the test dataset #32 in WORK directory */
	%*ds_print(_dstest32);

	%put;
	%put (ii) Retrieve the list of GEO countries in test dataset #32...;
	%let octry=("BE","AT","BG","LU","FR","IT");
	%var_to_clist(_dstest32, geo, _varclst_=ctry);
	%if &ctry EQ &octry %then 	%put OK: TEST PASSED - List &octry returned from GEO in _dstest32;
	%else 						%put ERROR: TEST FAILED - Wrong list returned from GEO in _dstest32;

	%let oval=("0","0.1","0.2","0.3","0.4","0.5");
	%put;
	%put (iii) Retrieve the list of VALUE of test dataset #32...;
	%let val=;
	%var_to_clist(_dstest32, value, _varclst_=val, lib=WORK);
	%if &val EQ &oval %then 	%put OK: TEST PASSED - List &oval returned from VALUE in _dstest32;
	%else 						%put ERROR: TEST FAILED - Wrong list returned from VALUE in _dstest32;

	%put;
	%put (iv) Retrieve the list of (missing or not) VALUE in test dataset #28 using the option NA_RM;
	%_dstest28;
	%let oval=("1",".","2","3",".","4");
	%let val=;
	%var_to_clist(_dstest28, value, _varclst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 	%put OK: TEST PASSED - List of (missing or not) VALUE returned for _dstest28: &oval;
	%else 						%put ERROR: TEST FAILED - Wrong list of (missing or not) VALUE returned for _dstest28: &val;

	%put;
	%put (v) Same operation passing this time var as a varnum position, instead of a field: varnum=2;
	%let val=;
	%var_to_clist(_dstest28, 2, _varclst_=val, na_rm=no, lib=WORK);
	%if &val EQ &oval %then 	%put OK: TEST PASSED - List of (missing or not) VALUE returned for _dstest28: &oval;
	%else 						%put ERROR: TEST FAILED - Wrong list of (missing or not) VALUE returned for _dstest28: &val;

	%_dstest3;

	%put;
	%put (vi) Retrieve the list of COLOR by VALUE;
	%let oval=("blue","blue red","blue green red","green red");
	%let val=;
	%var_to_clist(_dstest3, color, by = value, _varclst_=val);
	%if &val EQ &oval %then 	%put OK: TEST PASSED - List of COLOR by VALUE returned for _dstest3: &oval;
	%else 						%put ERROR: TEST FAILED - Wrong list of VALUE returned for _dstest3: &val;

	%put;
	%put (vii) Ibid, retrieve the list of VALUE by COLOR;
	%let oval=(1 2 3,3 4,2 3 4);
	%let val=;
	%var_to_clist(_dstest3, value, by = color, _varclst_=val, mark=_EMPTY_);
	%if &val EQ &oval %then 	%put OK: TEST PASSED - List of VALUE by COLOR returned for _dstest3: &oval;
	%else 						%put ERROR: TEST FAILED - Wrong list of VALUE returned for _dstest3: &val;

	%put;

	/* clean your shit... */
	%work_clean(_dstest1, _dstest3, _dstest28, _dstest32); 

	%exit:
%mend _example_var_to_clist;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_var_to_clist; 
*/

/** \endcond */
