package App::Constant;
use Dwarf::Pragma;

our(@ISA, @EXPORT);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw|
	TRUE FALSE HTTPS_PORT SUCCESS FAILURE
	SES_KEY SES_TABLE|;

use constant {
	TRUE                  => 1,
	FALSE                 => 0,
	SUCCESS               => 0,
	FAILURE               => 1,
	HTTPS_PORT            => 443,
	SES_KEY               => '<APP_NAME>_sid',
	SES_TABLE             => 'sessions',
};

1;

