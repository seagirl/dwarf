package Dwarf::Plugin::HTML::Template;
use strict;
use warnings;
use Dwarf::Util qw/add_method/;
use HTML::Template;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, render => sub {
		my ($self, $template, $vars, $options) = @_;
		$vars    ||= {};
		$options ||= {};
	
		my $ht = HTML::Template->new(
			filename => $template,
			%{ $options }
		);
		$ht->param(%$vars);
	    my $out = $ht->output;

		return $out;
	});
}

1;
