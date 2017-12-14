/** 
## sql_clause_where {#sas_sql_clause_where}
Generate a quoted text that can be interpreted by the `WHERE` clause of a SQL procedure.

~~~sas
	%sql_clause_where(dsn, var, _where_=, op=, lab=, log=);
~~~
*/

/* credits: gjacopo */

%macro sql_clause_where(dsn
						, var
						, _where_=
						, op=
						, lab=
						, log=
						);

	%list_append(&op, %list_quote(&lab,rep=_EMPTY_), 
								zip=%quote(=), 
								rep=%quote( and )
						);
%mend sql_clause_where;
