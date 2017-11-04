## silc_ind_browse {#sas_silc_ind_browse}
Provide information (report) regarding the definition/data of EU-SILC indicators. 

~~~sas
	%silc_ind_browse(ind, lib, page=, fm=, odir=, oreport=);
~~~

### Arguments
* `ind` : (list of) indicator(s) whose information is requested;
* `lib` : input library where the indicator is stored;
* `page` : (_option_) variable used by proc report to create deparate page for each `BY` (`GEO` or `TIME` are accepted): 
	if not passed `GEO` is used;
* `odir` : (_option_) pathname where the report is stored, by default: `&G_PING_DIRHTML` is used;
* `fm` : (_option_) format of values.

### Returns
* `oreport` : (_option_) name of the output report; by default: `HTML_&ind` is used.

### Example
The instructions:

~~~sas
	%let ind=MDDD01;
	%let lib=C_RDB;
 	%silc_ind_browse(&ind,&lib);
~~~
will store in the output html `oreport` file the following table:
<table>
 <tr>
 <td colspan="18" align="center"><code>&ind</code></td>
 </tr>
 <tr>
 <td colspan="18" align="center"><code>geo = AT</code></td>
 </tr>
 <tr>
  <td colspan="3"> </td> 
 <td colspan="6" align="center"><code>n_item</code></td> 
 <td colspan="2"> </td> 
 <td colspan="6" align="center"><code>n_item</code></td>
 <td> </td> 
 </tr>
 <tr>
 <td colspan="3"> </td> 
 <td>0</td> <td>1</td> <td>2</td> <td>3</td> <td>4</td> <td>5</td> 
 <td colspan="2"> </td> 
 <td>0</td> <td>1</td> <td>2</td> <td>3</td> <td>4</td> <td>5</td> 
 <td> </td> 
 </tr>
 <tr> 
 <td><code>time</code></td> <td><code>incgrpZ</code></td> <td><code>hhtyp</code></td> 
 <td colspan="6"> </td> 
 <td><code>totnobs</code></td> <td><code>unrel</code></td> 
 <td><code>nobs</code></td> <td><code>nobs</code></td>  <td><code>nobs</code></td> <td><code>nobs</code></td> <td><code>nobs</code></td> <td><code>nobs</code></td> 
 <td><code>weight</code></td> 
 </tr>
 <tr> 
 <td>2003</td> <td><code>A_MD60</code></td>  <td><code>A1</code></td>  <td>72.02</td> <td>15.99</td> <td>7.23</td> <td>2.68</td> <td>1.78</td> <td>0.30</td> <td>857</td> <td>0</td> <td>632</td> <td>146</td> <td>70</td> <td>29</td> <td>17</td> <td>3</td> <td>4839214</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td><code>A1F</code></td>  <td>67.61</td> <td>19.69</td> <td>7.79</td> <td>3.54</td> <td>1.19</td> <td>0.17</td> <td>557</td> <td>0</td> <td>373</td> <td>108</td> <td>45</td> <td>22</td> <td>8</td> <td>1</td> <td>2776244</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td><code>A1M</code></td>  <td>77.94</td> <td>11.00</td> <td>6.48</td> <td>1.52</td> <td>2.58</td> <td>0.47</td> <td>340</td> <td>0</td> <td>259</td> <td>38</td> <td>25</td> <td>7</td> <td>9</td> <td>2</td> <td>2062971</td>
 </tr>
 <tr> 
 <td>...</td>  <td>...</td> <td>...</td>  <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td> <td>...</td>
</tr>
</table>

### See also
[%ds_contents](@ref sas_ds_contents), [%file_check](@ref sas_file_check), [%ds_check](@ref sas_ds_check),
[%par_check](@ref sas_par_check).
