R quantile {#r_quantile}
Compute empirical quantiles of sample data (_e.g._ survey data) corresponding to selected
probabilities. Include the 9 methods described by (Hyndman and Fan, 1996) + the one by
(Cunnane, 1978) + the one by (Filiben, 1975).


q <- quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))


Arguments
* `x` : a numeric vector or a value (character or integer) providing with the sample
data; when `data` is not null, `x` provides with the name (`char`) or the position
(int) of the variable of interest in the table;
* `data : (_option_) input table, defined as a dataframe, whose column defined by `x`
is used as sample data for the estimation; if passed, then `x` should be defined as
a character or an integer; default: `data=NULL` and input sample data should be passed
as numeric vector in `x`;
* `probs : (_option_) numeric vector giving the probabilities with values in [0,1];
default: `probs=seq(0, 1, 0.25)` like in original `stats::quantile` function;
* `na.rm, names : (_option_) logical flags; if `na.rm=TRUE`, any NA and NaN's are
removed from `x` before the quantiles are computed; if `names=TRUE`, the result has
a names attribute; these two flags follow exactly the original implementation of
`stats::quantile`; default: `na.rm= FALSE` and `names= FALSE`;
* `type : (_option_) an integer in [1,11] used to select one of the 9 algorithms
detailed in (Hyndman and Fan, 1996), alternatively the one inspired from (Cunnane, 1978)
or the one in (Filiben, 1975), as in the `Python scipy` library; see the references for
more details;
* `method : (_option_) choice of the implementation of the quantile estimation method;
this can be either:
+ `"INHERIT"` so that the function uses the original `stats::quantile` function already
implemented in `R`; this is incompatible with `type>9`,
+ `"DIRECT"` for a canonical implementation based on the direct transcription of the various
quantile estimation algorithms;

default: `method="DIRECT"`.

Returns
`q` : a vector containing the quantile values.
