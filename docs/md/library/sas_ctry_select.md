## ctry_select {#sas_ctry_select}
Build the list of countries/years to take into consideration in order to calculate the 
aggregate value for a given indicator and a given area.
 
~~~sas
	%ctry_select(idsn, geo, time, ctrydsn, ilib=, _pop_infl_=, _run_agg_=, _pop_part_=,
				max_yback=0, sampsize=0, max_sampsize=0, thr_min=, thr_cum=,
				cds_popxctry=META_POPULATIONxCOUNTRY, cds_ctryxzone=META_COUNTRYxZONE, 
				clib=LIBCFG);
~~~

### Arguments
* `dsn` : a dataset storing the indicator for which an aggregated value is estimated;
* `geo` : list of (blank-separated) strings representing the ISO-codes of all the countries 
	that belong to a given geographical area;
* `time` : year of interest;
* `max_yback` : (_option_) look backward in time, _i.e._ consider the `max_yback` years prior to 
	the considered year; default: `max_yback=0`, _i.e._ only data available for current year shall 
	be considered; `max_yback` can also be set to `_ALL_` so as to take all available data from 
	the input dataset, whatever the year considered: in that case, all other arguments normally 
	used for building the list of countries (see below: `sampsize, max_sampsize, thr_min, thr_cum`) 
	are ignored; default: `max_yback=0` (_i.e._, only current year);
* `sampsize` : (_option_) size of the set of countries from previous year that is sequentially 
	added to the list of available countries so as to reach the desired threshold; this parameter 
	is ignored (_i.e._, set to 0) when `max_yback=_ALL_`; default: `sampsize=0`, _i.e._ all data 
	shall be added at once when available;
* `max_sampsize` : (_option_) maximum number of additional countries from previous to take into
	consideration for the estimation; default: `max_sampsize=0`;
* `thr_min` : (_option_) value (in range [0,1]) of the threshold to test whether:
		`pop_part / pop_glob >= thr_min` ? 
	default: `thr_min=0.7` (_i.e._ `pop_part` should be at least 70% of `pop_glob`); seting `thr_min=0`
	ensures `_run_agg_=yes`;
* `thr_cum` : (_option_) value (in range [0,1]) of the second threshold considered when cumulating
	the list of currently available countries with countries from previous years; this parameter is 
	set to `thr_cum=1` when `max_yback=_ALL_`, and to `thr_cum=0` and `max_yback=0`; default: not 
	set; 
* `ilib` : (_option_) input dataset library; default (not passed or ' '): `ilib=WORK`.

### Returns
* `ctrydsn` : name of the output table where the list of countries with the year of estimation is
	stored;
* `_pop_infl_` : name of the macro variables storing the 'inflation' rate between both global and
	partial population, _i.e._ the ratio pop_glob / pop_part;
* `_run_agg_` : name of the macro variables storing the result of the test whhether some aggregates
	shall be computed or not, _i.e._ the result (`yes/no`) of the test:
		`pop_part / pop_glob >= thr_min` ?
* `_pop_part_` : name of the macro variable storing the final cumulated population considered for 
	the estimation of the aggregate.

### References
1. World Bank [aggregation rules](http://data.worldbank.org/about/data-overview/methodologies).

### Example
Run macro `%%_example_aggregate_build`.

### See also
[%str_isgeo](@ref sas_str_isgeo), [%ctry_find](@ref sas_ctry_find),
[%ctry_population](@ref sas_ctry_population), [%population_compare](@ref sas_population_compare), 
[%zone_replace](@ref sas_zone_replace).
