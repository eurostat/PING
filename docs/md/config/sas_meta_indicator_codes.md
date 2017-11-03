## META_INDICATOR_CODES {#meta_indicator_codes}
Generate the tables of predefined indicator codes.

### Contents
A table named after the value `&G_PING_INDICATOR_CODES` (_e.g._, `META_INDICATOR_CODES`) shall 
be defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as 
to contain the codes of all indicators created in production. 

In practice, the table looks like this:
 code | survey | lib 
:----:|:------:|-----:
 DI01 |	EUSILC | RDB
 DI02 |	EUSILC | RDB
 DI03 |	EUSILC | RDB
 DI04 |	EUSILC | RDB
 DI05 |	EUSILC | RDB
 di06 |	ECHP   |  .
 DI07 |	EUSILC | RDB
 di07h| ECHP   |  .
 DI08 | EUSILC | RDB
 DI09 |	EUSILC | RDB
    
### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%meta_indicator_codes(cds_ind_cod=A, cfg=B, clib=C);

Note that, by default, the command `%%meta_indicator_contents;` runs:

	%meta_indicator_codes(cds_ind_cod=&G_PING_INDICATOR_CODES, 
					cfg=&G_PING_ESTIMATION/meta, 
					clib=&G_PING_LIBCFG, zone=yes);

### Example
Generate the table `META_INDICATOR_CODES` in the `WORK` directory:

	%meta_indicator_codes(clib=WORK);

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%meta_indicator_contents](@ref meta_indicator_contents), 
[%meta_variablexvariable](@ref meta_variablexvariable), [%meta_variable_dimension](@ref meta_variable_dimension).
