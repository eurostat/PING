 /** 
## str_type {#sas_str_type}

~~~sas
	%str_type(str);
~~~

### Arguments

### Returns

### Reference
Peng, F. (2005): ["%IsNum, A Macro Function Checks Data Type In Data Step"](http://www.lexjansen.com/pharmasug/2005/CodersCorner/cc01.pdf).

### See also
[%datatyp](http://support.sas.com/documentation/cdl/en/mcrolref/69726/HTML/default/viewer.htm#p14qy9r4wu1an0n11kfn30idvy20.htm).
*/ /** \cond */
 
%macro str_type(str);
	/*  */
	%if verify(trim(left(&str)),'0123456789')=0 /*number only*/
		or verify(trim(left(&str)),'0123456789.')=0
		and not indexc(substr(&str,indexc(&str,'.')+1), '.')  /*allow only one '.'*/
		or verify(trim(left(&str)),'0123456789.+-')=0
		and not indexc(substr(&str,indexc(&str,'.')+1), '.')
		and (indexc(&str,'+-')=1
		and not indexc(substr(&str,2),'+-') /*allow only one leading '+' or '-'*/
		and indexc(&str,'0123456789.') > 1 ) /* '+-' must followed by number*/
		or compress(&str)='' /*'', ' ', or multiple ' ' is numeric*/ %then %do;
		N
	%else %do;
		C
	%end;
%mend str_type;

%macro _example_str_type;
	%if %symexist(G_PING_ROOTPATH) EQ 0 %then %do; 
		%if %symexist(G_PING_SETUPPATH) EQ 0 %then 	%let G_PING_SETUPPATH=/ec/prod/server/sas/0eusilc/PING; 
		%include "&G_PING_SETUPPATH/library/autoexec/_setup_.sas";
		%_default_setup_;
	%end;

	DATA c;
		length str $30;
		str='.'; 			type='NUMERIC';	output;
		str=''; 			type='NUMERIC';	output;
		str='+'; 			type='CHAR';	output;
		str='+.'; 			type='CHAR';	output;
		str='+.1'; 			type='NUMERIC';	output;
		str='+.0'; 			type='NUMERIC';	output;
		str=' '; 			type='NUMERIC';	output;
		str='123456789'; 	type='NUMERIC'; output;
		str=' 1234567899 '; type='NUMERIC'; output;
		str='1234 56789'; 	type='CHAR';	output;
		str='1234,56789'; 	type='CHAR';	output;
		str='+123456789'; 	type='NUMERIC'; output;
		str='+-123456789';  type='CHAR';	output;
		str='+12345-6789'; 	type='CHAR';	output;
		str='12345+6789' ; 	type='CHAR';	output;
		str='123.23+'; 		type='CHAR';	output;
		str='-123.23'; 		type='NUMERIC'; output;
		str='-12323'; 		type='NUMERIC'; output;
		str='-12323-'; 		type='CHAR';	output;
		str='12323-'; 		type='CHAR';	output;
		str='.12.323'; 		type='CHAR';	output;
		str='123.23.45.67'; type='CHAR';	output;
		str='00.123'; 		type='NUMERIC'; output;
		str='.123'; 		type='NUMERIC'; output;
		str='+.123'; 		type='NUMERIC'; output;
		str='.123.'; 		type='CHAR';	output;
		str='.123+'; 		type='CHAR';	output;
		str='+123.'; 		type='NUMERIC'; output;
		str='0000.123400'; 	type='NUMERIC'; output;
		str='assdfasd400'; 	type='CHAR';	output;
		str='1.5E-9'; 		type='CHAR';	output;
	run;

	DATA n;
		length num 8;	
		set c;
		if %isnum(str)=N then do;
			num=input( str, best.);
			put str 'is numeric';
		end;
		else put str 'is character';
		if %isnum(str)=N;
	run;
%mend _example_str_type;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_str_type; 
*/

/** \endcond */

