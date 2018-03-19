/** 
## obs_duplicate {#sas_obs_duplicate}
Extract duplicated/unique observations from a given dataset.

~~~sas
	%obs_duplicate(idsn, dim=, dupdsn=, unidsn=, where=, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `dim` : (_option_) list of fields/variables of `idsn` ; 
* `where` : (_option_) expression used to refine the selection (`WHERE` clause); it should be 
	passed with `%%str`; note that if `&where` applies on duplicates, then the (complement)
	condition `not(&where)` is implicitely applied for defining unique values; default: empty;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used.

### Returns
* `dupdsn` : name of the output dataset with duplicated observations and, when the parameter 
	`where` is set, where the condition `&where` applies; it will contain the selection operated 
	on the original dataset;
* `unidsn` : name of the output dataset with unique observations or, when the parameter `where` 
	is set, observations where the condition `not(&where)` applies.

### Examples
Given the following `test` dataset:

| geo | time | hhtyp      | unit   | value        |
|:---:|-----:|:----------:|:------:|-------------:|
| BE  | 2015 | HH_NDCH    | PC_POP | 9.6357       |
| BE  | 2015 | A1         | PC_POP | 16.3064      |
| BE  | 2016 | A1_DCH     | PC_POP | 15.2566      |
| BE  | 2015 | A_GE2_DCH  | PC_POP | 13.6311      |
| BE  | 2015 | A_GE2_NDCH | PC_POP | 7.5261       |
| BE  | 2015 | HH_DCH     | PC_POP | 13.7553      |
| BE  | 2015 | HH_NDCH    | PC_POP | 9.2194       |
| BE  | 2017 | A1         | PC     | 14.1011      |
| BE  | 2015 | A1_DCH     | PC     | 28.1739      |
| BE  | 2015 | A_GE2_DCH  | PC     | 17.0768      |
| BE  | 2015 | A_GE2_NDCH | PC     | 8.2945       |
| BE  | 2015 | HH_DCH     | PC     | 18.041       |
| BE  | 2015 | HH_NDCH    | PC     | 9.2041       |
| BE  | 2016 | A1         | PC     | 25.9502      |
| BE  | 2015 | A1_DCH     | PC     | 17.0741      |
| BE  | 2015 | A_GE2_DCH  | PC     | 6.0417       |
| BE  | 2015 | A_GE2_NDCH | PC     | 5.5593       |
then launching the following command:

~~~sas
	%let _dim=geo time hhtyp;
	%let _where=%quote(UNIT="PC_POP");
	%obs_duplicate(test, dim=&_dim, unidsn=unidsn, dupdsn=dupdsn, where=_where);
~~~
will create the following `dupdsn` table of duplicate observations: 
| geo | time | hhtyp      | unit   | value        |
|:---:|-----:|:----------:|:------:|-------------:|
| BE  | 2015 | 	A_GE2_D   | PC_POP | 13.6311      |
| BE  | 2015 | 	A_GE2_N   | PC_POP | 7.5261       |
| BE  | 2015 | 	HH_DCH    | PC_POP | 13.7553      |
| BE  | 2015 | 	HH_NDCH	  | PC_POP | 9.6357       |
| BE  | 2015 | 	HH_NDCH	  | PC_POP | 9.2194       |

and the following `unidsn` table of non-duplicates observations:
| geo | time | hhtyp      | unit   | value        |
|:---:|-----:|:----------:|:------:|-------------:|
| BE  | 2015 | A1	      | PC_POP | 16.3064      |
| BE  | 2015 | A1_DCH     | PC	   | 28.1739      |
| BE  | 2015 | A1_DCH     | PC	   | 17.0741      |
| BE  | 2015 | A_GE2_D    | PC	   | 17.0768      |
| BE  | 2015 | A_GE2_D    | PC	   | 6.0417       |
| BE  | 2015 | A_GE2_N    | PC	   | 8.2945       |
| BE  | 2015 | A_GE2_N    | PC	   | 5.5593       |
| BE  | 2015 | HH_DCH     | PC	   | 18.041       |
| BE  | 2015 | HH_NDCH    | PC	   | 9.2041       |
| BE  | 2016 | A1	      | PC	   | 25.9502      |
| BE  | 2016 | A1_DCH     | PC_POP | 15.2566      |
| BE  | 2017 | A1	      | PC	   | 14.1011      |

Run `%%_example_obs_duplicate` for more examples.

* ### References
1. Note on ["FIRST. and LAST. variables"](http://www.albany.edu/~msz03/epi514/notes/first_last.pdf).
2. Note on ["Working with grouped observations"](http://www.cpc.unc.edu/research/tools/data_analysis/sastopics/bygroups).
3. ["How the DATA step identifies BY groups"](http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#a000761931.htm).
4. Cai, E. (2015): ["Getting all Duplicates of a SAS data set"](https://chemicalstatistician.wordpress.com/2015/01/05/getting-all-duplicates-of-a-sas-data-set/).
5. Cai, E. (2015): ["Separating unique and duplicate observations using PROC SORT in SAS 9.3 and newer versions"](https://chemicalstatistician.wordpress.com/2015/04/10/separating-unique-and-duplicate-variables-using-proc-sort-in-sas-9-3-and-newer-versions/).

### Notes
1. In practice, when all input parameters are set, the following is run:

~~~sas
	PROC SORT 
		DATA=&ilib..&idsn OUT=TMP;
		BY &dim;
	run;
	
	%let dim_last = %scan(&dim, %list_length(&dim));
	DATA TMP;
		SET TMP;
		BY &dim;
		f_&dim_last = first.&dim_last;
		l_&dim_last = last.&dim_last;
	run;
	
	PROC SQL;
		CREATE TABLE &olib..&dupdsn(DROP=f_&dim_last l_&dim_last) AS
		SELECT * FROM TMP
		WHERE (f_&dim_last=0 or l_&dim_last=0) AND &where;
	run;

	PROC SQL;
		CREATE TABLE &olib..&unidsn(DROP=f_&dim_last l_&dim_last) AS
		SELECT * FROM TMP
		WHERE (f_&dim_last=1 and l_&dim_last=1) OR not (&where);
	run;
~~~
2. By convention (and construction because of the way `where` is used: see above), the output 
datasets `dupdsn` and `unidsn` will always be complement to each other with respect to the 
initial dataset, _i.e._ `idsn \ dupdsn = unidsn` and `idsn \ unidsn = dupdsn`. This means that
any observation from the input dataset `idsn` will be present, in output, in either `unidsn` or 
`dupdsn`. 
3. As a consequence, it also means that the observations in `unidsn` may actually not be unique
when the condition `where` is set. Instead, the observations in `dupdsn` are always duplicates
(and `unidsn` is the set of non-duplicates observations).

### See also
[%obs_select](@ref sas_obs_select), [%ds_isempty](@ref sas_ds_isempty), [%ds_check](@ref sas_ds_check),
[%sql_clause_by](@ref sas_sql_clause_by), [%sql_clause_as](@ref sas_sql_clause_as), [%ds_select](@ref sas_ds_select), 
[SELECT ](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473678.htm).
*/ /** \cond */

/* credits: gjacopo, pierre-lamarche */

%macro obs_duplicate(idsn		/* Input dataset 															(REQ) */
					, dim=		/* Dimensions taken into account when identifying identical observations	(OPT) */
					, dupdsn=	/* Output dataset of duplicated observations 								(OPT) */
					, unidsn=	/* Output dataset of unique observations									(OPT) */
					, where=	/* Statement used which duplicates to select 								(OPT) */
					, ilib=		/* Name of the input library 												(OPT) */
					, olib=		/* Name of the output library 												(OPT) */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%local _dimensions;
	%let _dimensions=;

	/* IDSN/ILIB: check  the input dataset */
	%if %macro_isblank(ilib) %then 	%let ilib=WORK;

	%if %error_handle(ErrorInputDataset, 
			%ds_check(&idsn, lib=&ilib) EQ 1, mac=&_mac,		
			txt=!!! Input dataset %upcase(&idsn) not found !!!) %then
		%goto exit;

	/* DIM: set/check */
	%ds_contents(&idsn, _varlst_=_dimensions, lib=&ilib);

	%if %macro_isblank(dim) %then 		%let dim=&_dimensions;
	%else 								%let dim=%list_intersection(&_dimensions, &dim);
	/* note that, in the case it is not empty, DIM is now reordered according to the occurrence 
	* of the variables in the dataset (same as _DIMENSIONS */

	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(dim) EQ 1, mac=&_mac,		
			txt=!!! Input variables not found in input dataset &idsn !!!) %then
		%goto exit;

	/* OLIB: set default  */
	%if %macro_isblank(olib) %then 	%let olib=WORK/*&ilib*/;

	/* DUPDSN: default output dataset */
	%if not %macro_isblank(dupdsn) %then %do;
		%if %error_handle(WarningOutputDataset, 
				%ds_check(&dupdsn, lib=&olib) EQ 0, mac=&_mac,		
				txt=! Output dataset of duplicates %upcase(&dupdsn) already exists: will be replaced !, 
				verb=warn) %then
			%goto warning1;
		%warning1:
	%end;

	/* UNIDSN: default output dataset */
	%if not %macro_isblank(unidsn) %then %do;
		%if %error_handle(WarningOutputDataset, 
				%ds_check(&unidsn, lib=&olib) EQ 0, mac=&_mac,		
				txt=! Output dataset of unique values %upcase(&unidsn) already exists: will be replaced !, 
				verb=warn) %then
			%goto warning2;
		%warning2:
	%end;

	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _dim_last
		_ndim;

	/*	%let dim=geo time hhtyp indic_il; */
	%let _ndim=%list_length(&dim);
	%let _dim_last=%scan(&dim, &_ndim);

	%local _dsn;
	%let _dsn=_TMP&_mac;

	%let _FORCE_SORT_=NO;

	%if %sysevalf(&sysver >= 9.3) or "&_FORCE_SORT_"="YES" %then %do;
		PROC SORT
			DATA = &ilib..&idsn
			%if not %macro_isblank(dupdsn) %then %do;
		    	OUT = &olib..&dupdsn
			%end;
			%if not %macro_isblank(unidsn) or not %macro_isblank(where) %then %do;
				UNIQUEOUT = &olib..&unidsn
			%end;
		    NOUNIQUEKEY;
		    BY &dim;
		run;
		%if not %macro_isblank(where) %then %do;
			%ds_select(&dupdsn, &_dsn, where=&where, all=yes, ilib=&olib, olib=WORK);
			/* !!! NOPE %ds_append(&unidsn, &_dsn, , lib=&olib, ilib=WORK); */
		%end;
		%goto exit;
	%end;
 	/* %else: proceed... */

	PROC SORT 
		DATA=&ilib..&idsn 
		OUT=&_dsn;
		BY &dim;
	run;
	
	/* we get rid of the simplest case: WHERE is blank */
	%if %macro_isblank(where) %then %do;
		/* unique values */
		DATA &olib..&unidsn;
			SET &_dsn; 
			BY &dim;
			IF first.&_dim_last=1 AND last.&_dim_last=1;
		run;
		/* duplicates */
		DATA &olib..&dupdsn;
			SET &_dsn; 
			BY &dim;
			IF first.&_dim_last=0 OR last.&_dim_last=0;
		run;
		%goto quit;
	%end;
	/* %else: proceed... */

	/* create table with FIRST/LAST variables */
	DATA &_dsn;
		SET &_dsn;
		BY &dim;
		first_&_dim_last = first.&_dim_last;
		last_&_dim_last = last.&_dim_last;
		/* LABEL
			first_&_dim_last = 'first.&_dim_last'
			last_&_dim_last = 'last.&_dim_last'; */
	run;
	
	/* create table of duplicates */
	%if not %macro_isblank(dupdsn) %then %do;
		PROC SQL noprint;
			CREATE TABLE &olib..&dupdsn(DROP=first_&_dim_last last_&_dim_last)  AS
			SELECT * /* &_dimensions, * */
			FROM &_dsn
			WHERE (first_&_dim_last=0 or last_&_dim_last=0) AND &where;
		run;
	%end;

	/* create table of unique values */
	%if not %macro_isblank(unidsn) %then %do;
		PROC SQL noprint;
			CREATE TABLE &olib..&unidsn(DROP=first_&_dim_last last_&_dim_last) AS
			SELECT * /* &_dimensions, * */
			FROM &_dsn
			WHERE (first_&_dim_last=1 and last_&_dim_last=1) OR not (&where);
		run;
	%end;

	%quit:
	%work_clean(&_dsn);

	%exit:
%mend obs_duplicate;


%macro _example_obs_duplicate;
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

	%local dim where 
		cnt dcnt ucnt
		dupval unitval;

	/* note the variable DUP below:
	* 	- first digit: boolean flag (0/1) set to 1 when the current observation has a duplicate with unit="PC_POP"
	*	- second digit: ibid, set to 1 when the current observation has a duplicate with unit="PC" 
	*/
	DATA test;
		geo="BE  "; time=2015; hhtyp="HH_NDCH";    indic_il="LIP_MD60"; unit="PC_POP"; dup="11"; ivalue=9.6356617344; output;
		geo="BE";   time=2015; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC_POP"; dup="00"; ivalue=16.30637264;  output;
		geo="BE";   time=2016; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC_POP"; dup="00"; ivalue=15.256596775; output;
		geo="BE";   time=2015; hhtyp="A_GE2_DCH";  indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=13.631088356; output;
		geo="BE";   time=2015; hhtyp="A_GE2_NDCH"; indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=7.5261077037; output;
		geo="BE";   time=2015; hhtyp="HH_DCH";     indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=13.755266381; output;
		geo="BE";   time=2015; hhtyp="HH_NDCH";    indic_il="LIP_MD60"; unit="PC_POP"; dup="11"; ivalue=9.2194453624; output;
		geo="BE";   time=2017; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC";     dup="00"; ivalue=14.101123997; output;
		geo="BE";   time=2015; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="01"; ivalue=28.173894694; output;
		geo="BE";   time=2015; hhtyp="A_GE2_DCH";  indic_il="LIP_MD60"; unit="PC";     dup="11"; ivalue=17.076805818; output;
		geo="BE";   time=2015; hhtyp="A_GE2_NDCH"; indic_il="LIP_MD60"; unit="PC";     dup="11"; ivalue=8.2945434449; output;
		geo="BE";   time=2015; hhtyp="HH_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=18.040964168; output;
		geo="BE";   time=2015; hhtyp="HH_NDCH";    indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=9.2040946555; output;
		geo="BE";   time=2016; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC";     dup="00"; ivalue=25.95019727;  output;
		geo="BE";   time=2015; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="01"; ivalue=17.074086034; output;
		geo="BE";   time=2015; hhtyp="A_GE2_DCH";  indic_il="LIP_MD60"; unit="PC";     dup="11"; ivalue=6.0416912031; output;
		geo="BE";   time=2015; hhtyp="A_GE2_NDCH"; indic_il="LIP_MD60"; unit="PC";     dup="11"; ivalue=5.5593306824; output;
		geo="EA18"; time=2015; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=14.101123997; output;
		geo="EA18"; time=2015; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=18.298578708; output;
		geo="EA18"; time=2015; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=28.173894694; output;
		geo="EA18"; time=2015; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=25.232276752; output;
		geo="EA18"; time=2015; hhtyp="A_GE2_DCH";  indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=17.076805818; output;
		geo="EA18"; time=2015; hhtyp="A_GE2_DCH";  indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=11.35293719;  output;
		geo="EA18"; time=2015; hhtyp="A_GE2_NDCH"; indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=8.2945434449; output;
		geo="EA18"; time=2015; hhtyp="A_GE2_NDCH"; indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=6.4145051183; output;
		geo="EA18"; time=2015; hhtyp="HH_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=18.040964168; output;
		geo="EA18"; time=2015; hhtyp="HH_DCH";     indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=12.842222186; output;
		geo="EA18"; time=2015; hhtyp="HH_NDCH";    indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=9.2040946555; output;
		geo="EA18"; time=2015; hhtyp="HH_NDCH";    indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=10.075303418; output;
		geo="EA19"; time=2015; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC";     dup="10"; ivalue=14.101123997; output;
		geo="EA19"; time=2015; hhtyp="A1";         indic_il="LIP_MD60"; unit="PC_POP"; dup="01"; ivalue=18.382338974; output;
		geo="EA19"; time=2015; hhtyp="A1_DCH";     indic_il="LIP_MD60"; unit="PC";     dup="00"; ivalue=28.173894694; output;
	run;

	%ds_print(test, title="Original table");

	%let cnt=;
	%obs_count(test,_ans_=cnt, pct=no);
	%put cnt=&cnt;

	/* PROC SORT 
		DATA=test 
		OUT=dumb;
		BY geo time hhtyp indic_il;
	run;
	DATA dumber;
		SET dumb;
		BY geo time hhtyp indic_il;
		first_indic_il = first.indic_il;
		last_indic_il = last.indic_il;
		LABEL
			first_indic_il = 'first.indic_il'
			last_indic_il = 'last.indic_il';
	run; */
		
	%put;
	%let dim=geo time hhtyp indic_il;
	%put (i) Retrieve tables of unique/duplicated observations along dimensions &dim;
	%obs_duplicate(test, dim=&dim, unidsn=unidsn, dupdsn=dupdsn);
	%let dcnt=;	%let ucnt=;
	%obs_count(unidsn,_ans_=ucnt, pct=no);
	%obs_count(dupdsn,_ans_=dcnt, pct=no);
	%let dupval=;
	%var_to_list(unidsn, dup, _varlst_=dupval, distinct=YES);
	%if %sysevalf(&dcnt + &ucnt = &cnt) and "&dupval"="00" %then
		%put OK: TEST PASSED - #{duplicated observations}: %sysfunc(trim(&dcnt)) -  #{unique observations}: %sysfunc(trim(&ucnt)) - unique flag: "00";
	%else 
		%put ERROR: TEST FAILED - #{duplicated observations}: %sysfunc(trim(&dcnt)) -  #{unique observations}: %sysfunc(trim(&ucnt)) - unique flag: &dupval;
	%ds_print(dupdsn, title="Duplicates on &dim");

	%put;
	%let dim=geo time hhtyp indic_il;
	%let where=%quote(UNIT="PC_POP");
	%put (ii) Ibid, with a WHERE clause: &where;
	%obs_duplicate(test, dim=geo time hhtyp indic_il, unidsn=unidsn, dupdsn=dupdsn, where=&where, 
		ilib=WORK, olib=WORK);
	%let dcnt=;	%let ucnt=;
	%obs_count(unidsn,_ans_=ucnt, pct=no);
	%obs_count(dupdsn,_ans_=dcnt, pct=no);
	%let dupval=;
	%var_to_list(dupdsn, dup, _varlst_=dupval, distinct=YES);
	%let unitval=;
	%var_to_list(dupdsn, unit, _varlst_=unitval, distinct=YES);
	%if %sysevalf(&dcnt + &ucnt = &cnt)  and "&unitval"="PC_POP" and %list_difference(&dupval, 01 11) EQ %then
		%put OK: TEST PASSED - #{duplicated observations}: %sysfunc(trim(&dcnt)) - #{unique observations}: %sysfunc(trim(&ucnt)) - Duplicated flag: "01 11" - Unit: PC_POP;
	%else 
		%put ERROR: TEST FAILED - #{duplicated observations}: %sysfunc(trim(&dcnt)) - #{unique observations}: %sysfunc(trim(&ucnt)) - Duplicated flag: &dupval - Unit: &unitval;
	%ds_print(dupdsn, title="Duplicates on &dim with where clause");
	%ds_print(unidsn, title="Unique values on &dim with where clause");

	%work_clean(test, unidsn, dupdsn);
	
	%put;
	%exit:
%mend _example_obs_duplicate;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_obs_duplicate; 
*/

/** \endcond */
 
