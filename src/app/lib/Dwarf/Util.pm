package Dwarf::Util;
use Dwarf::Pragma;
use Encode ();
use File::Basename ();
use File::Path ();

our @EXPORT_OK = qw/
	add_method
	load_class
	capitalize
	shuffle_array
	filename
	write_file
	get_suffix
	encode_utf8
	decode_utf8
	safe_join
	hash_merge
/;

use base qw(Exporter);

# メソッドの追加
sub add_method {
	my ($klass, $method, $code) = @_;
	$klass = ref $klass || $klass;
	no strict 'refs';
	no warnings 'redefine';
	*{"${klass}::${method}"} = $code;
}

# クラスの読み込み
sub load_class {
	my($class, $prefix) = @_;

	if ($prefix) {
		unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
			$class = "$prefix\::$class";
		}
	}

	my $file = $class;
	$file =~ s!::!/!g;
	require "$file.pm";

	return $class;
}

# キャピタライズ
sub capitalize {
	my $value = shift;
	$value =~ s/-/_/g;
	my @flagments = split '_', $value;
	return join '', map { ucfirst $_ } @flagments;
}

# 配列をシャッフル
sub shuffle_array {
	my @a = @_;
	return @a if @a == 0;

	for (my $i = @a - 1; $i >= 0; $i--) {
		my $j = int(rand($i + 1));
		next if $i == $j;
		@a[$i, $j] = @a[$j, $i];
	}

	return (@a);
}

# ある Perl モジュールのファイル名を返す
sub filename {
	my $invocant = shift;
	my $class = ref $invocant || $invocant;
	$class =~ s/::/\//g;
	$class .= '.pm';
	return exists $INC{$class} ? $INC{$class} : $class;
}

# あるパスにコンテンツを書き出す（自動的に mkpath してくれる）
sub write_file {
	my ($path, $content) = @_;

	my $dir = File::Basename::dirname($path);

	unless (-d $dir) {
		File::Path::mkpath $dir or die "Couldn't make $dir"
	}

	open my $fh, '>', $path or die "Couldn't open $path";
	print $fh $content;
	close $fh;
}

# ファイルの拡張子を取得
sub get_suffix {
	my $filename = shift;
	my $suffix;
	if ($filename =~ /.+\.(\S+?)$/) {
		$suffix = lc $1;
	}
	return $suffix;
}

# Encode-2.12 以下対策
sub encode_utf8 {
	my $utf8 = shift;
	return unless defined $utf8;
	my $bytes = Encode::is_utf8($utf8) ? Encode::encode_utf8($utf8) : $utf8;
	return $bytes;
}

# Encode-2.12 以下対策
sub decode_utf8 {
	my $bytes = shift;
	return unless defined $bytes;
	my $utf8 = Encode::is_utf8($bytes) ? $bytes : Encode::decode_utf8($bytes);
	return $utf8;
}

# undef が含まれるかも知れない変数の join
sub safe_join {
	my $a = shift;
	my @b = map { defined $_ ? $_ : '' } @_;
	join $a, @b;
}

# 二つのハッシュリファレンスを簡易マージ
sub hash_merge {
	my ($a, $b) = @_;
	return $b unless defined $a;
	return {} if ref $a ne 'HASH' or ref $b ne 'HASH';

	for my $k (%{ $b }) {
		next unless defined $k;
		if (defined $b->{ $k }) {
			$a->{ $k } = $b->{ $k };
		}
	}

	return $a;
}

1;
