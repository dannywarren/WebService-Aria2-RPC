use strict;
use warnings;

use ExtUtils::MakeMaker;

my $readme = 'podselect $(VERSION_FROM) > README.pod';

WriteMakefile 
(

  NAME          => "WebService::Aria2",
  AUTHOR        => "Danny Warren <danny\@dannywarren.com>",
  LICENSE       => "perl",
  VERSION_FROM  => "lib/WebService/Aria2.pm",
  ABSTRACT_FROM => "lib/WebService/Aria2.pod",

  PREREQ_PM =>
  {
    'JSON::RPC'  => "1.06",
  },

  TEST_REQUIRES => 
  {
    'Test::More' => "0.98",
  },

  META_MERGE =>
  {
    resources => 
    {
      homepage   => "https://github.com/dannywarren/WebService-Aria2",
      repository => "https://github.com/dannywarren/WebService-Aria2",
    },
  },

  dist => 
  {
    PREOP => $readme,
  },

);
