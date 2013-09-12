# Copyright (c) 2012  S2 Factory, Inc.  All rights reserved.
#
# $Id: Kanji.pm 4635 2012-03-01 05:57:38Z kuriyama $

package S2Factory::Validator::Kanji;
use FormValidator::Lite::Constraint;
use Encode;

# CP932 ではなく、Shift_JIS の範囲に入っているかどうかをチェックする。
# ただし入力は UTF-8。
rule 'Shift_JIS' => sub {
	my ($t) = ($_);
	my $out = decode('shift_jis', encode('shift_jis', $t));
	return $out eq $t ? 1 : 0;
};

# Local Variables:                    #
# tab-width: 4                        #
# cperl-indent-level: 4               #
# cperl-label-offset: -4              #
# cperl-continued-statement-offset: 4 #
# End:                                #

1;
