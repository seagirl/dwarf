#!/bin/sh
PATH=/Users/yoshizu/perl5/perlbrew/perls/perl-5.14.2/bin
PATH=$PATH:/bin:/usr/bin:/usr/local/bin
if [ "$USE_SPEEDY" != "" ]; then
    exec speedy -x "$0" "${1+$@}" -- -t60 -r200 -g$USE_SPEEDY -M60
else
    exec perl -x "$0" "${1+$@}"
fi
#!perl
use strict;
use warnings;
use FindBin;
use lib ($FindBin::Bin . '/../../app/lib');
use Plack::Loader;
my $app = Plack::Util::load_psgi($FindBin::Bin . '/../../app/app.psgi');
Plack::Loader->auto->run($app);


