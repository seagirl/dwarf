package Dwarf::Plugin::HTML::Template;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use HTML::Template;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, render => sub {
		my ($self, $template, $vars, $options) = @_;
		$vars    ||= {};
		$options ||= {};

		$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $vars);
	
		my $ht = HTML::Template->new(
			filename => $template,
			%{ $options }
		);
		$ht->param(%$vars);
	    my $out = $ht->output;

	    $self->call_trigger(AFTER_RENDER => $self->handler, $self, \$out);

		return $out;
	});
}

1;
