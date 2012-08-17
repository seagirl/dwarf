package Dwarf::Plugin::Template;
use strict;
use warnings;
use Dwarf::Util qw/add_method/;
use Template;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, render => sub {
		my ($self, $template, $vars, $options) = @_;
		$options ||= {};

		my $tt = Template->new($options);
		$tt->process($template, $vars, \my $out) or die $tt->error;

		return $out;
	});
}

1;
