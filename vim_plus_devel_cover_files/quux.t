#!/usr/bin/perl

#===============================================================================
#     REVISION:  $Id$
#  DESCRIPTION:  Test for Quux module
#       AUTHOR:  Alexander Simakov, <xdr [dot] box [at] Gmail>
#                http://alexander-simakov.blogspot.com/
#      LICENSE:  Public domain
#===============================================================================

use strict;
use warnings;

our $VERSION = qw($Revision$) [1];

use Readonly;
use English qw( -no_match_vars );

use FindBin qw($Bin);
use lib "$Bin";

use Quux;

use Test::More tests => 3;
use Test::Exception;

Readonly my $TEST_FILE    => '/dev/null';
Readonly my $NO_SUCH_FILE => '/no/such/file';

sub run_tests {
    my $quux = Quux->new();

    my $result;

    $result = $quux->foo( $TEST_FILE, 1, 1 );
    ok( $result, 'Check var1=1 and var2=1' );

    $result = $quux->foo( $TEST_FILE, 0, 0, 'some_flag' );
    ok( $result, 'Check var1=0 and var2=0' );

    # We haven't checked var1=1,var2=0 and var1=0,var2=1 but
    # branch-coverage for method foo() will be 100%

    dies_ok { $quux->foo( $NO_SUCH_FILE, 'no_matter', 'no_matter' ) }
    "Try to open non-existent file '$NO_SUCH_FILE'";

    return;
}

run_tests();
