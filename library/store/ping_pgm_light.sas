/*%global G_PING_PGM_LIGTH_LOADED
	G_PING_PGM_LIGTH_PATH;

%let G_PING_PGM_LIGTH_PATH=			/ec/prod/server/sas/0eusilc/7.3_Dissemination/pgm; 
%let G_PING_PGM_LIGTH_LOADED=		1;
*/

%macro error_handle(i_errcode, i_cond, mac=, txt=, verb=ERR);
	%if "&verb"="ERR" %then					%let mssg=ERROR;
	%else %if &verb="WARN" %then 			%let mssg=WARNING;
	%else 									%let mssg=NOTE;			
	%if &i_cond %then %do;
		%put &mssg: &i_errcode &mac (cond.: &i_cond);
		%if "&txt" NE "" %then %put &txt;
	   	1
	%end;
	%else %do;
	   	0
	%end;
%mend error_handle;

%macro work_clean/parmbuff;
	%local ds num;
	%let num=1;
	%let ds=%scan(&syspbuff,&num);
	%if &ds= %then %do;
		PROC DATASETS lib=WORK kill nolist;
		quit;
  	%end;
	%else %do;
   		%do %while(&ds ne);
			PROC DATASETS lib=WORK nolist; 
				delete &ds;  
			quit;
   			%let num=%eval(&num+1);
      		%let ds=%scan(&syspbuff,&num);
   		%end;
	%end;
%mend work_clean;

%macro macro_isblank(v);
	%let __v = %superq(&v);
	%let ___v = %sysfunc(compbl(%quote(&__v))); 
	%if %sysevalf(%superq(__v)=, boolean) or %nrbquote(&___v) EQ 	%then %do;			
		1
	%end;
	%else %do;											
		0
	%end;
%mend;

%macro list_length(list, sep=%quote( ));
	%sysfunc(countw(&list, &sep))
%mend;

%macro list_ones(list, item=);
	%let res=;
	%do ___i=1 %to &list; 
		%let res=&res &item; 
	%end;
	&res
%mend;

%macro list_append(list1, list2, zip=);
	%let res=;
	%do ___i=1 %to %sysfunc(countw(&list1)); 
		%let res=&res %scan(&list1,%___i)%scan(&list2,%___i); 
	%end;
	&res
%mend;

%macro list_difference(list1, list2); 
	%local _diff _i _list1 item1 _item1;
	%let _diff=;
	%let _list1=%upcase(&list1); 	
	%let list2=%upcase(&list2);
	%if "&list1" EQ "" %then
		%goto exit;
	%else %if "&list2" EQ "" %then %do;
		%let _diff=&list1;
		%goto exit;
	%end;
	%do _i=1 %to %sysfunc(countw(&list1));
		%let item1=%scan(&list1, &_i); 	
		%let _item1=%scan(&_list1, &_i);
		%let _pos=%sysfunc(findw(&list2, &_item1));
		%if &_pos <= 0 %then 
			%let _diff=&_diff &item1;
	%end;
	%exit:
	&_diff
%mend list_difference;

%macro list_intersection(list1, list2);
	%local _isec _i _pos _posi _posj _list2 _item _uitem;
	%let _isec=;
	%if "&list1" EQ "" or "&list2" EQ "" %then 
		%goto exit;
	%let _list2=%upcase(&list2);
	%do _i=1 %to %sysfunc(countw(&list1));
		%let _item=%scan(&list1, &_i);
		%let _uitem=%upcase(&_item); 
		%let _pos=%sysfunc(findw(&_list2, &_uitem));
		%if &_pos>0 %then %do;
			%if &_isec= %then 	%let _isec=&_item;
			%else %do;
				%let _posi=%sysfunc(findw(&_isec, &_item));
				%let _posj=%sysfunc(findw(&_isec, &_uitem));
				%if &_posi<=0 and &_posj<=0 %then	
					%let _isec=&_isec &_item;
			%end;
		%end;
	%end;
	%exit:
	&_isec
%mend list_intersection;

%macro list_slice(list, beg=, ibeg=, end= , iend=, sep=);
	%local _len	 _alist
		_i  item _item;
	%if &sep=  %then %let sep=%quote( ); 
	%let _len=%list_length(&list, sep=&sep);
	%if "&ibeg" EQ "" and "&beg" EQ "" %then	
		%let ibeg=1; 
	%if &iend= and &end= %then	
		%let iend=%eval(&_len+1); 
	%if "&beg" NE "" %then 	%let beg=%upcase(&beg);
	%if "&end" NE "" %then 	%let end=%upcase(&end);
	%let _alist=;
	%do _i=1 %to &_len;
		%let item=%scan(&list, &_i, &sep);
		%let _item=%upcase(&item);
		%if "&beg" EQ "" and &_i=&ibeg %then	%do;
			%let beg=&_item;
			%goto append;
		%end;
		%else %if "&ibeg" EQ "" %then %do;
			%if &_item=&beg %then	%let ibeg=&_i;
			%else 					%goto continue;
		%end;
		%else %if "&iend" EQ "" and &_item=&end %then %do; 
			%let iend=&_i;
			%goto exit;
		%end;
		%if "&ibeg" NE "" and &_i<&ibeg %then 	
			%goto continue;
		%else %if "&ibeg" NE "" and &_i=&ibeg %then 	
			%goto append; 
		%else %if "&iend" NE "" and &_i>=&iend %then 	
			%goto exit;
		%append:
		%if &_alist= %then 		%let _alist=&item;
		%else					%let _alist=&_alist.&sep.&item;
		%continue:
	%end;
	%exit:
	&_alist
%mend list_slice;

%macro ds_contents(dsn, _varlst_=, lib=);
	%if &lib= %then 	%let lib=WORK;
	PROC CONTENTS noprint DATA = &lib..&dsn 
		OUT = __tmp(keep = name varnum);
	run;
	PROC SORT DATA = __tmp 
		OUT = __tmp(keep = name) OVERWRITE;
	 	BY varnum;
	run;
	PROC SQL noprint; 	
		SELECT name INTO :&_varlst_ SEPARATED BY " " 
		FROM __tmp;
	quit;
	%work_clean(__tmp);
%mend ds_contents;

%macro par_check/parmbuff; 		0 /* always OK */
%mend;

%macro ds_check(dsn, lib=); 
	%local __ans _i _ds;	
	%let __ans=;	
	%if &lib= %then 	%let lib=WORK;
	%do _i=1 %to %sysfunc(countw(&dsn));
		%let _ds=%scan(&dsn, &_i);
		%if %sysfunc(exist(&lib..&_ds, data)) or %sysfunc(exist(&lib..&_ds,view)) %then
			%let __ans=&__ans 0;
		%else 
			%let __ans=&__ans 1;
	%end;	
	%quit:
	&__ans
	%exit:
%mend ds_check;

%macro var_check(dsn, var, lib=);
	%local _dsid _i _var _rc _res	
		__ans;	
	%let __ans=;
	%if &lib= %then 	%let lib=WORK;
	%let _dsid=%sysfunc(open(&lib..&dsn));
	%if %error_handle(WrongInputDataset, 
			&_dsid EQ 0, mac=&_mac, 
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then 	
		%goto clean_exit;
	%do _i=1 %to %sysfunc(countw(&var));
		%let _var=%scan(&var, &_i);
		%let _res=%sysfunc(varnum(&_dsid, &_var));
		%if &_res>0 %then 
			%let __ans=&__ans 0;
		%else 
			%let __ans=&__ans 1;
	%end;
	%goto quit;
	%quit:
	&__ans
	%clean_exit:
	%let _rc=%sysfunc(close(&_dsid));
	%exit:
%mend var_check;

%macro list_quote(l, mark=, sep=%quote( ), rep=%quote(, ));
	%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&l)))), &sep, &rep))
%mend;

%macro sql_list(list);
	%if %upcase("%datatyp(%scan(&list,1))")="NUMERIC" %then %do;
		(%sysfunc(tranwrd(%qsysfunc(compbl(%sysfunc(strip(&list)))), %quote( ), %quote(,))))
	%end;
	%else %if %sysfunc(find(&list,%str(%'))) %then %do;
		(%sysfunc(tranwrd(%sysfunc(compbl(&list)), %quote(' '), %quote('%quote(,)'))))
	%end;
	%else %if %sysfunc(find(&list,%str(%"))) %then %do;
		(%sysfunc(tranwrd(%sysfunc(compbl(&list)), %quote(" "), %quote("%quote(,)"))))
	%end;
	%else %do; 
		("%sysfunc(tranwrd(%sysfunc(compbl(&list)), %quote( ), %quote("%quote(,)")))")
	%end;
%mend;

%macro sql_clause_as(idsn, var, _as_=, ilib=); /* idsn/ilib: ignored */
	%local _var;
	%let _var=%list_quote(&var, rep=%quote(,), mark=_EMPTY_);
	data _null_;
		call symput("&_as_","&_var");
	run;
%mend;

%macro sql_clause_add(dsn, var, _add_=, typ=, lib=);
	%local _i _var _typ _varlen
		_newvar;
	%let _newvar=; 
	%let _varlen=%sysfunc(countw(&var));
	%if &lib= %then 			%let lib=WORK;		
	%if "&typ" EQ "" %then 		%let typ=CHAR;
	%if %sysfunc(countw(&typ))=1 and &_varlen>1 %then  		
		%let typ=%list_ones(&_varlen, item=&typ);
	%do _i=1 %to %sysfunc(countw(&var));
		%let _var=%scan(&var, &_i);
		%let _typ=%scan(&typ, &_i);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) EQ 0, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_var) already exists in dataset %upcase(&dsn) !),  
				verb=warn) %then 
			%goto next;
		%else %do;
			%let _newvar=&_newvar, &_var &_typ;
		%end;
		%next:
	%end;
	data _null_;
		call symput("&_add_","&_newvar");
	run;
%mend sql_clause_add;

%macro list_unique(list,casense=,sep=);
	%local _mac;
	%local _i 
		_item 	
		_luni; 
	%let _luni=;
	%if %macro_isblank(casense)  %then 	%let casense=NO; 
	%else								%let casense=%upcase(&casense);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&casense, type=CHAR, set=YES NO) NE 0, mac=&_mac,	
			txt=!!! Parameter CASENSE is boolean flag with values in (yes/no) !!!) %then
		%goto exit;
	%if %macro_isblank(sep) %then 	%let sep=%quote( );  
	%if "&casense"="NO" %then 
		%let list=%upcase(&list);
	%do _i=1 %to %list_length(&list, sep=&sep);
		%let _item = %scan(&list, &_i, &sep);
		%if %macro_isblank(_luni) %then 
			%let _luni=&_item;
		%else %if %sysfunc(find(&_luni, &_item))<=0 %then 
			%let _luni=&_luni.&sep.&_item;
	%end;
	%exit:
	&_luni
%mend list_unique;

%macro ds_isempty(dsn,var=,_ans_=,lib=, verb=);
	%local _mac;
	%let _mac=&sysmacroname;
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_ans_) EQ 1, mac=&_mac,		
			txt=!!! Output macro variable _ANS_ not set !!!) %then
		%goto exit;
	
 	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%local _dsn	
		__ans	
		_rc		
		_dsid	
		_nobs;	

	%let __ans=1;

	%if not %sysfunc(exist(&lib..&dsn)) %then %do;
		%let ans=-1;
		%goto quit;
	%end;
	%let _dsid = %sysfunc( open(&lib..&dsn) );
	%let _nobs = %sysfunc( attrn(&_dsid, nobs) );

	%if &_nobs=0 %then %do;
		%let __ans=1; 
		%goto quit;
	%end;

	%if &_nobs^=0 and %macro_isblank(var) %then %do;
		%let __ans=0;
		%goto quit;
	%end;
	%else %do;
		%if %error_handle(ErrorInputParameter, 
				%sysfunc(varnum(&_dsid, &var)) EQ 0, mac=&_mac,		
				txt=%quote(!!! Variable %upcase(&var) not found in dataset %upcase(&dsn) !!!)) %then %do;
			%let ans=-1;
			%goto quit;
		%end;
	%end;

	%let _dsn=TMP_%upcase(&sysmacroname);
	PROC SQL noprint;
		CREATE TABLE &_dsn AS 
		SELECT * FROM  &lib..&dsn 
		WHERE &var IS NOT MISSING;
	quit;

	PROC SQL noprint;
		SELECT DISTINCT count(&var) as N 
		INTO :_nobs 
		FROM &_dsn;
	quit;
 
	%work_clean(&_dsn); 
	%if &_nobs = 0 %then 
		%let __ans=1; 
	%else  
		%let __ans=0; 

	%quit:
	data _null_;
		call symput("&_ans_","&__ans");
	run;
	%let _rc = %sysfunc( close(&_dsid) ); 

	%exit:
%mend ds_isempty;

%macro ds_export(idsn, ofn=, odir=, _ofn_=, fmt=, dbms=, ilib=, delim=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
	%local Ufmt
		DEBUG; 
	%if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else								%let DEBUG=0;

	%local __file; 
	%if %macro_isblank(fmt) %then 		%let fmt=csv;
	%let Ufmt=%upcase(&fmt);
	%if "&Ufmt"="DTA" %then 				%let dbms=STATA; 
	%if %macro_isblank(dbms) %then 		%let dbms=&Ufmt;
	%else 								%let dbms=%upcase(&dbms);
	%if %macro_isblank(ilib) %then 		%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;
	%if %macro_isblank(odir) %then %do; 
		%if %symexist(_SASSERVERNAME) %then 
			%let odir=&G_PING_ROOTPATH/%_egp_path(path=drive);
		%else %if &sysscp = WIN %then %do; 	
			%let odir=%sysget(SAS_EXECFILEPATH);
			%if not %macro_isblank(odir) %then
				%let odir=%qsubstr(&odir, 1, %length(&odir)-%length(%sysget(SAS_EXECFILENAME));
		%end;
		%if %macro_isblank(odir) %then
			%let odir=%sysfunc(pathname(&ilib));
	%end;
	%if %error_handle(ErrorOutputParameter, 
			%dir_check(&odir) NE 0, mac=&_mac,		
			txt=%quote(!!! Output directory &odir does not exist !!!)) %then
		%goto exit;
	%if %macro_isblank(ofn) %then 		%let ofn=&idsn;
	%if %error_handle(ErrorInputParameter, 
			%index(%upcase(&ofn),/) NE 0, mac=&_mac,		
			txt=%quote(!!! Parameter OFN contains output basename only - Set ODIR for output pathname !!!)) %then
		%goto exit;
	%if %index(%upcase(&ofn),.CSV) EQ 0 %then 	
		%let __file=&ofn..&fmt;
	%else 								
		%let __file=&ofn;
	%if "&odir" NE "_EMPTY_" %then 		%let __file=&odir./&__file;

	%if &DEBUG=1 %then 
		%goto quit;
	%if %error_handle(WarningOutputFile, 
			%file_check(&__file) EQ 0, mac=&_mac,		
			txt=%quote(! Output file %upcase(&__file) already exist - Will be overwritten !), verb=warn) %then
		%goto warning;
	%warning:
	PROC EXPORT DATA=&ilib..&idsn OUTFILE="&__file" REPLACE
		DBMS=&dbms
		%if not %macro_isblank(delim) %then %do;
			 DELIMITER=&delim
		%end;
		;
	quit;

	%quit:

	%if not %macro_isblank(_ofn_) %then %do;
		%let &_ofn_=&__file;
	%end;

	%exit:
%mend ds_export;


%macro ds_append(dsn, idsn, cond=, icond=, drop=, ikeep=, lib=, ilib= );		 
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
	%local _idsn   	
		nidsn		
		_var 		
		_sep      
		;

    %let _sep=%str(-);


	%if %macro_isblank(lib)	%then 	%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
		%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
		txt=!!! Master dataset %upcase(&dsn) not found !!!) %then
	%goto exit;


	%if %macro_isblank(ilib) %then 	%let ilib=WORK;
	%ds_check(&idsn, _dslst_=_idsn, lib=&ilib);		

	%if %error_handle(ErrorInputParameter,
			%macro_isblank(_idsn), mac=&_mac,
			txt=!!! No reference dataset found !!!) %then	
		%goto exit;

	%let idsn=&_idsn;
	%let nidsn=%list_length(&idsn);

	%if not %macro_isblank(drop) %then 		%let drop=%upcase(&drop);


	%if not %macro_isblank(ikeep) %then 	%let ikeep=%upcase(&ikeep);

	%local _i 
		_j	 
		ans
		SEP		                            
      	_ivar	 
		_ilvar;	 
	%let _ilvar=;
	%let SEP=%quote( );

	%ds_contents(&dsn, _varlst_=_var, varnum=yes, lib=&lib);
 
	%if &drop^= %then %do;	
		%let _var=%list_difference(&_var, &drop); 
	%end;  

	%if  not %macro_isblank(ikeep) %then %do;
		%do _i=1 %to &nidsn;
			%local _ikeep&_i;
			%let _idsn=%scan(&idsn, &_i);
			%let _ivar=; /* reset */
			%ds_contents(&_idsn, _varlst_=_ivar, varnum=yes, lib=&ilib);
		 
			%if "&ikeep"="_ALL_" %then %do;
			
				%let _ikeep&_i=&_ivar; 
			%end;
			%else %do;
			
				%let _ikeep&_i=%list_intersection(&_ivar, &ikeep);
			%end;
			%let _ikeep&_i=%list_unique(&_var.&SEP.&&_ikeep&_i);
		
			%let _ilvar=%list_unique(&_ilvar.&SEP.&_ivar);
		
			%let _ivar=%list_intersection(&_ivar, &_var); 
		
			%var_compare(&_idsn, &_ivar, _ans_=ans, dsnc=&dsn, typ=YES, len=NO, fmt=NO, lib=&lib, libc=&ilib);
			%if %error_handle(ErrorInputParameter,
					%list_count(&ans, 1) GT 0, mac=&_mac,
					txt=%quote(!!! Variables %upcase(&_ivar) have different types in datasets &dsn and &_idsn !!!)) %then 
				%goto exit;
		%end;
	%end;

	%if not (%macro_isblank(cond) and %macro_isblank(drop)) %then %do;
		DATA &lib..&dsn
			%if not %macro_isblank(drop) %then %do;
				(DROP=&drop)
			%end;
			;
			SET &lib..&dsn;
			%if not %macro_isblank(cond) %then %do;
				WHERE &cond
			%end; 
			;
		run;
	%end;	
	%if %macro_isblank(ikeep) %then %do;
		%do _i=1 %to &nidsn;
			%let _idsn=%scan(&idsn, &_i);
		PROC APPEND
				BASE=&lib..&dsn 	
			
				DATA=&ilib..&_idsn
			     %if  not %macro_isblank(icond) %then %do;	
					(WHERE=&icond) 
				%end;
				FORCE NOWARN
				;
			run;
		%end;
	%end;

	%else %do;
		DATA  &lib..&dsn;
			SET &lib..&dsn 	
			%do _i=1 %to %list_length(&idsn);
			   	%let _idsn=%scan(&idsn, &_i);
			    &ilib..&_idsn
				%if not (%macro_isblank(icond) and %macro_isblank(ikeep)) %then %do;
				(
				%end;
				%if  not %macro_isblank(icond) %then %do;
					WHERE=&icond
				%end;
				%if  not %macro_isblank(ikeep) %then %do;
					%if  not %macro_isblank(_ikeep&_i) %then %do;
						%put ------------ KEEP=&&_ikeep&_i;
						KEEP=&&_ikeep&_i
					%end;
				%end;
				%if not (%macro_isblank(icond) and %macro_isblank(ikeep)) %then %do;
				)
				%end;
			%end; 
			;
		 run;
	%end;
	%exit:
%mend ds_append;

%macro ds_contents(dsn, _varlst_=, _lenlst_=, _typlst_=, varnum=, lib=);	 
																 
			
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_varlst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _VARLST_ needs to be set !!!) %then
		%goto exit;

	%local __istyplst	
		__islenlst	
		__varnum		
		__tmp		
		__vars 			
		__lens			
		__typs			
		SEP;			
	%let __tmp=TMP_&_mac;
	%let SEP=%str( );

	%let __istyplst=%macro_isblank(_typlst_);
	%let __islenlst=%macro_isblank(_lenlst_);


	%if %macro_isblank(varnum) %then 	%let varnum=YES;
	%else								%let varnum=%upcase(&varnum);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&varnum, type=CHAR, set=YES NO) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Wrong value for input boolean flag %upcase(&dsn) !!!)) %then
		%goto exit;


	%if %macro_isblank(lib) %then 		%let lib=WORK;
	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Input dataset %upcase(&dsn) not found in library %upcase(&lib) !!!)) %then
		%goto exit;

	PROC CONTENTS noprint
		DATA = &lib..&dsn 
        OUT = &__tmp(keep = name 
		%if "&varnum"="YES" %then %do; 
			varnum 
		%end;
		%if &__istyplst EQ 0 %then %do; 
			type 
		%end;
		%if &__islenlst EQ 0 %then %do; 
			length 
		%end;
		);
	run;
	%if "&varnum"="YES" %then %do; 
		PROC SORT
	     	DATA = &__tmp
			OUT = &__tmp(keep = name
			%if &__istyplst EQ 0 %then %do; 
				type 
			%end;
			%if &__islenlst EQ 0 %then %do; 
				length 
			%end;
			) OVERWRITE;
	     	BY varnum;
		run;
	%end;
	PROC SQL noprint; 	
		SELECT
			name 
			%if &__istyplst EQ 0 %then %do; 
				, type
			%end;
			%if &__islenlst EQ 0 %then %do; 
				, length
			%end;
		INTO 
			:&_varlst_ SEPARATED BY "&SEP"
			%if &__istyplst EQ 0 %then %do; 
				, :&_typlst_ SEPARATED BY "&SEP"
			%end;
			%if &__islenlst EQ 0 %then %do; 
				, :&_lenlst_ SEPARATED BY "&SEP"
			%end;		
		FROM &__tmp;
	quit;

	%work_clean(&__tmp);
	%exit:
%mend ds_contents;

%macro var_compare(dsn , var, varc=, dsnc=, _ans_=, pos=, typ=yes, lab=, fmt=, vfmt=, len=, infmt=, lib=, libc=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	%if %macro_isblank(lib) %then 	%let lib=WORK;
	%if %macro_isblank(libc) %then 	%let libc=&lib;
	%if %macro_isblank(dsnc) %then 	%let dsnc=&dsn;
	%if %macro_isblank(varc) %then 	%let varc=&var;

	%local nvar;
	%let nvar=%list_length(&var);
	%local _i
		_pos _cpos
		_typ _ctyp
		_lab _clab
		_fmt _cfmt
		_vfmt _cvfmt
		_infmt _cinfmt
		_ans _tmp
		_var _varc
		SEP;
	%let _ans=;
	%let SEP=%quote( );

	%do _i=1 %to &nvar;
		%let _var=%scan(&var, &_i);	
		%let _varc=%scan(&varc, &_i);

		%var_info(&dsn, &_var, _typ_=_typ, _pos_=_pos, _lab_=_lab, _fmt_=_fmt, _vfmt_=_vfmt, _len_=_len, _infmt_=_infmt,
			lib=&lib);
		%var_info(&dsnc, &_varc, _typ_=_ctyp, _pos_=_cpos, _lab_=_clab, _fmt_=_cfmt, _vfmt_=_cvfmt, _len_=_clen, _infmt_=_cinfmt, 
			lib=&libc);
		
		%let _tmp=0;
		%if %upcase("&typ")="YES" %then %do;
			%if &_typ^=&_ctyp %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&len")="YES" %then %do;
			%if &_len^=&_clen %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&fmt")="YES" %then %do;
			%if &_fmt^=&_cfmt %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&vfmt")="YES" %then %do;
			%if &_vfmt^=&_cvfmt %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&pos")="YES" %then %do;
			%if &_pos^=&_cpos %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&lab")="YES" %then %do;
			%if &_lab^=&_clab %then 	%let _tmp=1;
			%goto next;
		%end;
		%if %upcase("&infmt")="YES" %then %do;
			%if &_infmt^=&_cinfmt %then %let _tmp=1;
			%goto next;
		%end;
		%next:
		%let _ans=&_ans.&SEP.&_tmp;
	%end;

	%let _ans=%sysfunc(trim(&_ans));

	data _null_;
		call symput("&_ans_","&_ans");
	run;

	%exit:
%mend var_compare;

%macro var_info(dsn, var, _pos_=, _typ_=, _lab_ =, _fmt_=, _vfmt_=, _len_=, _infmt_=, lib=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac); 

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(_pos_) EQ 1 and %macro_isblank(_lab_) EQ 1
			and %macro_isblank(_typ_) EQ 1 and %macro_isblank(_len_) EQ 1
			and %macro_isblank(_fmt_) EQ 1 and %macro_isblank(_infmt_) EQ 1 
			and %macro_isblank(_vfmt_) EQ 1,		
			txt=%quote(!!! Missing parameters: _POS_, _LAB_, _TYP_, _LEN_, _FMT_, _INFMT_, and _VFMT_ !!!)) %then
		%goto exit;


	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter, 
			%var_check(&dsn, &var, lib=&lib) EQ 1,		
			txt=!!! Field %upcase(&var) not found in dataset %upcase(&dsn) !!!) %then
		%goto exit;

	data _null_;
   		dsid = open("&lib..&dsn",'i', , 'D'); 
		pos = varnum(dsid, "&var");
		%if not %macro_isblank(_pos_) %then %do;
			call symput("&_pos_",compress(pos,,'s'));
		%end;
		%if not %macro_isblank(_lab_) %then %do;
	    	lab = varlabel(dsid, pos);
			call symput("&_lab_",compress(lab,,'s'));
		%end;
		%if not %macro_isblank(_typ_) %then %do;
	    	typ = vartype(dsid, pos);
			call symput("&_typ_",compress(typ,,'s'));
		%end;
		%if not %macro_isblank(_fmt_) %then %do;
	    	fmt = varfmt(dsid, pos);
			call symput("&_fmt_",compress(fmt,,'s'));
		%end;
		%if not %macro_isblank(_len_) %then %do;
			len = varlen(dsid, pos);
			call symput("&_len_",compress(len,,'s'));
		%end;
		%if not %macro_isblank(_infmt_) %then %do;
			infmt = varinfmt(dsid, pos);
			call symput("&_infmt_",compress(infmt,,'s'));
		%end;
	    rc = close(dsid);
	run;

	%if not %macro_isblank(_vfmt_) %then %do;
		data _null_;
			SET &lib..&dsn;
			vfmt = vformat(&var);
			call symput("&_vfmt_",compress(vfmt,,'s'));
		run;
	%end;

	%exit:
%mend var_info;


%macro ds_alter (dsn ,add= ,typ= ,modify= ,fmt =,lab = ,len = ,drop =, lib= 	);    									     
				  	   			
    %local _mac;
	%let   _mac=&sysmacroname;
	%macro_put(&_mac);

	%local _i                                                
		_isaded         
		_ismodified		
		_isdroped;	

	%let _isaded=%macro_isblank(add);
	%let _ismodified=%macro_isblank(modify);
	%let _isdroped=%macro_isblank(drop);
   
	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&dsn) not found !!!) %then
		%goto exit;

	%if %error_handle(ErrorInputParameter,
			&_isaded EQ 1 and &_ismodified EQ 1 and &_isdroped EQ 1, mac=&_mac,
			txt=!!! At least one variable MUST be empty  !!!) %then	
		%goto exit;
	%else %if %error_handle(ErrorInputParameter,
		  	&_ismodified EQ 1 and (%macro_isblank(fmt) EQ 0 or %macro_isblank(lab) EQ 0 or %macro_isblank(len) EQ 0), mac=&_mac,
			txt=%bquote(!!! Parameters FMT, LAB and LEN ignored when MODIFY is not passed !!!)) 
			or
			%error_handle(ErrorInputParameter,
			  	&_isaded EQ 1 and %macro_isblank(typ) EQ 0, mac=&_mac,
				txt=%bquote(!!! Parameter TYP when ADD is not passed !!!)) %then	
		%goto warning;
	%warning:

	%if not %macro_isblank(add) %then %do;
		%local varadd;
		%sql_clause_add(&dsn, &add, typ=&typ, _add_=varadd, lib=&lib);
		%let add=&varadd;
	%end;

    %if not %macro_isblank(modify) %then %do;
		%local varmod;
		%sql_clause_modify(&dsn, &modify, fmt=&fmt, len=&len, lab=&lab, _mod_=varmod, lib=&lib);
		%let modify=&varmod;
	%end;

	%if not %macro_isblank(drop) %then %do;
		%local vardrop;
		%sql_clause_as(&dsn, &drop, _as_=vardrop, lib=&lib);
		%let drop=&vardrop;
	%end;

   	PROC SQL noprint;
		ALTER TABLE &lib..&dsn
		%if not %macro_isblank(add) %then %do;
		    ADD &add
		%end;
		%if not %macro_isblank(modify) %then %do;
			MODIFY &modify
		%end;
		%if not %macro_isblank(drop) %then %do;
            DROP &drop
		%end;
		;	
	quit;

	%exit:
%mend ds_alter;

%macro sql_clause_modify(dsn, var, _mod_=, fmt=, len=, lab=	, lib=);	 										 
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
	%if %error_handle(ErrorMissingInputParameter, 
			%macro_isblank(var) EQ 1, mac=&_mac,		
			txt=%quote(!!! Missing input parameter VAR !!!))
			or
			%error_handle(ErrorMissingOutputParameter, 
				%macro_isblank (_mod_) EQ 1, mac=&_mac,		
				txt=!!! Missing output parameter _MOD_ !!!) %then
		%goto exit;

	%local SEP
		_modlen;	
	%let SEP=%str( );

	%let _modlen=%list_length(&var, sep=&SEP);


	%if not %macro_isblank(fmt) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&fmt, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and FMT must be of same length !!!) %then	
		%goto exit;
	%end;


	%if not %macro_isblank(len) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&len, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and LEN must be of same length !!!) %then	
		%goto exit;
	%end;


	%if not %macro_isblank(lab) %then %do;
		%if %error_handle(ErrorInputParameter,
			%list_length(&lab, sep=&SEP) NE &_modlen, mac=&_mac,
			txt=!!! Parameters VAR and LAB must be of same length !!!) %then	
		%goto exit;
	%end;


	%if %macro_isblank(lib) %then 	%let lib=WORK;		

	%local _i
		SEP REP
		SEPZIP          
		_var
		_fmt
		_newfmt
		_fmtlen	
		_len
		_newlen
		_nlen
		_lab
		_newlab
		_lablen	
		_newvar; 
	%let SEP=%str( );
	%let REP=%str(,);
	%let SEPZIP=%quote(/UNLIKELYSEPARATOR/);
	%let _newvar=; 
	%let _newfmt=; 
	%let _newlen=; 
	%let _newlab=; 
	%do _i=1 %to %list_length(&var, sep=&SEP);
		%let _var=%scan(&var, &_i, &SEP);
		%if not %macro_isblank(fmt) %then		%let _fmt=%scan(&fmt, &_i, &SEP);
		%if not %macro_isblank(len) %then		%let _len=%scan(&len, &_i, &SEP);
		%if not %macro_isblank(lab) %then		%let _lab=%scan(&lab, &_i, &SEP);
		%if %error_handle(WarningInputParameter, 
				%var_check(&dsn, &_var, lib=&lib) EQ 1, mac=&_mac,		
				txt=%quote(! Variable %upcase(&_var) does not exist in dataset %upcase(&dsn) !),  
				verb=warn) %then 
			%goto next;
		%else %do;
			%let _newvar=&_newvar.&SEP.&_var;
			%if not %macro_isblank(fmt) %then	%let _newfmt=&_newfmt.&SEP.&_fmt;
			%if not %macro_isblank(len) %then	%let _newlen=&_newlen.&SEP.&_len;
			%if not %macro_isblank(lab) %then	%let _newlab=&_newlab.&SEP.&_lab;
		%end;
		%next:
	%end;


	%if not %macro_isblank(_newfmt) %then %do;
		%let _fmtlen=%list_length(&_newfmt, sep=&SEP);
		%let _newfmt=%list_append(%list_ones(&_fmtlen, item=FORMAT), &_newfmt, zip=%str(=));
		%let _newvar=%list_append(&_newvar, %quote(&_newfmt), zip=&SEPZIP);
	%end;
	%if not %macro_isblank(_newlen) %then %do;
		%let _nlen=%list_length(&_newlen, sep=&SEP);
		%let _newlen =%list_append(%list_ones(&_nlen, item=LENGTH), &_newlen, zip=%str(=));
		%let _newvar =%list_append(%quote(&_newvar), %quote(&_newlen), zip=&SEPZIP);
	%end;
	%if not %macro_isblank(_newlab) %then %do;
		%let _lablen=%list_length(&_newlab, sep=&SEP);
		%let _newlab=%list_quote(&_newlab, rep=_EMPTY_, mark=%str(%')); /*'*/
		%let _newlab=%list_append(%list_ones(&_lablen, item=LABEL), &_newlab, zip=%str(=));
		%let _newvar =%list_append(%quote(&_newvar), %quote(&_newlab), zip=&SEPZIP);
	%end;
	%let _newvar=%sysfunc(tranwrd(%quote(&_newvar), %str( ), %str(, )));
	%let _newvar=%sysfunc(tranwrd(%quote(&_newvar), &SEPZIP, %str( )));

	data _null_;
		call symput("&_mod_","&_newvar");
	run;


	%exit:
%mend sql_clause_modify;

%macro sql_clause_where(dsn, var, _where_=, op=, lab=, log=);

	%list_append(&op, %list_quote(&lab,rep=_EMPTY_), 
								zip=%quote(=), 
								rep=%quote( and )
						);
%mend sql_clause_where;

%macro ds_select(idsn, odsn ,var=, varas=, varop=, where=, groupby=, orderby=, having=, distinct=, ilib=, olib=, all=, _proc_=);		 
					
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
	%local nvar 
		DEBUG; 
	%if not %macro_isblank(_proc_) %then		%let DEBUG=1;
	%else %if %symexist(G_PING_DEBUG) %then 	%let DEBUG=&G_PING_DEBUG;
	%else										%let DEBUG=0;


	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	%if %macro_isblank(olib) %then 	%let olib=WORK/*&ilib*/;
	%if %error_handle(WarningOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,		
			txt=! Output dataset %upcase(&odsn) already exists: will be replaced !, 
			verb=warn) %then
		%goto warning;
	%warning:

	%if %macro_isblank(var) %then 			%let var=_ALL_;
	%else 									%let var=%upcase(&var);

	%if "&var"="_ALL_" %then %do;
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(varas) EQ 0 or %macro_isblank(varop) EQ 0, mac=&_mac,		
				txt=!!! Parameters VARAS and VAROP incompatible with empty VAR !!!) %then
			%goto exit;
		%let all=NO;
	%end;
	%else %do;
		%let nvar=; 
		%sql_clause_as(&idsn, &var, as=&varas, op=&varop, _as_=nvar, lib=&ilib);
		%let var=&nvar;
	
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(var) EQ 1, mac=&_mac,		
				txt=%quote(!!! No variables selected from %upcase(&var) !!!)) %then
			%goto exit;
	%end;
	%if %macro_isblank(all)  %then 			%let all=NO; 
	%else									%let all=%upcase(&all);
	%if %macro_isblank(distinct)  %then 	%let distinct=NO; 
	%else									%let distinct=%upcase(&distinct);
 
	%if %error_handle(ErrorInputParameter, 
			%par_check(&all, type=CHAR, set=YES NO) NE 0,	
			txt=!!! Parameter ALL is boolean flag with values in (yes/no) !!!) 
			or
			%error_handle(ErrorInputParameter, 
				%par_check(&distinct, type=CHAR, set=YES NO) NE 0,	
				txt=!!! Parameter DISTINCT is boolean flag with values in (yes/no) !!!) %then
		%goto exit;

	%local REP SEP
		ngrpby	
		nordby; 
	%let SEP=%str( );
	%let REP=%str(,);

	%if not %macro_isblank(groupby) %then %do;
		%let ngrpby=; 
		%sql_clause_by(&idsn, &groupby, _by_=ngrpby, lib=&ilib);
		%let groupby=&ngrpby;
	%end;

	%if not %macro_isblank(orderby) %then %do;
		%let nordby=; 
		%sql_clause_by(&idsn, &orderby, _by_=nordby, lib=&ilib);
		%let orderby=&nordby;
	%end;

	%if &DEBUG=1 %then 
		%goto print;


	PROC SQL noprint 
		%if "&all"="YES" %then %do;
			nowarn
		%end;
		;
		CREATE TABLE &olib..&odsn AS
		SELECT 
		%if "&distinct"="YES" %then %do;
			DISTINCT
		%end;
		%if "&var"^="_ALL_" %then %do;
			&var      
			%if "&all"="YES" %then %do;
				,
			%end; 
		%end; 
		%if "&var"="_ALL_" or "&all"="YES" %then %do;
			*      
		%end; 
		FROM &ilib..&idsn 
		%if not %macro_isblank(where) %then %do;
			WHERE &where
		%end;
		%if not %macro_isblank(groupby) %then %do;
			GROUP BY &groupby
		%end;
		%if not %macro_isblank(having) %then %do;
			HAVING &having
		%end;
		%if not %macro_isblank(orderby) %then %do;
			ORDER BY &orderby
		%end;
		;
	quit;
	%goto exit;

	%print:
	%local _proc;
											%let _proc=%str(PROC SQL noprint;);
											%let _proc=&_proc.%str( CREATE TABLE &olib..&odsn AS SELECT);
	%if %upcase(&distinct)=YES %then 		%let _proc=&_proc.%str( DISTINCT);
											%let _proc=&_proc.%str( &var);
	%if %upcase(&all)=YES %then 			%let _proc=&_proc.%str(, *);
											%let _proc=&_proc.%str( FROM &ilib..&idsn);
	%if not %macro_isblank(where) %then 	%let _proc=&_proc.%str( WHERE &where); 
	%if not %macro_isblank(groupby) %then 	%let _proc=&_proc.%str( GROUP BY &groupby);
	%if not %macro_isblank(having) %then 	%let _proc=&_proc.%str( HAVING &having);
	%if not %macro_isblank(orderby) %then 	%let _proc=&_proc.%str( ORDER BY &orderby);
											%let _proc=&_proc.%str(; quit;);


	%if not %macro_isblank(_proc_) %then %do;
		data _null_;
			call symput("&_proc_", "&_proc");
		run;
	%end;
	%else %do;
		%macro_put(&_mac, txt=%quote(Run procedure: &_proc), debug=1);
	%end;		

	%exit:
%mend ds_select;


%macro silc_ind_create(dsn, var=, dim=, lib=, type=, len=, ignore_var_dim=	, cds_ind_con=, cds_var_dim=, force_Nwgh=NO	, clib=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%local _existvardim	 
		_existindcon;	 
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(var) EQ 0 and %macro_isblank(dim) EQ 0, mac=&_mac,
			txt=%quote(!!! Parameters VAR and DIM are incompatible !!!)) 
			or
			%error_handle(ErrorInputParameter, 
				%macro_isblank(var) EQ 1 and %macro_isblank(dim) EQ 1, mac=&_mac,
				txt=%quote(!!! One at least among parameters VAR and DIM must be set !!!)) %then 
		%goto exit;

 
	%if %macro_isblank(lib) %then	%let lib=WORK;

 
	%if %macro_isblank(ignore_var_dim) %then	%let ignore_var_dim=NO;
	%else 										%let ignore_var_dim=%upcase(&ignore_var_dim);

	%if %error_handle(ErrorInputParameter, 
			%par_check(&ignore_var_dim, type=CHAR, set=YES NO) NE 0, mac=&_mac,
			txt=%quote(!!! Wrong value for boolean flag IGNORE_VAR_DIM !!!)) %then
		%goto exit;

 
	%if %error_handle(ErrorInputParameter, 
			"&ignore_var_dim" EQ "NO" and (%macro_isblank(type) EQ 0 or %macro_isblank(len) EQ 0), mac=&_mac,
			txt=%quote(!!! Parameters TYPE and LEN compatible with IGNORE_VAR_DIM=YES only !!!)) %then
		%goto exit;
 
	%if %macro_isblank(clib) %then	%do;
		%if %symexist(G_PING_LIBCFG) %then 					%let clib=&G_PING_LIBCFG;
		%else												%let clib=LIBCFG;
	%end;

	%if %macro_isblank(cds_ind_con) %then	%do;
		%if %symexist(G_PING_INDICATOR_CONTENTS) %then 		%let cds_ind_con=&G_PING_INDICATOR_CONTENTS;
		%else												%let cds_ind_con=INDICATOR_CONTENTS;
	%end;

 
	%if %macro_isblank(force_Nwgh) %then		%let force_Nwgh=NO; 
	%else 										%let force_Nwgh=%upcase(&force_Nwgh); 

	%if %error_handle(ErrorInputParameter, 
			%par_check(&force_Nwgh, type=CHAR, set=YES NO) NE 0, mac=&_mac,		
			txt=%quote(!!! Wrong value for boolean flag FORCE_NWGH - Must be in YES or NO !!!)) %then 
		%goto exit;

	%if "&ignore_var_dim"="YES" %then %goto ignore_var_dim;

	%let _existindcon= %ds_check(&cds_ind_con, lib=&clib);
	%if %error_handle(MissingConfigurationFile, 
			&_existindcon NE 0, mac=&_mac,
			txt=%quote(! Temporary configuration file %upcase(&cds_ind_con) does not exist: default values to be used !), 
			verb=warn) %then;
		%goto warning1;
	%warning1:

 
	%if %macro_isblank(cds_var_dim) %then %do;
		%if %symexist(G_PING_VARIABLE_DIMENSION) %then 		%let cds_var_dim=&G_PING_VARIABLE_DIMENSION;
		%else												%let cds_var_dim=VARIABLE_DIMENSION;
	%end;

	%let _existvardim= %ds_check(&cds_var_dim, lib=&clib);
	%if %error_handle(MissingConfigurationFile, 
			&_existvardim NE 0, mac=&_mac,
			txt=%quote(! Temporary configuration file %upcase(&cds_var_dim) does not extist: default values to be used !), 
			verb=warn) %then %do;
		%if %error_handle(ErrorMissingParameter, 
				%macro_isblank(var) EQ 0, mac=&_mac,
				txt=%quote(!!! Configuration file requested when passing VAR instead of DIM !!!)) %then 
			%goto exit;
		%else 
			%goto warning2;
		%warning2:
	%end;

	%ignore_var_dim:
	%local _typ _len
		l_NWGH			 
		l_TOTWGH		 
		;
	%let _typ=;
	%let _len=;

	%if not %macro_isblank(var) %then %do;  
		%local variables;  
		%let variables=;

	 
		%var_to_list(&cds_var_dim, VARIABLE, _varlst_=variables, lib=&clib);
	 
		%if %error_handle(UnmatchedInputVariable, 
				%list_difference(&var, &variables) NE , mac=&_mac,
				txt=%quote(!!! Unmatched variables %upcase(&var) in %upcase(&cds_var_dim) !!!)) %then 
			%goto exit;
		
	 
		%list_map(&cds_var_dim, &var, var=VARIABLE DIMENSION, _maplst_=dim, lib=&clib);		
	%end;

 
	%if &_existvardim=0 and "&ignore_var_dim"="NO" %then %do;
		%local dimensions;  
		%let dimensions=;

	 
		%var_to_list(&cds_var_dim, DIMENSION, _varlst_=dimensions, lib=&clib);

	 
		%if %error_handle(UnmatchedInputDimension, 
				%list_difference(&dim, &dimensions) NE , mac=&_mac,
				txt=%quote(!!! Unmatched dimensions %upcase(&dim) in %upcase(&cds_var_dim) !!!)) %then 
			%goto exit;

	 
		%list_map(&cds_var_dim, &dim, var=DIMENSION type, _maplst_=_typ, lib=&clib);
		%list_map(&cds_var_dim, &dim, var=DIMENSION length, _maplst_=_len, lib=&clib);
	%end;
	%else %if "&ignore_var_dim"="YES" %then %do;
		%if not %macro_isblank(type) %then %let _typ=&type;
		%if not %macro_isblank(len) %then %let _len=&len;
	%end;

 
	%if %symexist(G_PING_LAB_NWGH) %then 		%let l_NWGH=&G_PING_LAB_NWGH;
	%else										%let l_NWGH=nwgh;
	%if %symexist(G_PING_LAB_TOTWGH) %then 		%let l_TOTWGH=&G_PING_LAB_TOTWGH;
	%else										%let l_TOTWGH=totwgh;

	 
	%if &_existindcon NE 0 %then %do;
		%local _ISTEMP_		 
			l_GEO			 
			GEO_LENGTH		
			l_TIME		 
			TIME_LENGTH			
			l_UNIT		 
			UNIT_LENGTH		
			l_VALUE		 
			l_UNREL		 
			l_N			 
			l_NTOT		 
			l_IFLAG			 
			IFLAG_LENGTH;
		%let _ISTEMP_=YES;

	 
		%if %symexist(G_PING_LAB_GEO) %then 		%let l_GEO=&G_PING_LAB_GEO;
		%else										%let l_GEO=geo;
		%if %symexist(G_PING_LEN_GEO) %then 		%let GEO_LENGTH=&G_PING_LEN_GEO;
		%else										%let GEO_LENGTH=15;
		%if %symexist(G_PING_LAB_TIME) %then 		%let l_TIME=&G_PING_LAB_TIME;
		%else										%let l_TIME=time;
		%if %symexist(G_PING_LEN_TIME) %then 		%let TIME_LENGTH=&G_PING_LEN_TIME;
		%else										%let TIME_LENGTH=4;
		%if %symexist(G_PING_LAB_UNIT) %then 		%let l_UNIT=&G_PING_LAB_UNIT;
		%else										%let l_UNIT=unit;
		%if %symexist(G_PING_LEN_UNIT) %then 		%let UNIT_LENGTH=&G_PING_LEN_UNIT;
		%else										%let UNIT_LENGTH=8;
		%if %symexist(G_PING_LAB_VALUE) %then 		%let l_VALUE=&G_PING_LAB_VALUE;
		%else										%let l_VALUE=ivalue;
		%if %symexist(G_PING_LAB_UNREL) %then 		%let l_UNREL=&G_PING_LAB_UNREL;
		%else										%let l_UNREL=unrel;
		%if %symexist(G_PING_LAB_N) %then 			%let l_N=&G_PING_LAB_N;
		%else										%let l_N=n;
		%if %symexist(G_PING_LAB_NTOT) %then 		%let l_NTOT=&G_PING_LAB_NTOT;
		%else										%let l_NTOT=ntot;
		%if %symexist(G_PING_LAB_IFLAG) %then 		%let l_IFLAG=&G_PING_LAB_IFLAG;
		%else										%let l_IFLAG=iflag;
		%if %symexist(G_PING_LEN_IFLAG) %then 		%let IFLAG_LENGTH=&G_PING_LEN_IFLAG;
		%else										%let IFLAG_LENGTH=8;

		DATA WORK.&cds_ind_con;
			length LABEL $15;
			length TYPE $4;
			LABEL="&l_GEO"; 	TYPE="char"; 	LENGTH=&GEO_LENGTH; 	ORDER=1; 	output;
			LABEL="&l_TIME "; 	TYPE="num"; 	LENGTH=&TIME_LENGTH; 	ORDER=2; 	output;
			LABEL="&l_UNIT"; 	TYPE="char"; 	LENGTH=&UNIT_LENGTH; 	ORDER=-10; 	output;
			LABEL="&l_VALUE"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-9; 	output;
			LABEL="&l_IFLAG"; 	TYPE="char"; 	LENGTH=&IFLAG_LENGTH; 	ORDER=-8; 	output;
			LABEL="&l_UNREL"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-7; 	output;
			LABEL="&l_N"; 		TYPE="num"; 	LENGTH=8; 				ORDER=-6; 	output;
			LABEL="&l_NWGH"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-5; 	output;
			LABEL="&l_NTOT"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-4; 	output;
			LABEL="&l_TOTWGH"; 	TYPE="num"; 	LENGTH=8; 				ORDER=-3; 	output;
			LABEL="lastup"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-2; 	output;
			LABEL="lastuser"; 	TYPE="char"; 	LENGTH=8; 				ORDER=-1; 	output;
		run;
		%let clib=WORK;
	%end;
	%else %let _ISTEMP_=NO;

	%ds_create(&dsn
			, idsn=&cds_ind_con
			, var=&dim
			, type=&_typ
			, len=&_len
			, ilib=&clib
			, olib=&lib
			);
	DATA &lib..&dsn
		%if %var_check(&dsn, &l_TOTWGH, lib=&lib) NE 0 %then %do;
			(rename=(n&l_TOTWGH=&l_TOTWGH)) /* we clean up a bit... */
		%end;
		;
		SET &lib..&dsn
		%if "&force_Nwgh" EQ "NO" and %var_check(&dsn, &l_NWGH, lib=&lib) EQ 0 %then %do;
				(DROP=&l_NWGH)
		%end;
		;
	run;

	%if &_ISTEMP_=YES %then %do;
		%work_clean(&cds_ind_con);
	%end; 

	%exit:
%mend silc_ind_create;

%macro ds_create(odsn, idsn=, var=, type=, len=	, idrop=, olib=, ilib=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);
	%local nvar		 
		ntyp		 
		nlen			 
		DEF_VAR_LENGTH	
		DEF_VAR_TYPE
		_i _j _k		 
		cvar			 
		cord		 
		ctyp		 
		clen		 
		ncvar			 
		_ord		 
		_lab		 
		_typ		 
		_len		 
		_ENTRY_;	 

	%if %symexist(G_PING_VAR_LENGTH) %then 		%let DEF_VAR_LENGTH=&G_PING_VAR_LENGTH;
	%else										%let DEF_VAR_LENGTH=15;
	%if %symexist(G_PING_VAR_TYPE) %then 		%let DEF_VAR_TYPE=&G_PING_VAR_TYPE;
	%else										%let DEF_VAR_TYPE=char;

	%let nvar=%list_length(&var); 

	%if %macro_isblank(type) %then 	%let type=&DEF_VAR_TYPE;
	%let ntyp=%list_length(&type);
	%if &ntyp=1 and &ntyp^=&nvar %then 
		%let type=%list_ones(&nvar, item=&type);

	%if %macro_isblank(len) %then 	%let len=&DEF_VAR_LENGTH;
	%let nlen=%list_length(&len);
	%if &nlen=1 and &nlen^=&nvar %then 
		%let len=%list_ones(&nvar, item=&len);

	%if %error_handle(ErrorInputParameter, 
			%list_length(&type) NE &nvar or %list_length(&len) NE &nvar, mac=&_mac,
			txt=%quote(!!! Incompatible parameters TYP and/or LEN with VAR !!!)) %then 
		%goto exit; 


	%if %macro_isblank(olib) %then %let olib=WORK;
	%if %error_handle(ExistingOutputDataset, 
			%ds_check(&odsn, lib=&olib) EQ 0, mac=&_mac,
			txt=%quote(! Output table already exist !), verb=warn) %then 
		%goto warning1;
	%warning1:


	%if %macro_isblank(ilib) %then %let ilib=WORK;

	%if %error_handle(MissingConfigurationFile, 
			%macro_isblank(idsn) EQ 1, mac=&_mac,
			txt=%quote(! No dataset of common dimensions passed - Only VAR will be included !), 
			verb=warn) %then %do;
		%if %error_handle(MissingConfigurationFile, 
				%macro_isblank(idrop) EQ 0, mac=&_mac,
				txt=%quote(! Parameter IDROP ignored when IDSN is not passed !), 
				verb=warn) %then
			%goto warning2;
		%warning2:
		%goto skip;
	%end;
	%else %if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) NE 0, mac=&_mac,
			txt=%quote(!!! Input dataset %upcase(idsn) not found !!!)) %then 
		%goto exit;

	%local _tmp; 		
	%let _tmp=TMP&_mac;

	PROC SQL noprint;
		CREATE TABLE WORK.&_tmp AS
		SELECT *
		FROM &ilib..&idsn
		ORDER BY (case when order<0 then 1 else 0 end), order;
	quit;

	%var_to_list(&_tmp, 1, _varlst_=cvar);
	%if not %macro_isblank(idrop) %then %do;
		%let cvar=%list_difference(&cvar, &idrop);
	%end;
	%let ncvar=%list_length(&cvar); 
	%var_to_list(&_tmp, TYPE, 	_varlst_=ctyp);
	%var_to_list(&_tmp, LENGTH, _varlst_=clen);
	%var_to_list(&_tmp, ORDER, 	_varlst_=cord);
	%work_clean(&_tmp);
	%goto build;

	%skip: 
	%let cvar=;	
	%let cord=;	
	%let ctyp=;	
	%let clen=;	
	%let ncvar=-1;
	%goto build;

	%build: 
	%let _ENTRY_=0;
	PROC SQL noprint;
		CREATE TABLE &olib..&odsn 
			(
			%do _i=1 %to &ncvar;
				%let _ord=%scan(&cord, &_i, %str( ));
				%if &_ord<0 %then 	%goto break;
				%let _lab=%scan(&cvar, &_i, %str( ));
				%let _typ=%scan(&ctyp, &_i, %str( ));
				%let _len=%scan(&clen, &_i, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab &_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
				%if &_i=&ncvar %then %let _i=%eval(_i+1);
			%end;
			%break:
			%do _j=1 %to &nvar;
				%let _lab=%scan(&var, &_j, %str( ));
				%let _typ=%scan(&type, &_j, %str( ));
				%let _len=%scan(&len, &_j, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab	&_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
			%end;
			%do _k=&_i %to &ncvar;
				%let _lab=%scan(&cvar, &_k, %str( ));
				%let _typ=%scan(&ctyp, &_k, %str( ));
				%let _len=%scan(&clen, &_k, %str( ));
				%if &_ENTRY_=0 %then %do;
					&_lab 	&_typ
				%end;
				%else %do;
					, &_lab &_typ
				%end;
				%if &_len^= %then %do;
					(&_len)
				%end;
				%let _ENTRY_=1;
			%end;
			%quit:
			);
	quit;
	
	%exit:
%mend ds_create;

%macro var_to_list(dsn, var, _varlst_=, distinct=, where=, na_rm=, sep=, lib=);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	%if %error_handle(ErrorOutputParameter, 
			%macro_isblank(_varlst_) EQ 1, mac=&_mac,		
			txt=!!! Output parameter _VARLST_ not set !!!) %then
		%goto exit;

	%if %macro_isblank(distinct)  %then 	%let distinct=NO; 
	%else									%let distinct=%upcase(&distinct);
 	%if %macro_isblank(na_rm)  %then 		%let na_rm=YES; 
	%else									%let na_rm=%upcase(&na_rm);

	%if %error_handle(ErrorInputParameter, 
			%par_check(%upcase(&distinct &na_rm), type=CHAR, set=YES NO) NE 0 0, mac=&_mac,		
			txt=%quote(!!! Wrong parameter for boolean flags NA_RM/DISTINCT !!!)) %then
		%goto exit;

	%if %macro_isblank(sep) %then 	%let sep=%quote( ); 

 	%if %macro_isblank(lib) %then 	%let lib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&dsn, lib=&lib) NE 0, mac=&_mac,		
			txt=%quote(!!! Dataset %upcase(&dsn) not found in library %upcase(&lib) !!!)) %then
		%goto exit;
	%local _ans	
		_count 		
		_varlst		
		_METHOD_;	
	%let _METHOD_=BEST; 

	%if %list_count(%par_check(&var, type=INTEGER), 0) >0 %then %do;
		%var_check(&dsn, &var, _varlst_=_varlst, lib=&lib);
		%if %error_handle(ErrorInputParameter, 
				%macro_isblank(_varlst) EQ 1, mac=&_mac,		
				txt=%quote(!!! Field %upcase(&var) not found in dataset %upcase(&dsn) !!!)) %then
			%goto exit;
	
		%let var=&_varlst; 
	%end;
	%ds_isempty(&dsn, var=&var, lib=&lib, _ans_=_ans);
	%if %error_handle(EmptyInputDataset, 
			&_ans EQ 1, mac=&_mac,		
			txt=%quote(!!! Dataset %upcase(&dsn) is empty !!!)) %then
		%goto exit;
	%if &_METHOD_=BEST or %upcase(&na_rm)=NO %then %do;

		PROC SQL noprint;
			SELECT 
			%if %upcase("&distinct")="YES" %then %do;
				DISTINCT
			%end;
			&var
			INTO :&_varlst_  SEPARATED BY "&sep" 
			FROM &lib..&dsn
			%if not %macro_isblank(where) OR %upcase("&na_rm")="YES" %then %do;
				WHERE
				%if %upcase("&na_rm")="YES" %then %do;
					not missing(&var)
				%end;
				%if not %macro_isblank(where) AND %upcase("&na_rm")="YES" %then %do;
					and
				%end;
				%if not %macro_isblank(where) %then %do;
					&where
				%end;
			%end;
			;
		quit;
	%end;
	%else %if &_METHOD_=DUMMYandOBSOLETE %then %do;
		%local _dsn 	 
			_slen 		 
			_typ 		 
			_fmt 	 
			_vfmt 		 
			_len 	 
			num;		 
		%let _dsn=TMP_%upcase(&sysmacroname);
		%if %upcase(&distinct)=YES %then %do;
			PROC SQL noprint;
				CREATE TABLE &_dsn AS
				SELECT DISTINCT &var
				FROM &lib..&dsn
			quit;
			%let lib=WORK;
		%end;
		%else %do;
			%let _dsn=&dsn;
		%end;
		%var_info(&_dsn, &var, _typ_=_typ, _fmt_=_fmt, _vfmt_=_vfmt, _len_=_len, lib=&lib);
		%if %macro_isblank(_fmt) %then %do;
	
			%if &_typ=N %then 			%let _fmt=best&_len..;
			%else %if &_typ=C %then 	%let _fmt=$char&_len..;
		%end;
		%let num=%eval(&_count);
		%let _slen=%eval(&num*(&_len+4));
		DATA _null_;
			set &lib..&_dsn end=_last; 
			array v(&num) $&_len;
			retain i (0);
			retain v;
			length varlst $&_slen;
			if  not missing(&var) then do;
				i = i + 1;
				v(i) = put(&var, &_fmt);
			end;
			if _last then do;
				varlst = v(1);
				do j = 2 to i-1;
					varlst = compbl(varlst)||trim(v(j))||"&sep";
				end;
				if i>1 then do;
					varlst = compbl(varlst)||trim(v(i));
				end;
				call symput("&_varlst_",compbl(varlst));
			end;
		run;

		%if %upcase(&distinct)=YES %then %do;
			%work_clean(&_dsn);
		%end;
	%end;

	%exit:
%mend var_to_list;

















