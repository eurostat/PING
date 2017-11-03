/** 
## _DSTEST45 {#sas_DSTEST45}
Test dataset #45.

	%_DSTEST45;
	%_DSTEST45(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_DSTEST45`:
DB020 | DB010 |   RB030  |EQ_INC20 | RB050a
------|-------|----------|---------|-------
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

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_DSTEST45`.

### Example
To create dataset #35 in the `WORK`ing directory and print it, simply launch:
	
	%_DSTEST45;
	%ds_print(_DSTEST45);

### See also
[%_dstestlib](@ref sas_dstestlib).
*/ /** \cond */

%macro _DSTEST45(lib=, _ds_=, verb=no, force=no);
 	%local _dsn _ilib;
	%let _dsn=&sysmacroname;
	%_dstestlib(&_dsn, _lib_=_ilib);

	%if %macro_isblank(_ilib) or &force=yes %then %do;	
		%if &verb=yes %then %put dataset &_dsn is created ad-hoc;
		%let _ilib=WORK;
		DATA &_ilib..&_dsn;
			DB020='BE'; DB010=2015; RB030=3310; EQ_INC20=10; RB050a=10; output ;
			DB020='BE'; DB010=2015; RB030=3311; EQ_INC20=10; RB050a=10; output ;
			DB020='BE'; DB010=2015; RB030=3312; EQ_INC20=60; RB050a=10; output ;
			DB020='BE'; DB010=2015; RB030=4434; EQ_INC20=20; RB050a=20; output ;
			DB020='BE'; DB010=2015; RB030=4435; EQ_INC20=10; RB050a=20; output ;
			DB020='BE'; DB010=2015; RB030=4455; EQ_INC20=30; RB050a=20; output ;
			DB020='BE'; DB010=2015; RB030=55667;EQ_INC20=40; RB050a=20; output ;
			DB020='IT'; DB010=2015; RB030=999998;EQ_INC20=10; RB050a=10; output ;
			DB020='IT'; DB010=2015; RB030=999999;EQ_INC20=50; RB050a=10; output ;
			DB020='IT'; DB010=2015; RB030=999900;EQ_INC20=50; RB050a=10; output ;
			DB020='IT'; DB010=2015; RB030=777777;EQ_INC20=30; RB050a=20; output ;
			DB020='IT'; DB010=2015; RB030=777790;EQ_INC20=30; RB050a=20; output ;
			DB020='IT'; DB010=2015; RB030=555578;EQ_INC20=20; RB050a=20; output ;
			DB020='IT'; DB010=2015; RB030=778900;EQ_INC20=50; RB050a=20; output ;


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

%mend _DSTEST45;

%macro _example_DSTEST45;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autocall/_setup_.sas";
		%_default_setup_;
	%end;
	
	%_DSTEST45(lib=WORK);
	%put Test dataset is generated in WORK library as: _DSTEST45;
	%ds_print(_DSTEST45);

	*%work_clean(_DSTEST45);
%mend _example_DSTEST45;

/*
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_DSTEST45; 
*/

/** \endcond */
