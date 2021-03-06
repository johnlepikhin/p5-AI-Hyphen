use 5.024001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AI::Hyphen',
    VERSION_FROM      => 'lib/AI/Hyphen.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'AI::NeuralNet::Simple' => 0.11}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/AI/Hyphen.pm', # retrieve abstract from module
    AUTHOR            => 'Evgenii Lepikhin <johnlepikhin@gmail.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
