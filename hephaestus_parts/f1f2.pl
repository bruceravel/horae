
## ===========================================================================
##  This is the anomolous scattering portion of hephaestus


sub f1f2 {
  $periodic_table -> pack(-side=>'top', -padx=>4, -pady=>4, -fill=>'x') 
    if $current !~ /$uses_periodic_regex/;
  switch({page=>"f1f2", text=>'Periodic Table of Complex Scattering Factors'});
  $data{pt_resource} -> gridForget;
};

sub setup_f1f2 {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  $data{f1f2_emin}  ||= 3000;
  $data{f1f2_emax}  ||= 7000;
  $data{f1f2_egrid} ||= 5;
  $data{f1f2_width} = 0;
  $data{f1f2_plot}  = 'new';
  $data{f1f2_function} = 'both';
  $data{f1f2_naturalwidth} = 1;

  my $fr = $frame -> Frame() -> pack(-side=>'top', -pady=>3);
  $fr -> Label(-text=>'Starting energy', @label_args,)
    -> pack(-side=>'left');
  $fr -> Entry(-width=>12,
	       -textvariable=>\$data{f1f2_emin},
	       -validate=>'key', -validatecommand=>\&set_variable)
    -> pack(-side=>'left', -padx=>4);
  $fr -> Label(-text=>'Ending energy', @label_args,)
    -> pack(-side=>'left');
  $fr -> Entry(-width=>12,
	       -textvariable=>\$data{f1f2_emax},
	       -validate=>'key', -validatecommand=>\&set_variable)
    -> pack(-side=>'left', -padx=>4);
  $fr -> Label(-text=>'Energy grid', @label_args,)
    -> pack(-side=>'left');
  $fr -> Entry(-width=>12,
	       -textvariable=>\$data{f1f2_egrid},
	       -validate=>'key', -validatecommand=>\&set_variable)
    -> pack(-side=>'left', -padx=>4);

  $fr = $frame -> Frame() -> pack(-side=>'top', -pady=>3);
  my $w_label = $fr -> Label(-text=>'Convolution with',
			     -font=>$config{fonts}{small},
			     -foreground=>'grey50',)
    -> pack(-side=>'left');
  my $w_entry = $fr -> Entry(-width=>12,
			     -foreground=>'grey50',
			     -textvariable=>\$data{f1f2_width},
			     (($Tk::VERSION > 804) ? (-disabledbackground=>$bgcolor) : ()),
			     -validate=>'key',
			     -validatecommand=>[\&set_variable, 'width'],
			     -state=>'disabled')
    -> pack(-side=>'left', -padx=>4);
  $fr -> Checkbutton(-text=>'Convolute by the natural core-level width',
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_naturalwidth},
		     -command=>sub{$w_label->configure(-foreground => ($data{f1f2_naturalwidth}) ? 'grey50'   : 'blue4');
				   $w_entry->configure(-state      => ($data{f1f2_naturalwidth}) ? 'disabled' : 'normal',
						       -foreground => ($data{f1f2_naturalwidth}) ? 'grey50'   : 'black' );
				 })
    -> pack(-side=>'left');

  $fr = $frame -> Frame() -> pack(-side=>'top', -pady=>3);
  $fr -> Radiobutton(-text=>'New plot',
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_plot},
		     -value=>'new')
    -> grid(-column=>0, -row=>0, -sticky=>'w');
  $fr -> Radiobutton(-text=>'Overplot',
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_plot},
		     -value=>'over')
    -> grid(-column=>0, -row=>1, -sticky=>'w');

  $fr -> Label(-width=>5)
    -> grid(-column=>1, -row=>1);

  $fr -> Radiobutton(-text=>"Plot just f\'",
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_function},
		     -value=>'f1')
    -> grid(-column=>2, -row=>0, -sticky=>'w');
  $fr -> Radiobutton(-text=>"Plot just f\"",
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_function},
		     -value=>'f2')
    -> grid(-column=>2, -row=>1, -sticky=>'w');
  $fr -> Radiobutton(-text=>"Plot both f' and f\"",
		     -font=>$config{fonts}{small},
		     -variable=>\$data{f1f2_function},
		     -value=>'both')
    -> grid(-column=>2, -row=>2, -sticky=>'w');

  $fr = $frame -> Frame() -> pack(-side=>'top', -pady=>3);
  $data{f1f2_save} = $fr -> Button(-text=>"Save data", @button_args,
				   -width=>20,
				   -state=>'disabled')
    -> pack();

  return $frame;
};


sub get_f1f2_data {
  my $z = get_Z($_[0]);
  my $w = ($data{f1f2_naturalwidth}) ? '-2' : $data{f1f2_width};
  Ifeffit::ifeffit("f1f2.energy = range($data{f1f2_emin},$data{f1f2_emax},$data{f1f2_egrid})\n");
  Ifeffit::ifeffit("f1f2(energy=f1f2.energy, z=$z, width=$w)\n");
  my $plot = ($data{f1f2_plot} eq 'new') ? "newplot" : "plot";
  if ($data{f1f2_function} eq 'f1') {
    my $key = "$_[0] f1";
    Ifeffit::ifeffit("$plot(f1f2.energy, f1f2.f1, xmin=$data{f1f2_emin}, xmax=$data{f1f2_emax}, xlabel=\"Energy (eV)\", ylabel=f1, key=\"$key\")\n");
    Ifeffit::ifeffit("plot(title=\"Complex scattering factors\")\n");
  } elsif ($data{f1f2_function} eq 'f2') {
    my $key = "$_[0] f2";
    Ifeffit::ifeffit("$plot(f1f2.energy, f1f2.f2, xmin=$data{f1f2_emin}, xmax=$data{f1f2_emax}, xlabel=\"Energy (eV)\", ylabel=f2, key=\"$key\")\n");
    Ifeffit::ifeffit("plot(title=\"Complex scattering factors\")\n");
  } else {
    my $key = "$_[0] f1";
    Ifeffit::ifeffit("$plot(f1f2.energy, f1f2.f1, xmin=$data{f1f2_emin}, xmax=$data{f1f2_emax}, xlabel=\"Energy (eV)\", ylabel=\"f1 and f2\", key=\"$key\")\n");
    $key = "$_[0] f2";
    Ifeffit::ifeffit( "plot(f1f2.energy, f1f2.f2, xmin=$data{f1f2_emin}, xmax=$data{f1f2_emax}, xlabel=\"Energy (eV)\", ylabel=\"f1 and f2\", key=\"$key\")\n");
    Ifeffit::ifeffit("plot(title=\"Complex scattering factors\")\n");
  };
  my $sym = get_symbol($z);
  $data{f1f2_save} -> configure(-text=>"Save data for $sym",
				-command=>[\&save_f1f2, $sym, $data{f1f2_function},
					   $data{f1f2_emin}, $data{f1f2_emax},
					   $data{f1f2_egrid}],
				-state=>'normal');
};

sub save_f1f2 {
  my ($sym, $which, $emin, $emax, $egrid) = @_;
  my $types = [['Scattering factor files', '*.f1f2'], ['All Files', '*'],];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialfile=>lc($sym).".f1f2",
				 -initialdir=>$save_dir,
				 -title => "Hephaestus: Save f1f2 data");
  return unless ($file);

  $save_dir = dirname($file);
  my $command;
  my $ifeffit_version = (split(" ", Ifeffit::get_string("\$&build")))[0];
  Ifeffit::put_string("f1f2_title1","Hephaestus $VERSION, Ifeffit $ifeffit_version");
  if ($which eq 'f1') {
    Ifeffit::put_string("f1f2_title2","f1 data for $sym");
    $command = "write_data(file=$file, \$f1f2_title*, f1f2.energy, f1f2.f1)";
  } elsif ($which eq 'f2') {
    Ifeffit::put_string("f1f2_title2","f2 data for $sym");
    $command = "write_data(file=$file, \$f1f2_title*, f1f2.energy, f1f2.f2)";
  } else {
    Ifeffit::put_string("f1f2_title2","f1 and f2 data for $sym");
    $command = "write_data(file=$file, \$f1f2_title*, f1f2.energy, f1f2.f1, f1f2.f2)";
  };
  Ifeffit::put_string("f1f2_title3","computed between $emin and $emax on a $egrid eV grid");
  Ifeffit::ifeffit($command);
};
