package Build::Graph::Wildcard;

use strict;
use warnings;

use parent 'Build::Graph::Role::Entries';

use Carp ();

use File::Spec ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{pattern} = $args{pattern} || Carp::croak('No pattern is given');
	$self->{pattern} = qr/$self->{pattern}/ if not ref $self->{pattern};
	$self->{dir}     = ref($args{dir}) ? $args{dir} : [ File::Spec->splitdir($args{dir}) ];
	return $self;
}

sub dir {
	my $self = shift;
	return @{ $self->{dir} };
}

sub _dir_matches {
	my ($self, $name) = @_;
	my (undef, $dirs, $file) = File::Spec->splitpath($name);
	my @dirs  = File::Spec->splitdir($dirs);
	my @match = $self->dir;
	return if @dirs < @match;
	return File::Spec->catdir(@dirs[ 0..$#match ]) eq File::Spec->catdir(@match);
}

sub _match_filename {
	my ($filename, $pattern) = @_;
	require File::Basename;
	return File::Basename::basename($filename) =~ $pattern;
}

sub match {
	my ($self, $filename) = @_;
	if ($self->_dir_matches($filename) && _match_filename($filename, $self->{pattern})) {
		push @{ $self->{entries} }, $filename;
		$_->process($filename) for @{ $self->{substs} };
	}
	return;
}

sub to_hashref {
	my $self = shift;
	my $ret = $self->SUPER::to_hashref;
	$ret->{pattern} = "$self->{pattern}";
	$ret->{dir}     = $self->{dir};
	return $ret;
}

1;

#ABSTRACT: A Build::Graph pattern

=begin Pod::Coverage

match

=end Pod::Coverage
