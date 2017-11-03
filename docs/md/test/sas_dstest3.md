## _DSTEST3 {#sas_dstest3}
Test dataset #3.

	%_dstest3;
	%_dstest3(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest3`:
| color | value |
|:-----:|------:|
|  blue |   1   |
|  blue |   2   |
|  blue |   3   |
| green |   3   |
| green |   4   |
|  red  |   2   |
|  red  |   3   |
|  red  |   4   |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest<XX>` storing the 
	following table: 

### Example
To create dataset #3 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest3;
	%ds_print(_dstest3;

### See also
[%_dstestlib](@ref sas_dstestlib).
