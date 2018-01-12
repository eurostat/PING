## silc_agg_list {#sas_silc_agg_list}
List default aggregates calculated when estimating EU-SILC indicators in a given year. 

~~~sas
	%silc_agg_list(time, _agg_=, _eu_=, _ea_=);
~~~

### Arguments
`time` : any single year of interest.

### Returns
* `_agg_` : (_option_) variable storing the default list of aggregates to be computed
	in survey year `time`; 
* `_eu_` : (_option_) variable storing the actual aggregate (_e.g._, either EU28, or EU27, or
	EU25, ...) to be calculated in place of EU;
* `_ea_` : (_option_) variable storing the actual aggregate (_e.g._, either EA19, or EA18, or
	EA17, ...) to be calculated in place of EA.

### Example
Running for instance:

~~~sas
	%let Agg=;
	%let EU=;
	%let EA=;
	%silc_agg_list(2006, _agg_=Agg, _eu_=EU, _ea_=EA);
~~~
will return: `Agg=EA18 EA19`, `EA=EA12` and `EU=EU25`.

See `%%_example_silc_agg_list` for more examples.

### Notes
1. One at least of the parameters `_agg_`, `_eu_` or `_ea_` should be set.
2. This macro should be implemented through a metadata table, instead of being hard encoded 
as is the case now, _e.g._ something like:
|       |EU15	|EU25	|EU27	|EU28	|EA12	|EA13	|EA15	|EA16	|EA17	|EA18	|EA19   |
|------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|2003	| X		|       |		|	    | X	    |	    |	    |	    |	    |	    |	    | 		
|2004	|		| X	  	|		|	    | X     |	    |	    |	    |	    |	    |	    | 
|2005	|		| X	  	|		|	    | X	    |	    |	    |	    |	    |	    |	    | 		  
|2006	|		| X	  	|		|	    | X	    |	    |	    |	    |	    |	    |	    |   
|2007	|		|	  	|   X	|		|	    | X	    |	    |	    |	    |	    |	    |			  
|2008	|		|	  	|   X	|		|	    | 		| X	    |	    |	    |	    |	    |	    	  
|2009	|		|	  	|   X	|		|	    | 		|		| X	    |	    |	    |	    |
|2010	|		|	  	|   	| X		|		|		|  		| X	    |	    |	    |	    |
|2011	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2012	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2013	|		|	  	|   	| X		|		|		|  		|  		| X	    |	    |	    |
|2014	|		|	  	|   	| X		|		|		|		|  		|  		| X	    |	    |
|2015	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    |
|2016	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    |
|2017	|		|	  	|   	| X		|		|		|		|		|  		|  		| X	    | 		
|... 	|...	|...	|...	|...	|...	|...	|...	|...	|...	|...	|...	|	
should be used to retrieve the desired global variables 
	
### Reference
Eurostat [geography glossary](http://ec.europa.eu/eurostat/statistics-explained/index.php/Category:Geography_glossary).
	
### See also
[%silc_agg_process](@ref sas_silc_agg_process), [%silc_agg_compute](@ref sas_silc_agg_compute).