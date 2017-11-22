#!/bin/bash

##
# sas2store.sh {#sh_sas2store}
# Automatic generation of a "store- and compile-able" version of a `SAS` source file.
#
# ~~~bash
#    sas2store.sh [-h] [-v] [-t] [-s] [-d] [-f <fname>] [-d <dir>] <filename>
# ~~~
#
# ### Arguments
# * `<input>` : input defined as either a filename storing some `SAS` source code, or a
#	directory containing such files; all first-level (_i.e._, non nested) macros present 
# 	in the file(s) will be transformed into "store- and compile-able" macros thanks to 
#	the adding of the `/ store` keyword option;
# * `-f <name>` : output name; it is either the name of the output file (with or without
#	`.sas` extension) when the parameter <input> (see above) is passed as a single file,
# 	or a generic suffix to be added to the output filenames otherwise; when a suffix 
# 	is passed, the '_'" symbol is added prior to the suffix; when considered as a suffix,
# 	the special flag _NONE_ can be used to force <name> to blank (i.e. no suffix will 
# 	be used); default: the suffix 'store' is used;
# * `-d <dir>` : output directory for storing the output formatted files; in the case of 
# 	test mode (see option -t` below), this is overwritten by the temporary directory 
# 	/tmp/; default: when not passed, <dir> is set to the same location as the input(s);
# * `-s` : flag used store the source code with the compiled code, _e.g._ adding the 
#	`source` keyword option;
# * `-c` : flag used to add a comment (description) to the store macro, _e.g._ adding the 
#	`des` keyword option;
# * `-h` : display this help;
# * `-v` : verbose mode (all kind of useless comments…);
# * `-t` : test mode; a temporary output will be generated and displayed; use it for 
# 	checking purpose prior to the automatic generation.
# 
# ### Example
# Run the script with the dedicated test file [
# `sas2store_testfile.sas`](https://github.com/gjacopo/bodylanguage/blob/master/handle/tests/sas2store_testfile.sh), 
# _e.g._ in test mode:
#
# ~~~bash
#    sas2store.sh -t -c -f stored sas2store_testfile.sas
# ~~~
#
# ### Note
# The output store-able file(s) must be different from the input source files, _i.e._
# the input file(s) cannot be overwritten. Therefore, you need to ensure that `<dir>`
# and `<name>` are not left 'blank' (empty) simultaneously; the operation will otherwise
# be cancelled.
#
# ### References
# 1. [_"Saving macros using the stored compiled macro facility"_](http://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a001328775.htm).
# 2. Myers, J.M. (2014): [_"Store and recall macros with SAS macro libraries"_](http://analytics.ncsu.edu/sesug/2014/IT-03.pdf).
# 3. Larsen, E.S. (2008): [_"Creating a stored macro facility in ten minutes"_](http://www2.sas.com/proceedings/forum2008/101-2008.pdf).
# 4. Stojanovic, M. (2005): [_"Ways to store macro source codes and how to retrieve them"_](http://analytics.ncsu.edu/sesug/2005/AD07_05.PDF).
##

# @date:     15/11/2017
# @credit:   grazzja <mailto:jacopo.grazzini@ec.europa.eu>

SASEXT=sas

PROGRAM=`basename $0` # `echo $0|sed -e 's:.*/::'`
TODAY=`date +'%y%m%d'` # `date +%Y-%m-%d`

BASHVERS=${BASH_VERSION%.*}

case "$(uname -s)" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*)    MACHINE=Cygwin;;
    MSYS*)      MACHINE=Msys;;
    MINGW*)     MACHINE=MinGw;;
    Windows*)   MACHINE=Windows;;
    SunOS*)     MACHINE=SunOS;;
    *)          MACHINE="UNKNOWN:${OSTYPE}"
esac

[ "${MACHINE}" = "Mac" ] && AWK=gawk || AWK=awk
[ "${MACHINE}" = "Mac" ] && SED=gsed || SED=sed

hash find 2>/dev/null || { echo >&2 " !!! Command FIND required but not installed - Aborting !!! "; exit 1; }
hash ${AWK} 2>/dev/null || { echo >&2 " !!! Command ${AWK} required but not installed - Aborting !!! "; exit 1; }
hash ${SED} 2>/dev/null ||  { echo >&2 " !!! Command ${SED} required but not installed - Aborting !!! "; exit 1; }

function usage() { 
    ! [ -z "$1" ] && echo "$1";
    echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Automatic generation of a 'store- and compile-able' version of a SAS";
	echo "source file.";
    echo "";
    echo "Run: ${PROGRAM} -h for further help. Exiting program...";
    echo "=================================================================================";
    echo "";
    exit 1; 
}

function help() {
    ! [ -z "$1" ] && echo "$1";
    echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Automatic generation of a 'store- and compile-able' version of a SAS";
	echo "source file.";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
    echo "------";
    echo "    ${PROGRAM} [-h] [-v] [-t] [-c] [-s] [-f <fname>] [-d <dir>] <input>";
    echo "";
    echo "Parameters";
    echo "----------";
    echo " <input>   : input defined as either a filename storing some SAS source code, or";
    echo "             a directory containing such files; all first-level (i.e., non nested)";
    echo "             macros present in the file(s) will be transformed into 'store- and";
	echo "             compile-able' macros thanks to the adding of the '/ store' keyword";
	echo "             option;";
    echo " -f <name> : output name; it is either the name of the output file (with or without";
    echo "             '.sas' extension) when the parameter <input> (see above) is passed as";
    echo "             a single file, or a generic suffix to be added to the output filenames";
    echo "             otherwise; when a suffix is passed, the '_' symbol is added prior to";
    echo "             the suffix; when considered as a suffix, the special flag _NONE_ can";
    echo "             be used to force <name> to blank (i.e. no suffix will be used); default:";
    echo "	           the suffix 'store' is used;";
    echo " -d <dir>  : output directory for storing the output formatted files; in the case of";
    echo "             test mode (see option -t below), this is overwritten by the temporary";
    echo "             directory /tmp/; default: when not passed, <dir> is set to the same";
    echo "             location as the input(s);";
	echo " -s 		 : flag used store the source code with the compiled code, e.g. adding the"  
	echo "             'source' keyword option;";
    echo " -c        : flag used to add a comment (description) to the store macro, e.g. adding;";
	echo "             the 'des' keyword option;";
	echo " -h        : display this help;";
    echo " -v        : verbose mode (all kind of useless comments…);";
    echo " -t        : test mode; a temporary output will be generated and displayed;";
    echo "             use it for checking purpose prior to the automatic generation.";
    echo "";
    echo "Note";
    echo "----";
    echo "The output store-able file(s) must be different from the input source files, i.e.";
    echo "the input file(s) cannot be overwritten. Therefore, you need to ensure that <dir>";
    echo "and <name> are not left 'blank' (empty) simultaneously; the operation will otherwise";
    echo "be cancelled.";
    echo "";
    echo "Example";
    echo "-------";
    echo "Run the script with the dedicated test file sas2store_testfile.sas, e.g. in test mode:";
    echo "    ${PROGRAM} -t -c -f stored sas2store_testfile.sas";
    echo "";
    echo "        European Commission  -   DG ESTAT   -   2017        ";
    echo "=================================================================================";
    exit 
}

## useful function declarations

function  greaterorequal (){
	# arguments: 	1:numeric 2:numeric
	# returns:	 	0 when argument $1 >= $2
	#				1 otherwise
	# note: 0 is the normal bash "success" return value (to be used in a "if...then" test)
	return `${AWK} -vv1="$1" -vv2="$2" 'BEGIN { print (v1 >= v2) ? 0 : 1 }'`
}

function uppercase () {
	# argument: 	1:string
	# returns: 		a uppercase version of $1
	if `greaterorequal ${BASHVERS} 4`; then
		echo ${1^^} # does not work on bash version < 4
	else
		echo  $( tr '[:lower:]' '[:upper:]' <<< $1)
	fi
}
function lowercase () {
	# argument: 	1:string
	# returns: 		a lowercase version of $1
	if `greaterorequal ${BASHVERS} 4`; then
		echo ${1,,} # does not work on bash version < 4
	else
		echo  $( tr '[:upper:]' '[:lower:]' <<< $1)
	fi
}

function remcomms () {
	# argument: 	1:file
	# returns: 		remove comments
    if true; then
        # source: https://gist.github.com/mystix/426760
		a="`echo | tr '\012' '\001'`"
      	b="`echo | tr '\012' '\002'`"
       	${SED} '
       	    # if no start comment then go to end of script
            /\/\*/!b
       	    :a
	    s:/\*:'"$a"':g
	    s:\*/:'"$b"':g
   	    # if no end comment
	    /'"$b"'/!{
	        :b
		# if not last line then read in next one
	   	$!{
	     	    N
		    ba
		}
		# if last line then remove from start
		# comment to end of line
		# then go to end of script
	        s:'"$a[^$b]"'*$::
		bc
	    }
	    # remove comments
            '"s:$a[^$b]*$b"'::g
	    /'"$a"'/ bb
	    :c
	    s:'"$a"':/*:g
	    s:'"$b"':*/:g
	' $1
    else 
        # source: https://www.gnu.org/software/gawk/manual/html_node/Plain-Getline.html#Plain-Getline
	# some issue found with this approach
	${AWK} 
	    '{if ((i = index($0, "/*")) != 0) {
	        out = substr($0, 1, i - 1)  
		# leading part of the string
	       	rest = substr($0, i + 2)    
	       	# ... */ ...
	       	j = index(rest, "*/")       
	       	# is */ in trailing part?
	       	if (j > 0) {
	            rest = substr(rest, j + 2) 
      		    # remove comment
       		} else {
       		    while (j == 0) {
	       		# get more text
       			if (getline <= 0) {
		       	    print("unexpected EOF or error:", ERRNO) > "/dev/stderr"
	      		    exit
	      	       	}
		       	# build up the line using string concatenation
		       	rest = rest $0
		       	j = index(rest, "*/")   
		       	# is */ in trailing part?
		       	if (j != 0) {
		       	    rest = substr(rest, j + 2)
		       	    break
		       	}
	       	    }
	        }
	       	# build up the output line using string concatenation
       		$0 = out rest
       	    }
       	    print $0}
        ' $1
    fi
}

function rememptylines () {
	# argument: 	1:file
	# returns: 		suppress repeated empty (including space/tabs) output lines
	${SED} ' 
		# space/tabs in  "empty" line
		/^\s*$/N; /^\s*\n$/D
		' $1
	# ${SED} '/^\s*$/D' $1 # remove all blank lines
	# ${SED} -re '$!N; /^\s*\n$/!P;D'
}

function getdesc () {
	# argument: 	1:file
	# returns: 		first lines of documentation
	${AWK} '
		/^\#\#/ && /\{\#/ {m=1; next} 
			m==1 {if (!NF) {m=0; exit} else {print}
				} 
		' $1
}

function insstore () {
	# argument: 	1:file 2:description 3:source flag 
	# returns: 		instore the "\store" keyword after main macro declarations
	local store="/ store"
        local edesc=
	local tdesc=
	local ename=
	local tname=
	[ $# -lt 2 ] && fname= || fname=`basename "$2" .${SASEXT}`
	[ $# -lt 3 ] && desc=   || desc=${3}
	[ $# -lt 4 -o $4 -eq 0 ] && source= || source="source"
        ! [ -z "$fname" ]                                               \
	    && tname=_test_$fname                                       \
	    && ename=_example_$fname  
        ! [ -z "$desc" ]                                                \
	    && desc="des=\"$desc\""                                     \
	    && tdesc="des=\"Test case for macro $fname\""               \
	    && edesc="des=\"Example of application of macro $fname\"" 
	# options=("/ storea")
	# ! [ -z $source ] && options+=(" source")
	${AWK} -v fname="$fname" -v ename="$ename" -v tname="$tname" 	\
		-v store="$store" -v source="$source" 			\
		-v desc="$desc" -v edesc="$edesc" -v tdesc="$tdesc" 	\
		'BEGIN {m=0; f=0; 
			nofname1="[[:alnum:]]+"fname; nofname2=fname"[[:alnum:]]+";
			noename1="[[:alnum:]]+"ename; noename2=ename"[[:alnum:]]+";
			notname1="[[:alnum:]]+"tname; notname2=tname"[[:alnum:]]+"
			}
		# note the presence of the [[::space::]] after the keyword "%macro"
		/%macro[[:space:]]/ {
			# check whether the existence of a macro whose name is exactly the name of the file, 
			# i.e. <fname>, hence we need to care about the presence of spaces/blanks " ", semi-columns ";" 
			# or parenthesis ")"
			if ( $0 ~ fname && $0 !~ nofname1 && $0 !~ nofname2 ) {p=1} {p=0};
			# ibid with example macro:
			if ( $0 ~ ename && $0 !~ noename1 && $0 !~ noename2 ) {e=1} {e=0};
			# ibid with test macro:
			if ( $0 ~ tname && $0 !~ notname1 && $0 !~ notname2 ) {t=1} {t=0};
			# check for the presence of the <store> string, e.g. "/ store" to find out whether the
			# macro currently analysed is already stored or not
			if ( $0 ~ store ) {s=1} {s=0};
			# increment the flag variable m
			m+=1
			} # m>0
			{if (f==0) {
				# still look for the <fname> and <store> strings... they may be on any line between 
				# the keyword "%macro" and the semi-period
				if ( p<=0 && $0 ~ fname && $0 !~ nofname1 && $0 !~ nofname2 ) {p=1};
				if ( e<=0 && $0 ~ ename && $0 !~ noename1 && $0 !~ noename2 ) {e=1};
				if ( t<=0 && $0 ~ tname && $0 !~ notname1 && $0 !~ notname2 ) {t=1};
				if ( s<=0 && $0 ~ store ) {s=1};
				# look for the first occurrence of a semi-column right after the "%macro" keyword
				if (/;/ && m==1) { 
					i=index($0, ";");
					if (s>0) {
						print $0
					} else {
						# look for _example_<fname>
						if (e>0 && length(edesc)>0) {
							print substr($0, 0, i-1) " " store " " source " " edesc " " substr($0, i)
						# look for _test_<fname>
						} else if (t>0 && length(tdesc)>0) { 
							print substr($0, 0, i-1) " " store " " source " " tdesc " " substr($0, i) 
						# simply look for <fname>
						} else if (p>0 && length(desc)>0) { 
							print substr($0, 0, i-1) " " store " " source " " desc " " substr($0, i) 
						} else { 
							print substr($0, 0, i-1) " " store " " source " " substr($0, i)
						}
					}
					# reset the parameter f so that nothing occurs (except the printing) for all following 
					# lines prior to the next occurence of the keyword "%macro"
					f=1; 
					# also reset the other parameters
					p=0; s=0; e=0; t=0;
				} else {
					print $0
				}
			} else {
				print $0 
			}
			} 
		# ibid: note the presence of the blank after the keyword %mend or a semi-column ;
		/%mend[[:space:]]/ || /%mend;/ {m-=1} 
			{if (m==0) {f=0};
			}
		' $1
}

## set global parameters

dirname=
fname=
comm=0
#progname=

verb=0
test=0
remdoc=0
source=0
 
## basic checks: options, command error or help

[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help

# we use getopts to pass the arguments
# options are: [-d <dir>] [-f <fname>] [-d] [-h] [-v] [-t]
while getopts :d:f:cdshtv OPTION; do
    # extract options and their arguments into variables.
    case ${OPTION} in
	d)  dirname=${OPTARG}
            # check the existence of the directory
	    [ -d "${dirname}" ] || usage "!!! Output directory ODIR=${dirname} not found - Exiting !!!"
 	    ;;
	f)  fname=${OPTARG}
	    ;;
	c) comm=1
		;;
	s) source=1
		;;
	h)  help #show help
	    ;;
	#r)  remdoc=1 # NOT IMPLEMENTED YET
	#    ;;
	t)  test=1
	    ;;
	v)  verb=1
	    ;;
	\?) #unrecognized option - show help
	    usage "!!! option ${OPTARG} not allowed - Exiting !!!"
	    ;;
    esac
done

shift $((OPTIND-1))  

# force REMDOC to 1... # NOT IMPLEMENTED YET
remdoc=1

[ $# -lt 1 ] && usage "!!! Missing input PROGNAME argument - Exiting !!!"
progname=("$@")
nprogs=${#progname[@]}

## further settings

for (( i=0; i<${nprogs}; i++ )); do
    ! [ -e "${progname[$i]}" ]                                                  \
	&& usage "!!! Input file/directory ${progname[$i]} does not exist - Exiting !!!"
done

if [ ${test} -eq 1 ]; then
    ECHOSTART=("echo  ... run: \"") 
    ECHOEND=("\"") 
    [ -z "${dirname}" ] && dirname=/tmp   
    [ -z "${fname}" ] && fname=`date +%Y%m%d-%H%M%S`
else
    [ -z "${dirname}" ] && dirname=`dirname ${progname[0]}`
	ECHOSTART=
	ECHOEND=
fi

# some practical issue here: ensure that we do not put any extension in the string
# defined by FNAME (this is added later on)
[ -n "${fname}" ] && [ ${nprogs} -eq 1 ]                    \
    && fname=${fname%.*} #`basename ${fname} .${MDEXT}`

# if FNAME is not empty and does not start with a '_' character, then add it
[ -n "${fname}" ] && [ ${fname} != _* ]                     \
    && ([ ${nprogs} -gt 1 ] || [ -d "${progname[0]}" ])     \
    && fname=_${fname}
		
for (( i=0; i<${nprogs}; i++ )); do
	for file in `find ${progname[$i]} -type f`; do
		# get the file basename 
		base=`basename "$file"`
		# get the extension
        ext=`lowercase ${base##*.}`
		# check that it is one of the types (i.e. programming languages) whose
		# documentation is actually supported
		! [ "$ext" = "${SASEXT}" ] && continue
		## we will not run the operation when the input and output are the same! 
		
		# retrieve the desired output name based on generic FNAME and the MDEXT extension: 
		# this will actually depend only on whether one single file was passed or not
		[ ${nprogs} -eq 1 -a ! -d ${progname[0]} ]                          \
			&& filename=${base%.*}${fname}.${SASEXT}                       	\
			|| filename=${fname}.${SASEXT} 
			
		# check that we are not overwritting the file
		[ ${filename} = ${file} ]  																\
			&& echo "!!! Input/output files must differ - Operation with ${file} aborted !!! " 	\
			&& continue 
		
		# retrieve the description from the documentation header whenever desired
		[ ${comm} -eq 1 ] && desc=`getdesc ${file}` || desc= #_NONE_
		
		# run the operation of string conversion
		if [ ${remdoc} -eq 1 ]; then
			`remcomms ${file} | rememptylines - | insstore - ${base} "\${desc}" ${source} > ${filename}`	
		else	
			`insstore ${file} "\${desc}" ${source} > ${filename}`	
		fi		
		
		# display in case of test
		if [ ${test} -eq 1 ];    then
			echo ""
			echo "Preview of store-able version"
			echo "------------------------------------------"
			cat ${filename}
			echo "------------------------------------------"
			rm -f ${filename}
			break
		fi
    done
done
