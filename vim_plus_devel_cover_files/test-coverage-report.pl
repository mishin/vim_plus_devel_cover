#!/usr/bin/perl

#===============================================================================
#     REVISION:  $Id$
#  DESCRIPTION:  Build & display test coverage report
#       AUTHOR:  Alexander Simakov, <xdr [dot] box [at] Gmail>
#                http://alexander-simakov.blogspot.com/
#      LICENSE:  Public domain
#===============================================================================

use strict;
use warnings;

our $VERSION = qw($Revision$) [1];

use Readonly;
use English qw( -no_match_vars );
use Getopt::Long 2.24 qw(:config no_auto_abbrev no_ignore_case);
use Pod::Usage;
use IO::Prompt;
use File::Temp qw(tempdir);
use File::Basename;
use Carp;

#use Smart::Comments;

Readonly my $DEFAULT_PROVE_CMD  => '/usr/bin/prove';
Readonly my $DEFAULT_PROVE_ARGS => q{};

Readonly my $DEFAULT_COVER_CMD => '/usr/bin/cover';
## no critic (RequireInterpolationOfMetachars)
Readonly my $DEFAULT_COVER_ARGS => q{-ignore_re '[.]t$'};
## use critic

Readonly my $DEFAULT_BROWSER_CMD  => q{};
Readonly my $DEFAULT_BROWSER_ARGS => q{};

sub get_options {
    my $options = {
        'prove-cmd'    => $DEFAULT_PROVE_CMD,
        'prove-args'   => $DEFAULT_PROVE_ARGS,
        'cover-cmd'    => $DEFAULT_COVER_CMD,
        'cover-args'   => $DEFAULT_COVER_ARGS,
        'browser-cmd'  => $DEFAULT_BROWSER_CMD,
        'browser-args' => $DEFAULT_BROWSER_ARGS,
    };

    my $options_okay = GetOptions(
        $options,
        'input-file|f=s',      # Input .t or .pm file
        'prove-cmd|p=s',       # Which prove command to use
        'prove-args|P=s',      # prove args
        'cover-cmd|c=s',       # Which cover command
        'cover-args|C=s',      # cover args
        'browser-cmd|b=s',     # Which browser to use
        'browser-args|B=s',    # Browser args
        'output-dir|d=s',      # Output directory
        'help|?',              # Show brief help message
        'man',                 # Show full documentation
    );

    # More meaningful names for pod2usage's -verbose parameter
    Readonly my $SHOW_USAGE_ONLY         => 0;
    Readonly my $SHOW_BRIEF_HELP_MESSAGE => 1;
    Readonly my $SHOW_FULL_MANUAL        => 2;

    # Show appropriate help message
    if ( !$options_okay ) {
        pod2usage( -exitval => 2, -verbose => $SHOW_USAGE_ONLY );
    }

    if ( $options->{'help'} ) {
        pod2usage( -exitval => 0, -verbose => $SHOW_BRIEF_HELP_MESSAGE );
    }

    if ( $options->{'man'} ) {
        pod2usage( -exitval => 0, -verbose => $SHOW_FULL_MANUAL );
    }

    # Check required options
    foreach my $option (qw( input-file browser-cmd prove-cmd cover-cmd )) {
        if ( !$options->{$option} ) {
            pod2usage(
                -message => "Option $option is required",
                -exitval => 2,
                -verbose => $SHOW_USAGE_ONLY,
            );
        }
    }

    ### options: $options
    return $options;
}

sub create_tmp_dir {
    my $output_dir = shift;
    my $input_file = shift;

    my $basename = basename( $input_file, qw(.pm .t) );
    ### basename: $basename

    my $tmp_dir;
    if ($output_dir) {
        $tmp_dir = tempdir(
            "$basename-XXXX",
            DIR     => $output_dir,
            CLEANUP => 0,
        );
    }
    else {
        $tmp_dir = tempdir(
            "$basename-XXXX",
            TMPDIR  => 1,
            CLEANUP => 0,
        );
    }
    ### tmp_dir: $tmp_dir

    return $tmp_dir;
}

sub enable_coverage_report {
    my $output_dir = shift;

    $ENV{'HARNESS_PERL_SWITCHES'} = "-MDevel::Cover=-db,$output_dir";

    return;
}

sub prove {
    my $input_file = shift;
    my $prove_cmd  = shift;
    my $prove_args = shift;

    system "$prove_cmd $input_file $prove_args";

    return if $CHILD_ERROR == 0;
    croak 'Cannot prove the test';
}

sub generate_coverage_report {
    my $output_dir = shift;
    my $cover_cmd  = shift;
    my $cover_args = shift;

    system "$cover_cmd $cover_args $output_dir";

    return if $CHILD_ERROR == 0;
    croak 'Cannot generate coverage report';
}

sub open_browser {
    my $url          = shift;
    my $browser_cmd  = shift;
    my $browser_args = shift;

    system "$browser_cmd $browser_args $url";

    return if $CHILD_ERROR == 0;
    croak 'Cannot open browser';
}

sub cleanup_dir {
    my $dir = shift;

    system "rm -frv '$dir'";

    return;
}

sub confirm_cleanup {
    my $output_dir = shift;

    my $msg
        = "Coverage report is generated in '$output_dir'. "
        . 'Press \'Y\' (default) to cleanup this directory or \'N\' '
        . 'if you want to keep it.';

    my $answer = prompt( $msg, -default => 'Y', -YN, -one_char );

    if ( $answer eq 'Y' ) {
        cleanup_dir($output_dir);
    }

    return;
}

sub build_coverage_report {
    my $options = shift;

    my $tmp_dir = create_tmp_dir( $options->{'output-dir'},
        $options->{'input-file'} );

    enable_coverage_report($tmp_dir);

    eval {
        prove(
            $options->{'input-file'},
            $options->{'prove-cmd'},
            $options->{'prove-args'},
        );

        generate_coverage_report(
            $tmp_dir,
            $options->{'cover-cmd'},
            $options->{'cover-args'},
        );

        open_browser(
            "$tmp_dir/coverage.html",
            $options->{'browser-cmd'},
            $options->{'browser-args'},
        );
    };

    if ($EVAL_ERROR) {
        print "$EVAL_ERROR\n";
        cleanup_dir($tmp_dir);

        exit 1;
    }

    confirm_cleanup($tmp_dir);

    return;
}

sub main {
    my $options = get_options();

    build_coverage_report($options);

    return;
}

main();

__END__

=head1 NAME

test-coverage-report.pl - Build & display test coverage report

=head1 SYNOPSIS

test-coverage-report.pl [options]

 Options:
   --input-file|-f      Input .t or .pm file
   --prove-cmd|-p       Which prove command to use
   --prove-args|-P      prove args
   --cover-cmd|-c       Which cover command
   --cover-args|-C      cover args
   --browser-cmd|-b     Which browser to use
   --browser-args|-B    Browser args
   --output-dir|-d      Output directory
   --help|-?            Show brief help message
   --man                Show full documentation
 

=head1 DESCRIPTION

Run tests, build coverage report and open web-browser.

=cut
