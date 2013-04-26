use strict;
use warnings;
use lib qw(lib);
use utf8;

use constant TEST_COUNT => 4;

use Test::More tests => TEST_COUNT;

use AnyEvent;
use AnyEvent::Mac::Pasteboard ();
use Time::HiRes;
use Encode;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $cv = AE::cv;

my @dictionary = (qw(FINE ☀ ☁ CLOUD RAIN ☂ ☃ ☆ ★ ♬ ♪ ♫));

diag("This test rewrite your current pasteboard. And do not edit pasteboard on running this test.");

my $onchange_call_count = 0;
my $previous_content = '';
my $paste_tick = AnyEvent::Mac::Pasteboard->new(
    multibyte => 1,
    interval  => 2,
    on_change => sub {
        $onchange_call_count++;
        my $current_content = shift;
        isnt($current_content, $previous_content, "Catch changing pasteboard status");
        $cv->send() if $onchange_call_count == TEST_COUNT;
        $previous_content = $current_content;
    },
    on_unchange => sub {
        my $current_content = shift;
        fail("changing test is not ok. prev=$previous_content cur=$current_content");
        $cv->send("Error");
    },
);

my $dictionary_idx = 0;
my $system_pbcopy_cb = sub {
    my $word = encode('utf-8', $dictionary[ $dictionary_idx++ % @dictionary ]);
    system(qq{bash -c 'echo "$word" | pbcopy'});
};
$system_pbcopy_cb->(); # initialize at first.

sleep 1;

my $pbpaste_system_tick = AE::timer 0, 0.3, $system_pbcopy_cb;

my $error = $cv->recv();

if ( $error ) {
    failed($error);
}

# cleanup pasteboard
system(qq{bash -c 'echo -n "" | pbcopy'});
