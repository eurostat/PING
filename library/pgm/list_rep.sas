/** 
## list_rep {#sas_list_rep}
Generate a list of repeated values (as R function rep does).

~~~sas
	%let rep=%list_rep(str, times);
~~~

### Arguments
* `str` : string to be repeated in the list;
* `times` : number of times the string is repeated.
 
### Returns
`rep` : output list of repeated strings. 

### Examples
The following examples:

~~~sas
	%let rep=%list_rep("test", 5);
~~~	
return `test test test test test`

Run macro `%%_example_list_rep` for examples.

### See also
[%list_permutation](@ref sas_list_permutation), [%list_length](@ref sas_list_length), 
[%list_count](@ref sas_list_count), [%list_sequence](@ref sas_list_sequence).
*/ /** \cond */

/* credits: pierre-lamarche */

%macro list_sequence(str		/* string to be repeated */
					, times=	/* number of times the string has to be repeated */
					);
	%local _mac;
	%let _mac=&sysmacroname;
	%let _=%macro_put(&_mac);

	/************************************************************************************/
	/**                                 checkings/settings                             **/
	/************************************************************************************/

	%if %macro_isblank(sep) %then 	%let sep=%quote( ); /* list separator */

	/* set default output to empty */
	%let _list=;

	/* check str */
	%if %error_handle(ErrorInputParameter,
					  %macro_isblank(str), mac = &_mac,
					  txt = !!! The parameter str is missing !!!) %then 
					  %goto exit ;

	/* check times */
	%if %error_handle(ErrorInputParameter,
					  %macro_isblank(times), mac = &_mac,
					  txt = !!! The parameter times is missing !!!) %then 
					  %goto exit ;

	/************************************************************************************/
	/**                                  actual operation                              **/
	/************************************************************************************/

	/* build the sequence */
	%do _i=1 %to %eval(&times);
		%let _list=&_list. &str ;
	%end;

	%exit:
	&_list
%mend list_rep;

