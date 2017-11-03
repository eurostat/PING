## silc_EUvals {#sas_silc_euvals}
Legacy "EUVALS" code that calculates the EU aggregates of either RDB or RDB2 indicators
in the "old-fashioned" way. 

~~~sas
	%silc_EUvals(eu, ms, _idb=, _yyyy=, _tab=, _thres=, _grpdim=, _flag=, _not60=, 
				_rdb=, _ex_data=, force_Nwgh=0);
~~~

### Arguments
* `eu` : ISO-code of the aggregate area (_e.g._, `EU28`);
* `ms` : list of country(ies) ISO-codes corresponding to (_i.e._, included in)  the 
	`eu` area;
* `mode` : flag (char) setting the mode of data output; it can be `UPDATE` (_e.g., for
	primary RDB indicators) or `INSERT` (for a secondary RDB2 indicators);
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
* `force_Nwgh` : additional boolean flag (0/1) set when an additional variable `nwgh` 
	(representing the weighted sample) is present in the output dataset; note that 
	this option is not foreseen in the original `EUvals` implementation.

### Notes
1. The macro defines automatically which type of indicators is calculated, _i.e._ whether
the indicator is in RDB or RDB2 database. For that purpose, it will check whether:
	+ the (global) variable `not60` is defined and a table `WORK.&tab` exists

In the case of positive answer, the indicator is regarded as a RDB2 indicator, and the 
output indicator will be stored in `WORK` library. In the case of negative answer, the 
indicator is considered as a RDB indicator, and the original indicator will be modified. 
Note also that in that latter case, the library `rdb` must be defined prior.
2. The macro `%%silc_EUvals` does not require the use of `PING` library.
3. None of the keyword arguments (_e.g._, `_yyyy`, `_tab`, etc...) is optional, _i.e._
they all need to be set.
4. The "weird" naming of this macro's parameters derives from the global parameters used in 
legacy _EUvals_ program. 

### See also
[%silc_agg_compute](@ref sas_silc_agg_compute).
