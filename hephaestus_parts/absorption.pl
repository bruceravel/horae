#! /usr/bin/perl -w

## ===========================================================================
##  This is the absorption portion of hephaestus

sub absorption {
  $periodic_table -> pack(-side=>'top', -padx=>4, -pady=>4, -fill=>'x')
    if $current !~ /$uses_periodic_regex/;
  switch({page=>"absorption", text=>'Periodic Table of Absorption Data'});
  $data{pt_resource} -> grid(-column=>3, -columnspan=>7, -row=>0, -rowspan=>3, , -sticky=>'w');
};


sub setup_absorption {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  ## energy and thickness entry widgets
##   $data{abs_energy_label} = $frame -> Label(-text=>'Energy', @label_args)
##     -> grid(-column=>0, -row=>4, -sticky=>'w');
##   my $entry = $frame -> Entry(-width=>9, -textvariable=>\$data{abs_energy},
## 			      -validate=>'key', -validatecommand=>\&set_variable)
##     -> grid(-column=>1, -row=>4, -sticky=>'ew');
##   $data{abs_units_label} = $frame -> Label(-text=>"eV", @label_args)
##     -> grid(-column=>2, -row=>4, -sticky=>'w');
##
##   my $label = $frame -> Label(-text=>'Thickness', @label_args)
##     -> grid(-column=>0, -row=>5, -sticky=>'w');
##   $entry = $frame -> Entry(-width=>9, -textvariable=>\$data{abs_thickness},
## 			   -validate=>'key', -validatecommand=>\&set_variable)
##     -> grid(-column=>1, -row=>5, -sticky=>'ew');
##   $label = $frame -> Label(-text=>'µm', @label_args)
##     -> grid(-column=>2, -row=>5, -sticky=>'w');
##

  my $r = -1;
  foreach my $l ('Name', 'Number', 'Weight', 'Density',) {
    ##		 'Absorption Length', 'Transmitted Fraction') {
    ##$r=5 if ($l eq 'Absorption Length');
    my $label = $frame -> Label(-text=>$l, @label_args)
      -> grid(-column=>0, -row=>++$r, -sticky=>'w', -padx=>2);
    my $entry = $frame -> Label(-relief=>'flat', -textvariable=>\$data{"abs_$l"},
			     -width=>12, -anchor=>'w', -font=>$config{fonts}{small}, @answer_args)
      -> grid(-column=>1, -row=>$r, -sticky=>'e', -padx=>2);
  };
  my $label = $frame -> Label(-text=>'Filter', @label_args)
    -> grid(-column=>0, -row=>++$r, -sticky=>'w');
  $data{abs_entry} = $frame -> Entry(-width=>3, -textvariable=>\$data{abs_filter},)
    -> grid(-column=>1, -row=>$r, -sticky=>'w');
  $data{abs_plot} = $frame -> Button(-text    => 'Plot filter',
				     -width   => 20,
				     @button_args,
				     -command => \&plot_filter,
				     -state   => 'disabled')
    -> grid(-column=>0, -columnspan=>2, -row=>++$r, -sticky=>'ew');


  ## Table of Edge energies
  my $edges = $frame -> Scrolled("HList",
				 -columns    => 2,
				 -header     => 1,
				 -scrollbars => 'oe',
				 -background => $bgcolor,
				 -selectmode => 'single',
				 #-selectbackground => $bgcolor,
				 -highlightcolor => $bgcolor,
				 -width      => 15,
				 -relief     => 'ridge',
				 -browsecmd  => \&highlight_lines,
				 )
      -> grid(-column=>4, -row=>0, -rowspan=>9, -padx=>3);
  my @header_style_params = ('text', -font=>$config{fonts}{smbold}, -anchor=>'center', -foreground=>'blue4');
  my @label_style_params  = ('text', -font=>$config{fonts}{small}, -anchor=>'center', -foreground=>'blue4');
  my $header_style = $edges -> ItemStyle(@header_style_params);
  my $label_style  = $edges -> ItemStyle(@label_style_params);
  $edges -> headerCreate(0, -text	   => "Edge",
			 -style		   => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1);
  $edges -> headerCreate(1, -text          => "Energy",
			 -style            => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1,);
  $edges -> columnWidth(0, -char=>6);
  $edges -> columnWidth(1, -char=>8);
  $edges -> Subwidget("yscrollbar")
    -> configure(-background=>$bgcolor, ($is_windows) ? () : (-width=>8));
  foreach my $e (qw(K L1 L2 L3 M1 M2 M3 M4 M5 N1 N2 N3 N4 N5 N6 N7
		    O1 O2 O3 O4 O5 P1 P2 P3)) {
    $edges -> add($e);
    $edges -> itemCreate($e, 0, -text=>$e, -style=>$label_style);
    $edges -> itemCreate($e, 1);
  };
  $energies{edges} = $edges;


  ## Table of Line energies

  my $lines = $frame -> Scrolled("HList",
				 -columns    => 4,
				 -header     => 1,
				 -scrollbars => 'oe',
				 -background => $bgcolor,
				 -selectmode => 'single',
				 #-selectbackground => $bgcolor,
				 -highlightcolor => $bgcolor,
				 -width      => 36,
				 -relief     => 'ridge',
				 )
      -> grid(-column=>5, -row=>0, -rowspan=>9, -padx=>3, -sticky=>'ew');
  $header_style = $lines -> ItemStyle(@header_style_params);
  $label_style  = $lines -> ItemStyle(@label_style_params);
  $lines -> headerCreate(0, -text	   => "Line",
			 -style		   => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1);
  $lines -> headerCreate(1, -text	   => "Trans.",
			 -style		   => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1);
  $lines -> headerCreate(2, -text	   => "Energy",
			 -style		   => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1);
  $lines -> headerCreate(3, -text	   => "Prob.",
			 -style		   => $header_style,
			 -headerbackground => $bgcolor,
			 -borderwidth	   => 1);
  $lines -> columnWidth(0, -char=>9);
  $lines -> columnWidth(1, -char=>10);
  $lines -> columnWidth(2, -char=>9);
  $lines -> columnWidth(3, -char=>7);
  $lines -> Subwidget("yscrollbar")
    -> configure(-background=>$bgcolor, ($is_windows) ? () : (-width=>8));
  foreach my $e (@LINELIST) {
    $lines -> add($e);
    $lines -> itemCreate($e, 0, -text=>Xray::Absorption -> get_Siegbahn_full($e), -style=>$label_style);
    $lines -> itemCreate($e, 1, -text=>Xray::Absorption -> get_IUPAC($e),         -style=>$label_style);
    $lines -> itemCreate($e, 2);
    $lines -> itemCreate($e, 3);
  };
  $energies{lines} = $lines;

  my $hash;
  do {
    no warnings;
    $hash = $$Xray::Absorption::Elam::r_elam{energy_list};
  };
  my @k_list = ();
  foreach my $key (keys %$hash) {
    next unless exists $$hash{$key}->[2];
    next unless (lc($$hash{$key}->[1]) eq 'k');
    push @k_list, $$hash{$key};
  };
  ## and sort by increasing energy
  @k_list = sort {$a->[2] <=> $b->[2]} @k_list;
  $data{k_list} = \@k_list;
  $data{abs_linewidth} = 30;

  return $frame;
};





sub get_foils_data {
  my $elem = $_[0];
  my $in_resource = Xray::Absorption -> in_resource($elem);
  map {$probs{$_} = ''} keys(%probs);
  ## enable writing in the entry widgets
  #map {$_ -> configure(-state=>'normal')} @all_entries;
  $data{abs_Name}    = get_name($elem);
  $data{abs_Number}  = get_Z($elem);
  $data{abs_Symbol}  = get_symbol($elem);
  my $z              = $data{abs_Number};
  $data{abs_Weight}  = Xray::Absorption -> get_atomic_weight($elem);
  $data{abs_Weight}  = ($data{abs_Weight}) ? $data{abs_Weight} . ' amu' : '' ;
  my $density    = Xray::Absorption -> get_density($elem);
  $data{abs_Density} = ($density) ? $density . ' g/cm^3' : '' ;

  ## vanadium is the first element for which a reasonable filter works
  ##if ($data{abs_Number} < 23) {
  ##  $data{abs_filter} = q{};
  ##  $data{abs_plot}  -> configure(-state=>'disabled');
  ##};
  if ($config{general}{ifeffit}) {  #and ($data{abs_Number} > 22)) {
    $data{abs_filter} = ($data{abs_Number} <  24) ? q{}
                      : ($data{abs_Number} == 37) ? 35     ## Kr is a stupid filter material
                      : ($data{abs_Number} <  39) ? $z - 1 ## Z-1 for V - Y
                      : ($data{abs_Number} == 45) ? 44     ## Tc is a stupid filter material
                      : ($data{abs_Number} == 56) ? 53     ## Xe is a stupid filter material
                      : ($data{abs_Number} <  57) ? $z - 2 ## Z-2 for Zr - Ba
		      : l_filter($elem);                   ## K filter for heavy elements
    $data{abs_filter} = get_symbol($data{abs_filter});
    $data{abs_plot}  -> configure(-state=>($data{abs_filter}) ? 'normal' : 'disabled');
    $data{abs_entry} -> configure(-background=>$bgcolor);
  };

  my @edges = (qw(K L1 L2 L3 M1 M2 M3 M4 M5 N1 N2 N3 N4 N5 N6 N7
		    O1 O2 O3 O4 O5 P1 P2 P3));

  foreach my $e (@edges, @LINELIST) {
    $energies{$e} = Xray::Absorption -> get_energy($elem, $e);
    $energies{$e} ||= '';
    unless ($e =~ /^(K|([LMNOP][1-7]))$/) {
      next unless $energies{$e};
      if ($Xray::Absorption::resource eq 'elam') {
	$probs{$e} =
	  sprintf "%6.4f", Xray::Absorption -> get_intensity($elem, $e);
      };
    };
  };

  if (($z >= 22) and ($z <= 29)) {
    $energies{M4} = '';
    $energies{M5} = '';
  };
  if ($z <= 17) {
    $energies{M1} = '';
    $energies{M2} = '';
    $energies{M3} = '';
  };
  if ($data{units} eq "Wavelengths") {
    foreach (keys(%energies)) {
      next if ($_ eq 'lines');
      next if ($_ eq 'edges');
      $energies{$_} = &e2l($energies{$_});
    };
  };

  ## fill Edge and Line tables with these values
  my @label_style_params  = ('text', -font=>$config{fonts}{small}, -anchor=>'center', -foreground=>'blue4');
  my @data_style_params = ('text', -font=>$config{fonts}{small}, -anchor=>'e', -foreground=>'black');
  my $data_style   = $energies{edges} -> ItemStyle(@data_style_params);
  foreach my $e (@edges) {
    $energies{edges} -> itemConfigure($e, 1, -text=>$energies{$e}, -style=>$data_style);
  };
  $energies{edges} -> selectionClear;
  $energies{edges} -> anchorClear;
  my $label_style   = $energies{lines} -> ItemStyle(@label_style_params);
  $data_style   = $energies{lines} -> ItemStyle(@data_style_params);
  foreach my $l (@LINELIST) {
    $energies{lines} -> itemConfigure($l, 0, -style=>$label_style);
    $energies{lines} -> itemConfigure($l, 1, -style=>$label_style);
    $energies{lines} -> itemConfigure($l, 2, -text=>$energies{$l}, -style=>$data_style);
    $energies{lines} -> itemConfigure($l, 3, -text=>$probs{$l},    -style=>$data_style);
  };
  $energies{lines} -> selectionClear;
  $energies{lines} -> anchorClear;


  my $is_gas = ($elem =~ /\b(Ar|Cl|H|He|Kr|N|Ne|O|Rn|Xe)\b/);

##   $data{'abs_Absorption Length'} = '';
##   $data{'abs_Transmitted Fraction'}       = '';
##   my $bail = 0;
##   if ($data{abs_energy} and $in_resource) {
##     if ((lc($data{resource}) eq "henke") and ($data{abs_energy} > 30000)) {
##       my $dialog =
## 	$top -> Dialog(-bitmap         => 'info',
## 		       -text           => "The Henke tables only include data up to 30 keV.",
## 		       -title          => 'Hephaestus warning',
## 		       -buttons        => [qw/OK/],
## 		       -default_button => 'OK')
## 	  -> Show();
##       return;
##     };
##     if (($data{abs_energy} < $data{abs_odd_value}) and ($data{units} eq "Energies")) {
##       my $dialog = $top -> DialogBox(-title=>"Hephaestus warning!",
## 				     -buttons=>['OK', 'Cancel'],);
##       $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
## 		     "You have chosen a very low energy.  Should I$/" .
## 		     "try to calculate the absorption length?$/" .
## 		     "(There might be no data at that energy!)",)
## 	-> pack(-side=>'left');
##       my $answer = $dialog -> Show;
##       ($answer eq 'Cancel') and $bail = 1;
##     } elsif (($data{abs_energy} > $data{abs_odd_value}) and ($data{units} eq "Wavelengths")) {
##       my $dialog = $top -> DialogBox(-title=>"Hephaestus warning!",
## 				     -buttons=>['OK', 'Cancel'],);
##       $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
## 		     "You have chosen a very large wavelnegth.  Should I$/" .
## 		     "try to calculate the absorption length?$/" .
## 		     "(There might be no data at that wavelength!)",)
## 	-> pack(-side=>'left');
##       my $answer = $dialog -> Show;
##       ($answer eq 'Cancel') and $bail = 1;
##     };
##     unless ($bail) {
##       my $conv   = Xray::Absorption -> get_conversion($elem);
##       ($data{units} eq "Wavelengths") and $data{abs_energy} = &e2l($data{abs_energy});
##       my $barns  = Xray::Absorption -> cross_section($elem, $data{abs_energy}, $data{xsec});
##       ($data{units} eq "Wavelengths") and $data{abs_energy} = &e2l($data{abs_energy});
##       my $factor = ($is_gas) ? 1 : 10000;
##       my $abslen = ($conv and $barns and $density) ?
## 	$factor/($barns*$density/$conv) : 0;
##       $data{'abs_Absorption Length'} = '';
##       if ($abslen) {
## 	$data{'abs_Absorption Length'}  = 	sprintf "%8.2f", $abslen;
## 	$data{'abs_Absorption Length'} .= ($is_gas) ? ' cm' : ' µm';
## 	$data{'abs_Absorption Length'} =~ s/^\s+//;
##       };
##
##       $data{'abs_Transmitted Fraction'} = '';
##       ##print join("  ", $conv, $barns, $density, $thickness, $abslen, $is_gas, $/);
##       if ($data{abs_thickness} and $abslen) {
## 	my $factor = $data{abs_thickness} / $abslen;
## 	$data{'abs_Transmitted Fraction'} = sprintf ("%6.4g", exp(-1 * $factor));
##       };
##     };
##   };

  ## and disable writing in the entry widgets once again
  #map {$_ -> configure(-state=>'disabled')} @all_entries;

  ## set items on formulas and data utilities
  return if ($current eq "data");
  get_chemical_data($elem);
  return 0;
};

sub l_filter {
  my $elem = $_[0];
  return q{} if (get_Z($elem) > 98);
  my $en = Xray::Absorption -> get_energy($elem, 'la1') + 3*$data{abs_linewidth};
  my $filter = q{};
  foreach (@{$data{k_list}}) {
    $filter = $_->[0];
    last if ($_->[2] >= $en);
  };
  my $result = get_Z($filter);
  ++$result if ($result == 36);
  return $result;
};

sub plot_filter {
  my $znum = get_Z($data{abs_filter});
  if (not $znum) {
    $data{abs_entry} -> configure(-background=>'indianred1');
    return;
  };
  $data{abs_entry} -> configure(-background=>$bgcolor);
  my $e  = ($data{abs_Number} < 57) ? "K"   : "L3";
  my $l1 = ($data{abs_Number} < 57) ? "Ka1" : "Lb2";
  my $l2 = ($data{abs_Number} < 57) ? "Ka2" : "La1";
  my $l3 = ($data{abs_Number} < 57) ? q{}   : "La2";
  my $l1key = ($data{abs_Number} < 57) ? "K \\ga1" : "L \\gb2";
  my $l2key = ($data{abs_Number} < 57) ? "K \\ga2" : "L \\ga1";
  my $l3key = ($data{abs_Number} < 57) ? q{}       : "L \\ga2";
  my ($edge_energy, $e1, $e2) = (Xray::Absorption -> get_energy($data{abs_Number}, $e),
				 Xray::Absorption -> get_energy($data{abs_Number}, $l1),
				 Xray::Absorption -> get_energy($data{abs_Number}, $l2));
  my ($h1, $h2) = (Xray::Absorption -> get_intensity($data{abs_Number}, $l1),
		   Xray::Absorption -> get_intensity($data{abs_Number}, $l2));
  my ($e3, $h3) = (0, 0);
  ($e3 = Xray::Absorption -> get_energy($data{abs_Number}, $l3)) if $l3;
  ($h3 = Xray::Absorption -> get_intensity($data{abs_Number}, $l3)) if $l3;
  my $third = q{};
  if ($l3) {
    $third  = "set line.3 = $h3*300*gauss(f1f2.energy, $e3, $data{abs_linewidth})\n";
    $third .= "plot(f1f2.energy, line.3, key='$data{abs_Symbol} $l3key')\n";
  };

  my ($emin, $emax, $z) = ($e2-400, $edge_energy+300, $znum);
  my $commands = "
f1f2.energy = range($emin, $emax, 10)
f1f2(energy=f1f2.energy, z=$z, width=-2)
newplot(f1f2.energy, f1f2.f2, key='$data{abs_filter} filter', title='Filter plot', xlabel='Energy (eV)', ylabel='filter and lines', key_x=0.15)
set line.1 = $h1*300*gauss(f1f2.energy, $e1, $data{abs_linewidth})
set line.2 = $h2*300*gauss(f1f2.energy, $e2, $data{abs_linewidth})
plot(f1f2.energy, line.1, key='$data{abs_Symbol} $l1key')
plot(f1f2.energy, line.2, key='$data{abs_Symbol} $l2key')
$third
set top = ceil(f1f2.f2)*1.2
plot_arrow(x1=$edge_energy, y1=0, x2=$edge_energy, y2=top, no_head=1)
plot_text(x=$edge_energy+10, y=1, text='  $data{abs_Symbol} $e edge')
";
  Ifeffit::ifeffit($commands);
};


sub highlight_lines {
  my ($edge, $position) = @_;
  clear_lines_styles();
  my @label_style_params  = ('text', -font=>$config{fonts}{small}, -anchor=>'center', -foreground=>'blue4', -background=>$acolor);
  my @data_style_params = ('text', -font=>$config{fonts}{small}, -anchor=>'e', -foreground=>'black', -background=>$acolor);
  my $label_style  = $energies{lines} -> ItemStyle(@label_style_params);
  my $data_style   = $energies{lines} -> ItemStyle(@data_style_params);
  foreach my $e (@LINELIST) {
    my $iupac = Xray::Absorption->get_IUPAC($e);
    my $is_m45 = ( ($edge =~ m{M[45]}) and ($e eq 'Mz') );
    next if ((not $is_m45) and ($iupac !~ m{$edge\-}));
    map {$energies{lines} -> itemConfigure($e, $_, -style=>$label_style) } (0, 1);
    map {$energies{lines} -> itemConfigure($e, $_, -style=>$data_style) } (2, 3);
  }
};
sub clear_lines_styles {
  my ($lines) = @_;
  my @label_style_params  = ('text', -font=>$config{fonts}{small}, -anchor=>'center', -foreground=>'blue4', -background=>$bgcolor);
  my @data_style_params = ('text', -font=>$config{fonts}{small}, -anchor=>'e', -foreground=>'black', -background=>$bgcolor);
  my $label_style  = $energies{lines} -> ItemStyle(@label_style_params);
  my $data_style   = $energies{lines} -> ItemStyle(@data_style_params);
  foreach my $e (@LINELIST) {
    map {$energies{lines} -> itemConfigure($e, $_, -style=>$label_style) } (0, 1);
    map {$energies{lines} -> itemConfigure($e, $_, -style=>$data_style) } (2, 3);
  };
};
