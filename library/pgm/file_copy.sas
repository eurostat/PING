/**
## file_copy {#sas_file_copy}
Copy a file byte by byte.

~~~sas
	%file_copy(ifn, ofn);
~~~

### Arguments
* `ifn` : full path and name of the input file to copy (!not a fileref!);
* `ofn` : ibid with the output copy file (!not a fileref!).
  
### Note
No error checking.

### Example
Run macro `%%_example_file_copy` for examples.

### See also
[%file_check](@ref sas_file_check), [%file_delete](@ref sas_file_delete),
[%file_move](@ref sas_file_move).
*/ /** \cond */

/* credits: gjacopo */

%macro file_copy(ifn	/* Full path of input filename 	(REQ) */
				, ofn	/* Full path of output filename (REQ) */
				);
	%local _mac;
	%let _mac=&sysmacroname;

	%if %error_handle(ErrorInputFile, 
			%file_check(&ifn) EQ 1, mac=&_mac,		
			txt=%quote(!!! Input file %upcase(&ifn) does not exist !!!)) %then
		%goto exit;

	DATA _null_;
		INFILE "&ifn" RECFM=N LRECL=1048576 LENGTH=l SHAREBUFFERS BLKSIZE=32768;
		FILE "&ofn" RECFM=N LRECL=32768 BLKSIZE=1048576;
		INPUT line $char32767.;
		PUT line $varying32767. l;
	run;

	%exit:
%mend file_copy;

%macro _example_file_copy;
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

	%put !!! &sysmacroname: Not yet implemented !!!;

	%put;

	%exit:
%mend _example_file_copy;

/* Uncomment for quick testing
options NOSOURCE MRECALL MLOGIC MPRINT NOTES;
%_example_file_copy; 
*/

/** \endcond */
