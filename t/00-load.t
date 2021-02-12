use strict;
use warnings;
use Test::More;
BEGIN {
   use_ok($_) for qw<
      Command::Template
      Command::Template::Instance
      Command::Template::RunRecord
      Command::Template::Runner
   >;
}
done_testing()
