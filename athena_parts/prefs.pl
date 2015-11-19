## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  Athena's preferences dialog


sub prefs {

  my %prefs_params = ();
  &read_config(\%prefs_params);

  #$Data::Dumper::Indent = 2;
  #print Data::Dumper->Dump([\%prefs_params], [qw/prefs_params/]);
  #$Data::Dumper::Indent = 0;



  $fat_showing = 'prefs';
  $hash_pointer = \%prefs_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $prefs = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$prefs -> packPropagate(0);
  $which_showing = $prefs;

  $prefs_params{save} = 0;
  $prefs -> Label(-text=>"Edit Preferences",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  my $labframe = $prefs -> LabFrame(-label=>'All parameters',
				    -foreground=>$config{colors}{activehighlightcolor},
				    -labelside=>'acrosstop')
    -> pack(-side=>'left', -expand=>1, -fill=>'both');
  my $tree;
  $tree = $labframe -> Scrolled('Tree',
				-scrollbars => 'se',
				-width	    => 15,
				-background => $config{colors}{hlist},
				-browsecmd  => sub{&browse_variable($tree, \%prefs_params)},
				  )
    -> pack(-expand=>1, -fill=>'both');
  $tree->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					    ($is_windows) ? () : (-width=>8));
  $tree->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					    ($is_windows) ? () : (-width=>8));

  $prefs -> Button(-text=>'Return to the main window',  @button_list,
		   -background=>$config{colors}{background2},
		   -activebackground=>$config{colors}{activebackground2},
		   -command=>sub{
		     my $response = 'No';
		     if ($prefs_params{save}) {
		       my $message = ($prefs_params{save} eq -1) ?
			 "You have applied the preferences, but have not saved them for future sessions.  Would you like to save your new preference selections?" :
			   "Would you like to apply and save your new preference selections?";
		       my $dialog =
			 $top -> Dialog(-bitmap         => 'questhead',
					-text           => $message,
					-title          => 'Athena: preferences...',
					-buttons        => ["Apply", "Apply and save", "Return"],
					-default_button => 'Return');
		       $response = $dialog->Show(-popover => 'cursor');
		     }
		     &prefs_apply(\%prefs_params) if ($response =~ /Apply/);
		     &prefs_save(\%prefs_params)  if ($response =~ /Save/);
		     &reset_window($prefs, "preferences", 0);
		     Echo("Your preferences were applied and saved to $personal_rcfile")
		       if ($response =~ /(Apply|Save)/);
		   })
    -> pack(-side=>'bottom', -fill=>'x');
  $prefs_params{future} = $prefs -> Button(-text=>'Save changes for future sessions',  @button_list,
					   -state=>'disabled',
					   -command=>sub{
					     &prefs_apply(\%prefs_params); &prefs_save(\%prefs_params);
					     $prefs_params{apply} ->configure(-state=>'disabled');
					     $prefs_params{future}->configure(-state=>'disabled');
					   } )
    -> pack(-side=>'bottom', -fill=>'x');
  $widget{prefs_future} = $prefs_params{future};
  $prefs_params{apply} = $prefs -> Button(-text=>'Apply changes to this session',  @button_list,
					  -state=>'disabled',
					  -command=>sub{
					    &prefs_apply(\%prefs_params);
					    $prefs_params{apply} ->configure(-state=>'disabled');
					  } )
    -> pack(-side=>'bottom', -fill=>'x');
  $widget{prefs_apply} = $prefs_params{apply};



  my $frame = $prefs -> Frame(-relief=>'flat')
    -> pack(-side=>'right', -expand=>1, -fill=>'both');

  $prefs_params{parameter_label} = $frame -> Label(-text=>'Parameter:  ',
						   -font=>$config{fonts}{small},
						   -justify=>'right',
						   -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $prefs_params{parameter} = $frame -> Label(-text=>'',
					     -font=>$config{fonts}{small},
					     -justify=>'left')
    -> grid(-row=>0, -column=>1, -sticky=>'ew');
  $frame -> Label(-text=>'Type:  ',
		  -font=>$config{fonts}{small},
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $prefs_params{type} = $frame -> Label(-text=>'',
					-font=>$config{fonts}{small},
					-width=>1,
					-justify=>'left')
    -> grid(-row=>1, -column=>1, -sticky=>'ew');
  $frame -> Label(-text=>"Athena's Default:  ",
		  -font=>$config{fonts}{small},
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $prefs_params{default} = $frame -> Label(-text=>'',
					   -font=>$config{fonts}{small},
					   -justify=>'left')
    -> grid(-row=>2, -column=>1, -sticky=>'ew');
  $frame -> Label(-text=>'Value:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $prefs_params{values} = $frame -> Label(-text=>'',
					  -font=>$config{fonts}{small},
					  -justify=>'left')
    -> grid(-row=>3, -column=>1, -sticky=>'ew');
  $labframe = $frame -> LabFrame(-label=>'Description',
				 -foreground=>$config{colors}{activehighlightcolor},
				 -labelside=>'acrosstop')
    -> grid(-row=>4, -column=>0, -columnspan=>2, -sticky=>'nsew',);

  $prefs_params{description} = $labframe -> Scrolled('ROText', -scrollbars=>'oe',
						     -wrap=>'word',
						     -font=>$config{fonts}{small},
						     -width=>1, -height=>18)
    -> pack(-expand=>1, -fill=>'both');
  $prefs_params{description} ->
    Subwidget("yscrollbar") ->
      configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));
  $widget{prefs_all} =
  $frame -> Button(-text=>"Set ALL params to Athena's defaults",  @button_list,
		   -command=>[\&prefs_restore_all, \%prefs_params, $tree])
    -> grid(-row=>5, -column=>0, -columnspan=>2, -sticky=>'ew');
  disable_mouse3($prefs_params{description}->Subwidget('rotext'));
  $prefs_params{description} -> tagConfigure('descr', -rmargin=>2, -spacing1=>1,
					     -lmargin1=>2, -lmargin2=>2,);
  $prefs_params{description} -> tagConfigure('warn', -rmargin=>2, -spacing1=>1,
					     -lmargin1=>2, -lmargin2=>2,
					     -foreground=>'red3',);
  $prefs_params{description} -> tagConfigure('units', -rmargin=>2, -spacing1=>1,
					     -lmargin1=>2, -lmargin2=>2,
					     -foreground=>'green4',);
  $prefs_params{description} -> tagConfigure('restart', -rmargin=>2, -spacing1=>1,
					     -lmargin1=>2, -lmargin2=>2,
					     -foreground=>'darkviolet',);

  foreach my $s (@{$prefs_params{order}}) {
    $tree -> add($s, -text=>$s);
    foreach my $v (@{$prefs_params{$s}{order}}) {
      my $this = $s.".".$v;
      $tree -> add($this, -text=>$v);
      $tree -> setmode($this, 'none');
      $prefs_params{$s}{$v}{new} = $config{$s}{$v};
    };
    $tree -> setmode($s, 'close');
    $tree -> close($s);

  };
  $tree->autosetmode();

  ## save, so it can be unbound if changed (this is the global variable)
  $user_key = $config{general}{user_key};

  $top -> update;
};


sub browse_variable {
  my ($tree, $rhash) = @_;
  my $this = $tree->infoAnchor;
  return unless $this;
  my ($s, $v) = split(/\./, $this);

  my $frame = $$rhash{values}->parent;
  return unless $s;
  unless ($v) {
    $$rhash{parameter_label} -> configure(-text=>"Section:  ");
    $$rhash{parameter}   -> configure(-text=>$s);
    $$rhash{type}        -> configure(-text=>"");
    $$rhash{default}     -> configure(-text=>"");
    $$rhash{description} -> delete(qw(1.0 end));
    $$rhash{description} -> insert('end', $$rhash{$s}{description}, 'descr');
    $$rhash{default} -> gridForget();
    $$rhash{default} = $frame -> Label(-text=>'', -justify=>'left')
      -> grid(-row=>2, -column=>1, -padx=>2, -sticky=>'ew');
    $$rhash{values} -> gridForget();
    $$rhash{values} = $frame -> Label(-text=>'',)
      -> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
    #$tree -> open($this) if ($tree->getmode($this) eq 'open');
    return;
  };

  $$rhash{values} -> gridForget();
  ##$$rhash{values} -> bind('<Any-KeyPress>');
  $$rhash{parameter_label} -> configure(-text=>"Parameter:  ");
  $$rhash{parameter} -> configure(-text=>$v);
  $$rhash{type}      -> configure(-text=>$$rhash{$s}{$v}{type});
  $$rhash{default} -> gridForget();
  $$rhash{default} = $frame -> Button(-text=>"", -borderwidth=>1,
				      -command=>sub{
					## restore the default value
					$$rhash{$s}{$v}{new} = $$rhash{$s}{$v}{default};
					$$rhash{$s}{$v}{new} = $$rhash{$s}{$v}{windows}
					  if (exists $$rhash{$s}{$v}{windows} and $is_windows);
					if ($$rhash{$s}{$v}{type} eq 'boolean') {
					  $$rhash{$s}{$v}{new} = ($$rhash{$s}{$v}{new} eq 'true') ? $$rhash{$s}{$v}{onvalue} : 0;
					} elsif ($$rhash{$s}{$v}{type} eq 'keypress') {
					  $$rhash{values} -> delete(0, 'end');
					  $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
					};
					$$rhash{save} = 1;
					$$rhash{apply} ->configure(-state=>'normal');
					$$rhash{future}->configure(-state=>'normal');
					## and make sure it is displayed properly
					$tree -> KeyboardBrowse;
				      })
    -> grid(-row=>2, -column=>1, -padx=>2, -sticky=>'ew');
  if (exists $$rhash{$s}{$v}{windows} and $is_windows) {
    $$rhash{default}   -> configure(-text=>$$rhash{$s}{$v}{windows});
  } else {
    $$rhash{default}   -> configure(-text=>$$rhash{$s}{$v}{default});
  };
  #$$rhash{parameter} -> configure(-text=>$v);
  $$rhash{description} -> delete(qw(1.0 end));
  $$rhash{description} -> insert('end', $$rhash{$s}{$v}{description}, 'descr');
  if ($s eq 'fonts') {
    my $rcfile = $groups{"Default Parameters"} -> find('athena', 'rc_personal');
    $$rhash{description} -> insert('end', "\n\nFonts cannot currently be changed interactively.  You will need to edit $rcfile by hand.", 'warn');
  } elsif ($$rhash{$s}{$v}{type} eq 'color') {
    $$rhash{description} -> insert('end', "\n\nPress the colored \"Value\" button to change this color.", 'descr');
  } elsif ($$rhash{$s}{$v}{type} eq 'regex') {
    $$rhash{description} -> insert('end', "\n\nThis parameter must be a valid Perl regular expression.", 'warn');
  };

  ##$$rhash{description} -> insert('end', "\n\nMost color changes (with the exception of the \"current\" color) do not take effect until the next time Athena is started.  That will be fixed in a future version of Athena.", 'descr')
  ##  if ($s eq 'colors');

  $$rhash{description} -> insert('end', "\n\nThe units of this parameter are $$rhash{$s}{$v}{units}.", 'units')
    if (exists $$rhash{$s}{$v}{units});
  $$rhash{description} -> insert('end', "\n\nYou must restart Athena to see the effect of changing this parameter.", 'restart')
    if (exists $$rhash{$s}{$v}{restart} and (not (($s eq 'fonts') or ($$rhash{$s}{$v}{type} eq 'font'))));

  $$rhash{description} -> insert('end', "\n\nPress the \"Default\" button to restore Athena's default value for this variable.", 'descr');

 SWITCH: {
    ($$rhash{$s}{$v}{type} eq 'string') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_string, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'regex') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_string, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'real') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_real, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };
    ## need to set the save flag
    ($$rhash{$s}{$v}{type} eq 'positive integer') and do {
      $$rhash{values} = $frame -> NumEntry(-width	 => 4,
					   -orient	 => 'horizontal',
					   -foreground	 => $config{colors}{foreground},
					   -textvariable => \$$rhash{$s}{$v}{new},
					   -minvalue	 => $$rhash{$s}{$v}{minint}||0,
					   -maxvalue	 => $$rhash{$s}{$v}{maxint},
					   -browsecmd	 => [\&prefs_modified, $rhash],
					   -command	 => [\&prefs_modified, $rhash],
					  )
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'w');
      $$rhash{values} -> configure( -value=>$$rhash{$s}{$v}{new});
      ## crufty solution to the lack of a callback for NumEntry
      $$rhash{apply}  -> configure(-state=>'normal');
      $$rhash{future} -> configure(-state=>'normal');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'list') and do {
      my @vals = split(" ", $$rhash{$s}{$v}{values});
      $$rhash{values} = $frame -> Optionmenu(-font=>$config{fonts}{small},
					     -borderwidth=>1,
					     -textvariable=>\$$rhash{$s}{$v}{new}
					     )
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      foreach my $vl (@vals) {
	$$rhash{values} -> command(-label => $vl,
				   -command=>sub{$$rhash{$s}{$v}{new}=$vl;
						 $$rhash{save} = 1;
						 $$rhash{apply} ->configure(-state=>'normal');
						 $$rhash{future}->configure(-state=>'normal');
					       } );
      };
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'boolean') and do {
      $$rhash{values} = $frame -> Checkbutton(-text=>$v,
					      -onvalue=>$$rhash{$s}{$v}{onvalue},
					      -offvalue=>$$rhash{$s}{$v}{offvalue}||0,
					      -selectcolor=> $config{colors}{single},
					      -variable=>\$$rhash{$s}{$v}{new},
					      -command=>
					      sub{
						$$rhash{apply} ->configure(-state=>'normal');
						$$rhash{future}->configure(-state=>'normal');
						$$rhash{save} = 1;
					      })
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'keypress') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -justify=>'center')
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> bind('<Any-KeyPress>' => sub
			      {
				my($c) = @_;
				my $e = $c->XEvent;
				my $keysym = $e->K;
				$$rhash{$s}{$v}{new} = $keysym;
				$$rhash{values} -> delete(0, 'end');
				$$rhash{values} -> insert('end', $keysym);
				$$rhash{save} = 1;
				$$rhash{apply} ->configure(-state=>'normal');
				$$rhash{future}->configure(-state=>'normal');
			      });
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'color') and do {
      my $color = $$rhash{$s}{$v}{new};
      my ($r, $g, $b) = $frame -> rgb($color);
      #print join(" ", $color, $r, $g, $b), $/;
      my $acolor = sprintf("#%4.4x%4.4x%4.4x", int($r*0.85), int($g*0.85), int($b*0.85));
      ($acolor = "#300030003000") if ($acolor eq "#000000000000");
      #print $acolor, $/;
      $$rhash{values} = $frame -> Button(-background=>$color,
					 -activebackground=>$acolor,
					 -borderwidth=>1,
					 -command=>sub{
					   my $color = "";
					   #$top->Busy(-recurse=>1);
					   $color = $$rhash{values}->chooseColor(-initialcolor=>$$rhash{$s}{$v}{new});
					   #$top->Unbusy;
					   return unless defined($color);
					   $$rhash{values}->configure(-background=>$color,
								      -activebackground=>$color);
					   $$rhash{$s}{$v}{new}=$color;
					   $$rhash{save} = 1;
					   $$rhash{apply} ->configure(-state=>'normal');
					   $$rhash{future}->configure(-state=>'normal');
					 })
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'font') and do {
      $$rhash{values} = $frame -> Button(-foreground=>'black',
					 -borderwidth=>1,
					 -text=>'abc ABC 123',
					 -font=>$$rhash{$s}{$v}{new},
					 -command=>sub{Error("Changing fonts interactively is not yet supported.  You can edit ".$groups{'Default Parameters'} -> find('athena', 'rc_personal')." by hand.")})
	-> grid(-row=>3, -column=>1, -padx=>2, -sticky=>'ew');
      last SWITCH;
    };

  };
};


## validate command for a string type variable (no restrictions)
sub prefs_string {
  my ($k, $hash, $entry) = (shift, shift, shift);
  my ($s, $v) = split(/\./, $k);
  $$hash{$s}{$v}{new} = $entry;
  $$hash{save} = 1;
  $$hash{apply} ->configure(-state=>'normal');
  $$hash{future}->configure(-state=>'normal');
  #print join(" ", ">>>", $s, $v, $$hash{save}, $$hash{$s}{$v}, $/);
  return 1;
};
sub prefs_modified {
  my $hash = shift;
  $$hash{save} = 1;
  $$hash{apply} ->configure(-state=>'normal');
  $$hash{future}->configure(-state=>'normal');
  return 1;
};

## validate command for a real type variable (must be a +/-real)
sub prefs_real {
  my ($k, $hash, $entry) = (shift, shift, shift);
  my ($s, $v) = split(/\./, $k);
  #print join(" ", $s, $v, $entry, $hash, $/);
  ($entry =~ /^\s*$/) and ($entry = 0);	# error checking ...
  ($entry =~ /^\s*-$/) and return 1;	# error checking ...
  ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
  $$hash{$s}{$v}{new} = $entry;
  $$hash{save} = 1;
  $$hash{apply} ->configure(-state=>'normal');
  $$hash{future}->configure(-state=>'normal');
  #print join(" ", ">>>", $s, $v, $$hash{save}, $$hash{$s}{$v}, $/);
  return 1;
};

sub prefs_restore_all {
  my ($rhash, $tree) = @_;

  my $message = "Are you sure that you wish to restore ALL the default values, overwriting any configuration you may have already made to Athena?  Doing so will only restore them within this dialog.  You will then need to click the buttons below to apply or save the default values.";
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => $message,
		   -title          => 'Athena: preferences...',
		   -buttons        => [qw/Yes No/],
		   -default_button => 'Yes');
  my $response = $dialog->Show();
  unless ($response eq 'Yes') {
    return;
  };
  foreach my $s (@{$$rhash{order}}) {
    foreach my $v (@{$$rhash{$s}{order}}) {
      $$rhash{$s}{$v}{new} = $$rhash{$s}{$v}{default};
      $$rhash{$s}{$v}{new} = $$rhash{$s}{$v}{windows}
	if (exists $$rhash{$s}{$v}{windows} and $is_windows);
      if ($$rhash{$s}{$v}{type} eq 'boolean') {
	$$rhash{$s}{$v}{new} = ($$rhash{$s}{$v}{new} eq 'true') ? $$rhash{$s}{$v}{onvalue} : 0;
      };
    };
  };
  $$rhash{save} = 1;
  $$rhash{apply} ->configure(-state=>'normal');
  $$rhash{future}->configure(-state=>'normal');
  ## and make sure it is displayed properly
  $tree -> KeyboardBrowse;
  Echo("Restored ALL parameter defaults.  Click the apply or save buttons to use these defaults.");
};


sub prefs_apply {
  my $rhash = $_[0];

  my %old = (charsize => $config{plot}{charsize},
	     charfont => $config{plot}{charfont},
	     mru_display => $config{general}{mru_display},
	    );

  foreach my $s (@{$$rhash{order}}) {
    foreach my $v (@{$$rhash{$s}{order}}) {
      $config{$s}{$v} = $$rhash{$s}{$v}{new};
    };
  };
  $$rhash{save} = -1;

  ## certain parameters need to take effect immediately and so require
  ## some special care

  ## set various plotting defaults
  my @fclist;
  map {push @fclist, "color".$_, $config{plot}{'c'.$_}} (0 ..9);
  my $screen = ", fg=$config{plot}{fg}, bg=$config{plot}{bg}, ";
  $screen .= ($config{plot}{showgrid}) ? "grid, gridcolor=\"$config{plot}{grid}\"" : "nogrid";
  $setup -> SetDefault(screen=>$screen,
		       @fclist,
		       'showmarkers',        $config{plot}{showmarkers},
		       'marker',             $config{plot}{marker},
		       'markersize',         $config{plot}{markersize},
		       'markercolor',        $config{plot}{markercolor},
		       #'indicator',          $config{plot}{indicator},
		       'indicatorcolor',     $config{plot}{indicatorcolor},
		       'indicatorline',      $config{plot}{indicatorline},
		       'bordercolor',        $config{plot}{bordercolor},
		       'borderline',         $config{plot}{borderline},
		       'linetypes',          $config{plot}{linetypes},
		       'interp',             $config{general}{interp},);
  &set_key_params;
  ## set default analysis parameter values
  $setup -> SetDefault(bkg_kw	  => $config{bkg}{kw},
		       bkg_rbkg	  => $config{bkg}{rbkg},
		       bkg_pre1	  => $config{bkg}{pre1},
		       bkg_pre2	  => $config{bkg}{pre2},
		       bkg_nor1	  => $config{bkg}{nor1},
		       bkg_nor2	  => $config{bkg}{nor2},
		       bkg_nnorm  => $config{bkg}{nnorm},
		       bkg_spl1	  => $config{bkg}{spl1},
		       bkg_spl2	  => $config{bkg}{spl2},
		       bkg_nclamp => $config{bkg}{nclamp},
		       bkg_clamp1 => $config{bkg}{clamp1},
		       bkg_clamp2 => $config{bkg}{clamp2},
		       fft_arbkw  => $config{fft}{arbkw},
		       fft_dk	  => $config{fft}{dk},
		       fft_win	  => $config{fft}{win},
		       fft_kmin	  => $config{fft}{kmin},
		       fft_kmax	  => $config{fft}{kmax},
		       fft_pc	  => $config{fft}{pc},
		       bft_dr	  => $config{bft}{dr},
		       bft_win	  => $config{bft}{win},
		       bft_rmin	  => $config{bft}{rmin},
		       bft_rmax	  => $config{bft}{rmax},
		      );
  ## handle general.listside parameter
  &swap_panels unless
    (grep {$_ eq $config{general}{listside}} ($skinny -> packInfo()));
  ## deal with the toggle in the Merge menu
  $merge_weight = ($config{merge}{merge_weight} eq 'u') ? 'Weight by importance' : 'Weight by chi_noise';
  ## turn on/off the dispersive data conversion
  $data_menu -> menu -> entryconfigure(3, -state=>($config{pixel}{do_pixel_check}) ?
				       'normal' : 'disabled');
  ## handle general.projectbar parameter
  #if ($config{general}{projectbar} eq 'none') {
  #  $projectbar -> packForget;
  #} elsif ($config{general}{projectbar} eq 'file') {
  #  $project_label -> configure(-textvariable=>\$project_name);
  #  $projectbar -> pack(-side=>"top", -anchor=>'nw', -fill=>'x', -after=>$menubar)
  #};

  ## bring the edge step widget up to date
  $widget{bkg_step} -> configure(-increment=>$config{bkg}{step_increment});

  ## make sure that the default plot style is up to date
  foreach my $k (keys %plot_features) {
    next unless ($k =~ /^[ekqr](_|ma|mi)/);
    $plot_styles{default}{$k} = $plot_features{$k};
  };
  tied(%plot_styles) -> WriteConfig($groups{"Default Parameters"} -> find('athena', 'plotstyles'));
  $plot_features{smoothderiv} =$config{plot}{smoothderiv};


  ## user configured, user defined key sequences (yikes!)
  my $this_key = "<Control-" . $config{general}{user_key} . ">";
  my $old_key  = "<Control-" . $user_key . ">";
  $top -> bind($old_key, "");
  $top -> bind($this_key => [\&keys_dispatch, 'control']);
  $this_key = "<Meta-" . $config{general}{user_key} . ">";
  $old_key  = "<Meta-" . $user_key . ">";
  $top -> bind($old_key, "");
  $top -> bind($this_key => [\&keys_dispatch, 'meta']);
  $this_key = "<Alt-" . $config{general}{user_key} . ">";
  $old_key  = "<Alt-" . $user_key . ">";
  $top -> bind($old_key, "");
  $top -> bind($this_key => [\&keys_dispatch, 'meta']);

  &set_recent_menu if ($old{mru_display} ne $config{general}{mru_display});

  ## add any special handling of configuration parameters here
  $Ifeffit::Group::rmax_out = $config{fft}{rmax_out};
  $groups{"Default Parameters"} -> dispose("plot(charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})", $dmode)
    if (($old{charsize} != $config{plot}{charsize}) or ($old{charfont} != $config{plot}{charfont}));

  foreach (qw(slight weak medium strong rigid)) {
    $groups{"Default Parameters"} -> set_clamp(ucfirst($_), $config{clamp}{$_});
  };

  Echo("Applied new preferences to current session.");
};

sub prefs_save {
  my $rhash = $_[0];
  rename $personal_rcfile, $personal_rcfile.".bak";
  my $config_ref = tied %config;
  $config_ref -> WriteConfig($personal_rcfile);
  $$rhash{save} = 0;
  Echo("Saved preferences to \"$personal_rcfile\"");
};


sub read_config {
  my $rhash = $_[0];
  my $config_file = $groups{"Default Parameters"} -> find('athena', 'config');
  ##$config_file = "Ifeffit/lib/athena.config";
  return -1 unless (-e $config_file);

  $$rhash{order} = [];
  my ($current_section, $current_variable) = ("", "");
  Echo("Reading master configuration file ...");
  open C, $config_file or die "could not open $config_file for reading\n";
  while (<C>) {
    next if (/^\s*$/);		# blank line
    next if (/^\s*\#/);		# comment line
    chomp;
  SWITCH: {
      ## recognize a new section of variables
      (/^section=/) and do {
	my @line = split(/=/, $_);
	push @{$$rhash{order}}, $line[1];
	$$rhash{$line[1]} = {};
	$current_section = $line[1];
	last SWITCH;
      };
      ## read the description of the current section of variables
      (/^section_description/) and do {
	$$rhash{$current_section}{description} = "";
	my $next = <C>;
	while ($next !~ /^\s*$/) {
	  chomp $next;
	  $$rhash{$current_section}{description} .= substr($next, 1);
	  $next = <C>;
	};
	$$rhash{$current_section}{description} =
	  substr($$rhash{$current_section}{description}, 1);
	last SWITCH;
      };
      ## recognize a new variable
      (/^variable=/) and do {
	my @line = split(/=/, $_);
	push @{$$rhash{$current_section}{order}}, $line[1];
	$$rhash{$current_section}{$line[1]} = {};
	$current_variable = $line[1];
	last SWITCH;
      };
      ## read the description of the current variable
      (/^description/) and do {
	$$rhash{$current_section}{$current_variable}{description} = "";
	my $next = <C>;
	while ($next !~ /^\s*$/) {
	  chomp $next;
	  $next =~ s/^ *\.\s*$/\n\n\n/;
	  $next =~ s/^ *\./\n\n  /;
	  $$rhash{$current_section}{$current_variable}{description} .= substr($next, 1);
	  $next = <C>;
	};
	$$rhash{$current_section}{$current_variable}{description} =
	  substr($$rhash{$current_section}{$current_variable}{description}, 1);
	last SWITCH;
      };
      ## the type (i.e. string, boolean, etc) of the current variable
      (/^type=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{type} = $line[1];
	last SWITCH;
      };
      ## default value
      (/^default=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{default} = $line[1];
	last SWITCH;
      };
      ## list values
      (/^values=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{values} = $line[1];
	last SWITCH;
      };
      ## special treatment for windows
      (/^windows=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{windows} = $line[1];
	last SWITCH;
      };
      ## max value for a positive integer
      (/^maxint=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{maxint} = $line[1];
	last SWITCH;
      };
      ## min value for a positive integer
      (/^minint=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{minint} = $line[1];
	last SWITCH;
      };
      ## boolean for whether a font may be variable width
      (/^variable_width=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{variable_width} = $line[1];
	last SWITCH;
      };
      ## value for boolean true
      (/^onvalue=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{onvalue} = $line[1];
	last SWITCH;
      };
      ## value for boolean false if not 0
      (/^offvalue=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{offvalue} = $line[1];
	last SWITCH;
      };
      ## restart required
      (/^restart=/) and do {
	my @line = split(/=/, $_);
	($line[1] = 0) if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{restart} = $line[1];
	last SWITCH;
      };
      ## parameter units
      (/^units=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{units} = $line[1];
	last SWITCH;
      };
      ## callback string for list or boolean
      (/^callback=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{callback} = $line[1];
	last SWITCH;
      };
    };
  };

  close C;
  Echo("Reading master configuration file ... done!");

};
