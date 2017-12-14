/** 
## silc_ffile_export {#sas_silc_ffile_export}
Generate a flat file from a SILC indicator dataset to be uploaded on Eurobase. 

~~~sas
	%silc_ffile_export(idsn, geo, years, idir=, ilib=, ofn=, odir=, 
						key=, headkeys=, prefkey=ILC, mode=RECORDS);
~~~

### Arguments
* `idsn` : a SILC dataset;
* `geo` : a list of countries or a geographical area; default: `geo=EU28`; 
* `years` : a list of year(s) of interest;
* `ilib` : (_option_) name of the input library; by default, when not set, `ilib=WORK`;
* `idir` : (_option_) name of the input directory; incompatible with `ilib`;
* `key` : (_option_) name of the key used to indentified the indicator; when not passed, it
	is set to `&idsn`;
* `prefkey` : (_option_) prefix string for the identification of the published dataset; it is
	used before the indicator key of the disseminated dataset; for instance, for an indicator 
	named `<IND>` to be identified in Eurobase tree node as `ILC_<IND>`, `prefkey` should be 
	set to `ILC` so that the field ID keys in the flat file will appear as:

~~~sas
			`FIELDS=ILC_<IND>`
~~~
	note the use of `_EMPTY_` to set `prefkey` to a blank string; by default, it is set to: 
	`prefkey=ILC`;
* `headkeys` : (_option_) head keys (strings) used for the identification of the published 
	dataset; for instance, for an indicator named `<IND>` to be identified in Eurobase tree 
	node as `SAS.ILC.<IND>`, `headkeys` should be set to `SAS ILC` so that the field ID keys 
	in the flat file will appear as: 

~~~sas
			`FIELDS=SAS,ILC,<IND>`
~~~
	by default, it is not set: `headkeys=`;
* `mode` : (_option_) mode of upload; by default, when not set, `mode=RECORDS`.

### Returns
* `ofn` : (_option_) name of the output (text) file (without the txt extension); by default, 
	when not set, `ofn` is built from the input name `&idsn` and the input year(s) `&years`;
* `odir` : (_option_) name of the output directory; by default, `odir=%sysfunc(pathname(&ilib))`.

### Example
Run `%%_example_silc_ffile_export` for examples.

### Note
The indicator is "SILC-formatted" _e.g._ it is structured in such a way that it has/could have
been created using the macro [%silc_ind_create](@ref sas_silc_ind_create).

### See also
[%silc_ind_create](@ref sas_silc_ind_create), [%silc_ind_info](@ref sas_silc_ind_info), 
[%ds_contents](@ref sas_ds_contents), [%obs_count](@ref sas_obs_count), 
[%var_to_list](@ref sas_var_to_list).
*/ /** \cond */

/* credits: gjacopo */

%macro silc_ffile_export(idsn		/* Name of the input dataset/indicator to publish 				(REQ) */
						, geo		/* List of countries ISO-codes or geographical area 			(REQ) */
						, year		/* Year(s) of interest 											(REQ) */
						, ilib=		/* Name of the input library									(OPT) */
						, idir=		/* Name of the input directory 									(OPT) */
						, ofn=		/* Name of the output (text) file								(OPT) */
						, odir=		/* Name of the output directory									(OPT) */
						, key=		/* Name of the key used to indentified the indicator 			(OPT) */
						, headkeys=	/* Headkey string used for dataset identification in Eurobase 	(OPT) */
						, prefkey=	/* Prefix string used for dataset identification in Eurobase 	(OPT) */
						, mode=		/* Mode of upload to Eurobase (OPT)*/
						);
	/* for ad-hoc works, load PING library if it is not yet the case
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end; */
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _ilib _isLibTemp
		nobsy yyyy
		nobs Utab
		isgeo
		dimcol dimcolcomma
		mode nc RD
		MODES;
	%let _isLibTemp=NO;
	%let RD=10.1;
	%let MODES=RECORDS REPLACE DELETE/*CUBE*/;

	/* IDIR/ILIB: check/set */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(idir) EQ 0 and %macro_isblank(ilib) EQ 0, mac=&_mac,	
			txt=!!! Incompatible options IDIR and ILIB - One parameter needs to be set only !!!) %then
		%goto exit;

	%if %macro_isblank(idir) and %macro_isblank(ilib) %then %do;
		%let ilib=WORK;
	%end;
	%else %if %macro_isblank(ilib) %then %do;
		libname _ilib  "&idir";
		%let ilib=_ilib;
		%let _isLibTemp=YES;
	%end;

	/* GEO: check/set */
	%if %macro_isblank(geo) %then	%let geo=EU28;
	/* clean the list of geo and retrieve type 
	%str_isgeo(&geo, _ans_=isgeo, _geo_=geo);
	%if %error_handle(ErrorInputParameter, 
			%list_count(&isgeo, 0) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter GEO: must be country/geographical zone ISO code(s) !!!)) %then
		%goto exit;*/

	/* MODE: check/set */
	%if %macro_isblank(mode) %then 	%let mode=RECORDS;
	%else 	 						%let mode=%upcase(&mode);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&mode, type=CHAR, set=&MODES) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong type/value for input MODE !!!)) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			&mode EQ DELETE, mac=&_mac,		
			txt=%quote(! DELETE mode selected !), verb=warn) %then
		%goto warning1;
	%warning1:

	/* PREFKEY/HEADKEYS: check/set */
	%if %macro_isblank(prefkey) %then 		%let prefkey=ILC;
	%else %if "&prefkey"="_EMPTY_" %then 	%let prefkey=;
	%else 	 								%let prefkey=%upcase(&prefkey);

	%if not %macro_isblank(headkeys) %then
	/*%if %macro_isblank(headkeys) %then 	%let headkeys=SAS ILC;
	%else*/ 	 							%let headkeys=%upcase(&headkeys);

	/* ODIR/OFN: check/set */
	%if %macro_isblank(odir) %then 		%let odir=%sysfunc(pathname(&ilib));

	%if %macro_isblank(ofn) %then %do;
		%let ans=%file_check(&odir/&ofn, ext=txt);
		%if %error_handle(WarningOutputFile, 
			&ans EQ 0, mac=&_mac,		
			txt=%bquote(! Output file &ofn already exists in folder &odir !), verb=warn) %then
		%goto warning2;
	%end;
	%warning2:

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local dimcol dimcolcomma
		where
		PREFSEP;
	%let dimcol=;
	%let PREFSEP=_;	/* change the separator in case the taxonomy changes in Eurobase */

	/*work_clean*/	

	/* retrieve the list of variables in the table */
	%ds_contents(&idsn, _varlst_=dimcol, lib=&ilib);
	/* keep the variables up to the last one before IVALUE in the table */
	%let dimcol=%list_slice(%upcase(&dimcol), ibeg=1, end=IVALUE);
	/* transform by adding commas */
	%let dimcolcomma=%upcase(%list_quote(&dimcol, mark=_EMPTY_, rep=%quote(,)));

	/* instead of:
	PROC DATASETS library=&ilib nolist;
		CONTENTS data=&idsn out=varlst noprint;
	quit;
	PROC SORT
		DATA=&ilib..varlst OUT=WORK.varlst(keep=name varnum);
		BY varnum name;
	run;
	PROC DATASETS lib=&ilib nolist; delete varlst;  
	quit;
	DATA _NULL_;
		SET WORK.varlst;
		array v(10) $12;
		retain i (1); retain v;
		length dimcol $50; length dimcolcomma $50;

		if name ne "ivalue" then do;
			v(i) = name;
			i = i + 1;
		end;
		else do;
			dimcol = v(1); dimcolcomma = v(1);
				do j = 2 to i-1;
					dimcol = trim(dimcol)||" "||trim(v(j));
					dimcolcomma = trim(dimcolcomma)||","||trim(v(j));
				end;
				call symput("dimcol",trim(dimcol));
				call symput("dimcolcomma",trim(upcase(dimcolcomma)));
			stop;
		end;
	run;
	%put dimcol=&dimcol;
	%put dimcolcomma=&dimcolcomma;

	/* test if the datasets is empty and change the years variables */

	%let where=time in %sql_list(&year) AND geo in %sql_list(&geo);

	/* count the number of distinct observations */
	%obs_count(&idsn, _ans_=nobs, where=%quote(&where), pct=NO, distinct=YES, lib=&ilib);
	/* instead of:
	PROC SQL noprint;
		SELECT DISTINCT count(geo) AS N 
		INTO :nobs
		FROM  &ilib..&idsn (WHERE=(time in %sql_list(&year) AND geo in %sql_list(&geo)));
	quit;*/

	%if &nobs=0 %then %goto exit;

	/* check the years actually available */
	%var_to_list(&idsn, time, distinct=YES, where=%quote(&where), _varlst_=nobsy, lib=&ilib);
	/* instead of:
	PROC SQL noprint;
		SELECT distinct time as Ny 
		INTO :nobsy separated by ' ' 
		FROM  &ilib..&idsn (WHERE=(time in %sql_list(&year) AND geo in %sql_list(&geo)));
	quit;*/

	%let Utab=%upcase(&idsn);

	%let yyyy=&nobsy;

	%if %macro_isblank(ofn) %then %do;
		DATA _null_;
			sdat = put("&sysdate"d,yymmdd6.);
			nc = sdat||"_"||compress("&yyyy")||"_"||compress("&Utab");
			call symput("nc",ofn);
		run;
	%end;

	FILENAME ncfile "&odir/&ofn..txt" TERMSTR=CRLF;;

	/* create the ID keys */
	%if %macro_isblank(key) %then
		%let key=&Utab;
	%if not %macro_isblank(prefkey) %then
		%let key = &prefkey.&PREFSEP.&key;
	%if not %macro_isblank(headkeys) %then 
		%let key=%list_quote(&headkeys &key, rep=%quote(,), mark=_EMPTY_);

	/* update the filter */
	%let where=time in %sql_list(&yyyy) AND geo in %sql_list(&geo);

	DATA _null_;
		SET &ilib..&idsn(WHERE=(&where)) end=last;
			/*%end;*/
		length refval $ 50;
		file ncfile;
		if _N_ = 1 then do;
			put "FLAT_FILE=STANDARD";
			put "ID_KEYS=&key";
			put "FIELDS=&dimcolcomma";
			put "UPDATE_MODE=&mode";
		end;

		/* this will need to be defined externally */
		if (geo in ("EU15", "EU25", "EA", "EA12", "EA13", "EA15", "NMS10", "EA16") and time < 2005) 
				or (geo in (/*"EU27", */ "RO", "NMS12") and time < 2007)
			then do; 
				x="no put"; 
		end;
		else do;
			/* replace GR with EL for all occurencies */
	        len = LENGTH(GEO); 
		    if len =2 and GEO="GR" then GEO="EL";
		    if len >2 and substr(geo,1, 2)= "GR" then do;
	   			GEOx="EL";
	   			GEOrest=substr(geo,3,len);
	   			GEO=cats(GEOx, GEOrest); 
				drop=LEN;
	            drop= GEOx;
	            drop= GEOrest ; 
			end; 

			if unrel = 0 then do;
				if ivalue =. then refval = "0.0";
				else if round(ivalue,0.1)=0  then refval = "0.0n";
				else if unit ='THS_PER' then refval = round(ivalue)||iflag; 
				else  refval = put(ivalue,&rd)||iflag; 
			end;
			else if unrel = 1 then do; 
				if ivalue =. then refval = "0u"; 
				else if unit ='THS_PER' then refval = compress(round(ivalue)||iflag||"u"); 
				else refval = compress(put(ivalue,&rd)||iflag||"u"); 
			end;
			else if unrel = 2 then do; 
				if ivalue =. and ntot=0 then refval = ":z"; 
				else refval = ":u";
			end;
			else if unrel in (3,4) then do; 
				if ivalue =. then refval = "0e"; 
				else if iflag="e" then /* avoid occurrences of "ee" */
					if unit ='THS_PER' then refval = compress(round(ivalue)||"e"); 
		    		else refval = compress(put(ivalue,&rd)||"e");
				else 
					if unit ='THS_PER' then refval = compress(round(ivalue)||iflag||"e"); 
		    		else refval = compress(put(ivalue,&rd)||iflag||"e");
			end; 
			else if unrel = 5 then 
				refval = ":";
			/* s-flag replaced by e-flag on 5th Feb 2013 */
		 
		    put &dimcol refval;
		end;

		if last then put "END_OF_FLAT_FILE";
	run;

	%work_clean(varlst);

	%exit:

	%if %upcase("&_isLibTemp")="YES" %then %do;
		libname _ilib clear;
	%end;

%mend silc_ffile_export;

%macro _example_silc_ffile_export;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%silc_ffile_export(di01, AT, 2015, ilib=&G_PING_LIBCRDB, ofn=test, odir=&G_PING_C_RDB);

%mend _example_silc_ffile_export;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_silc_ffile_export; 
*/

/** \endcond */
