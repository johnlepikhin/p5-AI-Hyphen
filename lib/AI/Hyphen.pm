
package AI::Hyphen;

use 5.024001;
use Carp;
use AI::NeuralNet::Simple;
use Storable;
use warnings;
use strict;

{

    sub new {
        my $class = shift;
        if ( @_ % 2 ) {
            croak "Even number of arguments";
        }
        my %args            = @_;
        my $chars           = $args{chars} // croak "'chars=>...' is required";
        my $word_separator  = $args{word_separator} // q{ };
        my $sequence_length = $args{sequence_length} // 7;
        my $internal_layers = $args{internal_layers} // [30];
        my $input_size      = ( @{$chars} + 1 ) * $sequence_length;
        my $network         = AI::NeuralNet::Simple->new( $input_size, @{$internal_layers}, 1 );

        my %chars;
        my $i = 0;
        foreach ( @{$chars} ) {
            $chars{$_} = $i;
            $i++;
        }
        $chars{$word_separator} = $i;

        my $hyphen_pos = int( $sequence_length / 2 );
        if ( $sequence_length % 2 ) {
            $hyphen_pos++;
        }

        return bless {
            chars           => \%chars,
            network         => $network,
            input_size      => $input_size,
            sequence_length => $sequence_length,
            word_separator  => $word_separator,
            hyphen_pos      => $hyphen_pos,
        }, $class;
    }

    sub learn {
        my $self = shift;
        if ( @_ % 2 ) {
            croak "Even number of arguments";
        }
        my %args        = @_;
        my $data        = $args{data} // croak "'data=>...' is required";
        my $hyphen_char = $args{hyphen_char} // croak "'hyphen_char=>...' is required";
        my $iterations  = $args{iterations} // 1;
        my $chars_str   = join q{}, grep { $_ ne $self->{word_separator} } keys %{ $self->{chars} };

        $data =~ s/[^$chars_str$self->{word_separator}$hyphen_char]+/$self->{word_separator}/g;
        $data = "$self->{word_separator}$data$self->{word_separator}";

        my @traindata;
        my $len = length $data;
        for my $pos ( 0 .. $len - 1 ) {
            my $have  = 0;
            my @input = map {0} 1 .. $self->{input_size};
            my $spos  = $pos;
            my $apos  = 0;
            while ( $apos < $self->{sequence_length} && $spos < $len ) {
                my $c = substr $data, $spos, 1;
                if ( $c eq $hyphen_char ) {
                    if ( $apos == $self->{hyphen_pos} ) {
                        $have = 1;
                    }
                } else {
                    $input[ $self->{chars}{$c} * $apos ] = 1;
                    $apos++;
                }
                $spos++;
            }
            if ( $apos < $self->{sequence_length} ) {
                last;
            }
            push @traindata, \@input => [$have];
        }

        return $self->{network}->train_set( \@traindata, $iterations, 0.01 );
    }

    sub get_word_hyphens {
        my $self = shift;
        my $word = shift;

        my $len = length $word;
        my $add = $self->{sequence_length} - 1;
        my $p   = $self->{word_separator} x $add;
        $word = "$p$word$p";
        $len += $add * 2;
        my $word_start = $add;
        my $word_end   = $len - $add;

        my @result;
        for my $pos ( 0 .. $len - 1 ) {
            my $have = 0;
            my @input = map {0} 1 .. $self->{input_size};

            my $apos = 0;
            my $spos = $pos;
            my $str  = q{};
            while ( $apos < $self->{sequence_length} && $spos < $len ) {
                my $c = substr $word, $spos, 1;
                $str .= $c;
                $input[ $self->{chars}{$c} * $apos ] = 1;
                $apos++;
                $spos++;
            }
            if ( $apos < $self->{sequence_length} ) {
                last;
            }

            my $hypen_pos = $pos + $self->{hyphen_pos};
            if ( $hypen_pos > $word_start && $hypen_pos < $word_end ) {
                my $score = ( $self->{network}->infer( \@input ) )->[0];
                push @result, $score;
            }
        }

        return \@result;
    }

    sub hyphenize_word {
        my $self        = shift;
        my $word        = shift;
        my $hyphen_char = shift;
        my $min_score   = shift;
        my $min_length  = shift;

        my $hyphens   = $self->get_word_hyphens($word);
        my $offset    = 0;
        my $hd_length = 0;
        my $tl_length = length $word;
        my $pos       = 0;
        foreach ( @{$hyphens} ) {
            $hd_length++;
            $tl_length--;
            $pos++;

            #            print "$pos, score = $_, tl = $tl_length\n";
            if (   $_ >= $min_score
                && $hd_length >= $min_length
                && $tl_length >= $min_length ) {

                #                print "add, offset=$offset\n";
                substr $word, $pos + $offset, 0, $hyphen_char;
                $offset++;
                $hd_length = 0;
            }
        }

        return $word;
    }

    sub hyphenize_text {
        my $self        = shift;
        my $text        = shift;
        my $hyphen_char = shift;
        my $min_score   = shift;
        my $min_length  = shift;

        my $chars_str = join q{}, grep { $_ ne $self->{word_separator} } keys %{ $self->{chars} };

        $text =~ s/([$chars_str]+)/$self->hyphenize_word($1, $hyphen_char, $min_score, $min_length)/ge;

        return $text;
    }

    sub load {
        my $file = shift;
        return retrieve($file);
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AI::Hyphen - Perl extension for blah blah blah

=head1 SYNOPSIS

  use AI::Hyphen;
  use Storable;

  # learn and save network
  $h = AI::Hyphen->new( chars => \@chars );
  $h->learn(
    data        => $learn_data,
    hyphen_char => q{-},
    iterations  => 30,
  );
  store $h, '/path/to/network.data';

  # load already available network
  $h = AI::Hyphen::load('/path/to/network.data');

  # use network to hyphenize word or text
  print $h->hyphenize_word( $word, '-', 0.1, 2 ), "\n";
  print $h->hyphenize_text( $text, '-', 0.1, 2 ), "\n";

=head1 DESCRIPTION

Simple hyphenation library based on FANN neural network library

=head1 AUTHOR

Evgenii Lepikhin, E<lt>johnlepikhin@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Evgenii Lepikhin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
