## ctry_population_join {#sas_ctry_population_join}
Join countries available for an aggregate area estimation together with their respective
population.
 
~~~sas
	%ctry_population_join(idsn, ctrydsn, time, odsn, where=, ilib=WORK, olib=WORK,
						  cds_popxctry=META_POPULATIONxCOUNTRY, clib=LIBCFG);
~~~

### Arguments
* `dsn` : a dataset representing the indicator for which an aggregated value is estimated;
* `ctrydsn` : name of the table where the list of countries with the year of estimation is
	stored;
* `time` : year of interest;
* `where` : (_option_) ; default: not set; 
* `cds_popxctry, clib` : (_option_) respectively, name and library of the configuration file storing 
	the population of different countries; by default, these parameters are set to the values 
	`&G_PING_POPULATIONxCOUNTRY` and `&G_PING_LIBCFG`' (_e.g._, `META_POPULATIONxCOUNTRY` and `LIBCFG`
	resp.); see [%meta_populationxcountry](@ref meta_populationxcountry)	for further description.
* `lib` : (_option_) input dataset library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
* `odsn` : name of the joined dataset;
* `olib` : (_option_) output library.

### Example
Run macro `%%_example_ctry_population_join`.

### See also
[%population_compare](@ref sas_population_compare), [%meta_populationxcountry](@ref meta_populationxcountry).