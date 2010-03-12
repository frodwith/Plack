package Plack::Middleware::StackTrace;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Devel::StackTrace;
use Devel::StackTrace::AsHTML;
use Try::Tiny;

our $StackTraceClass = "Devel::StackTrace";

# Optional since it needs PadWalker
if (try { require Devel::StackTrace::WithLexicals; 1 }) {
    $StackTraceClass = "Devel::StackTrace::WithLexicals";
}

sub call {
    my($self, $env) = @_;

    my $trace;
    local $SIG{__DIE__} = sub {
        $trace = $StackTraceClass->new;
        die @_;
    };

    my $res = try {
        $self->app->($env);
    }
    catch {
        my $accept = $env->{HTTP_ACCEPT};
        my $use_html = $accept =~ qr(\*/\*)
            || $accept =~ qr(text/\*)
            || $accept =~ qr(html);

        my $type = $use_html ? 'text/html' : 'text/plain';
        my $body = $use_html ? $trace->as_html : $trace->as_string;
        [ 500, ['Content-Type' => "$type; charset=utf-8"], [ $body ]];
    };

    # break $trace here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef $trace;

    return $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::StackTrace - Displays stack trace when your app dies

=head1 SYNOPSIS

  enable "Plack::Middleware::StackTrace";

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen.

This middleware is enabled by default when you run L<plackup> in the
default development mode.

=head1 CONFIGURATION

No configuration option is available.

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Devel::StackTrace::AsHTML> L<Plack::Middleware>

=cut

