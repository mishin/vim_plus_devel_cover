package Quux;

#===============================================================================
#     REVISION:  $Id$
#  DESCRIPTION:  Test module
#       AUTHOR:  Alexander Simakov, <xdr [dot] box [at] Gmail>
#                http://alexander-simakov.blogspot.com/
#      LICENSE:  Public domain
#===============================================================================

use strict;
use warnings;

our $VERSION = qw($Revision$) [1];

use Readonly;
use English qw( -no_match_vars );
use Carp;

## no critic (RequireCarping)

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub foo {
    my $self      = shift;
    my $file_name = shift;
    my $var1      = shift;
    my $var2      = shift;
    my $flag      = shift || $ENV{'FLAG'} || 1;

    open my $fh, '>>', $file_name
        or die "Cannot open file '$file_name': $OS_ERROR";

    if ($var1) {
        print {$fh} $var1;
    }
    else {
        warn 'var1 is not saved!';
    }

    if ($var2) {
        print {$fh} $var2;
    }
    else {
        warn 'var2 is not saved!';
    }

    # This should not happen in practice!
    close $fh or die "Cannot close file '$file_name': $OS_ERROR";

    return 1;
}

sub not_tested {
    my $self = shift;

    return;
}

1;
