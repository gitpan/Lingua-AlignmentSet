use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::AlignmentSet',
    'VERSION_FROM'	=> 'AlignmentSet.pm', # finds $VERSION
    'PREREQ_PM'		=> {Pod::Usage =>1.14, Algorithm::MinMax => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AlignmentSet.pm', # retrieve abstract from module
       AUTHOR     => 'Patrik Lambert <lambert@lsi.upc.es>') : ()),
);
