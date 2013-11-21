package Build::Graph::CommandSet;
use Moo;

use Build::Graph::Group;

has _groups => (
	is       => 'ro',
	init_arg => 'groups',
	default  => sub { {} },
);

has loader => (
	is => 'ro',
	default => sub {
		require Build::Graph::ClassLoader;
		return Build::Graph::ClassLoader->new;
	}
);

sub get {
	my ($self, $key) = @_;
	my ($groupname, $command) = split m{/}, $key, 2;
	my $group = $self->_groups->{$groupname};
	return $group->get($command) if $group;
	return;
}

sub add {
	my ($self, $name, %args) = @_;
	$args{elements} = delete $args{commands};
	my $command = Build::Graph::Group->new(%args);
	$self->_groups->{ $name } = $command;
	return;
}

sub include {
	my ($self, $provider) = @_;
	$self->loader->load($provider)->configure_commands($self);
	return;
}

sub all_for_group {
	my ($self, $groupname) = @_;
	return $self->_groups->{ $groupname }->all;
}

1;

#ABSTRACT: The set of commands used in a build graph

