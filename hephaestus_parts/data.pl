#! /usr/bin/perl -w

## ===========================================================================
##  This is the chemical data portion of hephaestus

sub data {
  $periodic_table -> pack(-side=>'top', -padx=>4, -pady=>4, -fill=>'x')
    if $current !~ /$uses_periodic_regex/;
  switch({page=>"data", text=>'Periodic Table of Chemical Data'});
  $data{pt_resource} -> gridForget;
};


sub setup_data {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');


  tie %kalzium, 'Config::IniFiles', (-file=>File::Spec->catfile($hephaestus_lib, 'kalziumrc'));

  my $r = 0;
  foreach my $l ('Name', 'Number', 'Symbol', 'Atomic Weight',
		 'Orbit Configuration', 'Oxidation states', 'Mossbauer') {
    my $ll = ($l =~ /Orbit/) ? 'Orbital Configuration' : $l;
    $frame -> Label(-text=>$ll, @label_args)
      -> grid(-column=>0, -row=>$r, -sticky=>'e', -padx=>4);
    $frame -> Label(-textvariable=>\$data{"data_$l"}, -font=>$config{fonts}{smfixed}, -width=>20, -justify=>'left')
      -> grid(-column=>1, -row=>$r, -sticky=>'w');
    ++$r;
  };
  $frame -> Label(-width=>5)
      -> grid(-column=>2, -row=>$r);
  $r = 0;
  foreach my $l ('Melting Point', 'Boiling Point', 'Electronegativity',
		 'Ionization Energy', '2nd Ion. Energy',
		 'Atomic Radius') {
    $frame -> Label(-text=>$l, @label_args)
      -> grid(-column=>3, -row=>$r, -sticky=>'e', -padx=>4);
    $frame -> Label(-textvariable=>\$data{"data_$l"}, -font=>$config{fonts}{smfixed}, -width=>20, -justify=>'left')
      -> grid(-column=>4, -row=>$r, -sticky=>'w');
    ++$r;
  };

  return $frame;
};


sub get_chemical_data {
  my $s = $_[0];
  my $z = get_Z($_[0]);
  $data{data_Name}                  = get_name($s);
  $data{data_Number}                = $z;
  $data{data_Symbol}                = $s;
  $data{'data_Atomic Weight'}	    = $kalzium{$z}{Weight};
  $data{'data_Orbit Configuration'} = $kalzium{$z}{Orbits};
  $data{'data_Oxidation states'}    = $kalzium{$z}{Ox};
  $data{'data_Melting Point'}	    = $kalzium{$z}{MP} ? $kalzium{$z}{MP} . ' K' : "";
  $data{'data_Boiling Point'}	    = $kalzium{$z}{BP} ? $kalzium{$z}{BP} . ' K' : "";
  $data{'data_Electronegativity'}   = $kalzium{$z}{EN};
  $data{'data_Ionization Energy'}   = $kalzium{$z}{IE}  ? $kalzium{$z}{IE} . ' eV' : "";
  $data{'data_2nd Ion. Energy'}	    = $kalzium{$z}{IE2} ? $kalzium{$z}{IE2} . ' eV' : "";
  $data{'data_Atomic Radius'}	    = $kalzium{$z}{AR}  ? $kalzium{$z}{AR}/100 . ' Ang' : "";
  $data{'data_Mossbauer'}           = join(",", split(" ",  $kalzium{$z}{Mossbauer}));

  ## set items on formulas utility
  $data{form_string}  = $s;
  $data{form_density} = Xray::Absorption -> get_density($s);
  $data{form_type}    = "Density";
  $data{form_density_units} -> configure(-text=>'gram/cm^3');
  $data{form_add_button}    -> configure(-state=>'normal');
  $data{form_remove_button} -> configure(-state=>'normal');

  ## set items on absorption utility
  return if ($current eq "absorption");
  get_foils_data($s);
  return 0;
};
