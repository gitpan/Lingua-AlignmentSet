#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: Evaluates a submitted Alignment Set against an answer Alignment Set
#
#-----------------------------------------------------------------------
#
#  Copyright 2004 by Patrik Lambert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
########################################################################

use strict;
use Getopt::Long;
use Pod::Usage;
use Lingua::AlignmentSet;
#Debug:
use Dumpvalue;
my $dumper = new Dumpvalue; 

my $TRUE = 1;
my $FALSE = 0;
my $INFINITY = 9999999999;
my $TINY = 1 - $INFINITY / ($INFINITY + 1);

#PARSING COMMAND-LINE ARGUMENTS
my %opts=();
# optional arguments defaults
$opts{sub_format}="NAACL";
$opts{ans_format}="NAACL";
$opts{sub_range}="1-";
$opts{ans_range}="1-";
$opts{alignMode}="as-is";
$opts{wheighted}=0;
# parse command line
GetOptions(\%opts,'man','help|?','weighted|w!','format=s','submission|sub=s','answer|ans=s','sub_format=s','sub_range=s','ans_format=s','ans_range=s','alignMode=s') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"answer"}) && exists($opts{"submission"})) ){   #required arguments
    pod2usage(-msg=>"Required arguments missing",-verbose=>0);
}
#END PARSING COMMAND-LINE ARGUMENTS

#load submission Alignment Set
my $submission = Lingua::AlignmentSet->new([[$opts{submission},$opts{sub_format},$opts{sub_range}]]);
#load answer Alignment Set
my $answer = Lingua::AlignmentSet->new([[$opts{answer},$opts{ans_format},$opts{ans_range}]]);
#call library function
my @evaluation = ();
push @evaluation, [$submission->evaluate($answer,$opts{alignMode},$opts{weighted})," "];
Lingua::AlignmentEval::compare(\@evaluation,"Alignment evaluation",\*STDOUT,"text");

#my $evaluation = $submission->evaluate($answer,$opts{alignMode},$opts{weighted});
#Lingua::AlignmentEval::display($evaluation,\*STDOUT,"text");


__END__

=head1 NAME

evaluate_alSet.pl - Evaluates a submitted Alignment Set against an answer Alignment Set

=head1 SYNOPSIS

perl evaluate_alSet.pl [options] required_arguments

Required arguments:

	--sub, --submission FILENAME    Submission source-to-target links file
	--sub_format BLINKER|GIZA|NAACL    Submission file format (required if not NAACL)
	--ans, --answer FILENAME    Answer source-to-target links file
	--ans_format BLINKER|GIZA|NAACL    Answer file format (required if not NAACL)

Options:

	--sub_range BEGIN-END    Submission Alignment Set range
	--ans_range BEGIN-END    Answer Alignment Set range
	--alignMode as-is|null-align|no-null-align    Alignment mode
	-w,--wheighted    Activates the weighting of the links
	--help|?    Prints the help and exits
	--man    Prints the manual and exits

=head1 ARGUMENTS

=over 8

=item B<--sub,--submission FILENAME>

Submission source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--sub_format BLINKER|GIZA|NAACL>

Submission Alignment Set format (required if different from default, NAACL).

=item B<--ans,--answer FILENAME>

Answer source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--ans_format BLINKER|GIZA|NAACL>

Answer Alignment Set format (required if different from default, NAACL)

=head1 OPTIONS

=item B<--sub_range BEGIN-END>

Range of the submission source-to-target file (BEGIN and END are the sentence pair numbers)

=item B<--ans_range BEGIN-END>

Range of the answer source-to-target file (BEGIN and END are the sentence pair numbers)

=item B<--alignMode as-is|null-align|no-null-align>

Take alignment "as-is" or force NULL alignment or NO-NULL alignment (see AlignmentSet.pm documentation).
The default here is 'no-null-align' (as opposed to the other scripts, where the default is 'as-is').
Use "as-is" only if you are sure answer and submission files are in the same alignment mode.

=item B<-w, --weighted>

Weights the links according to the number of links of each word in the sentence pair.

=item B<--help, --?>

Prints a help message and exits.

=item B<--man>

Prints a help message and exits.

=head1 DESCRIPTION

Evaluates a submitted Alignment Set against an answer Alignment Set. 
The command-line utility has been made for convenience. For full details, see the documentation of the AlignmentSet.pm module.
If you want to compare alignment results in a table, the library function has more features so the best is to call it from a perl script.

=head1 EXAMPLES

perl evaluate_alSet.pl --sub test-giza.spa2eng.giza --sub_format=GIZA --ans test-answer.spa2eng.naacl

Gives the following output:

    Alignment evaluation   
----------------------------------
 Experiment                Ps	  Rs	  Fs	  Pp	  Rp	  Fp	 AER  

                         93.95	67.51	78.57	93.95	67.51	78.57	21.43

=head1 AUTHOR

Patrik Lambert <lambert@talp.upc.es>
Some code from Rada Mihalcea's wa_eval_align.pl (http:://www.cs.unt.edu/rada/wpt/code/) has been integrated in the library function.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
