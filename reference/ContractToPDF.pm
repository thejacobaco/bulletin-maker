package Portal::ContractToPDF;
use strict;
use Data::Dumper;
use PDF::API2;
use PDF::API2::Simple;
use IO::String;
use PDF::Box;
use PDF::Table;
use DateTime;
use constant mm => 25.4 / 72;
use constant in => 1 /72;
use constant pt => 1;

use constant header => 20;
use constant title => 14;
use constant normal => 11;
use constant padding => 5;
use constant leading => 5;
use constant leading_sm => 2;

use constant RESOURCES_DIR => './resources/';
use constant BLANK_SIGNATURE => RESOURCES_DIR.'blank-sig.png';
use constant CUSTOM_TAC_DIR => './files/custom-tac/';
use constant TAC_INITIAL_LOCATION => {x => 540, y => 45};
use constant FONTS => {roman => 'Helvetica', bold => 'Helvetica-Bold', italic => 'Times-Italic'};
use constant EUCL_NOTE => 'All voice service is subject to EUCL charge of $24.75/mo. International Calling Varies By Country.';

sub new {
  my $class_name = shift;
  my $data = {
    pdf => fresh_pdf(),
    is_built => 0,
  };

  my $customer_info_y = $data->{pdf}->y()-0.1/in;

  my $box_dimensions = {
    customer_info => {
      x => $data->{pdf}->margin_left(),
      y => $customer_info_y,
      width => 3.75/in,
    },
    our_info => {
      y => $customer_info_y,
      width => 3.75/in,
    },
  };

  my $our_info_start_x = $box_dimensions->{customer_info}->{x}+$box_dimensions->{customer_info}->{width};
  $box_dimensions->{our_info}->{x} = ($our_info_start_x)+(($data->{pdf}->width_right()-$our_info_start_x)-$box_dimensions->{our_info}->{width});

  $data->{positions} = $box_dimensions;

  return bless $data, $class_name;
}

sub clean_up {
  my $self = shift;
  $self->{pdf} = fresh_pdf();
  $self->{is_built} = 0;
}

sub build {
  my ($self, $contract) = @_;
  $self->{contract} = $contract;
  $self->clean_up;
  my $y = $self->print_customer_info($self->{positions}->{customer_info}, $contract->customer_info);
  my $y2 = $self->print_our_info($self->{positions}->{our_info}, $contract->quote_info);
  $y = $y2 if $y2 < $y;
  $self->{pdf}->y($y);
  my $table = $self->print_line_items($contract);
  $self->print_totals($contract->mrc, $contract->nrc, $table);
  $self->print_notes($contract->quote_info);
  $self->print_signature_box($contract->quote_info, $contract->signature_info);
  $self->print_page_numbers;
  $self->append_tac_pages($contract->quote_info, $contract->customer_info, $contract->signature_info);
  $self->set_metadata;

  $self->{is_built} = 1;
}

sub save_to {
  my ($self,$contract,$file_path) = @_;
  open(my $fh, '>', $file_path) or die "Sorry $!";
  binmode $fh;
  print $fh $self->stringify($contract);
  close($fh);
}

sub stringify {
  my ($self, $contract) = @_;
  $self->build($contract) if !$self->{is_built};
  return $self->{pdf}->stringify;
}

sub set_metadata {
  my $self = shift;
  my $now = DateTime->now(time_zone => 'America/Detroit');
  $self->{pdf}->pdf->info(
    Title => "Contract #".$self->{contract}->quote_info->{quote_id},
    Producer => '',
    Author => '123.Net, Inc',
    CreationDate => _pdf_date($now),
    ModDate => _pdf_date($now),
  );
}

sub _pdf_date {
  my $tstamp = shift;
  return "D:".$tstamp->ymd('').$tstamp->hms('')."-05'00'";
}

sub print_customer_info {
  my ($self,$dimensions,$info) = @_;
  my $box = PDF::Box->new($self->{pdf},
    x => $dimensions->{x},
    y => $dimensions->{y},
    width => $dimensions->{width},
    padding => padding,
    leading => leading_sm,
    header_text => "Customer Information",
  );
  $box->add_cell("<b>Company Name:</b> $info->{company_name}");
  if ($info->{company_name} ne $info->{billing_name}) {
    $box->add_cell("<b>Billing Company:</b> $info->{billing_name}");
  }
  $box->add_cell("<b>Billing Address:</b>");
  $box->add_cell("$info->{street_address} $info->{suite}");
  $box->add_cell("$info->{city}, $info->{state} $info->{zip}");
  my $billing_email = join(' ', split(/,/, $info->{billing_email}));
  $box->add_cell("<b>Billing Email:</b> $billing_email");
  if ($info->{account_number} ne '') {
    $box->add_cell("<b>Account Number:</b> $info->{account_number}");
  }
  if ($info->{billing_email} eq 'Accounts@SiFiNetworks.com') {
    $box->add_cell("\n");
    $box->add_cell("<b>Estimated Target Date as\nrequested by Customer:</b>")
  }
  $box->stroke();
  return $self->{pdf}->y();
}

sub print_our_info {
  my ($self,$dimensions,$info) = @_;
  my $box = PDF::Box->new($self->{pdf},
    x => $dimensions->{x},
    y => $dimensions->{y},
    width => $dimensions->{width},
    padding => padding,
    leading => leading_sm,
    #header_text => "123NET Information",
    header_text => "Order Information",
  );
  #$box->add_cell("<b>Address:</b>");
  #$box->add_cell("24700 Northwestern Hwy STE 700");
  #$box->add_cell("Southfield, MI 48075");
  #$box->add_cell('<b>Contact:</b>');
  #$box->add_cell('888.440.0123 | orders@123.net');
  if ($info->{sales_rep}->{fullname} ne '' && $info->{quote_id} != 2540138) {
    $box->add_cell("<b>Sales Rep:</b>");
    $box->add_cell("$info->{sales_rep}->{fullname}");
    if ($info->{sales_rep}->{phone} ne '') {
      $box->add_cell("$info->{sales_rep}->{phone} | $info->{sales_rep}->{email}");
    } else {
      $box->add_cell("$info->{sales_rep}->{email}");
    }
  }
  if ($info->{quote_id} == 2540138) {
    $box->add_cell("Heather Tokman");
    $box->add_cell("248.228.8251 | htokman@123.net");
  }
  $box->add_cell("<b>Quote ID:</b> $info->{quote_id}");
  my $valid_through = $info->{valid_through};

  ## one off code
  if ($info->{quote_id} eq '2541128') {
    $valid_through = "2022-09-30";
  }

  if ($info->{quote_id} eq '2540390') {
    $valid_through = "2023-02-21";
  }

  if ($info->{quote_id} eq '2542667') {
    $valid_through = "2023-03-03";
  }

  if ($info->{quote_id} eq '2543437') {
    $valid_through = "2023-03-31";
  }

  $box->add_cell("<b>Quote valid through:</b> $valid_through");
  $box->stroke();
  return $self->{pdf}->y();
}

sub print_line_items {
  my ($self,$contract) = @_;

  # TODO - Change width of MRC column based on largest value in that column
  my $table = PDF::Table->new($self->{pdf},
    x => $self->{pdf}->margin_left(),
    y => $self->{pdf}->y()-0.25/in,
    width => $self->{pdf}->effective_width,
    leading => 12,
    disable_row_borders => 1,
    headers => [
      {
        text => "Location",
        width => 0.30,
      },
      {
        text => "Type of Service",
        width => 0.50,
      },
      {
        text => "NRC",
        width => 0.10,
        justify => 'right',
      },
      {
        text => "MRC",
        width => 0.10,
        justify => 'right',
      },
    ],
  );

  # Printing the products
  my $printed_addresses = {};
  my $just_printed_a_grouped_product = 0;
  my $i = 0;
  foreach my $product (@{$contract->line_items}) {
    if (ref $product eq 'ARRAY') {
      unless ($i == 0) {
        $table->print_border;
      }
      foreach (@$product) {
        _print_product($_,$printed_addresses,$table);
      }
      $just_printed_a_grouped_product = 1;
    } else {
      if ($just_printed_a_grouped_product) {
        $table->print_border;
      }
      _print_product($product,$printed_addresses,$table);
      $just_printed_a_grouped_product = 0;
    }
    $i++;
  }

  $table->end_row;
  # Printing the bucket:
  my ($bucket, $rates) = ($contract->bucket, $contract->voice_rates);
  if (defined $bucket or defined $rates) {
    $table->print_border;
    $table->patch_row("<b>Voice Pricing</b>", undef, undef, undef);
    if (defined $rates) {
      $table->patch_row(undef, "<b>Minutes of Usage Rates</b>", undef, undef);
      foreach (@{$rates->{labels}}) {
        $table->patch_row(undef, $_, undef, undef);
      }
      $table->end_row;
    }
    if (defined $bucket) {
      my $bucket = $contract->bucket;
      _print_product($bucket,$printed_addresses,$table);
      if (defined $bucket->{unlimited_local}) {
        $table->patch_row(undef, "<b>$bucket->{unlimited_local}->{label}</b>", undef, _dollar_cell($bucket->{unlimited_local}->{mrc}));
      }
    }
    $table->end_row;
  }

  # Printing the minutes of usage rates information


  # Printing the one-off (MRC/NRC) notes
  $table->print_border;
  my $one_off_notes_label = '<b>Special Notes</b>';
  foreach (@{$contract->one_off_notes}) {
    $table->add_row([$one_off_notes_label,"<b>$_->{note}</b>",_dollar_cell($_->{nrc}),_dollar_cell($_->{mrc})]); # Maybe pass a sub, instead of data to render according to the sub?
    $one_off_notes_label = '';
  }
  $table->stroke();
  return $table;
}

sub print_totals {
  my ($self, $mrc, $nrc, $line_items_table) = @_;
  my $total_x = $line_items_table->get_col_x(2);
  my $total_width = $line_items_table->get_col_width(2)+$line_items_table->get_col_width(3);

  my $total_y = $self->{pdf}->y()-0.25/in;
  if ($self->{pdf}->y()-0.25/in-(2.5*$self->{pdf}->line_height()+2*padding) < $self->{pdf}->margin_bottom()) {
    $self->{pdf}->add_page();
    $total_y = $self->{pdf}->y();
  }

  my $table = PDF::Table->new($self->{pdf},
    x => $total_x,
    y => $total_y,
    width => $total_width,
    leading => leading,
    headers => [
      {
        text => "NRC Total",
        width => 0.50,
        justify => 'right',
      },
      {
        text => "MRC Total",
        width => 0.50,
        justify => 'right',
      },
    ],
  );
  $table->add_row([_dollar_cell(sprintf("%.2f", $nrc)), _dollar_cell($mrc)]);
  $table->stroke();
  $self->{pdf}->next_line();
}

sub print_notes {
  my ($self, $quotes_info) = @_;
  my ($notes, $needs_eucl, $special_notes) = ($self->{contract}->notes,$self->{contract}->needs_eucl,$self->{contract}->special_notes);
  my $nothing_to_print = (scalar @$notes == 0) && (scalar @$special_notes == 0) && (!$needs_eucl or $self->{contract}->hide_rules->{eucl_note}) && $self->{contract}->hide_rules->{budgetary_note};
  unless ($nothing_to_print) {
    my $box = PDF::Box->new($self->{pdf},
      x => $self->{pdf}->margin_left(),
      y => $self->{pdf}->y()-0.1/in,
      width => $self->{pdf}->effective_width,
      padding => padding,
      leading => leading,
      header_text => "Notes",
    );

    foreach (@$special_notes) {
      $box->add_cell($_);
    }
    foreach (@$notes) {
      $box->add_cell($_->{note});
    }
    $box->add_cell($quotes_info->{budgetary_note}, font_size => 7, leading => 0) unless $self->{contract}->hide_rules->{budgetary_note};
    
    if ($needs_eucl and !$self->{contract}->hide_rules->{eucl_note}) {
      $box->add_cell(EUCL_NOTE, font_size => 7, leading => 0);
    }

    $box->stroke();
  }
}

sub print_signature_box {
  my ($self, $quote_info, $signature_info) = @_;
  my $height = 45;
  my $flowed_over = 0;
  if (($self->{pdf}->y() - $height - normal*3 - leading*8) < $self->{pdf}->margin_bottom()) {
    $self->{pdf}->add_page();
    $flowed_over = 1;
  }
  my $box = PDF::Box->new($self->{pdf},
    x => $self->{pdf}->margin_left(),
    y => $self->{pdf}->y()-($flowed_over ? 0 : 0.25/in),
    width => $self->{pdf}->effective_width(),
    padding => padding,
    leading => leading,
    header_text => "Authorized Customer Signature",
  );
  $box->add_cell("<b>$quote_info->{signature_acknowledgement_text}</b>");
  if ($signature_info->{esignature} ne '' or !$quote_info->{is_signed}) {
    $box->add_image($signature_info->{esignature}||BLANK_SIGNATURE, width => 145, height => $height);
  } else {
    $box->add_cell($signature_info->{print_name}, font_size => 22, font => FONTS->{italic});
  }
  $box->add_cell('<b>Print Name: </b>'.$signature_info->{print_name});
  $box->add_cell('<b>Date: </b>'.$signature_info->{date});

  $box->stroke;
}

sub print_page_numbers {
  my $self = shift;
  my $number_of_pages = $self->{pdf}->pdf->pages;
  # TODO print on each page separately
  for (1 .. $number_of_pages) {
    my $page = $self->{pdf}->pdf->openpage($_);
    $self->{pdf}->current_page($page);
    my $text = "Page $_ of $number_of_pages";
    $self->{pdf}->text($text, x => $self->{pdf}->margin_right+$self->{pdf}->effective_width-text_width($text), y => $self->{pdf}->margin_bottom-0.3/in);
  }
}

sub _dollar_cell {
  return "<b>"._format_dollars(shift)."</b>"
}

sub address_col {
  my ($product, $printed_addresses) = @_;

  my $text = '';
  if (_should_print_address(@_)) {
    my $first = 1;
    foreach (@{$product->{address}}) {
      if (!$first) {
        $text .= "\n";
      }
			$text .= _format_address($_);
      my $final_newline = '';
      if ($_->{npa} ne '') {
        $text .= "NPA-NXX: $_->{npa}-$_->{nxx}";
        $final_newline = "\n";
      }
      if ($_->{lcon_name} ne '') {
        $text .= "\nLocal Contact: $_->{lcon_name}";
        $final_newline = "\n";
      }
      if ($_->{lcon_phone} ne '') {
        $text .= "\n$_->{lcon_phone}";
        if ($_->{lcon_hours} ne '') {
          $text .= "  $_->{lcon_hours}";
        }
        $final_newline = "\n";
      }
      $text .= $final_newline;
      $first = 0;
    }
  }

  return $text;
}

sub _should_print_address {
  my ($product, $printed_addresses) = @_;
  my $should_print = 0;

  my $num_addresses = scalar @{$product->{address}};
  if ($product->{is_partial} || $num_addresses > 1 || !$printed_addresses->{$product->{address}->[0]->{full_address}}) {
    $should_print = 1;
    unless ($num_addresses > 1 || $product->{is_partial}) {
      $printed_addresses->{$product->{address}->[0]->{full_address}} = 1;
    }
  }
  return $should_print;
}

sub _format_address {
	my $address = shift;
	return sprintf("<b>%s</b>\n%s%s\n%s, %s %s\n",
		_trim($address->{company_name}),
		_trim($address->{street_address}),
		(defined $address->{suite} && $address->{suite} ne '') ? "\n" . _trim($address->{suite}) : '',
		_trim($address->{city}),
		_trim($address->{state}),
		_trim($address->{zip})
	);
}

sub _trim {
	my $str = shift;
	$str =~ s/^\s+|\s+$//g;
	return $str;
}

sub _print_product {
  my ($product, $printed_addresses, $table) = @_;

  # Main product line
  unless ($product->{hide}->{product_name}) {
    $table->patch_row(($product->{order_type} ne 'bucket' ? address_col($product,$printed_addresses) : undef), "<b>$product->{product_name}</b>", _dollar_cell($product->{product_nrc}), _dollar_cell($product->{product_mrc}));
  }

  # order web type
  unless ($product->{hide}->{order_web_type}) {
    $table->patch_row(undef, "<b>$product->{order_web_type}->{label}</b>", undef, undef) if $product->{order_web_type}->{type} ne 'new';
  }

  # Attributes
  unless ($product->{hide}->{attributes}) {
    foreach (@{$product->{attributes}}) {
      unless ($product->{hide}->{attribute}->{$_->{attribute}}) {
        $table->patch_row(undef, ($_->{label}||"$_->{name}: $_->{value}"), undef, undef);
      }
    }
  }

  # Support for hosted to show the term before the addons
  my $term_text_printed = 0;
  my $term_text = "$product->{term}->{term_label}";
  if ($product->{order_type} eq 'hosted') {
    $term_text_printed = 1;

    ## one-off-code for hosted here
    $term_text = '80 Month Term ($499.00 Installation Waived)' if ($product->{product_id} eq '116164'); 

    $table->patch_row(undef, $term_text, undef, undef) unless $product->{hide}->{term};
  }

  # Addons
  unless ($product->{hide}->{addons}) {
    _print_addons($product,$table);
  }

  # Term
  if (!$term_text_printed) {

    ## one-off-code here
    $term_text = '18 Month Term ($500.00 Installation Waived)' if ($product->{quote_id} eq '2543528');
    $term_text = '18 Month Term ($5,000.00 Installation Waived)' if ($product->{quote_id} eq '2536785');
    $term_text = '27 Month Term ($2,500.00 Installation Waived)' if ($product->{quote_id} eq '2538721'); 
    $term_text = '80 Month Term ($5,000.00 Installation Waived)' if ($product->{product_id} eq '116165'); 
    $term_text = '44 Month Term ($5,000.00 Installation Waived)' if ($product->{product_id} eq '93652'); 
    $term_text = '44 Month Term ($99.00 Installation Waived)' if ($product->{product_id} eq '93654'); 
    $term_text = '44 Month Term ($5,000.00 Installation Waived)' if ($product->{product_id} eq '119511'); 
    $term_text = '44 Month Term' if ($product->{product_id} eq '93655'); 
    $term_text = '44 Month Term' if ($product->{product_id} eq '119513'); 
    $term_text = '19 Month Term' if ($product->{product_id} eq '104466');
    $term_text = '18 Month Term' if ($product->{product_id} eq '110687');
    $term_text = '18 Month Term' if ($product->{product_id} eq '119788');
    $term_text = '6 Month Term' if ($product->{product_id} eq '113029');
    $term_text = '6 Month Term' if ($product->{product_id} eq '119621');

    $table->patch_row(undef, $term_text, undef, undef) unless $product->{hide}->{term};
  }

  # DDD
  unless ($product->{hide}->{desired_due_date}) {
    $table->patch_row(undef, "Desired Due Date: $product->{desired_due_date}", undef, undef) if $product->{desired_due_date} ne '';
  }

  # Note
  unless ($product->{hide}->{note}) {
    $table->patch_row(undef, $product->{note}, undef, undef) if $product->{note} ne '';
  }

  # Special Notes
  unless ($product->{hide}->{special_notes}) {
    foreach (@{$product->{special_notes}||[]}) {
      $table->patch_row(undef, $_, undef, undef);
    }
  }

  $table->end_row;
}


sub _format_dollars {
  my $number = shift;
  if (length("$number") > 8){
    return ($number ne '' && $number =~ m/^[-]?\d+[.]?\d*$/ ? '$'._insert_commas(sprintf("%.0f", $number)) : $number);
  } else {
    return ($number ne '' && $number =~ m/^[-]?\d+[.]?\d*$/ ? '$'._insert_commas(sprintf("%.2f", $number)) : $number);
  }
  #return ($number ne '' ? '$'._insert_commas(sprintf("%.2f", $number)) : '');
}

# Receives a number, returns a string of the same number but with commas
sub _insert_commas {
  my $number = $_[0];
  my @number_parts = split(/[.]/, $number);
  $number = $number_parts[0];
  my $isNegative = 0;
  if ($number < 0) {
    $isNegative = 1;
    $number *= -1;
  }
  my $decimal_places = $number_parts[1];
  my $traverser = $number;
  my @digits;
  my $comma_counter = 0;
  while ($traverser != 0) {
    if ($comma_counter != 0 && $comma_counter % 3 == 0) {
      push @digits, ",";
      push @digits, $traverser % 10;
      $traverser = int($traverser/10);
      $comma_counter++;
    } else {
      push @digits, $traverser % 10;
      $traverser = int($traverser/10);
      $comma_counter++;
    }
  }
  $number = '';
  while (scalar @digits > 0) {
    $number .= pop(@digits);
  }
  $number = 0 if $number eq '';
  return (($isNegative) ? '-' : '').$number.((defined $decimal_places) ? ".".$decimal_places : '');
}

sub _print_addons {
  my ($product,$table) = @_;
  foreach (@{$product->{addons}}) {
    unless ($product->{hide}->{addon}->{$_->{item_code}} eq '1') {
      $table->patch_row(undef, $_->{header_label}, undef, undef) if ($_->{header_label} ne '');
      $table->patch_row(undef, $_->{included_label}.($_->{label} eq '' && !$product->{hide}->{addon}->{$_->{item_code}}->{rate} ? " $_->{rate_label}" : ''), undef, undef) if ($_->{included_label} ne '');
      $table->patch_row(undef, $_->{label}.(!$product->{hide}->{addon}->{$_->{item_code}}->{rate} ? " $_->{rate_label}" : ''), _dollar_cell($_->{nrc}), _dollar_cell($_->{mrc})) if ($_->{label} ne '');
    }
  }
}

sub append_tac_pages {
  my ($self, $quote_info, $customer_info, $signature_info) = @_;
  $self->{pdf}->end_page;
  $self->{pdf}->footer(undef);
  if ($customer_info->{company_type} eq '123.net retail') {
    my $tac_pdf;
    if ($quote_info->{tac_type} eq 'custom'){
     $tac_pdf = PDF::API2->open(CUSTOM_TAC_DIR."$quote_info->{custom_tac_number}.pdf");
    } elsif ($quote_info->{tac_type} eq 'mtm'){
     $tac_pdf = PDF::API2->open(RESOURCES_DIR.'tac_mtm.pdf');
    } elsif ($quote_info->{tac_type} eq 'bia'){
     $tac_pdf = PDF::API2->open(RESOURCES_DIR.'tac_bia.pdf');
    } elsif ($quote_info->{tac_type} eq 'bia_mtm'){
     $tac_pdf = PDF::API2->open(RESOURCES_DIR.'tac_bia_mtm.pdf');
    } else {
     $tac_pdf = PDF::API2->open(RESOURCES_DIR.'tac.pdf');
    }
    for (1 .. $tac_pdf->pages()) {
      $self->{pdf}->pdf->importpage($tac_pdf,$_,0);
    }
  }
}

sub _print_initials {
  my ($self, $page, $initials) = @_;
  $self->{pdf}->current_page($page);
  $self->{pdf}->text($initials, x => TAC_INITIAL_LOCATION->{x}, y => TAC_INITIAL_LOCATION->{y}, font_size => 10, font => FONTS->{bold});
}

sub fresh_pdf {
  my ($contract, $data) = @_;
  my $pdf_str = '';
  my $SH = IO::String->new(\$pdf_str);
  my $pdf = PDF::API2::Simple->new(
    file => $SH,
    margin_top => 0.5/in,
    margin_right => 0.3/in,
    margin_bottom => 0.75/in,
    margin_left => 0.3/in,
    footer => \&add_footer,
  );
	$pdf->add_font(FONTS->{italic});
	$pdf->add_font(FONTS->{bold});
	$pdf->add_font(FONTS->{roman});
	$pdf->add_page();

  $pdf->image(RESOURCES_DIR.'service-order-letterhead.jpg', x => $pdf->margin_left(), y => $pdf->effective_height()-0.1/in, width => $pdf->effective_width, height => 90);

	return $pdf;
}

sub text_width {
  my $text = shift;
  my $fake_file = '';
  my $SH = IO::String->new(\$fake_file);
  my $pdf = PDF::API2->new(-file => $SH);
  my $page = $pdf->page;
  my %font = (
    Helvetica => {
      Bold => $pdf->corefont(FONTS->{bold}, -encoding => 'latin1'),
      Roman => $pdf->corefont(FONTS->{roman}, -encoding => 'latin1'),
    }
  );
  my $text_obj = $page->text;
  $text_obj->font($font{Helvetica}{Roman}, normal);
  return $text_obj->advancewidth($text);
}

sub add_footer {
  my $pdf = shift;
  my @footer_text = ("24700 Northwestern Hwy, Southfield, MI 48075","888.440.0123 | orders\@123.net");
  my $y = $pdf->margin_bottom()-0.3/in;
  foreach (@footer_text) {
    $pdf->text($_, x => $pdf->margin_left()+($pdf->effective_width()-text_width($_))/2, y => $y);
    $y -= $pdf->line_height();
  }
}

1;
