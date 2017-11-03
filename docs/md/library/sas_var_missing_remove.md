## var_missing_remove {#sas_var_missing_remove}
Remove missing variables  numeric or character from a given dataset.

~~~sas
	%var_missing_remove(idsn, odsn,len=1400, ilib=WORK, olib=WORK);
~~~

### Arguments
* `idsn` : a dataset reference;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
* `len`  : (_option_) max length of macro variable ; by default: 1400 is used ( max value available is 32767) .

  
### Returns
* `odsn` : name of the output dataset (in `WORK` library); it will contain the selection operated on the 
	original dataset;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `WORK` is also used;

### Examples
Let us consider the test dataset #22:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy | fmt5_dummy | fmt6_dummy
-----------|----------|-------|-----|------------|------------|------------|------------|------------------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0		|            |      .      
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0     |            |      . 
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0     |            |      . 
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0     |            |      . 
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1     |            |      . 
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0     |            |      . 
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0     |            |      . 

and run the following:
	
~~~sas
	%_dstest22;
	%var_missing_remove(_dstest22, TMP);
~~~

to create the output table `TMP`:
 breakdown | variable | start | end | fmt1_dummy | fmt2_dummy | fmt3_dummy | fmt4_dummy
-----------|----------|-------|-----|------------|------------|------------|------------
  label1   |   DUMMY  |   1   |  5	|      1	 |      0	  |      1	   |      0
  label2   |   DUMMY  |   1   |  3	|      1	 |      1	  |      0	   |      0  
  label2   |   DUMMY  |   5   |  5	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   8   |  10	|      1	 |      1 	  |      0	   |      0
  label2   |   DUMMY  |   12  |  12	|      1	 |      1 	  |      0	   |      0
  label3   |   DUMMY  |   1   |  10	|      0	 |      1 	  |      1	   |      0
  label3   |   DUMMY  |   20  |HIGH |      0	 |      1	  |      1	   |      0
  label4   |   DUMMY  |   10  |  20	|      0	 |      0	  |      0	   |      1
  label5   |   DUMMY  |   10  |  12	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   15  |  17	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   19  |  20	|      0	 |      1	  |      1	   |      0
  label5   |   DUMMY  |   30  |HIGH	|      0	 |      1	  |      1	   |      0

Run macro `%%_example_ds_select` for examples.

### Notes
All character or numeric variables having missing values for alll observation in teh dataset will be removed.

### References

### See also
