/* TODO ANO_DS_SELECT
*/

/* credits: grazzja */

%macro ano_ds_select(geo		/* Input list of country(ies) ISO-code						(REQ) */
					, time		/* Year of interest 										(REQ) */
					, idsn		/* Input dataset from where observations are selected		(REQ) */
					, odsn		/* Output dataset where selected observations are stored 	(OPT) */
					, base_var=
					, der_var=
					, ahm_var=
					, oth_var=
					, vartype= 	/* Type of the variables to be set to missing			(OPT) */
					, where=	/* Where clause used to select the variables data from 	(OPT) */
					, ilib=
					, olib=
					);
	%local _mac;
	%let _mac=&sysmacroname;

	/************************************************************************************/
	/**                 stand-alone declarations/PING not available                    **/
	/************************************************************************************/

	/* this is what happens when PING library is not loaded: no check is performed */
	%if %symexist(G_PING_ROOTPATH) EQ 1 %then %do; 
		%macro_put(&_mac);
	%end;
	%else %if %symexist(G_PING_PGM_LIGTH_LOADED) EQ 0 %then %do; 
		%if %symexist(G_PING_PGM_LIGTH_PATH) EQ 0 %then 	
			%let G_PING_PGM_LIGTH_PATH=/ec/prod/server/sas/0eusilc/7.3_Dissemination/pgm; 
		%include "&G_PING_SETUPPATH/ping_pgm_light.sas";
	%end;
 
	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	PROC SQL;
	   	CREATE TABLE &olib..&odsn AS 
	   	SELECT 
			/* Basic variables */ 
			%if not %macro_isblank(base_var) %then %do;
				%sql_list(&base_var), 
				%if %macro_isblank(ahm_var) or %macro_isblank(oth_var) or %macro_isblank(der_var) %then %do;
					,
				%end;
			%end;
			/* AHM variables */ 
			%if not %macro_isblank(ahm_var) %then %do;
				%sql_list(&ahm_var), 
				%if %macro_isblank(oth_var) or %macro_isblank(der_var) %then %do;
					,
				%end;
			%end;
			/* other variables */ 
			%if not %macro_isblank(oth_var) %then %do;
				%sql_list(&oth_var), 
				%if %macro_isblank(der_var) %then %do;
					,
				%end;
			%end;
			/* Computed variables */
			%if not %macro_isblank(der_var) %then %do;
				%sql_list(&der_var)
   			%end;
   		FROM &ilib..&idsn
		WHERE 
			%if "&geo"^="_ALL_" %then %do;
				&vartype.B020 in %sql_list(&geo) 
				%if not %macro_isblank(where) or not %macro_isblank(time) %then %do;
					AND
				%end;
			%end;
			%if "&time"^="_ANY_" %then %do;
				&vartype.B010 in %sql_list(&time) 
				%if not %macro_isblank(where) %then %do;
					AND
				%end;
			%end;
			%if not %macro_isblank(where) %then %do;
				&where
			%end;
			;
	quit;

%mend ano_ds_select;

%macro _example_ano_ds_select;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;
	%put !!! &sysmacroname - Not implemented yet !!!;

%mend _example_ano_ds_select;
