package Dwarf::Util::Xslate;
use Dwarf::Pragma;
use parent 'Exporter';
use HTML::FillInForm::Lite qw//;
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

sub fillinform {
	return html_builder(\&HTML::FillInForm::Lite::fillinform);
}

1;
