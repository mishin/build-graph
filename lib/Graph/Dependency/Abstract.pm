package Graph::Dependency::Abstract;
use Any::Moose;
use Carp ();
use Graph::Dependency::Abstract::Node;
use Graph::Dependency::Abstract::Action;

has nodes => (
	isa => 'HashRef[Graph::Dependency::Abstract::Node]',
	traits => ['Hash'],
	init_arg => undef,
	default => sub { {} },
	handles => {
		get_node => 'get',
		'_set_node' => 'set',
	},
);

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak('File already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Abstract::Node->new(%args, graph => $self, phony => 0);
	$self->_set_node($name, $node);
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak('Phony already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Abstract::Node->new(%args, graph => $self, phony => 1);
	$self->_set_node($name, $node);
	return;
}

has actions => (
	isa => 'HashRef[Graph::Dependency::Abstract::Action]',
	traits => ['Hash'],
	init_arg => undef,
	default => sub { {} },
	handles => {
		all_actions => 'keys',
		get_action => 'get',
		add_action => 'set',
	},
);

sub compile {
	my ($self, $startpoint) = @_;
	my $compiler = Graph::Dependency::Compiling->new;
	$self->get_node($startpoint)->compile($startpoint, $compiler);
	return Graph::Dependency::OP->new(nodes => { $compiler->all_compiled });
}

sub _sort_nodes {
	my ($self, $startpoint) = @_;
	my @ret;
	$self->_node_sorter($startpoint, \@ret, {});
	return @ret;
}

sub _node_sorter {
	my ($self, $current, $list, $seen, %loop) = @_;
	return if $seen->{$current}++;
	Carp::croak("$current has a circular dependency, aborting!\n") if $loop{$current};
	my $node = $self->get_node($current) or Carp::croak("Node $current doesn't exist");
	$self->_node_sorter($_, $list, $seen, %loop, $current => 1) for $node->all_dependencies;
	push @{$list}, $current;
	return;
}

my $newer = sub {
	my ($destination, $source) = @_;
	return 1 if not -e $source;
	return 0 if -d $source;
	return -M $destination > -M $source;
};

sub run {
	my ($self, $startpoint) = @_;
	my @nodes = $self->_sort_nodes($startpoint);
	die join ', ', @nodes if $nodes[0] ne '_testing';
	my %seen_phony;
	for my $node_name (@nodes) {
		my $node = $self->get_node($node_name);
		if ($node->phony) {
			next if $seen_phony{$node_name}++;
		}
		else {
			my @files = grep { !$self->get_node($_)->phony } $node->all_dependencies;
			next if -e $node_name and not grep { $newer->($node_name, $_) } @files;
		}
		my $action = $self->get_action($node->action) or Carp::croak("Action ${ \$node->action } doesn't exist");
		$action->execute($node_name, $node);
	}
}

1;

__END__

=method get_node

=method add_file

=method add_phony

=method all_actions

=method get_action

=method add_action

=method compile

