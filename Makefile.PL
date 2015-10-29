use strict;
use warnings;

use ExtUtils::MakeMaker;

my $readme = 'podselect lib/WebService/Aria2/RPC.pod > README.pod';

WriteMakefile 
(

  NAME          => "WebService::Aria2::RPC",
  AUTHOR        => "Danny Warren <danny\@dannywarren.com>",
  LICENSE       => "perl",
  VERSION_FROM  => "lib/WebService/Aria2/RPC.pm",
  ABSTRACT_FROM => "lib/WebService/Aria2/RPC.pod",

  PREREQ_PM =>
  {
    'JSON::RPC' => "1.06",
    'Moose'     => "2.1603",
  },

  TEST_REQUIRES => 
  {
    'Test::More' => "0.98",
  },

  META_MERGE =>
  {
    resources => 
    {
      homepage   => "https://github.com/dannywarren/WebService-Aria2-RPC",
      repository => "https://github.com/dannywarren/WebService-Aria2-RPC",
    },
  },

  dist => 
  {
    PREOP => $readme,
  },

);
