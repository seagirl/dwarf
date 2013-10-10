#!/bin/sh
PATH=/Users/yoshizu/.plenv/shims
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
use lib ($FindBin::Bin . '/../../app/local/lib/perl5', $FindBin::Bin . '/../../app/lib');
use Plack::Loader;
my $app = Plack::Util::load_psgi($FindBin::Bin . '/../../app/app.psgi');
Plack::Loader->auto->run($app);


