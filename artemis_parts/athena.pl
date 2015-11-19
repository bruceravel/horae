# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## READING ATHENA PROJECT FILES IN ARTEMIS


sub read_athena {

  my $prjfile = $_[0];

#   my $was_mac = $paths{data0} ->
#     fix_mac($prjfile, $stash_dir, lc($config{general}{mac_eol}), $top);
#   Echo("Fixed EOL characters for \"$prjfile\".") if ($was_mac == 1);
#   return, Echo("Skipped \"$prjfile\" due to EOL characters.") if ($was_mac == -1);

  my ($tmp, $text);
  my $orig = $prjfile;
  my $athena_fh = gzopen($prjfile, "rb") or die "could not open $prjfile as an Athena project\n";
  ##open(ORIG, "< $prjfile")
  ##  or die "Can't open $prjfile for reading: $!";

  track({file=>$prjfile, mode=>"reading from", command=>sub{my $size = -s $prjfile; print "size : $size\n"}}) if $debug_file_path;

  ##my $athena_fh = *ORIG;
  my @athena_index = ();
  my %athena_group = ();
  my $nline = 0;
  my $line = q{};
  my $cpt = new Safe;
  ##while (<ORIG>) {
  while ($athena_fh->gzreadline($line) > 0) {
    ++$nline;
    next unless ($line =~ /^\$old_group/);
    push @athena_index, $nline;
    ## need to make a map to the groups by old group name so that
    ## background removal with a standard can be performed correctly
    $ {$cpt->varglob('old_group')} = $cpt->reval( $line );
    my $og = $ {$cpt->varglob('old_group')};
    $athena_group{$og} = {index=>$nline, hlist=>0};
  };
  $athena_fh->gzclose();
  ##close ORIG;


  $ath_params{plot}   ||= 'chir_mag';
  $ath_params{params} ||= "project";
  map {$_ -> configure(-state=>'disabled')}
    ($gsd_menu, $feff_menu, $paths_menu, $data_menu, $sum_menu, $fit_menu); #, $settings_menu);
  $edit_menu -> menu -> entryconfigure(13, -state=>'disabled');
 SWITCH: {
    $opparams  -> packForget(), last SWITCH if ($current_canvas eq 'op');
    $gsd       -> packForget(), last SWITCH if ($current_canvas eq 'gsd');
    $feff      -> packForget(), last SWITCH if ($current_canvas eq 'feff');
    $path      -> packForget(), last SWITCH if ($current_canvas eq 'path');
    $logviewer -> packForget(), last SWITCH if ($current_canvas eq 'logview');
  };
  $current_canvas = 'athena';

  my $ath = $fat -> Frame(-relief=>'flat',
			  -borderwidth=>0,
			  -highlightcolor=>$config{colors}{background})
    -> pack(-fill=>'both', -expand=>1);

  my $frm = $ath -> Frame() -> pack(-side=>'top', -anchor=>'w', -padx=>6);

  $frm -> Label(-text=>"Athena project ", @title2)
    -> pack(-side=>'left', -anchor=>'w', -padx=>4);
  $frm -> Label(-textvariable=>\$orig,
		-foreground=>$config{colors}{button})
    -> pack(-side=>'right', -anchor=>'e');


  $widgets{athena_return} = $ath -> Button(-text=>'Cancel and return to the main window',  @button3_list,
					   #-background=>$config{colors}{background},
					   #-activebackground=>$config{colors}{activebackground},
					   -command=>sub{$ath->packForget;
							 $current_canvas = "";
							 $edit_menu -> menu -> entryconfigure(13, -state=>'normal');
							 &display_properties;
							 Echo("Restored normal view");
						       })
    -> pack(-side=>'bottom', -fill=>'x');

  my $labframe = $ath -> LabFrame(-label=>'Athena records',
				  -labelside=>'acrosstop',
				  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left', -fill=>'y', -anchor=>'w');
  my $hlist;
  $hlist = $labframe -> Scrolled('HList',
				 -scrollbars=>'osoe',
				 -columns=>1,
				 -header=>0,
				 -selectmode=>'single',
				 -width=>20,
				 -background=>'white',
				 -selectbackground=>$config{colors}{selected},
				 -browsecmd=>sub{athena_plot($hlist, $prjfile, \%athena_group)},
				)
    -> pack(-expand=>1, -fill=>'y');
  $hlist->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					     ($is_windows) ? () : (-width=>8));
  $hlist->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					     ($is_windows) ? () : (-width=>8));

  $labframe = $ath -> Frame()
    -> pack(-side=>'right', -expand=>1, -fill=>'both', -anchor=>'n');

  $widgets{help_athena} = $labframe
    -> Button(-text => "Document: Importing Athena project data", @button2_list,
	      -command=>sub{pod_display("artemis_athena.pod")},
	      -width=>65)
    -> pack(-side=>'bottom', -fill=>'x', -padx=>2, -pady=>2);


  my $fr = $labframe -> LabFrame(-label=>'Titles',
				 -labelside=>'acrosstop',
				 -foreground=>$config{colors}{activehighlightcolor})
     -> pack(-side=>'top', -fill=>'x', -padx=>0, -pady=>0);
  $widgets{athena_selected} = $fr;
  $widgets{athena_titles} =  $fr -> Scrolled('ROText',
					     -scrollbars => 'soe',
					     -wrap       => 'none',
					     -height     => 8,)
    -> pack();
  $widgets{athena_titles}->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
							      ($is_windows) ? () : (-width=>8));
  $widgets{athena_titles}->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
							      ($is_windows) ? () : (-width=>8));


  my @radio_args = (-foreground       => $config{colors}{activehighlightcolor},
		    -activeforeground => $config{colors}{activehighlightcolor},
		    -selectcolor      => $config{colors}{check},
		    -font	      => $config{fonts}{med},
		    -variable	      => \$ath_params{plot},
		    -command	      => sub{athena_plot($hlist, $prjfile, \%athena_group)});

  $fr = $labframe -> LabFrame(-label=>'Plot as ... ',
			      -labelside=>'acrosstop',
			      -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'both', -pady=>4);
  $fr -> Radiobutton(-text => 'chi(k)',     @radio_args, -value => 'chi', )
    -> grid(-row=>0, -column=>0, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => '|chi(R)|',   @radio_args, -value => 'chir_mag',)
    -> grid(-row=>0, -column=>1, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => '|chi(q)|',   @radio_args, -value => 'chiq_mag', )
    -> grid(-row=>0, -column=>2, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => 'Re[chi(R)]', @radio_args, -value => 'chir_re', )
    -> grid(-row=>1, -column=>1, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => 'Re[chi(q)]', @radio_args, -value => 'chiq_re', )
    -> grid(-row=>1, -column=>2, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => 'Im[chi(R)]', @radio_args, -value => 'chir_im', )
    -> grid(-row=>2, -column=>1, -padx=>2, -sticky=>'w');
  $fr -> Radiobutton(-text => 'Im[chi(q)]', @radio_args, -value => 'chiq_im', )
    -> grid(-row=>2, -column=>2, -padx=>2, -sticky=>'w');


  $fr = $labframe -> Frame()
    -> pack(-side=>'top', -fill=>'x', -pady=>4, -padx=>4);
  $fr -> Radiobutton(-text	       =>"Use parameters from Athena project",
		     -foreground       => $config{colors}{activehighlightcolor},
		     -activeforeground => $config{colors}{activehighlightcolor},
		     -selectcolor      => $config{colors}{check},
		     -font	       => $config{fonts}{med},
		     -variable	       => \$ath_params{params},
		     -value	       => 'project' )
    -> pack(-side =>'top', -anchor=>'w');
  $fr -> Radiobutton(-text	       =>"Use default parameters",
		     -foreground       => $config{colors}{activehighlightcolor},
		     -activeforeground => $config{colors}{activehighlightcolor},
		     -selectcolor      => $config{colors}{check},
		     -font	       => $config{fonts}{med},
		     -variable	       => \$ath_params{params},
		     -value	       => 'default' )
    -> pack(-side=>'top', -anchor=>'w');


  $labframe -> Button(-text=>"Import these data",
		      @button3_list,
		      -command=>sub{
			$ath->packForget;
			$current_canvas = "";
			$edit_menu -> menu -> entryconfigure(13, -state=>'normal');
			athena_import($hlist, $prjfile, $orig, $ath_params{params});
		      })
    -> pack(-side=>'top', -fill=>'x', -pady=>10, -padx=>4);



  my @groups = ();
  my @group_lines = ();
  my $old_group = "";
  my $line_number = 1;

  #foreach my $i (@athena_index) {
  foreach my $g (sort {$athena_group{$a}{index} <=> $athena_group{$b}{index}} keys(%athena_group)) {
    my $i = $athena_group{$g}{index};
    my %args = athena_get_array($prjfile, $i, "args");
    $args{label} =~ s{[\"\']}{}g;
    next unless ($args{is_xmu} or $args{is_chi});
    $hlist -> add($i, -data=>$i);
    $hlist -> itemCreate($i, 0, -text=>$args{label});
    $athena_group{$g}{hlist} = $i;
  };
  $hlist -> anchorSet($athena_index[0]);
  $hlist -> selectionSet($athena_index[0]);
  athena_plot($hlist, $prjfile, \%athena_group);

## set_fit_button('fit');

};

## This is, perhaps, a bit slow.  It reads linearly through an athena
## project file until it finds the specified group, then it imports
## the requested array.

## arg 0 is the project file name
## arg 1 is the line in the file with that record (already found)
## arg 2 is one of: args x y stddev i0
sub athena_get_array {
  my ($prjfile, $index, $which) = @_;
  my $cpt = new Safe;
  my @array;
  my $prj = gzopen($prjfile, "rb") or die "could not open $prjfile as an Athena project\n";
  ##open A, $prjfile;
  my $count = 0;
  my $found = 0;
  my $re = '@' . $which;
  my $line = q{};
  ##foreach my $line (<A>) {
  while ($prj->gzreadline($line) > 0) {
    ++$count;
    $found = 1 if ($count == $index);
    next unless $found;
    last if ($line =~ /^\[record\]/);
    if ($line =~ /^$re/) {
      @ {$cpt->varglob('array')} = $cpt->reval( $line );
      @array = @ {$cpt->varglob('array')};
      last;
    };
  };
  $prj->gzclose();
  ##close A;
  return @array;
};





sub athena_plot {

  $top -> Busy;
  my $n = $_[0]->info('anchor');
  my $i = $_[0]->info('data', $n);
  my $prjfile = $_[1];
  my $r_athena_group = $_[2];
  my $noplot = $_[3];
  my $gname = "a___thena" ;
  if ($noplot) {
    $n = $r_athena_group->{$noplot}->{hlist};
    $i = $_[0]->info('data', $n);
    $gname = "st___andard";
  };

  ## get the args hash
  my %args = athena_get_array($prjfile, $i, "args");
  $args{fft_kw} ||= 2;

  ## get the x- and y-axis arrays
  my @x = athena_get_array($prjfile, $i, "x");
  @x = map {$_ + $args{bkg_eshift}} @x;
  my @y = athena_get_array($prjfile, $i, "y");

  my %clamp = ("None" => 0, "Slight" => 3, "Weak" => 6, "Medium" =>12, "Strong" => 24, "Rigid" => 96);
  my $title = $args{label};
  $widgets{athena_selected}  -> configure(-label=>"Header lines for " . $title);

  $widgets{athena_titles} -> delete(qw(1.0 end));
  foreach my $l (@{$args{titles}}) {
    $widgets{athena_titles} -> insert('end', $l.$/);
  };

  $paths{data0}->dispose("erase \@group $gname\n");
  $paths{data0}->dispose("##\n## reading Athena record \"$title\" into group $gname:", $dmode);
  $paths{data0}->dispose("set \&status=0", $dmode);
  if ($args{is_xmu}) {
    Ifeffit::put_array($gname.".energy", \@x);
    Ifeffit::put_array($gname.".xmu", \@y);
    #Ifeffit::ifeffit("newplot($gname.energy, $gname.xmu)\n");
    #print join(" ", %args), $/;
    #sleep 5;
    $args{bkg_clamp1} = $clamp{$args{bkg_clamp1}};
    $args{bkg_clamp2} = $clamp{$args{bkg_clamp2}};

    my $stan_string = q{};
    if ($args{bkg_stan} ne 'None') {
      athena_plot($_[0], $_[1], $r_athena_group, $args{bkg_stan});
      $stan_string = "k_std=st___andard.k, chi_std=st___andard.chi, ";
      ## need to remove background function from standard if standard
      ## is mu(E) data!
    };

    my $spline  = "$gname.energy, $gname.xmu, e0=$args{bkg_e0}, ";
    $spline    .= "rbkg=$args{bkg_rbkg}, kmin=$args{bkg_spl1}, ";
    $spline    .= "kmax=$args{bkg_spl2}, kweight=$args{bkg_kw}, ";
    $spline    .= "dk=$args{bkg_dk}, kwindow=$args{bkg_win}, pre1=$args{bkg_pre1}, ";
    $spline    .= "pre2=$args{bkg_pre2}, norm1=$args{bkg_nor1}, norm2=$args{bkg_nor2}, ";
    $spline    .= "clamp1=$args{bkg_clamp1}, clamp2=$args{bkg_clamp2}, nclamp=5, ";
    $spline    .= $stan_string;
    $spline    .= "interp=quad)\n";
    $spline     = wrap("spline(", "       ", $spline);
    ## remove the background and plot the data
    Echo("Removing background from Athena record \"$title\"");
    $paths{data0}->dispose($spline, $dmode);
    my $status = Ifeffit::get_scalar('&status');
    $paths{data0}->dispose($spline, $dmode) if ($status > 1);
    #Ifeffit::ifeffit("newplot($gname.k, $gname.k*$gname.chi)\n");
    #sleep 5;
    $paths{data0}->dispose("set \&status=0", $dmode);
  } else {
    Ifeffit::put_array("$gname.k", \@x);
    Ifeffit::put_array("$gname.chi", \@y);
  };

  $top -> Unbusy, return if $noplot;
  my ($plot, $sp);
  ## plot this in k-space
  if ($ath_params{plot} eq 'chi') {
    my $ylabel = "";
  SWITCH: {
      $ylabel = '\\gx(k)',                last SWITCH if ($args{fft_kw} == 0);
      $ylabel = 'k\\gx(k) (\\A\\u-1\\d)', last SWITCH if ($args{fft_kw} == 1);
      $ylabel = 'k\\u' . $args{fft_kw} . '\\d\\gx(k) (\\A\\u-' . $args{fft_kw} . '\\d)';
    };
    $plot  = "a___thena.k, a___thena.chi*a___thena.k**$args{fft_kw}, title=$title, ";
    $plot .= "xlabel=\"k (\\A\\u-1\\d)\", ylabel=\"$ylabel\", ";
    $plot .= "xmin=$plot_features{kmin}, xmax=$plot_features{kmax})\n";
    $plot = wrap("newplot(", "        ", $plot);
    $sp = 'k';

  ## fft then plot this in R-space
  } elsif ($ath_params{plot} =~ /chir/) {
    my $ylabel = '';
  SWITCH: {
      $ylabel = sprintf("|\\gx(R)| (\\A\\u-%s\\d)",   $plot_features{kweight}+1),
	  last SWITCH if ($ath_params{plot} =~ /mag$/);
      $ylabel = sprintf("Re[\\gx(R)] (\\A\\u-%s\\d)", $plot_features{kweight}+1),
	  last SWITCH if ($ath_params{plot} =~ /re$/);
      $ylabel = sprintf("Im[\\gx(R)] (\\A\\u-%s\\d)", $plot_features{kweight}+1),
	  last SWITCH if ($ath_params{plot} =~ /im$/);
    };
    my $fft   = "a___thena.chi, k=a___thena.k, kweight=$plot_features{kweight}, ";
    $fft     .= "kmin=$args{fft_kmin}, kmax=$args{fft_kmax}, ";
    $fft     .= "dk=$args{fft_dk}, kwindow=$args{fft_win})\n";
    $fft      = wrap("fftf(", "     ", $fft);
    $paths{data0}->dispose($fft, $dmode);
    $plot  = "a___thena.r, a___thena.$ath_params{plot}, title=$title, ";
    $plot .= "xlabel=\"R (\\A)\", ylabel=\"$ylabel\", style=lines, ";
    $plot .= "xmin=$plot_features{rmin}, xmax=$plot_features{rmax})\n";
    $plot  = wrap("newplot(", "        ", $plot);
    $sp = 'R';

  ## fft, bft, then plot this in q-space
  } else {
    my $ylabel = '';
  SWITCH: {
      $ylabel = sprintf("|\\gx(q)| (\\A\\u-%s\\d)",   $plot_features{kweight}),
	  last SWITCH if ($ath_params{plot} =~ /mag$/);
      $ylabel = sprintf("Re[\\gx(q)] (\\A\\u-%s\\d)", $plot_features{kweight}),
	  last SWITCH if ($ath_params{plot} =~ /re$/);
      $ylabel = sprintf("Im[\\gx(q)] (\\A\\u-%s\\d)", $plot_features{kweight}),
	  last SWITCH if ($ath_params{plot} =~ /im$/);
    };
    my $fft   = "a___thena.chi, k=a___thena.k, kweight=$plot_features{kweight}, ";
    $fft     .= "kmin=$args{fft_kmin}, kmax=$args{fft_kmax}, ";
    $fft     .= "dk=$args{fft_dk}, kwindow=$args{fft_win})\n";
    $fft      = wrap("fftf(", "     ", $fft);
    $paths{data0}->dispose($fft, $dmode);
    my $bft   = "real=a___thena.chir_re, imag=a___thena.chir_im, ";
    $bft     .= "rmin=$args{bft_rmin}, rmax=$args{bft_rmax}, ";
    $bft     .= "dr=$args{bft_dr}, rwindow=$args{bft_win})\n";
    $bft      = wrap("fftr(", "     ", $bft);
    $paths{data0}->dispose($bft, $dmode);
    $plot  = "a___thena.q, a___thena.$ath_params{plot}, title=$title, ";
    $plot .= "xlabel=\"q (\\A\\u-1\\d)\", ylabel=\"$ylabel\", ";
    $plot .= "xmin=$plot_features{qmin}, xmax=$plot_features{qmax})\n";
    $plot  = wrap("newplot(", "        ", $plot);
    $sp = 'q';
  };


  Echo("Plotting Athena record \"$title\"");
  $paths{data0}->dispose($plot, $dmode);

  Echo("This is Athena record \"$title\" plotted in $sp-space");
  $top -> Unbusy;
};

sub athena_import {

  my ($group, $response) = ("", "New");
  my @data = &every_data;
  if ($#data or $paths{$paths{$current}->data}->get('file')) {
    my $message = "Do you wish to read in a new data file (that is, to do multiple data set fitting), or do you wish to change the current data file (that is, to apply this fitting model to a different data set) ?";
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => $message,
		     -title          => 'Athena: Reading data',
		     -buttons        => [qw/Change New Cancel/],
		     -default_button => 'Change',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    $response = $dialog->Show();
    if ($response eq 'Cancel') {
      ## remove the index file
      my $indexname = File::Spec->catfile($project_folder, "tmp", "index");
      unlink $indexname if (-e $indexname);
      $group = $list->info('anchor') || 'data0';
      $current_canvas = "";
      $list->see($group);
      $list->anchorSet($group);
      &display_properties(0);
      Echo("Import of Athena record aborted");
      return;
    } elsif ($response eq 'Change') {
      Echo("Changing data ...");
    } else {
      Echo("Importing new data ...");
    };
  };

  $top->Busy;

  my $n = $_[0]->info('anchor');
  my $line = $_[0]->info('data', $n);
  my $how_params = $_[3];

  ## get the args hash
  my %args = athena_get_array($_[1], $line, "args");
  $args{fft_kw} ||= 2;
  $args{label} =~ s{[\"\']}{}g;

  my $i = 1;
  my $erase = "";
  foreach my $l (@{$args{titles}}) {
    Ifeffit::put_string("athena_title_$i",$l);
    $erase .= "erase \$athena_title_$i\n";
    ++$i;
  };
  (my $fname = $args{label}) =~ s/[.,:@&\/\\ ]/_/g;
  my $file = File::Spec->catfile($project_folder, "chi_data", $fname.".chi");
  $paths{data0}->dispose("write_data(file=$file,\n           a___thena.k, a___thena.chi, \$athena_title_*)", $dmode);
  if ($args{is_xmu}) {
    my $file = File::Spec->catfile($project_folder, "chi_data", $fname.".xmu");
    $paths{data0}->dispose("write_data(file=$file,\n           a___thena.energy, a___thena.xmu, \$athena_title_*)", $dmode);
  };

  $group = ($response eq 'Change') ?
    read_data($paths{$current}->data, $file, 1) :
      read_data(0, $file, 1);

  if ($args{is_chi}) {
    $paths{$group} -> make(is_xmu=>0, is_chi=>1);
  } else {
    $paths{$group} -> make(is_xmu=>1, is_chi=>0);
  };
  if ($how_params eq 'project') {		# use project parameters
    Echo("Setting parameters to values from Athena project");
    my $rmin = $args{bft_rmin};
    ($rmin = $args{bkg_rbkg}) if ($args{bkg_rbkg} > $args{bft_rmin});
    $paths{$group} -> make(kmin	       => $args{fft_kmin},
			   kmax	       => $args{fft_kmax},
			   dk	       => $args{fft_dk},
			   kwindow     => $args{fft_win},
			   rmin	       => $rmin,
			   rmax	       => $args{bft_rmax},
			   dr	       => $args{bft_dr},
			   rwindow     => $args{bft_win},
			   lab	       => $args{label},
			   k1	       => 0,
			   k2	       => 0,
			   k3	       => 0,
			   fs_absorber => $args{bkg_z},
			   fs_edge     => $args{fft_edge},
			  );
    $paths{$group} -> make(k1 => 1) if ($config{data}{kweight} == 1);
    $paths{$group} -> make(k2 => 1) if ($config{data}{kweight} == 2);
    $paths{$group} -> make(k3 => 1) if ($config{data}{kweight} == 3);
    $paths{$group} -> make(k2 => 1) if not (   $paths{$group}->get('k1')
					    or $paths{$group}->get('k2')
					    or $paths{$group}->get('k3'));
  } elsif ($response eq 'Change') { # replacing data, maintain params
    Echo("Maintaining parameter values from previous data");
    $paths{$group} -> make(lab	       => $args{label});
  } else { 			# new data, use artemis defaults
    Echo("Setting parameters to Artemis default values");
    $paths{$group} -> make(kmin        => $config{data}{kmin},
			   kmax        => $config{data}{kmax},
			   dk          => $config{data}{dk},
			   k1          => ($config{data}{kweight} == 1),
			   k2          => ($config{data}{kweight} == 2),
			   k3          => ($config{data}{kweight} == 3),
			   rmin        => $config{data}{rmin},
			   rmax        => $config{data}{rmax},
			   dr          => $config{data}{dr},
			   kwindow     => $config{data}{kwindow},
			   rwindow     => $config{data}{rwindow},
			   lab	       => $args{label},
			   fs_absorber => $args{bkg_z},
			   fs_edge     => $args{fft_edge},
			  );

    # interpret the range parameters
    if ($paths{$group}->get('kmax') == 0) {
      $paths{$group}->make(kmax=>15);
      my ($epsk, $epsr, $suggest) = $paths{$group}->chi_noise;
      $suggest ||= 15;
      $paths{$group}->make(kmax=>$suggest);
    };
    $paths{$group} -> fix_values();

  };
  ## parameters for the mu(E) tab
  if ($paths{$group}->get("is_xmu")) {
    foreach my $k (qw(e0 eshift kw rbkg dk pre1 pre2 nor1 nor2 spl1 spl2
	              slope int step fitted_step fixstep nc0
		      nc1 nc2 flatten stan clamp1 clamp2)) {
      $paths{$group} -> make("bkg_".$k => $args{"bkg_".$k});
    };
    $paths{$group} -> make(do_xmu=>1, is_xmu=>1);
  };
  $list -> itemConfigure($group, 0, -text=>$args{label});
  populate_op($group);
  $plot_features{kweight} = $args{fft_kw};
  plot('r', 0);
  ##--bkg-- $widgets{data_notebook} -> raise('chi');
  ##--bkg-- $widgets{data_notebook} -> pageconfigure('bkg', -state=>'normal') if $paths{$group}->get('is_xmu');

  ## push the athena project onto the MRU list
  &push_mru($_[2], 1, "athena");

  ## remove the index file
  my $indexname = File::Spec->catfile($project_folder, "tmp", "index");
  unlink $indexname if (-e $indexname);

  ## clean up ifeffit
  $paths{$group}->dispose($erase, $dmode);
  $paths{$group}->dispose("erase \@group a___thena\n", $dmode);

  $top->Unbusy;
  project_state(0);
  Echo("Imported Athena record \"$args{label}\"");
};


## sub build_index {
##   my $data_file  = shift;
##   my $index_file = shift;
##   my $offset     = 0;
##
##   while (<$data_file>) {
##     print $index_file pack("N", $offset);
##     $offset = tell($data_file);
##   }
## }
##
## # usage: line_with_index(*DATA_HANDLE, *INDEX_HANDLE, $LINE_NUMBER)
## # returns line or undef if LINE_NUMBER was out of range
## sub line_with_index {
##   my $data_file   = shift;
##   my $index_file  = shift;
##   my $line_number = shift;
##
##   my $size;			# size of an index entry
##   my $i_offset;			# offset into the index of the entry
##   my $entry;			# index entry
##   my $d_offset;			# offset into the data file
##
##   $size = length(pack("N", 0));
##   $i_offset = $size * ($line_number-1);
##   seek($index_file, $i_offset, 0) or return;
##   read($index_file, $entry, $size);
##   $d_offset = unpack("N", $entry);
##   seek($data_file, $d_offset, 0);
##   return scalar(<$data_file>);
## }


sub clear_athena {
  foreach my $k (qw(e0 eshift kw rbkg pre1 pre2 nor1 nor2 spl1 spl2 step)) {
    my $key = "bkg_".$k;
    $widgets{$key} -> configure(-validate=>'none');
    $widgets{$key} -> delete(qw(0 end));
    $widgets{$key} -> configure(-validate=>'key');
  };
  $temp{bkg_fixstep} = 0;
  $temp{bkg_flatten} = 1;
  $temp{bkg_clamp2}  = 'None';
};

##  END OF THE ATHENA SUBSECTION

