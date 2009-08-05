package Catalyst::Plugin::AccessLog;

use namespace::autoclean;
use Moose::Role;

after 'setup_finalize' => sub { # Init ourselves
  my $c = shift;
  my $config = $c->config->{'Plugin::AccessLog'} ||= {};
  %$config = (
    format => '%v %h %l %u %t "%r" %s %b "%{Referer}i" "%{User-Agent}i"',
    formatter_class => 'Catalyst::Plugin::AccessLog::Formatter',
    time_format => '%Y-%m-%dT%H:%M:%S', # ISO8601-compatible
    time_zone => 'local',
    enabled => 1,
    hostname_lookups => 0,
    %$config
  );
  Catalyst::Utils::ensure_class_loaded( $config->{formatter_class} );
};

after 'finalize' => sub {
  my $c = shift;
  my $config = $c->config->{'Plugin::AccessLog'};

  my $formatter = $config->{formatter_class}->new();
  my $line = $formatter->format_line($c);
  $c->log->info($line);
};

no Moose::Role;

1;

=head1 SYNOPSIS

Requires Catalyst 5.8 or above.

    # In lib/MyApp.pm context
    use Catalyst (qw<
        ConfigLoader
        -Stats=1
        ... other plugins here ...
    >);
    with 'CatalystX::Logger';

If you want to customize the log format globally throughout your application:

    # In lib/MyApp/Controller/Root.pm
    # or anywhere that runs on every request and with access to $c
    sub auto :Private {
        my ($self, $c) = @_;
        $c->log_format(' ... your format string here ... ');
    }

If you then wanted to change the logging format in a specific controller:

    # In lib/MyApp/Controller/Product.pm
    sub default :Path {
        my ($self, $c) = @_;
        $c->log_format(' ... another format just for this action ');
    }

=head1 DESCRIPTION

This isn't "debug" logging.  This is more like Apache access logs for the built
in Catalyst server.

The default format is the "Common Log Format".

http://en.wikipedia.org/wiki/Common_Log_Format

=cut