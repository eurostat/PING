## Testing {#mainpage_testing}

### Implement test and describe examples

Three types of tests are foreseen (see this [wiki](http://www.phusewiki.org/wiki/index.php?title=SAS_macro_validation_criteria)):

1. Testing with known, provided data and known results, check for correct results (_white box testing_)
2. Testing with unknown data and unknown results, check for plausible results (_black box testing_)

In general one should provide tests:
* with all variations of argument input parameters, so as to check their effects, 
* with existing but known erroneous data and argument parameters (fool proof testing)

and also check for appropriate responses,  error reports and their consistent layout and verify whether all 
parameters are being checked on validity (legal SAS names, limited options, numbers, etc.), verify checks on 
existence of specified dataset(s) and variables within dataset(s), also verify checks on non-existence of newly
to create permanent dataset(s), and/or an indication that these may be overwritten if existing, verify possible 
cross checks between input parameters.

 
####  White box testing

**Testing with known, provided data and known results, check for correct results.** 

Valid and appropriate, existing datasets 
should be used of which the contents are known. It should be clear what the result of the macro processing should 
be in terms of output datasets or output listings. These should be verified for correctness and possibly checked 
against other known correct results.

Currently, _white box testing_ is applied in practice in `PING` through the implementation of "checked examples" 
within the distributed macros. 
Let us consider for instance the macro [%ds_create](@ref sas_ds_create) in SAS, the following macro is also provided 
in the core of the program: 

~~~sas
	%macro _example_ds_create;
		%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
			%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
			%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
			%_default_setup_;
		%end;

		%local _cds _dsn labels rlabels olabels types rtypes otypes lengths rlengths olengths;
		%let _dsn=TMP&sysmacroname;
		%work_clean(&_dsn);

		%let labels=A B C;
		%put;
		%put (i) Create an ad-hoc table from parameter labels only; 
		%ds_create(&_dsn, var=&labels);
		%let olabels=%sysfunc(compbl(	A 	B 	C	));
		%let otypes=%sysfunc(compbl(	2	2	2	));
		%let olenghts=%sysfunc(compbl(	15	15	15	));
		%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
		%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
			%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
		%else 					
			%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
		%work_clean(&_dsn);

		%let _cds=cTMP&sysmacroname;
		%let types=char num char;
		%let lengths=15 8 15;
		DATA &_cds;
			LABEL="value"; 	TYPE="num "; 	LENGTH=8; 	ORDER=-3; output;
			LABEL="flag"; 	TYPE="char"; 	LENGTH=20; 	ORDER=-2; output;
			LABEL="n"; 		TYPE="num"; 	LENGTH=8; 	ORDER=-1; output;
			LABEL="geo"; 	TYPE="char"; 	LENGTH=15; 	ORDER=1; output;
			LABEL="time"; 	TYPE="num"; 	LENGTH=8; 	ORDER=2; output;
		run;
		%put;
		%put (ii) Create a dataset table from an ad-hoc configuration file;
		%ds_create(&_dsn, var=&labels, len=&lengths, typ=&types, idsn=&_cds, ilib=WORK);
		%let olabels=%sysfunc(compbl(	geo time 	A 	B 	C 	value 	flag 	n	));
		%let otypes=%sysfunc(compbl(	2	1		2	1	2	1		2		1	));
		%let olenghts=%sysfunc(compbl(	15	8		15 	8 	15	8		20		8	));
		%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
		%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
			%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
		%else 					
			%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
		%ds_print(&_cds);
		%ds_print(&_dsn); /* empty.... */

		%put;
		%put (iii) Create a dataset table from the ad-hoc configuration file (default: INDICATOR_CONTENTS in LIBCFG);
		%let labels=	AGE		SEX		HHTYP;
		%let types=		char	char	char;
		%let lengths=	15		15		15;
		%ds_create(&_dsn, var=&labels, len=&lengths, typ=&types, idsn=INDICATOR_CONTENTS, ilib=LIBCFG);
		%let olabels=%sysfunc(compbl(	geo time 	AGE SEX HHTYP 	unit 	ivalue 	iflag 	unrel 	n nwgh ntot	totwgh 	lastup 	lastuser	));
		%let otypes=%sysfunc(compbl(	2 	1 		2 	2 	2 		2 		1 		2 		1 		1 1	   1 	1 		2 		2			));
		%let olenghts=%sysfunc(compbl(	15 	8 		15 	15 	15 		8 		8 		8 		8 		8 8	   8 	8 		8 		8			));
		%ds_contents(&_dsn, _varlst_=rlabels, _lenlst_=rlengths, _typlst_=rtypes, varnum=yes);
		%put %quote(&olabels);
		%put %quote(&rlabels);
		%put %quote(&olenghts);
		%put %quote(&rlengths);
		%put %quote(&otypes);
		%put %quote(&rtypes);
		%if %quote(&olabels)=%quote(&rlabels) and %quote(&olenghts)=%quote(&rlengths) and %quote(&otypes)=%quote(&rtypes) %then 	
			%put OK: TEST PASSED - Dataset correctly created with (ordered and typed) fields: %upcase(&olabels);
		%else 					
			%put ERROR: TEST FAILED - Wrong dataset creation with fields: &rlabels;
		%ds_print(INDICATOR_CONTENTS, lib=LIBCFG);
		%ds_print(&_dsn); /* empty.... */

		%work_clean(&_cds, &_dsn);
		%exit:
	%mend _example_ds_create;
~~~
	
This is the main kind of testing that a developer carries out too while developing his macros. These tests of course 
should be completely successful when running:
	
~~~sas
	%_example_ds_create; 
~~~

The user also benefits from the examplification. Still, this approach will be modernised so as to integrate actual
tests (not just checked examples) through the adoption of dedicated unit testing. 

A list of simple/static test datasets are available on the [test]{#test} page.


####  Black box testing

**Testing with unknown data and unknown results, check for plausible results.**


Black box testing should carried out by trying all input options one at a time, while all the time normal output should be produced. 
This does not necessarily include all possible combinations of input options under all possible circumstances. It may be virtually 
impossible to check all possible variations in the functionality of a complex macro. During development new features have been added 
one by one and tested in their target environment mainly, while testing them in other situations might be either redundant or not 
applicable. So is validation, though during the validation process it may be difficult to judge sufficiently reliably in which situations 
additional checking is superfluous. Thus during validation checking actually should be performed at least as or even more extensively than 
during development. 
 
Use Public User Files.

### Run tests and examples
