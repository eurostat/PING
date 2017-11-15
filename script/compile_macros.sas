%let pgm_path = /ec/prod/server/sas/1eusilc/2.Personal_folders/Pierre/sas/PING/library/pgm ;
%let macro_lib = /ec/prod/server/sas/1eusilc/2.Personal_folders/Pierre/sas/PING/library/macros ;



%macro list_members(folder,suffix,partial,name_list=mylist) ;

%global &name_list ;

%let fileref = myfile ;

%let rc = %sysfunc(filename(fileref,"&folder")) ;
%let did = %sysfunc(dopen(&fileref)) ;
%let memcount = %sysfunc(dnum(&did)) ;


%let &name_list = ;

%if &memcount > 0 %then %do ;
	%do n = 1 %to &memcount ;
		%let name = %sysfunc(dread(&did,&n)) ;
		%if (&suffix ne ) %then %do ;
			%if (&partial = ) %then %do ;
				%if %substr(&name,%eval(%length(&name)-%length(&suffix)),%eval(%length(&suffix)+1)) = .&suffix %then %do ;
					%let &name_list = &&&name_list %substr(&name,1,%eval(%length(&name)-%length(&suffix)-1)) ;
				%end ;
			%end ;
			%if (&partial ne ) %then %do ;
				%if %substr(&name,%eval(%length(&name)-%length(&suffix)),%eval(%length(&suffix)+1)) = .&suffix and %index(&name,&partial) > 0 %then %do ;
					%let &name_list = &&&name_list %substr(&name,1,%eval(%length(&name)-%length(&suffix)-1)) ;
				%end ;
			%end ;
		%end ;
		%if (&partial ne ) and (&suffix = ) %then %do ;
			%if %index(&name,&partial) > 0 %then %do ;
				%let &name_list = &&&name_list &name ;
			%end ;
		%end ;
		%if (&partial = ) and (&suffix = ) %then %do ;
			%let &name_list = &&&name_list &name ;
		%end ;
	%end ;
%end ;

%let rc = %sysfunc(dclose(&did)) ;

%mend ;

%list_members(folder=&pgm_path,suffix=sas,name_list=list_script) ;

libname maclib "&macro_lib" ;

options mstored sasmstore=maclib ;

%let list_to_exclude = libformat_update _egp_geotime _egp_path _egp_prompt _example_check _template_macro str_type ;

%let list_to_exclude_regex=\b%sysfunc(prxchange(s/ +/ ?\b|\b/oi,-1,&list_to_exclude))\b;
%let list_script=%sysfunc(prxchange(s/&list_to_exclude_regex//oi,-1,&list_script));


%macro compile_macros(all=YES) ;

%do num_mac = 1 %to %sysfunc(countw(&list_script)) ;

	%let file = %scan(&list_script,&num_mac) ;
	%put ************************ ;
	%put macro n &num_mac ;
	%put COMPILING MACRO IN FILE %upcase(&file).SAS ;
	%put ************************ ;

	data temp ;
	infile "&pgm_path/&file..sas" termstr=crlf encoding='utf-8' dsd missover dlmstr="p!p" expandtabs;
	format text $500. ;
	informat text $500. ;
	input text $ ;
	run ;

	data temp ;
	set temp ;
	retain keep_obs 0 ;
	if index(lowcase(text),%nrstr('%macro')) > 0 and scan(lowcase(text),1) = "macro" and lag(keep_obs) = 0 
	%if &all = NO %then %do ;
		and lowcase(scan(text,2)) = "&file"
	%end ;
	then keep_obs = 1 ;
	else if lag(keep_obs) > 0 and index(lowcase(text),%nrstr('%macro')) > 0 and scan(lowcase(text),1) = "macro" then do ; /* macro inside another macro */
		keep_obs + 1 ;
	end ;
	if index(lowcase(lag(text)),%nrstr('%mend')) > 0 and scan(lowcase(text),1) = "mend" then keep_obs = keep_obs - 1 ;
	run ;

	data temp ;
	set temp ;
	retain header slash 0 ;
	if keep_obs > 0 and lag(keep_obs) = 0 then do ;
		header = 1 ;
		if index(text,"/") > 0 and (index(text,"/") ne index(text,"/*")) then slash = 1 ;
	end ;
	if header = 1 and index(text,";")>0 then do ;
		if slash = 0 then text = tranwrd(text,";"," / store ;") ;
		else text = tranwrd(text,";"," store ;") ;
		header = 0 ;
		slash = 0 ;
	end ;
	run ;

	data _null_ ;
	file "&macro_lib./script.sas" lrecl=36000 ;
	set temp ;
	put text ;
	where keep_obs > 0 ;
	run ;

	%include "&macro_lib./script.sas" / source2 ;
%end ;

%mend ;

%compile_macros ;






