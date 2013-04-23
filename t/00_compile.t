# -*- perl -*-

use strict;
use warnings;
use lib qw(lib);

# 'tests => late_test_to_print'
use Test::More;

BEGIN {
    use_ok('AnyEvent::Mac::Pasteboard');
}

done_testing();
