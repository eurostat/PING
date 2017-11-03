 /** 
## _DSTEST40 {#sas_dstest40}
Test dataset #40.

	%_dstest40;
	%_dstest40(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest40`:
geo | DB010 | AGE | RB090 | HT1 | RB050a | HH040
----|-------|-----|-------|-----|--------|-----
 BE	| 2014	| 25  |	  1   | 10  |   10   | YES
 BE	| 2014	| 35  |	  2   |	9   |   10   | YES
 BE	| 2014	| 22  |	  2	  | 11  |   10   | YES
 BE	| 2014	| 20  |	  1	  |  8  |   20   | YES
 BE	| 2014	| 18  |	  1	  |  4  |   20   | YES
 BE	| 2014	| 40  |	  2	  |  8  |   20   | YES
 BE	| 2014	| 41  |	  1	  |  2  |   20   | NO
 IT	| 2014	| 42  |	  1	  |  2  |   10   | NO
 IT	| 2014	| 49  |	  1	  |  2  |   10   | NO
 IT	| 2014	| 27  |	  1	  |  1  |   10   | NO
 IT	| 2014	| 28  |	  2	  | 10  |   20   | NO
 IT	| 2014	| 30  |	  2	  | 10  |   20   | NO
 IT	| 2014	| 18  |	  2	  | 10  |   20   | NO
 IT	| 2014	| 20  |	  1	  | 10  |   20   | NO


### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest35`.

### Example
To create dataset #40 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest40;
	%ds_print(_dstest40);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _dstest40(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			geo='BE';  DB010=2014; AGE=25; RB090=1;HT1=10; RB050a=10; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=35; RB090=2;HT1=9;  RB050a=10; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=22; RB090=2;HT1=11; RB050a=10; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=20; RB090=1;HT1=8;  RB050a=20; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=18; RB090=1;HT1=4;  RB050a=20; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=40; RB090=2;HT1=8;  RB050a=20; HH040='YES';output ;
			geo='BE';  DB010=2014; AGE=41; RB090=1;HT1=2;  RB050a=20; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=42; RB090=1;HT1=2;  RB050a=10; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=49; RB090=1;HT1=2;  RB050a=10; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=27; RB090=1;HT1=1;  RB050a=10; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=28; RB090=2;HT1=10; RB050a=20; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=30; RB090=2;HT1=10; RB050a=20; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=18; RB090=2;HT1=10; RB050a=20; HH040='NO'; output ;
			geo='IT';  DB010=2014; AGE=20; RB090=1;HT1=10; RB050a=20; HH040='NO'; output ;
		run;
	%end;
	%else %do;
		%if &verb=yes %then %put dataset &_dsn already exists in library &_ilib;
	%end;

	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if "&lib"^="&_ilib" %then %do;
		/* %ds_merge(&_dsn, &_dsn, lib=&_ilib, olib=&lib); */
		DATA &lib..&_dsn;
			set &_ilib..&_dsn;
		run; 
		%if &_ilib=WORK %then %do; /* but lib is not WORK */
			%work_clean(&_dsn);
		%end;
	%end;

	%if not %macro_isblank(_ds_) %then %do;
		data _null_;
			call symput("&_ds_", "&lib..&_dsn");
		run; 
	%end;		

%mend _dstest40;

%macro _example_dstest40;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_dstest40(lib=WORK);
	%put Test dataset is generated in WORK library as: _dstest35;
	%ds_print(_dstest40);

	*%work_clean(_dstest40);
%mend _example_dstest40;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_dstest40; 
*/

/** \endcond */
