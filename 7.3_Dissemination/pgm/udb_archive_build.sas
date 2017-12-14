/** 
## udb_archive_build {#sas_udb_archive_build}

### See also
[%udb_file_split](@ref sas_udb_file_split), [%udb_ds_split](@ref sas_ds_file_split).
*/ /** \cond */

/* credits: gjacopo */

%macro udb_archive_build (idir
						, odir=
						, ofn=
						, dirby=
						);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %macro_isblank(idir) %then 
		%goto exit;

	/************************************************************************************/
	/**                         some useful macro declarations                         **/
	/************************************************************************************/

	/* _DIR_LS
	* List the contents of a given directory */
	%macro _dir_ls(dir				/* Name of the input directory to explore 							(REQ) */
					, odsn 			/* Name of the output table where the file lists is stored 			(OPT) */
					/* , match= 	/* Matching pattern 												(OPT) */
					, fext=			/* Extension of files to look for 									(OPT) */
					, rec=			/* Boolean flag set to recursively explore subfolders 				(OPT) */
					, dtyp=			/* "Type" of the subfolders' names									(OPT) */
					/* , _ls_file_=	/* Name of the output variable storing the list of matching files	(REQ) */
					/* , sep=		/* List item separator 												(OPT) */
					, olib=
					);   /* see also: http://support.sas.com/kb/45/805.html */
	
		%if "&dir" EQ "" or "&odsn" EQ "" /* %symexist(&_ls_file_) EQ 0 */ %then %do;
			%put Missing input/output parameter(s);
			%goto exit;
		%end;

		/* default OLIB: WORK, i.e. recursive search */
		%if "&olib" EQ "" %then 			%let olib=WORK;

		/* default REC: YES, i.e. recursive search */
		%if "&rec" EQ "" %then 			%let rec=YES;
		%else 							%let rec=%upcase(&rec);

		/* default DTYP: NUMERIC, i.e. the names of subforlders are strings composed of numbers only */
		%if "&dtyp" EQ "" %then 		%let dtyp=NUMERIC;
		%else 							%let dtyp=%upcase(&dtyp);
		%if "&dtyp" EQ "N" or "&dtyp" EQ "NUM" %then 	%let dtyp=NUMERIC;
		%else %if "&dtyp" EQ "C" %then					%let dtyp=CHAR;
		%else %if "&dtyp" EQ "_NONE_" %then 			%let dtyp=;

		/* default FEXT: we look for CSV file */
		%if "&fext" EQ "" %then 		%let fext=CSV;
		%else 							%let fext=%upcase(&fext); 
		%if "&fext" EQ "_NONE_" %then 	%let fext=;

		%local filrf _filrf rc _rc did 
			memcnt name i isAFile;

		/* assign a fileref to the directory and opens the directory */
		%let rc=%sysfunc(filename(filrf, &dir));
		%let did=%sysfunc(dopen(&filrf));

		/* make sure directory can be open */
		%if &did eq 0 %then	%do;
			%put Directory &dir cannot be open or does not exist;
			%goto exit;
		%end;

		/* loop through entire directory */
		%do i = 1 %to %sysfunc(dnum(&did));

			/* retrieve name of the directory member (file/subfolder) */
			%let name=%qsysfunc(dread(&did,&i));

			/* test whether the member NAME is a file or a subfolder */
			%let _rc=%sysfunc(filename(_filrf, &dir/&name));
			%let isAFile = %sysfunc(fopen(&_filrf)); /* %let isADir = %sysfunc(dopen(&_filrf)); */
			%let _rc=%sysfunc(filename(_filrf)); /* close the member and clear the fileref */

			%if &isAFile NE 0 %then %do;	
				/* check to see if the extension matches the parameter value */
				%if "&fext" NE "" and "%qupcase(%qscan(&name,-1,.))" NE "&fext" %then 
					%goto next;
					
				/* add the name of the file to the list */
				DATA &olib..&odsn;
					%if not %sysfunc(exist(&olib..&odsn)) %then %do;
					   	length file $512; /* safe enough? */
						file="&dir/%unquote(&name)"; output;
					%end;
					%else %do;
						SET &olib..&odsn end=eof; output;
						IF eof THEN do;
							file="&dir/%unquote(&name)"; output;
						END;
					%end;
				run;
				/* %if "&&&_ls_file_" EQ "" %then
					%let &_ls_file_=&dir/%unquote(&name);
				%else 
					%let &_ls_file_=&&&_ls_file_.&sep.&dir/%unquote(&name); */

			%end;
			%else /* we know that: &isAFile EQ 0 */ %if "&rec"="YES" %then %do;
				/* check the name of the directory */
				%if "&dtyp" NE "" and "%datatyp(&name)" NE "&dtyp" %then 
					/* or test: %sysfunc(compress(%substr(&dir, %length (&dir)-3,4),"0123456789")); ? */
					%goto next;

				/* recursive call to the macro again */	
				%_dir_ls(&dir/%unquote(&name), &odsn, /*_ls_file_=&_ls_file_, */ 
					fext=&fext, dtyp=&dtyp, olib=&olib, rec=YES);
			%end;

			%next:
		%end;

		/* close the directory and clear the fileref */
		%let rc=%sysfunc(dclose(&did));
		%let rc=%sysfunc(filename(filrf));

	%exit:
	%mend _dir_ls;

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* IDIR: check */
	%if %error_handle(ErrorInputDataset, 
			%dir_check(&idir) NE 0, mac=&_mac,		
			txt=%quote(!!! Input directory %upcase(&idir) does not exist !!!)) %then
		%goto exit;

	/* ODIR/OFN: check/set default */
	%if %macro_isblank(ofn)  %then 		%let ofn=UDB;
	%if %macro_isblank(odir)  %then 	%let odir=&idir;

	/* done in UDB_FILE_SPLIT 
	%if %error_handle(WarningOutputDataset, 
			%dir_check(&odir) NE 0, mac=&_mac,		
			txt=%quote(! Output directory %upcase(&odir) does not exist - Will be created!)) %then
		%goto warning;
	%warning: */

	/* DIRBY: set default/update parameter */
	%if %macro_isblank(dirby)  %then 			%let dirby=GEO; 
	%else										%let dirby=%upcase(&dirby);

	/* note that we also check it in UDB_FILE_SPLIT; still we prefer to do it once for all at
	* this stage */
	%if %error_handle(ErrorInputParameter, 
			%par_check(&dirby, type=CHAR, set=GEO TIME FLAT) NE 0, mac=&_mac,		
			txt=%quote(!!! Structure directory DIRBY should be either GEO, TIME, or FLAT !!!)) %then
		%goto exit;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _tmpdsn _dsid _rc 
		nifile;

	/* check whether the temporary dataset _TMPDSN already exists or not */
	%let _tmpdsn=_TMP_&_mac;
	%if %error_handle(WarningTemporaryDataset, 
			%ds_check(&_tmpdsn, lib=WORK) EQ 1, mac=&_mac,		
			txt=%quote(! Temporary dataset %upcase(&_tmpdsn) not found - Will be overwritten!), verb=warn) %then %do;
		%work_clean(&_tmpdsn);
	%end;
	/*	%goto warning;
	%warning: 			*/

	/* retrieve the list of files of the directory IDIR into _TMPDSN */
	%_dir_ls(%quote(&idir), &_tmpdsn, fext=csv, dtyp=NUMERIC, olib=WORK);

	/* add a counter ID to _TMPDSN */
	DATA WORK.&_tmpdsn;
		SET WORK.&_tmpdsn;
		id = _N_;
	run;
		
	/* retrieve the number NIFILE of files in the folder */
	%let _dsid=%sysfunc(open(WORK.&_tmpdsn));
	%let nifile=%sysfunc(attrn(&_dsid, nobs));
	%let _dsid=%sysfunc(close(&_dsid));
	%let _rc = %sysfunc( close(&_dsid) ); 
	
	/* for each bulk file, extract the subsets of time/year data and organise the hierarchy
	* thanks to the UDB_FILE_SPLIT macro and according to DIRBY value */
	%do _i=1 %to &nifile;

		/* retrieve the bulk file name */
		%let ifile=;
		PROC SQL noprint;
			SELECT file INTO :ifile FROM WORK.&_tmpdsn
			WHERE id=&_i;
		quit;

		/* import, split and export the bulk file into a hierarchical directory structure
		* whose organisation depends on DIRBY value */
		%udb_file_split(/*geo*/	_ALL_
					, /*time*/	_ALL_
					, /*ifn*/	%quote(%sysfunc(strip(&ifile)))
					, ofn=		&ofn
					, odir=		&odir
					, dirby=	&dirby
					, fext=		csv
					); 
	%end;

	%work_clean(&_tmpdsn);
	%exit:
%mend udb_archive_build;


