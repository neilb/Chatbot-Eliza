use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Chatbot::Eliza2',
    AUTHOR           => q{Lnation <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Chatbot/Eliza2.pm',
    ABSTRACT_FROM    => 'lib/Chatbot/Eliza2.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.24,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Array::Utils' => 0.5,
        'Ref::Util' => 0.0020,
    },
    PREREQ_PM => {
        'Moo'              => 1.0010001,
        'Ref::Util'        => 0.0020,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Chatbot-Eliza2-*' },
);
