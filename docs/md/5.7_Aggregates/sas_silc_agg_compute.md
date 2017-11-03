## silc_agg_compute {#sas_silc_agg_compute}
Legacy _"EUVALS"_-based code that calculates the EU aggregates of any indicator, whenever
data are available or not, in the "old-fashioned" way. 

~~~sas
	%silc_agg_compute(geo, time, idsn, odsn, ctrylst=,
					max_yback=0, thr_min=0.7, thr_cum=0, pdsn=CCWGH60, agg_only=yes, 
					force_Nwgh=0, ilib=WORK, olib=WORK, plib=idb_rdb);
~~~

### Arguments
* `geo` : a given geographical area, _e.g._ EU28, EA, ...;
* `time` : year of interest;
* `idsn` : name of the dataset storing the indicator for which an aggregated value is estimated
	over the `&geo` area and during the `&time` year;
* `ctrylst` : (_option_) list of (blank-separated, no quote) strings representing the ISO-codes 
	of all the countries supposed to belong to `&geo`; when not provided, it is automatically 
	determined from `&geo` and `&time` (see macro [%zone_to_ctry](@ref sas_zone_to_ctry));
* `max_yback` : (_option_) look backward in time, _i.e._ consider the `&max_yback` years prior to 
	the considered year; default: `max_yback=0`, _i.e._ only data available for current year shall 
	be considered; `max_yback` can also be set to `_ALL_` so as to take all available data from 
	the input dataset, whatever the year considered: in that case, the other argument(s) normally 
	used for building the list of countries (see below: `thr_min`) are ignored; default: 
	`max_yback=0` (_i.e._, only current year);
* `thr_min` : (_option_) value (in range [0,1]) of the threshold used to test whether currently 
	(_i.e._ for the year `time` under investigation):
		available population [time] / global population [time] >= `&thr_min` ? 
	default:  `thr_min=0.7`, _i.e._ the available population should be at least 70% of the global 
	population of the `geo` area; 
* `thr_cum`: (_option_) value (in range [0,1]) of the threshold used to test the cumulated 
	available population, _i.e._ whether: 
		available population [time-maxyback,time] / global population [time] >= `&thr_cum` ? 
	default:  `thr_cum=0`, _i.e._ there is no further test on the cumulated population once the
	`thr_min` test on currently available population is passed; 
* `grpdim` : (_option_) list (blank separated, no comma) of dimensions used by the indicator; if not
	set (default), it is retrieved automatically from the input table using 
	[%ds_contents](@ref sas_ds_contents) and considering the standard format of EU-SILC tables (see 
	also [%silc_ind_create](@ref sas_silc_ind_create));
* `agg_only` : (_option_) boolean flag (`yes/no`) set to keep in the output table the aggregate `geo`
	only; when set to `no`, then all data used for the aggregate estimation are kept in the output 
	table `odsn` (see below); default: `agg_only=yes`, _i.e._ only the aggregate will be stored in 
	`odsn`;
* `flag` : (_option_) who knows...?
* `force_Nwgh` : (_option_) additional boolean flag (0/1) set when an additional
	variable `nwgh` (representing the weighted sample) is present in the output
	dataset; used in `EUvals` , where this option is not foreseen in the original `EUvals` 
	implementation;
* `pdsn` : (_option_) name of the dataset storing total populations per country; default: `CCWGH60`
	(_"EUVALS"_ legacy);
* `plib` : (_option_) name of the library storing the population dataset `pdsn`; default: `plib` 
	is associated to the folder `&EUSILC/IDB_RDB` folder commonly used to store this file; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`.

### Returns
* `odsn` : (generic) name of the output datasets; two tables are actually created: the table `&odsn` 
	will store all the calculations with the aggregated indicator; a table named `CTRY_&odsn` will 
	also store, for each country, the year of extraction of data for the calculation of aggregates in 
	year `time` will also be created; for instance for a given calculated at `time=2015`, where BG 
	data are missing till 2013, CY data till 2014, DE data till 2012, ES till 2014, etc..., this 
	table will look like:
		 geo | time
		-----|------
		  AT | 2015
		  BE | 2015
		  BG | 2013
		  CY | 2014
		  CZ | 2015
		  DE | 2012
		  DK | 2015
		  EE | 2015
		  EL | 2015
		  ES | 2014
 		  .. |  ....
		  
* `olib` : (_option_) output dataset library; default (not passed or ' '): `olib=WORK`.

### Example
Run macro `%%_example_silc_agg_compute`.

### Notes
1. The computed aggregate is not inserted into the input dataset `&idsn` but in the output `&odsn` 
dataset passed as an argument. If you want to actually update the input dataset, you will need to
explicitely call for it. For instance, say you want to calculate the 2016 EU28 aggregate of `PEPS01` 
indicator from the so-called `rdb` library:

~~~sas
	%silc_agg_compute(EU28, 2016, PEPS01, &odsn, ilib=rdb, olib=WORK);
	DATA rdb.PEPS01;
		SET rdb.PEPS01(WHERE=(not(time=2016 and geo=EU28))) 
			WORK.PEPS01; 
	run;
	%work_clean(PEPS01);
~~~
2. For that reason, the datasets `&idsn` and `&odsn` must be different!

### Reference
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).

### See also
[%silc_EUvals](@ref sas_silc_euvals), [%ctry_select](@ref sas_ctry_select), 
[%zone_to_ctry](@ref sas_zone_to_ctry), [%var_to_list](@ref sas_var_to_list),
[%ds_contents](@ref sas_ds_contents).
