package Dwarf::Plugin::Template;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Template;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, render => sub {
		my ($self, $template, $vars, $options) = @_;
		$options ||= {};

		$self->call_trigger(BEFORE_RENDER => $self->handler, $self, $vars);

		my $tt = Template->new($options);
		$tt->process($template, $vars, \my $out) or die $tt->error;

		$self->call_trigger(AFTER_RENDER => $self->handler, $self, \$out);

		return $out;
	});
}

1;
