#!/usr/bin/perl 
# @brief:    Automatic string replacement
#
#    replace.pl <filename> <key1> <key2>
#
# @note:
# Some DOS-related issue when running this command
# In order to deal with embedded control-M's in the file (source of the issue), it
# may be necessary to run dos2unix.
#
# @date:     15/06/2015
# @credit:     <mailto:jacopo.grazzini@ec.europa.eu>

$Infile= @ARGV[0];		# file to be modified
$Key1= @ARGV[1];		# Keyword to be replaced
$Key2= @ARGV[2];		# Replacement keyword

if ($#ARGV < 0) {
    print STDOUT "Usage: replace.pl filename key1 key2 \n\t replaces occurences of key1 by key2 in the file filename\n";
} else {
    open(IN,$Infile) || die "Cannot find file $Infile: $!\n"; 
    while(<IN>) {
	s/$Key1/$Key2/og;
	$Result .= sprintf("%s", $_);
    }
    close(IN);
    
    open(OUT,">$Infile");
    print OUT $Result;
    close(OUT);
}


