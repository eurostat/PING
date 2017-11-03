## META_ZONExYEAR {#meta_zonexyear}
Configuration file used to set years of existence/consideration of EU geographical areas.

### Contents
A table named after the value `&G_PING_ZONExYEAR` (_e.g._, `META_ZONExYEAR`) shall be defined 
in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain 
for EU geographical (aggregated) area:
* start and end year of use/existence of the area, 
* start and end year of actual use of the area in the computation. 

In practice, the table looks like this (can change owing to updates):
geo | YEAR_IN   |  YEAR_OUT  | YEAR_START |	YEAR_END   
----|-----------|------------|------------|----------
EU28|	2010	|	9999	 |	  2010    | 	9999
EU27|	2007	|	9999	 |	   .      | 	.		
EU25|	2004	|	9999	 |	   .      | 	.		
EU15|	1995	|	9999	 |	   .      | 	.	
EU	|	1957	|	9999	 |	  2003    | 	9999
EA19|	2015	|	9999	 |	  2005    | 	9999
EA18|	2014	|	9999	 |	   .      | 	.		
EA17|	2011	|	9999	 |	   .      | 	.		
EA16|	2009	|	9999	 |	   .      | 	.		
EA15|	2008	|	9999	 |	   .      | 	.		
EA13|	2007	|	9999	 |	   .      | 	.		
EA12|	1999	|	9999	 |	   .      | 	.		
EA	|	1999	|	9999	 |	  2003    | 	9999

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%meta_zonexyear(cds_zonexyear=A, cfg=B, clib=C);

Note that, by default, the command `%%meta_zonexyear;` runs:

	%meta_zonexyear(cds_zonexyear=&G_PING_ZONExYEAR, 
				cfg=&G_PING_AGGREGATES/config, 
				clib=&G_PING_LIBCFG);

### Example
Generate the table `META_ZONExYEAR` in the `WORK` directory:

	%meta_zonexyear(clib=WORK);

### See also
[%zone_to_ctry](@ref sas_zone_to_ctry), [%ctry_to_zone](@ref sas_ctry_to_zone), [%str_isgeo](@ref sas_str_isgeo),
[%meta_countryxzone](@ref meta_countryxzone).
