## silc_EUvals {#sas_silc_euvals}
Legacy "EUVALS" code that calculates the EU aggregates of either RDB or RDB2 indicators
in the "old-fashioned" way. 

~~~sas
	%silc_EUvals(eu, ms, _idb=, _yyyy=, _tab=, _thres=, _grpdim=, _flag=, _not60=, 
				_rdb=, _ex_data=, force_Nwgh=no);
~~~

### Arguments
* `eu` : ISO-code of the aggregate area (_e.g._, `EU28`);
* `ms` : list of country(ies) ISO-codes corresponding to (_i.e._, included in)  the 
	`eu` area;
* `mode` : flag (char) setting the mode of data output; it can be `UPDATE` (_e.g._, for
	primary RDB indicators) or `INSERT` (for secondary RDB2 indicators);
* `_yyyy` : year of interest;
* `_tab` : name of the input indicator (and the corresponding table as well);
* `_thres` : threshold (in range [0,1]) used to compare ratio of available population
	over the total area population; 
* `_grpdim` : list of dimension used by the indicator `_tab`;
* `_flag` : boolean flag (0/1) for...?  
* `_rdb`: name of the library where the indicator table `_tab` is located, _e.g._ 
	`_rdb=rdb` with primary indicators or `_rdb=WORK` with secondary indicators;
* `_ccwgh60`: name of the file storing countries' population;
* `_not60` : boolean flag (0/1) used to force the aggregate calculation;
* `_ex_data`: name of the library where the file `_ccwgh60` with countries' population 
	is stored;
* `force_Nwgh` : additional boolean flag (`yes/no`) set when an additional variable 
	`nwgh` (representing the weighted sample) is present in the output dataset; note that 
	this option is not foreseen in the original `EUvals` implementation; default: 
	`force_Nwgh=no`.

### Notes
1. In addition to the macro defined above, this file provides additional macros/scripts so 
as to be compatible with the current different uses of the so-called "EUvals" programs in 
EU-SILC production. Actually, the aggregate estimation is run at the "inclusion" of this file,
that is whenever the following command is used inside a SAS program:
~~~sas
		%include "<path_to_this_file>/silc_euvals.sas" 
~~~
The operation performed after the inclusion depends however on the type of indicator to be 
calculated, _i.e._ on whether:
	+ indicators in the so-called RDB2 database are processed: an `%%_EUVALS` macro is launched 
	so that aggregates are actually calculated,
	+ indicators in the so-called RDB database are processed: NOTHING happens (exit the program),
	+ the program is used together with the `PING` library: NOTHING happens either (exit the 
	program).

    In the two latter cases, the inclusion shall therfore be understood as a strict inclusion, with no 
actual operation running.
2. The macro `%%silc_EUvals` does not require the use of `PING` library.
3. The "weird" naming of this macro's parameters derives from the global parameters used in 
legacy `%%EUvals` program. 

### See also
[%silc_agg_compute](@ref sas_silc_agg_compute).
