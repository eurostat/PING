%global G_PING_PGM_LIGTH_LOADED
	G_PING_PGM_LIGTH_PATH;

%let G_PING_PGM_LIGTH_PATH=			/ec/prod/server/sas/0eusilc/7.3_Dissemination/pgm; 
%let G_PING_PGM_LIGTH_LOADED=		1;


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
