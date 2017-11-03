/** 
## sql_clause_if {#sas_sql_clause_if}
Generate a quoted text that can be interpreted by the `IF` clause of a SQL procedure.

~~~sas
	%sql_clause_if(dsn, var, _if_=, op=, lab=, log=);
~~~
*/
/* credits: grazzja */

%macro sql_clause_if(dsn
						, var
						, _if_=
						, op=
						, lab=
						, log=
						);

	%list_append(&op, %list_quote(&lab,rep=_EMPTY_), 
								zip=%quote(=), 
								rep=%quote( and )
						);
%mend sql_clause_if;
