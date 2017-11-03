## META_INDICATOR_CONTENTS {#meta_indicator_contents}
Provide a common contents as a set of generic dimensions to be included in an indicator table,
together with their types, lengths, and positions in the table.

### Contents
A table named after the value `&G_PING_INDICATOR_CONTENTS` (_e.g._, `META_INDICATOR_CONTENTS`) shall be 
defined in the library named after the value `&G_PING_LIBCFG` (_e.g._, `LIBCFG`) so as to contain 
the common variables/dimensions used in all indicators created in production. 

In practice, the table looks like this:
 dimension | type | length | order
:---------:|:----:|----- -:|--------:
  geo      | char |	  15   |	1
  time	   | num  |	   4   |	2
  unit	   | char |	   8   |   -9
  ivalue   | num  |	   8   |   -8
  iflag	   | char |	   8   |   -7
  unrel	   | num  |	   8   |   -6
  n	       | num  |	   8   |   -5
  nwgh     | num  |	   8   |   -5
  ntot	   | num  |	   8   |   -4
  ntotwgh  | num  |	   8   |   -3
  lastup   | char |	   8   |   -2
  lastuser | char |	   8   |   -1     

### Creation and update
Consider an input CSV table called `A.csv`, with same structure as above, and stored in a directory 
named `B`. In order to create/update the SAS table `A` in library `C`, as described above, it is 
then enough to run:

	%meta_indicator_contents(cds_ind_con=A, cfg=B, clib=C);

Note that, by default, the command `%%meta_indicator_contents;` runs:

	%meta_indicator_contents(cds_ind_con=&G_PING_INDICATOR_CONTENTS, 
					cfg=&G_PING_ESTIMATION/meta, 
					clib=&G_PING_LIBCFG, zone=yes);

### Example
Generate the table `META_INDICATOR_CONTENTS` in the `WORK` directory:

	%meta_indicator_contents(clib=WORK);

### See also
[%meta_variablexindicator](@ref meta_variablexindicator), [%meta_variable_dimension](@ref meta_variable_dimension).
