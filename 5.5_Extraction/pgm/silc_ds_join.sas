/** 
## silc_ds_join {#sas_ds_compare}
Retrieve the list (possibly ordered by varnum) of variables/fields in a given dataset.

~~~sas
	%ds_compare(dsn1, dsn2, _ans_=,lib1=, lib2=);
~~~

### Arguments
* `dsn1` `dsn1`: two datasets reference (_request_);
* `lib1`       : input(_option_) library for dsn1 dataset;
* `lib2`       : input (_option_) library for dsn2 dataset;

### Returns
`ans` : the boolean result of the comparison test of the "sets" associated to the input lists, 
	i.e.:
		+ `0` when two datasets are equal: `dsn1 = dsn2`,
		+ `1` when `dsn1`has less variables then `dsb2`,

### Examples
Consider the test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5
One can retrieve the ordered list of variables in the dataset with the command:

	%let list=;
	%ds_compare(_dstest5, _varlst_=list);

which returns `list=f e d c b a`, while:

	%ds_compare(_dstest5, _varlst_=list, varnum=no);

returns `list=a b c d e f`. Similarly, we can also run it on our database, _e.g._:

	libname rdb "&G_PING_C_RDB"; 
	%let lens=;
	%let typs=;
	%ds_compare(PEPS01, _varlst_=list, _typlst_=typs, _lenlst_=lens, lib=rdb);

returns:
	* `list=geo time age sex unit ivalue iflag unrel n ntot totwgh lastup lastuser`,
	* `typs=  2    1   2   2    2      1     2     1 1    1      1      2        2`,
	* `lens=  5    8  13   3   13      8     1     8 8    8      8      7        7`.

Another useful use: we can retrieve data of interest from existing tables, _e.g._ the list of geographical 
zones in the EU:

	%let zones=;
	%ds_compare(&G_PING_COUNTRYxZONE, _varlst_=zones, lib=&G_PING_LIBCFG);
	%let zones=%list_slice(&zones, ibeg=2);

which will return: `zones=EA EA12 EA13 EA16 EA17 EA18 EA19 EEA EEA18 EEA28 EEA30 EU15 EU25 EU27 EU28 EFTA EU07 EU09 EU10 EU12`.

Run macro `%%_example_ds_compare` for more examples.

### Note
In short, the program runs (when `varnum=yes`):

	PROC CONTENTS DATA = &dsn 
		OUT = tmp(keep = name type length varnum);
	run;
	PROC SORT DATA = tmp 
		OUT = &tmp(keep = name type length);
     	BY varnum;
	run;
and retrieves the resulting `name`, `type` and `length` variables.

### References
1. Smith,, C.A. (2005): ["Documenting your data using the CONTENTS procedure"](http://www.lexjansen.com/wuss/2005/sas_solutions/sol_documenting_your_data.pdf).
2. Thompson, S.R. (2006): ["Putting SAS dataset variable names into a macro variable"](http://analytics.ncsu.edu/sesug/2006/CC01_06.PDF).
3. Mullins, L. (2014): ["Give me EVERYTHING! A macro to combine the CONTENTS procedure output and formats"](http://www.pharmasug.org/proceedings/2014/CC/PharmaSUG-2014-CC43.pdf).

### See also
[CONTENTS](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000085766.htm).
*/ /** \cond */ 

/* credits: grillma */

%macro silc_ds_join(idsn  /* List of input dataset	    		(REQ) */
	        , join  	  /* List of dataset to join     	   	(REQ) */
            , yyyy        /* current year                       (REQ) */
			, trasm_typ=  /* type of trasmisson                 (REQ) */           
			, idsn_type=  /* type of master dataset (h/p/r/d)   (OPT) */
			, dsn_type=  /* type of master dataset (h/p/r/d)   (OPT) */
			, varlist =    /*                                   (OPT) */
			, join_typ=     /*                                   (OPT) */
			, distinct=   /*                                      (OPT)  */ 
          	, odsn =      /* output dataset                     (OPT) */  
			, olib =	  /* Name of the output  library      	(OPT) */
				);

				
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	/* various checkings */
	
	%local 	__joinlen			/* (optional) output list of variable lengths */
		_liblen			/* (optional) output list of variable types */
		_join
		dsnlist
		libdsn 
		list 
		SEP;			/* arbitrary chosen separator for the output lists */

	%let _dsn=TMP_&_mac;
	%let dsnlist=;
	%let liblist=;

	%let _sep=%str( );

		/* DSN/LIB/YYYY : check/set */
	%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(yyyy) , mac=&_mac,		
			txt=!!! year is not set !!!) %then %do;
		%goto exit;
	%end;
	%else 		%let yy=%substr(&yyyy,3,2); 

		 	%put yy=&yy step 1);

	    /* Chech master dataset */
	%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(idsn) NE 0  , mac=&_mac,		
			txt=!!! Input dataset/s not set !!!) %then
		%goto exit;
    %if (&idsn=BDB or &idsn=PDB )%then %do;
		%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(trasm_typ) NE 0  , mac=&_mac,		
			txt=!!! Type of trsmission  not set !!!) %then
		%goto exit;
	%end;
 
	%if %upcase(&idsn)=IDB %then  %do;                     /* master dataset: IDB/PDB/BDB/WORK */
		%let ilib=LIB%upcase(&trasm_typ)%upcase(&idsn);
		%let _idsn=&idsn&yy;
	%end;
	%else %if  %upcase(&idsn)=BDB %then %do;
		%let ilib=LIBBDB;
		%let _idsn=%upcase(&idsn)%upcase(_&trasm_typ)&yy&idsn_type;
	%end;
	%else %if  %upcase(&idsn)=PDB %then  %do;
		%let ilib=LIBPDB;
		%let  _idsn=&trasm_typ&yy&idsn_type;
	%end;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																					
	%else %do;
		%let ilib=WORK;
    	%let _idsn=&idsn;
	%end;
	%put master : _idsn=&_idsn ilib=&ilib;

    %if %error_handle(ErrorInputDataset, 
			%ds_check(&_idsn, lib=&ilib) EQ 1 , mac=&_mac,		
			txt=%bquote(!!! Input datasets %upcase(&idsn&yy) in library %upcase(&ilib) not found !!!)) %then
		%goto exit;


   /* check join dataset */

    %if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(join) NE 0  , mac=&_mac,		
			txt=!!! Dataset/s to join not set !!!) %then
		%goto exit; 

    %let joinlen=%list_length(&join, sep=%quote( ));
	%let dsn_typeLen=%list_length(&dsn_type, sep=%quote( ));
      
	%put &dsn_typeLen &joinlen=joinlen ;

    %do _i=1 %to %list_length(&join, sep=%quote( ));
   		%let _join=%scan(&join, &_i);

		%if %upcase(&_join)=BDB or %upcase(&_join)=PDB %then %do;
			%let  _dsn_type = %scan(&dsn_type, &_i,%str( ));
			%put &_dsn_type=_dsn_type &_join step 0);

			%do _k=1 %to %list_length(&_dsn_type, sep=%quote(_));
				%let __dsn_type=%scan(&_dsn_type, &_K,%str(_));
           	
				%if %upcase(&_join)=BDB %then %do;
					%let _join&_k= %upcase(&_join)%upcase(_&trasm_typ)&yy&__dsn_type;
             	   %let liblist=&liblist  LIBBDB;
				%end;
				%if %upcase(&_join)=PDB %then %do;
					%let _join&_k=%upcase(&trasm_typ)&yy&__dsn_type;
					%let liblist=&liblist  LIBPDB;
				%end;
				%put k=&_K __dsn_type=%scan(&_dsn_type, &_K,%str(_)) _join&_k=&&_join&_k  *** k ciclo;
				%let dsnlist=&dsnlist &&_join&_k;
			%end;
	 		%end;
	 	    %else %if %upcase(&_join)=IDB %then %do;
				%let dsnlist=&dsnlist &_join&yy;
				%let liblist=&liblist LIB%upcase(&trasm_typ)%upcase(&idsn);
		%end;
	%end;

      %put join: &dsnlist &liblist;

	%if %macro_isblank(olib) %then 		%let olib=WORK;
	%if %macro_isblank(odsn) %then 		%let olib=&_dsn;

 	%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			%macro_isblank(varlist) NE 0  , mac=&_mac,		
			txt=!!! any variables to join !!!) %then
		%goto exit; 



  /* var check */
   %let idbvar=;
   %let idbvarfund=;
  	%do _k=1 %to  %list_length(&varlist, sep=%quote( ));;
		%let _ans=%var_check(&_idsn,%scan(&varlist, &_k,%str( )) , lib=&ilib);
		%if %error_handle(ErrorInputParameter,   /*check if the three input variables are missing at the same time */
			&_ans NE 0  , mac=&_mac,		
			txt=!!! %scan(&varlist, &_k,%str( )) variable not found !!!) %then
		%goto continue;
	   	%put %scan(&varlist, &_k,%str( )) , lib=&ilib marina;
		%let idbvarfund=&idbvarfund %scan(&varlist, &_k,%str( ));
		%let idbvar= &idbvar &ilib..%scan(&varlist, &_k,%str( ));
	 	%put &idbvar &idbvarfund step1);
		%continue:
	%end;
%let diff=%list_difference(&varlist, &idbvarfund);

 
 %let joinvar=;
 %put &dsnlist &diff &liblist;

  	%do _k=1 %to  %list_length(&diff, sep=%quote( ));
	    %do _i=1 %to  %list_length(&dsnlist, sep=%quote( )); 
		 	%let _ans=%var_check(%scan(&dsnlist, &_i,%str( )),%scan(&diff, &_k,%str( )) , lib=%scan(&liblist, &_i,%str( )));;
		 	%if %error_handle(ErrorInputParameter,   
				&_ans NE 0  , mac=&_mac,		
				txt=!!! %scan(&diff, &_k,%str( )) variable not found  in  %scan(&dsnlist, &_i,%str( )) dataset!!!) %then 
			%goto skip;
		   	%let joinvar= &joinvar %scan(&liblist, &_i,%str( )).%scan(&dsnlist, &_i,%str( )).%scan(&diff, &_k,%str( ));
	     	%if &_k = %list_length(&dsnlist, sep=%quote( )) %then %goto exit;  
		%end;
		%skip:
	%end;

	%let _joinvar=%list_quote(&joinvar, mark=_EMPTY_);
	%let _idbvar=%list_quote(&idbvar, mark=_EMPTY_);

	%put &_joinvar &_idbvar;
	%if %error_handle(ErrorInputParameter,   
				%list_length( &join_typ, sep=%quote( )) NE %list_length(&join, sep=%quote( ))  , mac=&_mac,		
				txt=!!! number of dsn  are different from number of type of join !!!) %then 
		%goto exit;
     
/*	
/************************************************************************************/
/**                                 actual computation                             **/
/************************************************************************************/
 
	PROC SQL noprint;
		CREATE TABLE &olib.&odsn AS SELECT
		%if not %macro_isblank(distinct) %then %do;
		    distinct 
		%end;
        &_idbvar,&_joinvar
		from   &ilib.&_idsn as idb
        %do _J=1 %to  %list_length(&join_typ, sep=%quote( ));
            %scan(&join_typ, &_j,%str( )) join idb.DB020=%substr(&yyyy,1,1); 
		%end;

	%goto exit;
%scan(&dsnlist, &_i,%str( ))),%list_length(%scan(&dsnlist, &_i,%str( ))),sep=%quote( ))
&dsnlist &liblist

	%exit:
%mend silc_ds_join;

%macro _example_idb_join;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put (i) test without parameters;
	%let idsn=idb;
	%let join=bdb pdb;
	%let yyyy=2014;
	%let varlist=DB020 RB030 HY010;
	%let dsn_type=h_p  h;
	%let join_typ=left left ;
	%silc_ds_join(&idsn,&join,&yyyy,trasm_typ=c,dsn_type=&dsn_type,varlist=&varlist,join_typ=&join_typ);



%mend _example_idb_join;

%_example_idb_join;


