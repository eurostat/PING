/** 
## silc_selective_export {#sas_data_selective_export}
Perform selective export of a dataset to any format accepted by `PROC EXPORT`.

~~~sas
	%silc_selective_export(idsn, time=, geo=, idir=, ilib=, odir=, _ofn_=, fmt=csv);
~~~

### Arguments
* `idsn` : input dataset(s) to export;
* `geo` : (_option_) a list of countries or a geographical area; default: `geo=`, or 
	`geo=_ALL_VALUES_`, so that the whole dataset will be exported; in practice, a `where` 
	clause is created using this list; 
* `time` : (_option_) year(s) of interest; default: `time=`, or `time=_ALL_VALUES_`, so that 
	the whole dataset will be exported; ibid `geo`;
* `idir` : (_option_) name of the input directory where to look for input datasets, passed 
	instead of `ilib`; incompatible with `ilib`; by default, `ilib` will be set to the current 
	directory; 
* `ilib` : (_option_) name of the input library where to look for input datasets; incompatible 
	with `idir`; by default, it is not used.

### Returns
* `_ofn_` : (_option_) name (string) of the macro variable storing the output exported file 
	name(s);
* `odir` : (_option_) output directory/library to store the converted dataset; by default,
	it is set to:
			+ the location of your project if you are using SAS EG (see [%_egp_path](@ref sas__egp_path)),
			+ the path of `%sysget(SAS_EXECFILEPATH)` if you are running on a Windows server,
			+ the location of the library passed through `ilib` (_i.e._, `%sysfunc(pathname(&ilib))`) 
			otherwise.

### See also
[%ds_export](@ref sas_ds_export), [%ds_select](@ref sas_ds_select).
*/ /** \cond */

/* credits: grazzja */

%macro silc_selective_export(idsn		/* Input dataset(s)									(REQ) */
							, time=		/* Input year under consideration 					(OPT) */ 
							, geo=		/* Input country under consideration 				(OPT) */
							, idir=		/* Input directory name								(OPT) */
							, ilib=		/* Input library name 								(OPT) */
							, odir=		/* Full path of output directory 					(OPT) */
							, drop= 	/* Names of variables to be dropped					(OPT) */
							, _ofn_=	/* Name of the variable storing the output filename (OPT) */
							, fmt=		/* Format of import 							    (OPT) */
							);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _islibtemp
		YEARINIT;
	%let _islibtemp=0;

	/* TIME: check the year of interest */
	%if %upcase("&time")="_ALL_VALUES_" %then 	%let time=;

	%if not %macro_isblank(time) %then %do; 
		%if %symexist(G_PING_INITIAL_YEAR) %then 	%let YEARINIT=&G_PING_INITIAL_YEAR;
		%else										%let YEARINIT=2002;

		%if %error_handle(ErrorInputParameter, 
				%par_check(&time, type=INTEGER, range=&YEARINIT) NE 0,	mac=&_mac,
				txt=%bquote(!!! Wrong value for TIME parameter: must be integer >&YEARINIT !!!)) %then
			%goto exit;
	%end;

	/* GEO: check/set input ISO-code */
	%if %upcase("&geo")="_ALL_VALUES_" %then 	%let geo=;

	%if not %macro_isblank(geo) %then %do; 
		%local ans;
		%str_isgeo(&geo, _ans_=ans);

		%if %error_handle(ErrorInputParameter, 
				&ans NE %list_ones(%list_length(&geo), item=1), mac=&_mac,
				txt=%bquote(!!! Wrong value(s) for GEO parameter: &geo - Must be country ISO-code(s) !!!)) %then
			%goto exit;		
	%end;

	/* IDIR/ILIB: check/set default input library */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idir) EQ 0 and %macro_isblank(ilib) EQ 0, mac=&_mac,
			txt=%quote(!!! Incompatible parameters IDIR and ILIB: set one only !!!)) %then
		%goto exit;
	%else %if %macro_isblank(ilib) %then %do;
		%let _islibtemp=1;
		%if %macro_isblank(idir) %then %do;
			%if %symexist(_SASSERVERNAME) %then 
				%let idir=&G_PING_ROOTPATH/%_egp_path(path=drive);
			%else %if &sysscp = WIN %then %do; 
				%let idir=%sysget(SAS_EXECFILEPATH);
				%if not %macro_isblank(idir) %then
					%let idir=%qsubstr(&odir, 1, %length(&idir)-%length(%sysget(SAS_EXECFILENAME));
			%end;
		%end;
		libname lib "&idir"; 
		%let ilib=lib;
	%end;

	/* ODIR: default setting and checking odir */
	%if %macro_isblank(odir) %then %do; 
		/*%if %symexist(_SASSERVERNAME) %then 
			%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 
			%let odir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(odir) %then
				%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
		%end;*/
		%let odir=%sysfunc(pathname(&ilib)); 
	%end;

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(odir) EQ 1, mac=&_mac,		
			txt=%quote(!!! Output directory %upcase(&odir) not set !!!))
			or %error_handle(ErrorInputParameter, 
				%dir_check(&odir) NE 0, mac=&_mac,		
				txt=%quote(!!! Output directory %upcase(&odir) does not exist !!!)) %then
		%goto exit;

	/* DROP */
		%put in &_mac drop=&drop;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(drop) EQ 1, mac=&_mac,		
			txt=%quote(! No variable to drop !), verb=warn) %then
		%goto warning;
	%warning:

	/* FMT */
	%if %macro_isblank(fmt) %then 		%let fmt=csv;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i _ofn _idsn _tmplib
		where
		_var _ans
		l_GEO l_TIME TMP SEP;
	%let SEP=%quote( );
	%let TMP=_tmp&_mac;
	%let where=;

	%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
	%else										%let l_GEO=geo;
	%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
	%else										%let l_TIME=time;

	%if not (%macro_isblank(geo) and %macro_isblank(time)) %then %do;
		%local where;
		%let where=;
		%if not %macro_isblank(geo) %then %do;
			%let where=&l_GEO in %sql_list(&geo);
		%end;
		%if not (%macro_isblank(geo) or %macro_isblank(time)) %then %do;
			%let where=&where. and;
		%end;
		%if not %macro_isblank(time) %then %do;
			%let where=&where. &l_TIME in %sql_list(&time);
		%end;
	%end;

	%if not %macro_isblank(_ofn_) %then 	
		%let &_ofn_=;

	%do _i=1 %to %list_length(&idsn);
		/* perform selective extraction if requested */
		%let _var=;
		%let _idsn=%scan(&idsn, &_i);
		%if not (%macro_isblank(geo) and %macro_isblank(time) and %macro_isblank(drop)) %then %do;
			%ds_contents(&_idsn, _varlst_=_var, varnum=yes, lib=&ilib); 
			%if not %macro_isblank(drop) %then
				%let _var=%list_difference(&_var, &drop);
			%ds_select(&_idsn, &_idsn, where=%quote(&where), var=&_var, ilib=&ilib, olib=WORK);
			%let _tmplib=WORK;
		%end;
		%else 
			%let _tmplib=&ilib;

		/* check that the dataset is not empty */
		%let _ans=;
		%ds_isempty(&_idsn, _ans_=_ans, lib=&_tmplib);
		%if %error_handle(ErrorInputParameter, 
				&_ans NE 0, mac=&_mac,		
				txt=%quote(! Dataset %upcase(&_idsn) is empty - Nothing to export !), verb=warn) %then
			%goto next;

		/* do the actual export */
		%let _ofn=;
		%ds_export(&_idsn, odir=&odir, _ofn_=_ofn, fmt=&fmt, ilib=&_tmplib);
		%if not %macro_isblank(_ofn_) %then 
			%let &_ofn_=&&&_ofn_ &_ofn;
		%if not (%macro_isblank(geo) and %macro_isblank(time)) %then %do;
			%work_clean(&_idsn);
		%end;

		%next:
	%end;

	%if &_islibtemp=1 %then %do;
		libname lib clear;
	%end;
	
	%exit:
%mend silc_selective_export;

/*test
%let idir=/ec/prod/server/sas/0eusilc/5.5_Modules/participation_deprivation_2015/data;
%let idsn=eusilcprod218_3;
%silc_selective_export(&idsn, idir=&idir, time=2015, geo=AT);
/**/

/** \endcond */
