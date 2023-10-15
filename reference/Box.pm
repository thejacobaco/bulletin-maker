package PDF::Box;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use PDF::API2;
use PDF::API2::Simple;
use Data::Dumper;

use constant mm => 25.4 / 72;
use constant in => 1 /72;
use constant pt => 1;

use constant header => 20;
use constant title => 14;
use constant normal => 11;
use constant leading => 5;
use constant leading_sm => 2;
use constant DEFAULT_FONT => 'Helvetica';
use constant DEFAULT_FONT_BOLD => 'Helvetica-Bold';

sub new {
	my ($class_name,$pdf,%opts) = @_;
  $opts{auto_flow} = 1 if !defined $opts{auto_flow};
  if ($opts{auto_flow} && ($pdf->y()-($opts{padding}*2)-(leading*2)-($pdf->line_height()*2)) < $pdf->margin_bottom()) {
    $pdf->add_page();
    $opts{y} = $pdf->y();
  }
  my $self = {
    pdf => $pdf,
    opts => \%opts,
    rect => {},
  };
  my $pl = 0.08/in;
  my $line_thickness = 0.5;

  # Write the header box
  $pdf->x($opts{x});
  $pdf->y($opts{y});
  $pdf->rect(to_x => $pdf->x()+$opts{width}, to_y => $pdf->y()-($pdf->line_height()+$opts{padding}), fill_color => '#2CB355');

  # Write the header
  $pdf->x($opts{x}+$opts{padding});
  $pdf->y($pdf->y()+$opts{padding});
  $pdf->text($opts{header_text}, fill_color => '#FFFFFF');

  # Write the outer rectangle
  $self->{rect}->{x} = $opts{x}+$line_thickness/2;
  $self->{rect}->{y} = $pdf->y()-$opts{padding};
  $self->{rect}->{to_x} = $self->{rect}->{x}+($opts{width}-$line_thickness);

  $pdf->next_line();

  # Set position for writing lines
  $pdf->x($opts{x}+$opts{padding});
  $pdf->y($pdf->y()-$opts{padding});
  $pdf->current_fill_color('#000000');
  $self->{start_x} = $pdf->x();
  $self->{last_y} = $pdf->y();

  return bless $self, $class_name;
}

sub advance_y {
  my ($self, $text, $font_size, $font) = @_;
  my $last_y = $self->{last_y};
  my $pdf_y = $last_y;
  foreach my $lines (split /\n/, $text) {
    my @text = split /\s+/, $lines;
    while (scalar @text > 0) {
      my @split = @text;
      while (scalar @split > 1 && text_width((join ' ', @split), $font_size, $font) > $self->{opts}->{width}) {
        pop @split;
      }
      my $string = join ' ', @split;
      $pdf_y -= $self->{pdf}->line_height();
      $last_y = $pdf_y-$self->{opts}->{leading};
      shift @text for 1 .. scalar @split;
    }
  }
  return $last_y;
}

sub add_cell {
  my ($self,$text,%args) = @_;
  my $x = $self->{start_x};
  $self->{pdf}->x($x);
  $self->{pdf}->y($self->{last_y});
  my $modified_leading = 0;
  if (defined $args{leading}) {
    $modified_leading = $args{leading};
  } elsif (defined $args{font_size}) {
    $modified_leading = leading*$args{font_size}/normal;
  }
  $self->{pdf}->y($self->{pdf}->y()-$modified_leading);
  my $i = 0;
  my ($cleaned_text, $styles) = _process_styles($text);
  $text = $cleaned_text;
  my $line = 0;
  foreach my $lines (split /\n/, $text) {
    my @text = split / /, $lines;
    if ($lines eq '') {
      $self->{rect}->{to_y} = $self->{pdf}->y()-$self->{opts}->{padding};
      $self->{pdf}->next_line();
      $self->{pdf}->x($x);
      $self->{last_y} = $self->{pdf}->y()-$self->{opts}->{leading};
    } else {
      my $line_created = 0;
      while (scalar @text > 0) {
        my @split = @text;
        while (scalar @split > 1 && (text_width((join ' ', @split), $args{font_size}, $args{font})+$self->{opts}->{padding}) > $self->{opts}->{width}) {
          pop @split;
        }
        my $string = join ' ', @split;
        if ($self->{opts}->{justify} eq 'right') {
          $self->{pdf}->x(($x-$self->{opts}->{padding})+($self->{opts}->{width})-text_width($string, $args{font_size}, $args{font}));
        }

        # add page and flow over if auto flow is set and this would extend over the bottom margin
        if ($self->{opts}->{auto_flow} && ($self->{pdf}->y()-$self->{opts}->{padding}) < $self->{pdf}->margin_bottom()) {
          $self->stroke(); # write borders for box on current page
          $self->{pdf}->add_page();

          my $opts = $self->{opts};
          $opts->{y} = $self->{pdf}->y();
          $opts->{header_text} = $opts->{header_text}." (Continued)";

          # create a new table with the same options to reset y values
          my $new_box = PDF::Box->new($self->{pdf}, %$opts);

          # copy over the new internal data to the existing table object
          for (keys %$new_box) {
            $self->{$_} = $new_box->{$_};
          }
        }
        $i += $line_created;
        my $j = $i + (length $string) - 1;
        $self->{pdf}->y($self->{pdf}->y()-$modified_leading) if $line_created > 0;
        $self->write_with_styles($string, $i, $j, $styles, $args{font_size}, $args{font});
        $self->{rect}->{to_y} = $self->{pdf}->y()-$self->{opts}->{padding};
        if ($args{no_padding}) {
          if ((scalar @split) < (scalar @text)) {
            $self->{pdf}->next_line();
          }
        } else {
          $self->{pdf}->next_line();
        }
        $self->{pdf}->x($x);
        $self->{last_y} = $self->{pdf}->y()-$self->{opts}->{leading};
        shift @text for 1 .. scalar @split;
        $i = $j + 1;
        $line_created = 1;
      }
    }
    $self->{pdf}->next_line() if ($args{no_padding} && $lines ne '');
    $line++;
  }
  return $self->{last_y};
}

sub add_image {
  my ($self, $image_path, %args) = @_;
  my $x = $self->{start_x};
  $self->{pdf}->x($x);
  $self->{pdf}->y($self->{last_y});
  my $to_y = $self->{pdf}->y()-$args{height};
  # add page and flow over if auto flow is set and this would extend over the bottom margin
  if ($self->{opts}->{auto_flow} && ($to_y-$self->{opts}->{padding}) < $self->{pdf}->margin_bottom()) {
    $self->stroke(); # write borders for box on current page
    $self->{pdf}->add_page();

    my $opts = $self->{opts};
    $opts->{y} = $self->{pdf}->y();
    $opts->{header_text} = $opts->{header_text}." (Continued)";

    # create a new table with the same options to reset y values
    my $new_box = PDF::Box->new($self->{pdf}, %$opts);

    # copy over the new internal data to the existing table object
    for (keys %$new_box) {
      $self->{$_} = $new_box->{$_};
    }
  }
  $to_y = $self->{pdf}->y()-$args{height};
  $self->{pdf}->image($image_path, width => $args{width}, height => $args{height}, x => $x, y => $to_y);
  $self->{pdf}->y($to_y);
  $self->{rect}->{to_y} = $self->{pdf}->y()-$self->{opts}->{padding};
  $self->{pdf}->next_line();
  $self->{pdf}->x($x);
  $self->{last_y} = $self->{pdf}->y()-$self->{opts}->{leading};
}

sub write_with_styles {
  my ($self, $string, $i, $j, $styles, $font_size, $font) = @_;
  foreach (@{$styles->($string, $i, $j)}) {
    my $font_is = DEFAULT_FONT;
    if (defined $font_size) {
      $self->{pdf}->current_font_size($font_size);
    }
    if (defined $font) {
      $self->{pdf}->set_font($font);
      $font_is = $font;
    } elsif ($_->{bold}) {
      $self->{pdf}->set_font(DEFAULT_FONT_BOLD);
      $font_is = DEFAULT_FONT_BOLD;
    }
    $self->{pdf}->text($_->{text});
    $self->{pdf}->set_font(DEFAULT_FONT);
    $self->{pdf}->current_font_size(normal-1);
    $self->{pdf}->x($self->{pdf}->x+(text_width($_->{text}, $font_size, $font_is)));
  }
}

# returns a sub which will return you an array of structures to print with bold => 1, text => '' entries
# based on the styles present in the text you provided
sub _process_styles {
  my $text = shift;
  my ($cleaned_text, $styles) = _rip_styles($text);
  my $super_clean_text = $cleaned_text;
  $super_clean_text =~ s/\R//g;
  return $cleaned_text, sub {
    my ($string, $i, $j) = @_;
    my @strings;
    my $current_i = $i;
    foreach my $bold_piece (@{$styles->{bold}}) {
      if ($current_i <= $bold_piece->{end} && $j >= $bold_piece->{start}) {
        my $bold_start = $bold_piece->{start};
        if ($current_i > $bold_start) {
          $bold_start = $current_i;
        }
        if ($current_i != $bold_piece->{start}) {
          my $string_before = substr($super_clean_text, $current_i, ($bold_start-$current_i));
          if ($string_before ne '') {
            push @strings, {
              text => $string_before,
            };
          }
        }
        my $bold_end = $bold_piece->{end};
        if ($j < $bold_piece->{end}) {
          $bold_end = $j;
        }
        push @strings, {
          text => substr($super_clean_text, $bold_start, ($bold_end - $bold_start + 1)),
          bold => 1,
        };
        $current_i = $bold_end + 1;
      }
    }
    if ($current_i <= $j) {
      push @strings, {
        text => substr($super_clean_text, $current_i, $j-$current_i+1),
      };
    }
    return \@strings;
  };
}

# At the moment, you can not really nest elements
# Would need to know where to slide tag starts and ends to
sub _rip_styles {
  my $text = shift;
  #$text =~ s/[ ]+/ /g;
  $text =~ s/[ ]+\n/\n/g;

  my %tags = (
    'b' => 'bold',
  );
  my %styles;
  my @tag_stack;
  my $tag = '';
  my $tag_start = undef;
  my $i = 0;
  my $clean_text = '';
  foreach my $character (split //, $text) {
    if ($character eq '<') {
      if ($tag ne '') {
        $clean_text .= $tag;
      }
      $tag = $character;
      $tag_start = $i;
    } elsif ($character eq '>' && (length $tag > 1)) {
      $tag .= $character;
      $tag =~ m/<\/?(.+)>/;
      my $tag_type = $tags{$1};
      my $start = ($tag =~ m/\//) ? 0 : 1;
      if ($start) {
        push @tag_stack, {tag_type => $tag_type, start => $tag_start};
      } else {
        my $element = pop @tag_stack;
        push @{$styles{$element->{tag_type}}}, {start => $element->{start}, end => ($tag_start - 1)};
      }
      $tag = '';
      $tag_start = undef;
    } elsif ($character eq '/' && $tag eq '<') {
      $tag .= $character;
    } elsif ((length $tag) > 0 && $character ne '>' && $character ne '/') {
      $tag .= $character;
    } else {
      if ($tag ne '') {
        $clean_text .= $tag;
      }
      $clean_text .= $character;
      $tag = '';
      $tag_start = undef;
      unless ($character =~ m/\R/) {
        $i++;
      }
    }
  }
  return $clean_text, \%styles;
}

sub stroke {
  my $self = shift;
  my $border_color = $self->{opts}->{border_color}||'#DDDDDD';
  my $to_y = $self->{rect}->{to_y};
  if (!defined $to_y) {
    $to_y = $self->{rect}->{y} - ($self->{pdf}->line_height()*2);
  }
  $self->{pdf}->rect(
    x => $self->{rect}->{x}, 
    y => $self->{rect}->{y}, 
    to_x => $self->{rect}->{to_x},
    to_y => $to_y,
    fill => 'off', 
    stroke => 'on', 
    stroke_color => $border_color
  );
}

sub text_width {
  my ($text,$font_size,$font_selection) = @_;
  my $fake_file = '';
  my $SH = IO::String->new(\$fake_file);
  my $pdf = PDF::API2->new(-file => $SH);
  my $page = $pdf->page;
  my $font_type = $pdf->corefont('Helvetica');
  if (defined $font_selection) {
    $font_type = $pdf->corefont($font_selection);
  }
  my $text_obj = $page->text;
  $text_obj->font($font_type, ($font_size||normal));
  return $text_obj->advancewidth($text);
}

sub get_width {
  my $self = shift;
  return $self->{opts}->{width};
}

sub print_it {
  my $text = shift;
  foreach (split //, $text) {
    print "$_-";
  }
  print "\$\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Internet123::PDF::Box - It's new $module

=head1 SYNOPSIS

    use Internet123::PDF::Box;

=head1 DESCRIPTION

Internet123::PDF::Box is ...

=head1 LICENSE

Copyright (C) Jacob Monroe.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jacob Monroe E<lt>jmonroe@123.netE<gt>

=cut

