## file_import {#sas_file_import}
Import (convert) a file from any format accepted by `PROC IMPORT` into a SAS dataset.

~~~sas
	%file_import(ifn, odsn=, idir=, fmt=csv, _ods_=, olib=, guessingrows=, getnames=yes);
~~~

### Arguments
* `ifn` : file name to import;
* `fmt` : (_option_) format for import, _i.e._ extension of the input file; it can be any format 
	(_e.g._, csv) accepted by the DBMS key in `PROC import`;
* `idir` : (_option_) input directory where the file is stored; note that it may be also passed
	directly in `ifn`; default: empty, the location depends on `ifn`;
* `olib` : (_option_) output  library where the dataset will be stored; by default, `olib=WORK` 
    is selected as output library;
* `guessingrows` : flag set to the number of rows (observations) to be read so as to guess the type 
	of a column (variable); `guessingrows` must be an integer >0, or `_MAX_` when all the rows need
	to be read so as to define the type of the variable that is imported (in practice, `_MAX_` 
	corresponds to the integer value 2147483647); default: `guessingrows` is not set and the first 
	row is used to guess the type of the variable;
* `getnames` : boolean flag (`yes/no`) set to import the variable names; default: `getnames=yes`.
 
### Returns
* `odsn` : (_option_) name of the output dataset; otherwise, `odsn` is automatically built from 
	the basename of the input file name `ifn`;
* `_ods_` : (_option_) name (string) of the macro variable storing the name of the output dataset;
	useful when `odsn` has not been set.
 
### Notes
1. There is no format/existence checking, hence if the output selected type is the same as 
the type of the input dataset, or if the output dataset already exists, a new dataset will be 
produced anyway. If the `REPLACE` option is not specified, the `PROC IMPORT` procedure does 
not overwrite an existing data set.
2. In debug mode (_e.g._, `G_PING_DEBUG=1`), the import process is aborted; still it can checked
that the output dataset will be created with the correct name and location using the option 
`_ods_`. Consider using this option for checking before actually importing. 

### Example
Run macro `%%_example_file_import` for examples.

### Notes
1. When trying to guess the types of the input variables, there is a *SAS issue with 
the type of the last column/variable*, _e.g._ setting `guessingrows=MAX`. For instance, 
let us consider the following CSV table: 
    var1,var2,var3,var4,var5,var6
    ,,,,,
    1,,X,,1,1
    X,1,,,,
    X,1,,,,
    ,,,,,
    ,,1,1,,

the variables `var5` and `var6` (while equal) are imported as numerical and alphanumerical 
respectively, though they should bot be imported as numerical.
*This issue occurs when the file has been created on a Windows PC and SAS is running on 
Unix/Linux*. 
One difference between both operating systems is the newline char. While Windows uses 
Carriage Return and Line Feed, the *nix-systems use only one of the chars. The problem 
can be solved in different manners:
	* by using, instead of the `PROC IMPORT`, `INFILE` statement together with the `TERMSTR`
	option, which shall take the value: 
		+ `TERMSTR=CRLF` (Carriage Return Line Feed) to read Windows formatted files (default
			on Windows platforms),
		+ `TERMSTR=LF` (Line Feed) to read UNIX formatted files (default on UNIX systems),     
		+ `TERMSTR=CR` (Carriage Return) to read MAC formatted files;

	* by using dos2unix in the shell of the unix-box to transform the newline chars,

Instead, we will use the macro `%%handle_crlf` implemented by V.Nguyen which reads like:

~~~sas
	%macro handle_crlf(file, handle_name, other_filename_options=) ;
		%sysexec head -n 1 "&file" | awk '/\r$/ { exit(1) }' ;
		%if &SYSRC=1 %then %let termstr=crlf ;
		%else %let termstr=lf ;
		filename &handle_name "&file" termstr=&termstr &other_filename_options ;
	%mend ;
~~~
which automatically detect line break options with termstr as `CRLF` or `LF` (also default)
when importing data. This assumes SAS is running on a UNIX server with access to the `head` 
and `awk` commands. 
Original source code (no license, no disclaimer) is available at 
<http://blog.nguyenvq.com/blog/2015/10/09/automatically-specify-line-break-options-with-termstr-as-crlf-or-lf-in-sas-when-importing-data/>.

2. Variable names should be alphanumeric strings, not numeric values (otherwise converted).

### See also
[%ds_export](@ref sas_ds_export), [%file_check](@ref sas_file_check),
[%handle_crlf](http://blog.nguyenvq.com/blog/2015/10/09/automatically-specify-line-break-options-with-termstr-as-crlf-or-lf-in-sas-when-importing-data/),
[IMPORT](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000308090.htm).
