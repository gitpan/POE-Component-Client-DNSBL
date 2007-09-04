use strict;
use Test::More tests => 3;
use POE qw(Component::Client::DNSBL);
use Data::Dumper;

my @addresses = qw(100.0.0.1);

my $dnsbl = POE::Component::Client::DNSBL->spawn();

isa_ok( $dnsbl, 'POE::Component::Client::DNSBL' );

POE::Session->create(
        package_states => [
            'main' => [ qw(_start _stop _response) ],
        ],
        heap => {
                  addresses => \@addresses,
                  dnsbl => $dnsbl
        },
);

$poe_kernel->run();
exit 0;

sub _start {
   my ($kernel,$heap) = @_[KERNEL,HEAP];
   $heap->{dnsbl}->lookup(
      event => '_response',
      address => $_,
   ) for @{ $heap->{addresses} };
   return;
}

sub _stop {
   my ($kernel,$heap) = @_[KERNEL,HEAP];
   pass("PoCo let the refcount go");
   $kernel->call( $heap->{dnsbl}->session_id(), 'shutdown' );
   return;
}

sub _response {
   my ($kernel,$heap,$record) = @_[KERNEL,HEAP,ARG0];
   ok( $record->{response} eq 'NXDOMAIN', 'NXDOMAIN' ) or diag("Was expecting 'NXDOMAIN', got " . $record->{response} . "\n");
   return;
}
