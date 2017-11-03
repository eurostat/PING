#!/bin/bash
# @brief:    Automatic generation of markdown files from self-documented R/SAS programs
#
#    rsas2mddoc.sh [-help] [-v] [-test] [-of <oname>] [-od <dir>] <filename>
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix.
#
# @date:     15/06/2016
# @credit:   grazzja <mailto:jacopo.grazzini@ec.europa.eu>

BASH_VERS=${BASH_VERSION%%[^0-9.]*}

case "$OSTYPE" in
  linux*)   	DRIVE=/export/0eusilc ;;
  #darwin*)  	echo "OSX" ;; 
  #win*)     	echo "Windows" ;;
  cygwin*)  	DRIVE=/cygdrive ;;
  msys*|mingw*)	DRIVE=;;
  #bsd*)     	echo "BSD" ;;
  #solaris*) 	echo "SOLARIS" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

rootdir=${drive}/z
 
## basic checks: command error or help
if [ $# -eq 0 ]; then
    echo "`basename $0` : Create Markdown document from R/SAS file header."
    echo "Run: `basename $0` -help for further help. Exiting program..."
    #echo "Syntax : `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
    exit 
elif [ $# -eq 1 ] && [ $1 = "-help" ]; then 
    echo "================================================================================="
    echo "`basename $0` : Generate markdown file(s) from a self-documented R/SAS program(s)."
    echo "================================================================================="
    echo ""
    echo "Syntax";
 	echo "------"
    echo "    `basename $0` [-help] [-v] [-test] [-of <oname>] [-od <dir>] <input>"
    echo ""
    echo "Parameters"
  	echo "----------"
    echo " input        :   input R/SAS filename or a directory with R/SAS files "
    echo " -help        :   display this help"
    echo " -v           :   verbose mode (all kind of useless comments...)"
    echo " -test        :   test mode; a temporary output will be generated and displayed;"
    echo "                  use it for checking purpose prior to the automatic generation"
    echo " -od <dir>    :   output directory for storing the output formatted files; in the"
    echo "                  case of test mode (see option -test above), this is overwritten"
    echo "                  by the temporary directory /tmp/; default: same location as"
	echo "                  input original file"
    echo " -of <name>   :   output name; it is either the name of the output file (with or"
    echo "                  without .md extension) in the case parameter <input> is passed"
    echo "                  (see above) as a file, or a generic suffix to be added to the"
    echo "                  output file names otherwise; when a suffix is passed, the '_'" 
	echo "                  symbol is added prior to the suffix; default: empty suffix"
    echo ""
    echo "Notes"
	echo "-----"
	echo "The documentation is read directly from SAS/R file headers and follows a common"
	echo "framework:"
	echo "  * for R files, it shall be inserted like comments (i.e. preceded by #) and in"
	echo "  between two anchors: #STARTDOC and #ENDDOC,"
	echo "  * for SAS files, it shall be inserted like comments in /** and */ signs." 
	echo ""
    echo "Examples"
	echo "--------"
    echo "* Test the generation of a markdown file from the clist_unquote.sas program and"
    echo "  display the result:"
    echo "    `basename $0` -test $rootdir/library/pgm/clist_unquote.sas" 
    echo ""
    echo "* Actually generate (after the test) that file and store it in a dedicated folder:"
    echo "    `basename $0` -v -od $rootdir/documentation/md/library" 
    echo "                     $rootdir/z/library/pgm/clist_unquote.sas"
    echo ""
    echo "* Similarly with a R file:"
    echo "    `basename $0` -v -od $rootdir/documentation/md/library/5.3_Validation " 
    echo "                     $rootdir/5.3_Validation/pgm/generate_docs.R"
    echo ""
    echo "* Automatically generate markdown files with suffix \"doc\" (i.e., list_quote.sas"
    echo "  will be associated to the file list_quote_doc.md) from all existing SAS files"
    echo "  in a given directory:"
    echo "    `basename $0` -v -od $rootdir/documentation/md/library/"
    echo "                     -of doc"
    echo "                     $rootdir/library/pgm/"
    echo ""
    echo ""
    echo "        European Commission  -   DG ESTAT   -   The EU-SILC team  -  2016        "
    echo "================================================================================="
    exit 
fi

if [[ ${BASH_VERS:0:3} < 3.2 ]]; then 
	toUpper() { # (string)
		echo $(echo $1 | tr '[:lower:]' '[:upper:]')
		}
	toLower() { # (string)
		echo $(echo $1 | tr '[:upper:]' '[:lower:]')
		}	
	# issues with bash versions<3.2
	# see http://stackoverflow.com/questions/15510083/syntax-error-operator-in-msysgit-bash
	# ...if command -v /bin/sed >/dev/null 2>&1; then
    regexMatch() { # (string, regex)
        local string=$1
        if [[ ${2: -1} = $ ]]; then
            local regex="(${2%$})()()()()()()()()$"
        else
            local regex="($2)()()()()()()()().*"
        fi
        regex=${regex//\//\\/}
        local replacement="\1\n\2\n\3\n\4\n\5\n\6\n\7\n\8\n\9\n"
        local OLD_IFS=$IFS
        IFS=$'\n'
        BASH_REMATCH=($(echo "$string" | /bin/sed -rn "s/$regex/$replacement/p" | while read -r; do echo "${REPLY}"; done))
        IFS=$OLD_IFS
        [[ $BASH_REMATCH ]] && return 0 || return 1
    }
else
	toUpper() { # (string)
		echo ${1^^}
		}	
	toLower() { # (string)
		echo ${1,,}
		}	
	# ...if eval "[[ a =~ a ]]" 2>/dev/null; then
    regexMatch() { # (string, regex)
        eval "[[ \$1 =~ \$2 ]]"
        return $?
    }
fi

## set global parameters
VERB=0
SASEXT=sas
REXT=r
uREXT=`toUpper ${REXT}`
uSASEXT=`toUpper ${SASEXT}`
MDEXT=md
TEST=0
ODIR=0
OFILE=0
#ALLEXTS=$SASEXT $REXT 
ALLPROGS=0
# SUFF=_doc
SUFF=

## loop over the command arguments
# sh.........: I should have used getopts...
for i in $@;
    do
    if [ ${i:0:1} = "-" ];     then
        if [ $i = "-verb" ] || [ $i = "-v" ];         then
            VERB=1
            continue
        elif [ $i = "-test" ];         then
            TEST=1
            continue
        elif [ $i = "-of" ];     then
            OFILE=1
            continue
        elif [ $i = "-od" ];      then
            ODIR=1
            continue
        elif [ $OFILE -eq 1 ];      then
            echo "Output file name not set. Exiting program..."
            exit
        elif [ $ODIR -eq 1 ];        then   
            echo "Output directory not set. Exiting program..."
            exit
        else
            echo "Unknown option: $i. Exiting program..."
            exit
        fi        
    elif [ $OFILE -eq 1 ];     then
        mdname=$i
        OFILE=0
    elif [ $ODIR -eq 1 ];    then   
        dirname=$i
        ODIR=0
    else   
        progname=$i
    fi
done
     
## further settings
if [ $VERB -eq 1 ];     then
 	echo
	echo "* Setting parameters: input/output filenames and directories..."
fi
 
if ! [ -n "$progname" ];        then
    echo "Input filename not defined. Exiting program..."
    exit
elif [ -d "$progname" ];        then
	# a directory was passed: all PROG files in this directory will be treated
    ALLPROGS=1
elif ! [ -e "$progname" ];    then
    echo "Input file does not exist. Exiting program..."
    exit
# else: a single file was passed: OK
fi
  
if ! [ -n "$dirname" ] && ! [ $TEST -eq 1 ];    then
	# define the directory path as the directory name of the input file(s)
	if [ -d "$progname" ]; then
		dirname=$progname
	else
		dirname=`dirname $progname`
	fi
fi
	 
if ! [ -n "$mdname" ] && ! [ $ALLPROGS -eq 1 ];    then
	if [ $TEST -eq 1 ]; then
		mdname=tmp
	else
		mdname=`basename $progname`
	fi
elif [ -n "$mdname" ] && [ $ALLPROGS -eq 1 ];    then
    SUFF=$mdname
elif [ -n "$mdname" ] && [ `basename $mdname .$MDEXT` = $mdname ];    then
    mdname=$mdname.$MDEXT
fi
  
if [ $TEST -eq 1 ];    then
    dirname=/tmp
    SUFF=`date +%Y%m%d-%H%M%S`
    # mdname=`basename $mdname`_$SUFF.$MDEXT
fi
 
if [ -n "$SUFF" ] && ! [[ $SUFF = _* ]];    then
	# if SUFF is not empty and does not start with a '_' character, then add it
	SUFF=_$SUFF
fi

if [ $TEST -eq 1 ] || [ $VERB -eq 1 ];    then
 	echo
   if [ $VERB -eq 1 ];     then
        echo "* Program configuration..."
    fi
    echo "`basename $0` will run with the following arguments:"
    if [ $ALLPROGS -eq 1 ];    then
        echo "    - input files: all files f in $progname directory"
    else
        echo "    - input file: $progname"
    fi
    echo "    - output Markdown directory: $dirname"
    if [ $ALLPROGS -eq 1 ];    then
        echo "    - output Markdown files: \${ext}_\${f}$SUFF.$MDEXT for input file f with extension ext"
    else
        echo "    - output Markdown file: ${mdname%.*}$SUFF.$MDEXT"
    fi
    #echo "Exiting program. Rerun without option '-check' for actual operation..."
    #exit
fi

## actual operation
if [ $VERB -eq 1 ];     then
    echo "* Actual operation: extraction of files headers..."
fi 
 
# (i) keep only the first lines between /** and */
# (ii) get rid of lines starting with /**
# (iii) get rid of lines starting with */
# awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $1 | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > test1.txt
# awk -F"\/\*\*" '{print $2}' $1  | awk -F"\*\/" '{print $1}' - > test2.txt
 
# reminder:
# file 							<= 	<a>/<b>/<c>/<d>.<e>
# base=$(basename "$file") 		<= 	<d>.<e>
# fname=${base%.*}				<= 	<d>
# ext=${base##*.}				<= 	<e>
# eext=${ext,,}					<= 	<e> lower case

if [ $ALLPROGS -eq 1 ];    then
		for f in $progname/*; do
		if ! [ -f "$f" ]; then  # directory
			continue
		fi
		# get the file basename 
		f=`basename "$f"`
		# get the extension
		ext=${f##*.}
		ext=`toLower $ext`
		if [ $ext !=  $SASEXT ] && [ $ext !=  $REXT ];  then #not SAS file AND not R file
			continue
		fi
		mdname=${f%.*}$SUFF.$MDEXT
		if regexMatch "${mdname}" "^_.*"; then
			of=${dirname}/${ext}${mdname}
		else
			of=${dirname}/${ext}_${mdname}
		fi
        if [ $VERB -eq 1 ] && ! [ $TEST -eq 1 ];     then
            echo "    + processing $ext file $f => MD file $of ..."
        fi
        if [ $ext =  $SASEXT ];     then
			# echo "awk 'NF==0&&s==0{NR=0}NR==1&&\$1==\"/**\"{s=1}s==1{print \$0}\$NF==\"*/\"{s=2}' $progname/$f | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > $of"
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $progname/$f | awk '!/^ *\/\*\*/ { print; }' - | awk '!/^ *\*\// { print; }' - > $of
        elif [ $ext = $REXT ];    then
			awk 'NF==0&&s==0{NR=0}NR==1&&$1=="#STARTDOC"{s=1}s==1{print $0}$NF=="#ENDDOC"{s=2}' $progname/$f | awk '!/^ *\#STARTDOC/ { print; }' - | awk '!/^ *\#ENDDOC/ { print substr($0,2); }' - > $of
       fi
		if [ ! -s $of ]; then # file is empty: 0 byte...
			rm -f  $of
        elif [ $TEST -eq 1 ];    then
			echo
            echo "Result of automatic Markdown extraction from  test input file $f"
            echo "(first found in $progname directory)"
            echo "##########################################"
            cat $of
            echo "##########################################"
            rm -f $of
            break
        fi
    done
else
	mdname=${mdname%.*}$SUFF.$MDEXT
    f=`basename "$progname"`
	ext=${f##*.}
	ext=`toLower $ext`
	if regexMatch "${mdname}" "^_.*"; then
		of=${dirname}/${ext}${mdname}
	else
		of=${dirname}/${ext}_${mdname}
	fi
    if [ $VERB -eq 1 ];     then
        echo "processing $ext file $progname => MD file $of ..."
    fi
    if [ "$ext" = "$SASEXT" ];     then
		# echo "awk 'NF==0&&s==0{NR=0}NR==1&&\$1==\"/**\"{s=1}s==1{print \$0}\$NF==\"*/\"{s=2}' $progname | awk '!/^ *\/\*\*/ { print; }' - | \*\/awk '!/^ *\*\// { print; }' - > $mdname"
		awk 'NF==0&&s==0{NR=0}NR==1&&$1=="/**"{s=1}s==1{print $0}$NF=="*/"{s=2}' $progname | awk '!/^ *\/\*\*/ { print; }' - | awk '!/^ *\*\// { print; }' - > $of
    elif [ "$ext" = "$REXT" ];    then
		awk 'NF==0&&s==0{NR=0}NR==1&&$1=="#STARTDOC"{s=1}s==1{print $0}$NF=="#ENDDOC"{s=2}' $progname | awk '!/^ *\#STARTDOC/ { print; }' - | awk '!/^ *\#ENDDOC/ { print substr($0,2); }' - > $of
    fi
	if [ ! -s $of ]; then
		rm -f  $of
    elif [ $TEST -eq 1 ];    then
		echo
        echo "Result of automatic Markdown extraction from test input $progname"
        echo "##########################################"
        cat $of
        echo "##########################################"
        rm -f $of
    fi
fi
