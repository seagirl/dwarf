package Dwarf::Util::Xslate;
use Dwarf::Pragma;
use parent 'Exporter';
use Text::Xslate qw/html_builder html_escape/;

our @EXPORT_OK = qw/reproduce_line_feed/;

sub reproduce_line_feed {
	return html_builder {
		my $text = shift // '';
		my $escaped = html_escape($text);
		$escaped =~ s|\n|<br />|g;
		return $escaped;
	};
}

1;
