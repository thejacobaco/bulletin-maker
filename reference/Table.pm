package PDF::Table;
use strict;
use PDF::API2;
use PDF::API2::Simple;
use Data::Dumper;
use PDF::Box;
use Carp qw/carp/;

use constant mm => 25.4 / 72;
use constant in => 1 /72;
use constant pt => 1;

use constant header => 20;
use constant title => 14;
use constant normal => 11;
use constant padding => 5;
use constant leading => 5;
use constant leading_sm => 2;

sub new {
  my ($class_name,$pdf,%opts) = @_;
  my $self = {
    pdf => $pdf, 
    opts => \%opts,
    cols => [],
  };
  my $x = $opts{x};
  my $y = $opts{y};
  my $width = $opts{width};
  my $i = 0;
  foreach (@{$opts{headers}}) {
    if ($i > 0) {
      $x += $self->{cols}->[$i-1]->get_width();
    }
    push @{$self->{cols}}, PDF::Box->new($pdf,
      x => $x,
      y => $y,
      width => $width*$_->{width},
      padding => $opts{padding}||padding,
      leading => $opts{leading}||leading,
      header_text => $_->{text},
      border_color => "#DDDDDD",
      justify => $_->{justify},
      auto_flow => 0,
    );
    $i++;
  }
  $self->{last_y} = $pdf->y();
  return bless $self, $class_name;
}

sub end_row {
  my $self = shift;

  my $lowest_y;
  foreach (@{$self->{cols}}) {
    $lowest_y = $_->{last_y} if (!defined $lowest_y or $_->{last_y} < $lowest_y);
  }

  # Patch rows don't have any bottom margin
  # this adds it for when the row is ended
  if ($self->{patch_row_in_progress}) {
    $lowest_y -= $self->{pdf}->line_height();
  }

  # set the last y on all cols
  my $width = 0;
  foreach (@{$self->{cols}}) {
    $_->{last_y} = $lowest_y;
    $_->{rect}->{to_y} = $lowest_y;
    $width += $_->get_width();
  }

  unless ($self->{opts}->{disable_row_borders}) {
    my $hline_y = $lowest_y+$self->{pdf}->line_height();
    $self->{pdf}->line(x => $self->{opts}->{x}, y => $hline_y, to_x => $self->{opts}->{x}+$self->{opts}->{width}, to_y => $hline_y, stroke => 'on', stroke_color => '#DDDDDD', fill_color => '#DDDDDD');
  }

  $self->{patch_row_in_progress} = 0;
}

sub print_border {
  my $self = shift;
  my $lowest_y;
  my $width = 0;
  foreach (@{$self->{cols}}) {
    $lowest_y = $_->{last_y} if (!defined $lowest_y or $_->{last_y} < $lowest_y);
    $width += $_->get_width();
  }

  my $hline_y = $lowest_y+$self->{pdf}->line_height();
  $self->{pdf}->line(x => $self->{opts}->{x}, y => $hline_y, to_x => $self->{opts}->{x}+$self->{opts}->{width}, to_y => $hline_y, stroke => 'on', stroke_color => '#DDDDDD', fill_color => '#DDDDDD');

  $lowest_y -= $self->{pdf}->line_height();
  foreach (@{$self->{cols}}) {
    $_->{last_y} = $lowest_y;
  }
}

sub patch_row {
  my ($self,@row) = @_;
  $self->{patch_row_in_progress} = 1;

  # perform lookahead to see if this row will extend over the bottom
  # of the page. If so, ->stroke, and add page, and reset all the last_y's of
  # the columns, and the rect to_y

  my $i = 0;
  my $lowest_y;
  foreach (@{$self->{cols}}) {
    if (defined $row[$i]) {
      $lowest_y = $_->{last_y} if (!defined $lowest_y or $_->{last_y} < $lowest_y);
    }
    $i++;
  }

  my $i = 0;
  foreach (@{$self->{cols}}) {
    if (defined $row[$i]) {
      $_->{last_y} = $lowest_y;
    }
    $i++;
  }
  
  # get the lowest advance_y
  my $advance_y;
  for (my $i = 0; $i <= $#row; $i++) {
    my $y = $self->{cols}->[$i]->advance_y($row[$i]);
    $advance_y = $y if (!defined $advance_y or $y < $advance_y);
  }

  # if row would extend beyond bottom margin
  if ($advance_y < $self->{pdf}->margin_bottom()) {
    $self->end_row;
    $self->stroke(); # write borders for table on current page
    $self->{pdf}->add_page();

    my $opts = $self->{opts};
    $opts->{y} = $self->{pdf}->y();

    # create a new table with the same options to reset y values
    my $new_table = PDF::Table->new($self->{pdf}, %$opts);

    # copy over the new internal data to the existing table object
    for (keys %$new_table) {
      $self->{$_} = $new_table->{$_};
    }
  }

  for (my $i = 0; $i <= $#row; $i++) {
    $self->{cols}->[$i]->add_cell($row[$i], no_padding => 1);
  }
}

sub add_row {
  my ($self,$row) = @_;

  if ($self->{patch_row_in_progress}) {
    carp "Didn't end a patch row with ->end_row";
    $self->end_row;
  }

  # perform lookahead to see if this row will extend over the bottom
  # of the page. If so, ->stroke, and add page, and reset all the last_y's of
  # the columns, and the rect to_y
  
  # get the lowest advance_y
  my $advance_y;
  for (my $i = 0; $i <= $#$row; $i++) {
    my $y = $self->{cols}->[$i]->advance_y($row->[$i]);
    $advance_y = $y if (!defined $advance_y or $y < $advance_y);
  }

  # if row would extend beyond bottom margin
  if ($advance_y < $self->{pdf}->margin_bottom()) {
    $self->stroke(); # write borders for table on current page
    $self->{pdf}->add_page();

    my $opts = $self->{opts};
    $opts->{y} = $self->{pdf}->y();

    # create a new table with the same options to reset y values
    my $new_table = PDF::Table->new($self->{pdf}, %$opts);

    # copy over the new internal data to the existing table object
    for (keys %$new_table) {
      $self->{$_} = $new_table->{$_};
    }
  }

  for (my $i = 0; $i <= $#$row; $i++) {
    $self->{cols}->[$i]->add_cell($row->[$i]);
  }

  $self->end_row;
}

sub stroke {
  my $self = shift;
  foreach (@{$self->{cols}}) {
    if (!defined $_->{rect}->{to_y}) {
      $self->{pdf}->next_line();
      $_->{rect}->{to_y} = $_->{pdf}->y();
    }
    $_->{rect}->{to_y} += $_->{pdf}->line_height();
    $_->stroke();
  }
}

sub get_col_x {
  my ($self,$col_idx) = @_;
  return $self->{cols}->[$col_idx]->{opts}->{x};
}

sub get_col_width {
  my ($self,$col_idx) = @_;
  return $self->{cols}->[$col_idx]->{opts}->{width};
}

1;
