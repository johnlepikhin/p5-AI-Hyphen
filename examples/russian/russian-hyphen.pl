#! /usr/bin/perl

use lib q{../..};
use AI::Hyphen;
use Storable;
use Getopt::Long;
use Encode;
use warnings;
use strict;
use utf8;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

my $storage_file        = '/tmp/hyphens.data';
my $opt_learn_stdin     = 0;
my $opt_load_network    = 0;
my $opt_word            = undef;
my $opt_hyphenize_stdin = 0;
my $opt_hyphen_char     = q{-};

GetOptions(
    'storage-file=s'   => \$storage_file,
    'learn-stdin'      => \$opt_learn_stdin,
    'load-network'     => \$opt_load_network,
    'hyphenize-word=s' => \$opt_word,
    'hyphenize-stdin'  => \$opt_hyphenize_stdin,
    'hyphen-char=s'    => \$opt_hyphen_char,
);

$opt_hyphen_char = decode( 'UTF-8', $opt_hyphen_char );

my $h;

if ($opt_learn_stdin) {

    my @chars = split //, 'йцукенгшщзхъфывапролджэячсмитьбю';

    $h = AI::Hyphen->new( chars => \@chars );

    my $learn_data;
    while (<>) {
        $learn_data .= $_;
    }

    $h->learn(
        data        => $learn_data,
        hyphen_char => q{-},
        iterations  => 30,
    );

    store $h, $storage_file;
} else {
    $h = AI::Hyphen::load($storage_file);
}

if ( defined $opt_word ) {
    $opt_word = decode( 'UTF-8', $opt_word );
    print $h->hyphenize_word( $opt_word, $opt_hyphen_char, 0.1, 2 ), "\n";
}

if ($opt_hyphenize_stdin) {
    my $text;
    while (<>) {
        $text .= $_;
    }

    print $h->hyphenize_text( $text, $opt_hyphen_char, 0.1, 2 ), "\n";
}
