package AnyEvent::Mac::Pasteboard;

use strict;
use warnings;
use 5.008;
our $VERSION = '0.01';

use AnyEvent;
use Mac::Pasteboard ();
use Scalar::Util qw(looks_like_number);
use Time::HiRes;

our $DEFAULT_INTERVAL = 5;

#my $NATURAL_NUMBER_RE = qr/^[1-9][0-9]*$/;

sub new {
    my $class = shift;
    my %args  = @_;

    my $on_change   = delete $args{on_change}   || sub { };
    my $on_unchange = delete $args{on_unchange} || undef;
    my $on_error    = delete $args{on_error}    || sub { die @_; };
    my $interval    = delete $args{interval}    || $DEFAULT_INTERVAL;
    my $multibyte   = delete $args{multibyte}   || 1; # 1 is TRUE

    my $prev_content = my $current_content = Mac::Pasteboard::pbpaste();

    if (   !defined $interval
#        or (ref $interval eq 'ARRAY' && @$interval != grep { /$NATURAL_NUMBER_RE/ } @$interval )
        or (ref $interval eq 'ARRAY' && @$interval != grep { looks_like_number($_) && $_ > 0 } @$interval )
#        or (!ref $interval && $interval !~ /$NATURAL_NUMBER_RE/ ) ) {
        or (!ref $interval && !looks_like_number($interval) ) ) {
        $on_error->(qq(argument "interval" is natural number or arrayref contained its.));
    }

    my @interval = ref $interval eq 'ARRAY' ? @$interval : ($interval);
    my $interval_idx = 0;

    my $self = bless {}, $class;

    $self->{multibyte} = $multibyte;

    my $on_time; $on_time = sub {
        $current_content = $self->{content} = Mac::Pasteboard::pbpaste();
        if ( $prev_content ne $current_content ) {
            my $content = $self->pbpaste();
            $on_change->($content);
            $prev_content = $current_content;
            $interval_idx = 0;
        }
        elsif ( $on_unchange && ref $on_unchange eq 'CODE' ) {
            my $content = $self->pbpaste();
            $on_unchange->($content);
        }
        my $wait_sec = $interval_idx < @interval ? $interval[$interval_idx++] : $interval[-1];
        print "wait_sec=$wait_sec\n";
        $self->{timer} = AE::timer $wait_sec, 0, $on_time;
    };

    $on_time->();

    return $self;
}

sub pbpaste {
    my $self = shift;
    return $self->{multibyte} ? `pbpaste` : $self->{content};
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Mac::Pasteboard - observation and hook pasteboard changing.

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Mac::Pasteboard;
  
  my $cv = AnyEvent->condvar;
  
  my $pb_watcher = AnyEvent::Mac::Pasteboard->new(
    interval => [1, 1, 2, 3, 5],
    on_change => sub {
      my $pb_content = shift;
      print "change pasteboard content: $pb_content\n";
    },
    on_unchange => sub {
      # ...some code...
    },
    on_error => sub {
       my $error = shift;
       print "Error occured.";
       die $error;
    },
  );
  
  $cv->recv;

=head1 DESCRIPTIONS

=head1 AUTHOR

=head1 COPYRIGHT AND LICENSES

=cut
