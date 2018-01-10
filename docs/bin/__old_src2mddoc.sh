#!/bin/bash
# @name:     src2mddoc.sh
# @brief:    Automatic generation of markdown files from self-documented R/SAS/Stata
#            programs
#
#    src2mddoc.sh [-h] [-v] [-t] [-p] [-f <fname>] [-d <dir>] <filename>
#
# @notes:
# 1. The command shall be launched inline from a shell terminal running bash 
#    - commonly installed on all Unix/Linux servers/machines),
#    - on Windows, consider using shells provided by Cygwin (https://www.cygwin.com/) 
#      or Putty (http://www.putty.org/),
#    - on Mac, use the OS terminal.
# 3. To launch the command, run on the shell command line:
#	    bash src2mddoc.sh <arguments>
# with your own arguments/instructions.
# 4. On a Unix server, you may have some DOS-related issue when running this program: 
# in order to deal with embedded control-M's in the file (source of the issue), it may 
# be necessary to run dos2unix, e.g. execute the following:
#	    dos2unix src2mddoc.sh 
#
# @date:     15/06/2016
# @credit:   grazzja <mailto:jacopo.grazzini@ec.europa.eu>

## extension of files of interest: what we deal with...
MDEXT=md
SASEXT=sas
STATAEXT=do
REXT=r
EXTS=("${SASEXT}" "${REXT}" "${STATAEXT}")

## some basic global settings

PROGRAM=`basename $0`
TODAY=`date +'%y%m%d'` # `date +%Y-%m-%d`

BASHVERS=${BASH_VERSION%.*}

# requirements

hash find 2>/dev/null || { echo >&2 " !!! Command FIND required but not installed - Aborting !!! "; exit 1; }
hash awk 2>/dev/null || { echo >&2 " !!! Command AWK required but not installed - Aborting !!! "; exit 1; }
hash cat 2>/dev/null ||  { echo >&2 " !!! Command CAT required but not installed - Aborting !!! "; exit 1; }

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

## usage and help

function usage() { 
    ! [ -z "$1" ] && echo "$1";
    echo "";
    echo "=================================================================================";
    echo "${PROGRAM} : Generate markdown file(s) from self-documented program(s).";
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
    echo "${PROGRAM} : Generate markdown file(s) from a self-documented R/SAS program(s).";
    echo "=================================================================================";
    echo "";
    echo "Syntax";
    echo "------";
    echo "    ${PROGRAM} [-h] [-v] [-t] [-p] [-f <fname>] [-d <dir>] <input>";
    echo "";
    echo "Parameters";
    echo "----------";
    echo " <input>    :   input defined as either a filename storing some (R/SAS/Stata/…)”;
    echo “                source code, or a directory containing such files;";
    echo " -f <name>  :   output name; it is either the name of the output file (with or";
    echo "                without ‘.md’ extension) when the parameter <input> (see above)";
    echo "                is passed as a file, or a generic suffix to be added to the";
    echo "                output filenames otherwise; when a suffix is passed, the '_'";
    echo "                symbol is added prior to the suffix; default: an empty suffix,";
    echo "                i.e. no suffix, is used;";
    echo " -d <dir>   :   output directory for storing the output formatted files; in the";
    echo "                case of test mode (see option -t below), this is overwritten by";
    echo "                the temporary directory /tmp/; default: when not passed, <dir> is";
    echo "                set to the same location as the input(s);";
    echo " -h         :   display this help;";
    echo " -v         :   verbose mode (all kind of useless comments…);";
    echo " -t         :   test mode; a temporary output will be generated and displayed;";
    echo "                use it for checking purpose prior to the automatic generation.";
    echo "";
    echo "Notes";
    echo "-----";
    echo "The documentation is read directly from the headers of the source code files and";
    echo "follows a common framework (template):";
    echo "  * for R files, it shall be inserted like comments (i.e. preceded by #) and in";
    echo "  between two anchors: #STARTDOC and #ENDDOC,";
    echo "  * for SAS files, it shall be inserted like comments in /** and */ signs.";
    echo "";
    echo "Examples";
    echo "--------";
    echo "* Test the generation of a markdown file from the clist_unquote.sas program and";
    echo "  display the result:";
    echo "    ${PROGRAM} -t $rootdir/library/pgm/clist_unquote.sas";
    echo "";
    echo "* Actually generate (after the test) that file and store it in a dedicated folder:";
    echo "    ${PROGRAM} -v -d $rootdir/documentation/md/library";
    echo "                     $rootdir/z/library/pgm/clist_unquote.sas";
    echo "";
    echo "* Similarly with a R file:";
    echo "    ${PROGRAM} -v -d $rootdir/documentation/md/library/5.3_Validation "; 
    echo "                     $rootdir/5.3_Validation/pgm/generate_docs.R";
    echo "";
    echo "* Automatically generate markdown files with suffix \"doc\" (i.e., list_quote.sas";
    echo "  will be associated to the file list_quote_doc.md) from all existing SAS files";
    echo "  in a given directory:";
    echo "    ${PROGRAM} -v -d $rootdir/documentation/md/library/";
    echo "                     -f doc";
    echo "                     $rootdir/library/pgm/";
    echo "";
    echo "";
    echo "        European Commission  -   DG ESTAT   -   2016        ";
    echo "=================================================================================";
    exit 
}

## useful function declarations

function  greaterorequal (){
	# arguments: 	1:numeric 2:numeric
	# returns:	 	0 when argument $1 >= $2
	#				1 otherwise
	# note: 0 is the normal bash "success" return value (to be used in a "if...then" test)
	return `awk -vv1="$1" -vv2="$2" 'BEGIN { print (v1 >= v2) ? 0 : 1 }'`
	# hash bc 2>/dev/null && 	return $(bc <<< "$1 < $2") # we test the opposite, see the note above
	# if [ ${1%.*} -eq ${2%.*} ] && [ ${1#*.} \> ${2#*.} ] || [ ${1%.*} -gt ${2%.*} ]; then
	#	return 0
	#else
	#	return 1
	#fi
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

function contains () {
	# argument: 	1:value 2:list
	# returns: 		0 when the value $1 appears (i.e., is contained) in the list $2
	#				1 otherwise
	# note: 0 is the normal bash "success" return value
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

function regexMatch() { # (string, regex)
	if `greaterorequal ${BASHVERS} 3.3`; then
		eval "[[ \$1 =~ \$2 ]]"
		return $?
    else
		local string=$1	
		if [[ ${2: -1} = $ ]]; then
		local regex="(${2%$})()()()()()()()()$"
		else
		local regex="($2)()()()()()()()().*"
		fi
		regex=${regex//\//\\/}
		local replacement="\1\n\2\n\3\n\4\n\5\n\6\n\7\n\8\n\9\n"
		local oIFS=${IFS}
		IFS=$'\n'
		REMATCH=($(echo "$string" | /bin/sed -rn "s/$regex/$replacement/p" | while read -r; do echo "${REPLY}"; done))
		IFS=${oIFS}
		[[ $REMATCH ]] && return 0 || return 1
	fi
}

## set global parameters
TESTECHO=

uREXT=`uppercase ${REXT}`
uSASEXT=`uppercase ${SASEXT}`
uSTATAEXT=`uppercase ${uSTATAEXT}`
uEXTS=$(for i in ${EXTS[@]}; do uppercase $i; done)

dirname=
fname=
#progname=

pref=0
verb=0
test=0
 
## basic checks: command error or help

[ $# -eq 0 ] && usage
# [ $# -eq 1 ] && [ $1 = "--help" ] && help

# we use getopts to pass the arguments
# options are: [-d <dir>] [-f <fname>] [-p] [-h] [-v] [-t]
while getopts :d:f:phtv OPTION; do
    # extract options and their arguments into variables.
    case ${OPTION} in
	d)  dirname=${OPTARG}
            # check the existence of the directory
	    [ -d "${dirname}" ] || usage "!!! Output directory ODIR=${dirname} not found - Exiting !!!"
 	    ;;
	f)  fname=${OPTARG}
	    ;;
	h)  help #show help
	    ;;
	p)  pref=1
	    ;;
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

# further checks (possible after the shifts above)
[ $# -lt 1 ] && usage "!!! Missing input PROGNAME argument - Exiting !!!"
# [ $# -gt 1 ] && usage "!!! Only one argument can be passed - Exiting !!!"

# retrieve the input progname(s): all the arguments left
progname=("$@")
nprogs=${#progname[@]}

# new=()

for (( i=0; i<${nprogs}; i++ )); do
    # [ -n "${progname[$i]}" ]                                                  \
    #     && usage "!!! Input not defined - Exiting !!!"
    ! [ -e "${progname[$i]}" ]                                                  \
	&& usage "!!! Input file/directory ${progname[$i]} does not exist - Exiting !!!"
    # in case a program file was passed, check that its format (i.e. the programming language
    # used for its development) is actually supported for documentation
#    ([ -f "${progname[$i]}" ]                                                    \
#	&& ext=`uppercase  ${progname[$i]##*.}`                                 \
#	&& ! `contains ${ext} ${uEXTS[@]}`)                                      \
#	&& usage "!!! Format of input file ${progname[$i]} not supported - Exiting !!!"
#        # || new+=progname[$i]
done

# nprogs=${#new[@]}

## further settings

if [ ${test} -eq 1 ]; then
    # some settings for testing
    TESTECHO=("echo" "  ... run:") 
    [ -z "${dirname}" ] && dirname=/tmp   
    [ -z "${fname}" ] && fname=`date +%Y%m%d-%H%M%S`

else
    # define the default output directory path DIRNAME (when not passed with the
    # '-d' option) as the name of the directory storing the first file PROGNAME[0],
    # or PROGNAME[0] itself if it is a directory
    [ -z "${dirname}" ] && dirname=`dirname ${progname[0]}`
  
    # we define a generic name FNAME for the output markdown files as:
    #  - the generic string passed with the option '-f' when a directory or multiple
    #    files are passed in the main argument,
    #  - an empty string otherwise.
    # nothing to do: [ -n "${fname}" ] && [ ${nprogs} -gt 1 ] && fname=...as is
fi

# some practical issue here: ensure that we do not put any extension in the string
# defined by FNAME (this is added later on)
[ -n "${fname}" ] && [ ${nprogs} -eq 1 ]                    \
    && fname=${fname%.*} #`basename ${fname} .${MDEXT}`

# if FNAME is not empty and does not start with a '_' character, then add it
[ -n "${fname}" ] && [ ${fname} != _* ]                     \
    && ([ ${nprogs} -gt 1 ] || [ -d "${progname[0]}" ])     \
    && fname=_${fname}

([ ${test} -eq 1 ] || [ ${verb} -eq 1 ])                                        \
    && echo "* Setting parameters: input/output filenames and directories..."   

if [ ${test} -eq 1 ] || [ ${verb} -eq 1 ];    then
    echo ""
    [ ${verb} -eq 1 ] && echo "* Program configuration..."
    echo " `basename $0` will run with the following arguments:"
    echo "    - the output directory is: $dirname"
    for (( i=0; i<${nprogs}; i++ )); do
	inp=${progname[$i]}
	[ -d "$inp" ]                                                                          \
	    && (echo "    - for any program f.ext of ${inp}/, a documentation";                \
	       [ ${pref} -eq 1 ]                                                               \
	       && echo "      will be stored in a file named \$ext_\$f${fname}.${MDEXT}"       \
	       || echo "      will be stored in a file named \$f${fname}.${MDEXT}")            \
	    || (echo "    - the documentation of ${inp} program will be stored";               \
	       [ ${pref} -eq 1 ]                                                               \
	       && ([ ${nprogs} -eq 1 ]                                                         \
	          && echo "      in the file ${inp##*.}_${fname}.${MDEXT}"                     \
	          || echo "      in the file ${inp##*.}_${inp%.*}${fname}.${MDEXT}")           \
	       || ([ ${nprogs} -eq 1 ]                                                         \
	          && echo "      in the file ${fname}.${MDEXT}"                                \
	          || echo "      in the file ${inp%.*}${fname}.${MDEXT}") )
    done
fi

## actual operation
([ ${test} -eq 1 ] || [ ${verb} -eq 1 ])                                        \
    && echo "* Actual operation: extraction of files headers..."

for (( i=0; i<${nprogs}; i++ )); do
    # note that, as desired, the 'find' instruction below will return:
    #  - ${progname[$i]} itself when it is a file,
    #  - all the files in ${progname[$i]} when it is a directory.
    for file in `find ${progname[$i]} -type f`; do
		# get the file basename 
		f=`basename "$f"`
		# get the extension
        ext=`lowercase ${f##*.}`
		# check that it is one of the types (i.e. programming languages) whose
		# documentation is actually supported
		! `contains ${ext} ${EXTS[@]}` && continue
		# retrieve the desired output name based on generic FNAME and the MDEXT extension: 
		# this will actually depend only on whether one single file was passed or not
		([ ${nprogs} -eq 1 ] && ! [ -d ${progname[$0]} ])                               \
			&& filename=${f%.*}${fname}.${MDEXT}                                        \
			|| filename=${fname}.${MDEXT} 
		# by convention, avoid occurrences of "__" in the output filename (note the presence
		# of the parentheses)
		[ ${pref} -eq 1 ]                                                               \
			&& (regexMatch "${filename}" "^_.*"                                         \
			&& filename=${ext}${filename}                                               \
			|| filename=${ext}_${filename})
		# finally add the output DIRNAME to the FILENAME
		filename=${dirname}/${filename}
			([ ${verb} -eq 1 ] && ! [ ${test} -eq 1 ])                                      \
			&& echo "    + processing $ext file $f => MD file $filename ..."
		# run the extraction, e.g. for SAS and Stata files we do the following:
        #   (i) keep only the first lines between /** and */
        #   (ii) get rid of lines starting with /**
        #   (iii) get rid of lines starting with */
		# which uses mostly the awk command like in the example below:
        #     awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $1 | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > test1.txt
        #     awk -F"\/\*\*" '{print $2}' $1  | awk -F"\*\/" '{print $1}' - > test2.txt
		([ "${ext}" =  "${SASEXT}" ] || [ "${ext}" =  "${STATAEXT}" ])                       \
			&& ${TESTECHO}                                                                   \
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' ${file} \
			| awk '!/^ *\/\*\*/ { print; }' -                                                \
			| awk '!/^ *\*\// { print; }' - > $filename
		# ibid for R files
		[ "${ext}" = "${REXT}" ]                                                             \
			&& ${TESTECHO}                                                                   \
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="##"{s=1}s==1{print $0}$NF=="##"{s=2}' ${file}  \
			| awk '!/^ *\#\#/ { print; }' -                                                  \
			| awk '!/^ *\#\#/ { print substr($0,2); }' - > $filename
		# check that the file is not empty
		! [ -s ${filename} ] && rm -f  ${filename}
		# display in case of test
        if [ ${test} -eq 1 ];    then
			echo ""
			echo "Result of automatic Markdown extraction from test input file $f"
			echo "(first found in $progname directory)"
			echo "##########################################"
			cat ${filename}
	    echo "##########################################"
			rm -f ${filename}
			break
        fi
    done
done
