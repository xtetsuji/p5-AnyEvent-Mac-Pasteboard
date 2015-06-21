use strict;
use warnings;
use lib qw(lib);
use utf8;

use constant TEST_COUNT => 1;

use Test::More tests => TEST_COUNT;

use AnyEvent;
use AnyEvent::Mac::Pasteboard ();
use Encode;
use File::Temp;
use Time::HiRes;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# This test use `printf` rather than `echo`, because echo has many
# difference in each other system implement.

my $cv = AE::cv;

diag( "AnyEvent::Mac::Pasteboard is " . $INC{"AnyEvent/Mac/Pasteboard.pm"} );

diag("This test rewrite your current pasteboard. And do not edit pasteboard on running this test.");

### stash pasteboard content.
my $tmp_file = File::Temp->new( SUFFIX => '.pb' );
my $tmp_filename = $tmp_file->filename;
print {$tmp_file} `/usr/bin/pbpaste`;

my $content = encode('utf-8', "multiple line\nsecond line\nthird line");
system(qq{printf "DIFFERENT CONTENT" | pbcopy});

my $paste_tick = AnyEvent::Mac::Pasteboard->new(
    interval  => 1,
    multibyte => 1,
    on_change => sub {
        my $current_content = shift;
        diag(qq/current_content="$current_content" content="$content"/);
        if ( $current_content eq $content ) {
            pass("getting multiline correctly");
            $cv->send();
        }
    },
);
my $rewrite_timer = AE::timer 2, 0, sub {
    system(qq{printf "$content" | pbcopy});
};
my $end_timer = AE::timer 4, 0, sub {
    $cv->send("timeout");
};

my $error = $cv->recv();

if ( $error ) {
    diag("pasteboard is " . `pbpaste`);
    fail($error);
}

### revert pasteboard content.
if ( open my $fh, '<', $tmp_filename ) {
    my $pb_content = do { local $/; <$fh>; };
    close $fh;
    if ( open my $pipe, '|-', 'pbcopy' ) {
        print {$pipe} $pb_content;
        close $pipe;
    }
}
