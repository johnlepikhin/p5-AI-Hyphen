#! /usr/bin/perl

use AI::Hyphen;
use Storable;
use Getopt::Long;
use Encode;
use warnings;
use strict;
use utf8;

binmode STDIN,  ':raw';
binmode STDOUT, ':encoding(UTF-8)';

my $storage_file        = '~/bin/hyphen/russian/network.data';
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

$opt_hyphen_char = decode( 'UTF-8', $opt_hyphen_char, sub {q{}} );
$storage_file = glob $storage_file;

my $h;

if ($opt_learn_stdin) {

    my @chars = split //, 'йцукенгшщзхъфывапролджэячсмитьбю';

    $h = AI::Hyphen->new( chars => \@chars, internal_layers => [80] );

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
    $opt_word = decode( 'UTF-8', $opt_word, sub {q{}} );
    print $h->hyphenize_word( $opt_word, $opt_hyphen_char, 0.2, 2 ), "\n";
}

if ($opt_hyphenize_stdin) {
    my $text = q{};
    while (<>) {
        $text .= $_;
    }
    $text = decode( 'UTF-8', $text, sub {q{}} );
    print $h->hyphenize_text( $text, $opt_hyphen_char, 0.3, 2 );
}
