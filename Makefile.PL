use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'CGI::WeT',
               VERSION_FROM => 'lib/CGI/WeT.pm',
               dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
             );


