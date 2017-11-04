/** 
## silc_ind_browse {#sas_silc_ind_browse}
Provide information (report) regarding the definition/data of EU-SILC indicators. 

~~~sas
	%silc_ind_browse(ind, lib, page=, fm=, odir=, oreport=);
~~~

### Arguments
* `ind` : (list of) indicator(s) whose information is requested;
* `lib` : input library where the indicator is stored;
* `page` : (_option_) variable used by proc report to create deparate page for each `BY` (`GEO` or `TIME` are accepted): 
	if not passed `GEO` is used;
* `odir` : (_option_) pathname where the report is stored, by default: `&G_PING_DIRHTML` is used;
* `fm` : (_option_) format of values.

### Returns
* `oreport` : (_option_) name of the output report; by default: `HTML_&ind` is used.

### Example
The instructions:

~~~sas
	%let ind=MDDD01;
	%let lib=C_RDB;
 	%silc_ind_browse(&ind,&lib);
~~~
will store in the output html `oreport` file the following table:
<table>
 <tr>
 <td colspan="18" align="center"><code>&ind</code></td>
 </tr>
 <tr>
 <td colspan="18" align="center"><code>geo = AT</code></td>
 </tr>
 <tr>
  <td colspan="3"> </td> 
 <td colspan="6" align="center"><code>n_item</code></td> 
 <td colspan="2"> </td> 
 <td colspan="6" align="center"><code>n_item</code></td>
 <td> </td> 
 </tr>
 <tr>
 <td colspan="3"> </td> 
 <td>0</td> <td>1</td> <td>2</td> <td>3</td> <td>4</td> <td>5</td> 
 <td colspan="2"> </td> 
 <td>0</td> <td>1</td> <td>2</td> <td>3</td> <td>4</td> <td>5</td> 
 <td> </td> 
 </tr>
 <tr> 
 <td><code>time</code></td> <td><code>incgrpZ</code></td> <td><code>hhtyp</code></td> 
 <td colspan="6"> </td> 
 <td><code>totnobs</code></td> <td><code>unrel</code></td> 
 <td><code>nobs</code></td> <td><code>nobs</code></td>  <td><code>nobs</code></td> <td><code>nobs</code></td> <td><code>nobs</code></td> <td><code>nobs</code></td> 
 <td><code>weight</code></td> 
 </tr>
 <tr> 
 <td>2003</td> <td><code>A_MD60</code></td>  <td><code>A1</code></td>  <td>72.02</td> <td>15.99</td> <td>7.23</td> <td>2.68</td> <td>1.78</td> <td>0.30</td> <td>857</td> <td>0</td> <td>632</td> <td>146</td> <td>70</td> <td>29</td> <td>17</td> <td>3</td> <td>4839214</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td><code>A1F</code></td>  <td>67.61</td> <td>19.69</td> <td>7.79</td> <td>3.54</td> <td>1.19</td> <td>0.17</td> <td>557</td> <td>0</td> <td>373</td> <td>108</td> <td>45</td> <td>22</td> <td>8</td> <td>1</td> <td>2776244</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td><code>A1M</code></td>  <td>77.94</td> <td>11.00</td> <td>6.48</td> <td>1.52</td> <td>2.58</td> <td>0.47</td> <td>340</td> <td>0</td> <td>259</td> <td>38</td> <td>25</td> <td>7</td> <td>9</td> <td>2</td> <td>2062971</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td>...</td>  <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td>
</tr>
</table>

### See also
[%ds_contents](@ref sas_ds_contents), [%file_check](@ref sas_file_check), [%ds_check](@ref sas_ds_check),
[%par_check](@ref sas_par_check).
*/ /** \cond */

/* credits: grillma */

%macro silc_ind_browse(ind      /* Name of the input indicator 				               	    	(REQ)*/
					, lib       /* Input library, where the indicator is stored	                    (REQ)*/
	                , olib=     /* Outp[ut library       	                                        (OPT)*/
					, page=     /* variable used by proc report to create deparate page for each BY (OPT)*/
					, fm=      	/* Macro variable format (default 6.2)                          	(OPT)*/
					, odir=     /* Name of the output pathname                                  	(OPT)*/
					, oreport = /* Name of the output report                                   	    (OPT)*/
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%macro_put(&_mac);

	/*****************************************************************************************************/
	/**                                 checkings/settings                                              **/
	/*****************************************************************************************************/
    %local _ans  /* output answer       */
		   _ext  /* extention of report */
		   	;

	%let _ext=html;
	%let _ans=;

	/* IND: check */
	%if %error_handle(ErrorInputParameter, 
		 	%macro_isblank(ind) EQ 1, mac=&_mac,		
			txt=%bquote(!!! Input parameter IND not set !!!)) %then
		%goto exit;	

	/*LIB: check whether passed */
	%if %error_handle(ErrorInputParameter, 
			%macro_isblank(lib) EQ 1
			txt=%quote(!!! Missing input parameter lib)) %then 
		%goto exit;
     
    /* IND: check if it is empty in the libname passed */
	%if %error_handle(ErrorInputParameter, 
			%ds_check(&ind, lib=&lib) NE 0,		
			txt=!!! &ind  does not exit in %upcase(&lib) libname!!!) %then
		%goto exit;
	%ds_isempty(&ind, var=geo, _ans_=_ans, lib=&lib);
    %if %error_handle(ErrorInputParameter, 
			&_ans EQ 1
			txt=%quote(!!! &ind dataset is empty)) %then 
		%goto exit;

	/* OLIB : check whether passed/set default */
	%if %macro_isblank(olib) %then 				%let olib=WORK;

	/* FM : check whether passed/set default */
	%if %macro_isblank(fm) %then 				%let fm=6.2;

	/* PAGE : check whether passed/set default */
	%if %macro_isblank(page) %then 				%let page=GEO;
	%else 										%let page=%upcase(&page);

	%if %error_handle(ErrorInputParameter, 
	    %par_check(&page, type=CHAR, set=GEO TIME) NE 0, mac=&_mac,
            txt=%quote(!!! Wrong input parameter PAGE - Must be GEO or TIME !!!)) %then 
		%goto exit;
  
	/* REPORT : check whether passed/set default */
	%if %macro_isblank(oreport) %then 			%let oreport=HTML_&ind;
	
	/* ODIR : check whether passed/set default */
	%if %macro_isblank(odir) %then %do;
		%if %symexist(G_PING_HTMLDIR) %then 	%let odir=&G_PING_HTMLDIR;
		%else									%let odir=&G_PING_DIRREPORT/html;
	%end;

	/* OREPORT, ODIR : check if the report exists*/
	%if %error_handle(ExistingOutputDataset, 
				%file_check(&odir/&oreport, ext=html) EQ 0, mac=&_mac,
				txt=%quote(! Output table already exist - Will be overwritten !), verb=warn) %then 
			%goto warning1;
	%warning1: 

	
   	/************************************************************************************/
	/**                                 actual computation                             **/
	/************************************************************************************/

	%local _i      /* counter                                         */
		_dsn       /* temporary dataset                               */
		grp        /* scan temporary variable                         */
		_grp       /* temporary variable                              */
		dimgrp     /* macro variable to define group for the report   */
		dimcol     /* variables  to use  as columns in the  report    */
		dimrow     /* variables  to use  as columns in the  report    */
		sep 	   /* arbitrary chosen separator for the output lists */
		list       /* output list of ds_contents macro                */
		res        /* output list of list_slice macro                 */
	;

    %let _dsn=_TMP&_mac;
	%let list=;

	%let dimgrp=;
	%let sep=%quote( );

	/* retrieve the variables names from the configuration file and generate the &odsn file*/
    %let list=;
	%ds_contents(&ind, _varlst_=list,  varnum=yes, lib=&lib);
  	%let res=%list_slice(&list, ibeg=3, end=ivalue, sep=%quote( ));
  
	%let dimcol=%list_slice(&res, ibeg=%eval(%list_length(&res)-1), iend=%list_length(&res), sep=%quote( ));
	%let dimrow=%list_slice(&res, ibeg=%list_length(&res), iend=%list_length(&res), sep=%quote( ));

   
    %do _i=1 %to %eval(%list_length(&res)-1);
      	%let  grp = "define  %scan(&res, &_i, &sep) /group;" ;
	  	%let _grp =%clist_unquote(&grp);
	 	%let dimgrp = &dimgrp &_grp;
	%end;

 	%if &page=GEO %then %let col1=TIME; 
    %else %let col1=GEO; 

	PROC SORT
		DATA=&lib..&ind OUT=&olib..&_dsn(rename=(n=nobs));
		BY &page &col1 &dimcol;
	RUN;

    /* REPORT generation */
    ODS HTML path="&odir " body="&oreport" style=statistical nogtitle;
	PROC REPORT DATA=&olib..&_dsn nowd split="*";
		TITLE "&ind";
		BY &page;
		column &col1 &dimcol &dimrow,ivalue ntot unrel &dimrow,nobs totwgh;
		define &col1  /group;
		&dimgrp;
		define &dimrow /across;
		define ivalue /'' analysis format=&fm style(column)=[foreground=dark vivid blue background=GRAYEE];
		define nobs /analysis style(column)=[background=GRAYDD];
		define totwgh /'weight' analysis  format=9.0 style(column)=[background=GRAYEE];
		define ntot /'totnobs' analysis min style(column)=[background=very light vivid yellow];
		define unrel /analysis min;
		compute unrel;
		  If unrel.min = 1 then
		    call define(_col_, "style", "style=[background=very light vivid red]");
		  else if unrel.min = 2 then
		    call define(_col_, "style", "style=[background=light vivid red]");
		  else call define(_col_, "style", "style=[background=very light vivid yellow]");
		endcomp;
	RUN;

	ODS HTML close;
	TITLE; FOOTNOTE;

	%exit:
%mend silc_ind_browse;

%macro _example_silc_ind_browse;

	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	%put (i) Indicator does not exist in the library;
    %let ind=DUMMY;
	%let lib=LIBCRDB2;
	%silc_ind_browse(&ind,&lib);
	%put ; 
 	%put (ii) The indicators does not exit in  DUMMY library;
	%let ind=LI43;
	%let lib=DUMMY;
   	%silc_ind_browse(&ind,&lib);
	%put ; 
 	%put (iii) Display contents of existing indicator  in RDB library;
    %let ind=MDDD01;
	%let lib=LIBCRDB2;
   	%silc_ind_browse(&ind,&lib);
 
 %mend _example_silc_ind_browse;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES; */
*%_example_silc_ind_browse ;
*/
 
/** \endcond */
				

 /*
