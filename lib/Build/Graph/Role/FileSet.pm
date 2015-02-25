package Build::Graph::Role::FileSet;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		files        => {},
		substs       => [],
	}, $class;
}

sub files {
	my $self = shift;
	return keys %{ $self->{files} };
}

sub on_file {
	my ($self, $sub) = @_;
	push @{ $self->{substs} }, $sub;
	for my $file (keys %{ $self->{files} }) {
		$sub->process($file);
	}
	return;
}

1;

# ABSTRACT: A role shared by sets of files (e.g. wildcards and substitutions)
