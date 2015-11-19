# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### preferences subsystem
###===================================================================

sub prefs {

  my %prefs_params = ();
  &read_config(\%prefs_params);

  #$Data::Dumper::Indent = 2;
  #print Data::Dumper->Dump([\%prefs_params], [qw/prefs_params/]);
  #$Data::Dumper::Indent = 0;



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
  $current_canvas = 'prefs';

  my $prefs = $fat -> Frame(-relief=>'flat',
			    -borderwidth=>0,
			    -highlightcolor=>$config{colors}{background})
    -> pack(-expand=>1, -fill=>'both');


  $prefs_params{save} = 0;
  $prefs -> Label(-text	       => "Edit Preferences",
		  @title2,
		  -background  => $config{colors}{background2},
		  -borderwidth => 2,
		  -relief      => 'groove',
		  -anchor      => 'center')
    -> pack(-side=>'top', -anchor=>'w', -padx=>0, -fill=>'x');


  my $labframe = $prefs -> LabFrame(-label=>'All parameters',
				    -labelside=>'acrosstop')
    -> pack(-side=>'left', -expand=>1, -fill=>'both');
  my $tree;
  $tree = $labframe -> Scrolled('Tree', -scrollbars=>'se', -width=>15,
				-background=>'white',
				-browsecmd=>sub{&browse_variable($tree, \%prefs_params)},
				  )
    -> pack(-expand=>1, -fill=>'both');
  $tree->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
  $tree->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});

  $prefs -> Button(-text=>'Return to the main window',  @button3_list,
		   #-background=>$config{colors}{background},
		   #-activebackground=>$config{colors}{activebackground},
		   -command=>sub{
		     my $response = 'No';
		     if ($prefs_params{save}) {
		       my $message = ($prefs_params{save} eq -1) ?
			 "You have applied the preferences, but have not saved them for future sessions.  Would you like to save your new preference selections?" :
			   "Would you like to apply and save your new preference selections?";
		       my $dialog =
			 $top -> Dialog(-bitmap         => 'questhead',
					-text           => $message,
					-title          => 'Artemis: preferences...',
					-buttons        => [qw/Yes No/],
					-default_button => 'Yes',
					-font           => $config{fonts}{med},
					-popover        => 'cursor');
		       &posted_Dialog;
		       $response = $dialog->Show();
		     }
		     if ($response eq 'Yes') {
		       &prefs_apply(\%prefs_params);
		       &prefs_save(\%prefs_params);
		     };
		     Echo("Your preferences were applied and saved to $personal_rcfile")
		       if ($response eq 'Yes');
		     $prefs->packForget;
		     $current_canvas = "";
		     $edit_menu -> menu -> entryconfigure(13, -state=>'normal');
		     &display_properties;
		     Echo("Restored normal view") unless ($response eq 'Yes');
		   })
    -> pack(-side=>'bottom', -fill=>'x');
  $prefs_params{future} = $prefs -> Button(-text=>'Save changes for future sessions',  @button2_list,
					   -state=>'disabled',
					   -command=>sub{
					     &prefs_apply(\%prefs_params);
					     &prefs_save(\%prefs_params);
					     $prefs_params{apply} ->configure(-state=>'disabled');
					     $prefs_params{future}->configure(-state=>'disabled');
					   } )
    -> pack(-side=>'bottom', -fill=>'x');
  $prefs_params{apply} = $prefs -> Button(-text=>'Apply changes to this session',  @button2_list,
					  -state=>'disabled',
					  -command=>sub{
					    &prefs_apply(\%prefs_params);
					    $prefs_params{apply} ->configure(-state=>'disabled');
					  } )
    -> pack(-side=>'bottom', -fill=>'x');
  ## need a restore all values button


  my $frame = $prefs -> Frame(-relief=>'flat')
    -> pack(-side=>'right');#, -fill=>'both');

  my $subfr = $frame -> Frame()
    -> pack(-side=>'top');
  $prefs_params{parameter_label} = $subfr -> Label(-text=>'Parameter:  ',
						   -justify=>'right',
						   -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $prefs_params{parameter} = $subfr -> Label(-text=>'', -justify=>'left')
    -> grid(-row=>0, -column=>1, -sticky=>'ew');
  $subfr -> Label(-text=>'Type:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $prefs_params{type} = $subfr -> Label(-text=>'', -width=>15, -justify=>'left')
    -> grid(-row=>1, -column=>1, -sticky=>'ew');
  $subfr -> Label(-text=>"Artemis' Default:  ",
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $prefs_params{default} = $subfr -> Label(-text=>'', -justify=>'left')
    -> grid(-row=>2, -column=>1, -sticky=>'ew');
  $subfr -> Label(-text=>'Value:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $prefs_params{values} = $subfr -> Label(-text=>'', -justify=>'left')
    -> grid(-row=>3, -column=>1, -sticky=>'ew');


  $frame -> Button(-text=>"Set ALL parameters to Artemis' defaults",  @button2_list,
		   -command=>[\&prefs_restore_all, \%prefs_params, $tree])
    -> pack(-side=>'bottom', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);

  $labframe = $frame -> LabFrame(-label=>'Description', -labelside=>'acrosstop')
    -> pack(-side=>'top', -expand=>1, -fill=>'both');
  $prefs_params{description} = $labframe -> Scrolled('ROText', -scrollbars=>'oe',
						     -wrap=>'word',
						     #-width=>35, -height=>15
						    )
    -> pack(-expand=>1, -fill=>'both');
  $prefs_params{description}->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
  &disable_mouse3($prefs_params{description}->Subwidget('rotext'));
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
    ##next if (($s eq 'Histogram') and ($use_histo));
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

  ##Echo("Showing preferences dialog");
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
      -> grid(-row=>2, -column=>1, -sticky=>'ew');
    $$rhash{values} -> gridForget();
    $$rhash{values} = $frame -> Label(-text=>'',)
      -> grid(-row=>3, -column=>1, -sticky=>'ew');
    return;
  };

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
					};
					$$rhash{save} = 1;
					$$rhash{apply} ->configure(-state=>'normal');
					$$rhash{future}->configure(-state=>'normal');
					## and make sure it is displayed properly
					$tree -> KeyboardBrowse;
				      })
    -> grid(-row=>2, -column=>1, -sticky=>'ew');

  my ($small, $med) = ($config{fonts}{small}, $config{fonts}{med});
  $$rhash{default}   -> configure(-font=>($$rhash{$s}{$v}{type} eq 'folder') ?
				  $small : $med);
  if (exists $$rhash{$s}{$v}{windows} and $is_windows) {
    $$rhash{default}   -> configure(-text=>$$rhash{$s}{$v}{windows});
  } else {
    $$rhash{default}   -> configure(-text=>$$rhash{$s}{$v}{default});
  };
  if ($$rhash{$s}{$v}{type} eq 'folder') {
    my $text = $$rhash{default} -> cget('-text');
    ($text = substr($text, 0, 7) . "..." . substr($text, -7)) if (length($text) > 15);
    $$rhash{default} -> configure(-text=>$text);
  };

  #$$rhash{parameter} -> configure(-text=>$v);
  $$rhash{description} -> delete(qw(1.0 end));
  $$rhash{description} -> insert('end', $$rhash{$s}{$v}{description}, 'descr');
  if (($s eq 'fonts') or ($$rhash{$s}{$v}{type} eq 'font')) {
    my $rcfile = $setup -> find('artemis', 'rc_personal');
    $$rhash{description} -> insert('end', "\n\nFonts cannot currently be changed interactively.  You will need to edit $rcfile by hand.", 'warn');
  ##} elsif (($s eq 'gds') and ($$rhash{$s}{$v}{type} eq 'color')) {
  ##  $$rhash{description} -> insert('end', "\n\nColor changes on the parameters page will take effect the next time you start Artemis.", 'warn');
  } elsif ($$rhash{$s}{$v}{type} eq 'color') {
    $$rhash{description} -> insert('end', "\n\nPress the colored \"Value\" button to change this color.", 'descr');
  } elsif ($$rhash{$s}{$v}{type} eq 'regex') {
    $$rhash{description} -> insert('end', "\n\nThis parameter must be a valid Perl regular expression if the match_as parameter is set to \"perl\".", 'warn');
  };

  $$rhash{description} -> insert('end', "\n\nColor changes do not currently take effect until the next time Artemis is started.  That will eventually be fixed.", 'descr')
    if ($s eq 'colors');

  if (($s eq 'general') and ($v eq 'workspace')) {
    $$rhash{description} -> insert('end', "\n\nThe current project will be deleted when you change this parameter.  If you want to change this parameter, you should first return to the main menu and save your current project.\n", 'warn');
    $$rhash{description} -> insert('end', "\n\nThe fully resolved path is currently\n$$rhash{$s}{$v}{new}", 'descr');
  };
  $$rhash{description} -> insert('end', "\n\nThe units of this parameter are $$rhash{$s}{$v}{units}", 'units')
    if (exists $$rhash{$s}{$v}{units});
  $$rhash{description} -> insert('end', "\n\nYou must restart Artemis to see the effect of changing this parameter.", 'restart')
    if (exists $$rhash{$s}{$v}{restart} and (not (($s eq 'fonts') or ($$rhash{$s}{$v}{type} eq 'font'))));

  $$rhash{description} -> insert('end', "\n\nPress the \"Default\" button to restore Artemis' default value for this variable.", 'descr');

  $$rhash{values} -> gridForget();
 SWITCH: {

    ($$rhash{$s}{$v}{type} eq 'string') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_string, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'regex') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_string, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'folder') and do {
      my $text = $$rhash{$s}{$v}{new};
      ($text = substr($text, 0, 7) . "..." . substr($text, -7)) if (length($text) > 15);
      $$rhash{values} = $frame -> Button(-foreground=>'black',
					 -borderwidth=>1,
					 -text=>$text,
					 -font=>$config{fonts}{small},
					 -command=>
					 sub{
					   my $dir;
					   if ($Tk::VERSION < 804) {
					     $top -> Dialog(-bitmap  => 'error',
							    -text    => "Changing folders using this dialog requires perl/Tk 804.  You are using perl/Tk $Tk::VERSION.",
							    -title   => 'Artemis: Unable to change folders',
							    -buttons => ['OK'],
							    -font           => $config{fonts}{med},
							    -default_button => "OK", )
					       -> Show();
					     return;
					   #  $dir = $top -> DirSelect(-width=>40, -dir=>$$rhash{$s}{$v}{new},
						#		      -title=> "Artemis: Select a directory",
						#		      -text => "Select the path to your workspace",
						#		     ) -> Show;
					   } else {
					     $dir = $top -> chooseDirectory;
					   };
					   return unless ($dir and (-d $dir));
					   $$rhash{$s}{$v}{new}=$dir;
					   ($dir = substr($dir, 0, 7) . "..." . substr($dir, -7)) if (length($dir) > 15);
					   $$rhash{values}->configure(-text=>$dir);
					   $$rhash{save} = 1;
					   $$rhash{apply} ->configure(-state=>'normal');
					   $$rhash{future}->configure(-state=>'normal');
					 })
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'file') and do {
      my $text = $$rhash{$s}{$v}{new};
      ($text = substr($text, 0, 7) . "..." . substr($text, -7)) if (length($text) > 15);
      $$rhash{values} = $frame -> Button(-foreground=>'black',
					 -borderwidth=>1,
					 -text=>$text,
					 -font=>$config{fonts}{small},
					 -command=>
					 sub {
					   my $path = $current_data_dir || cwd;
					   my $types = [['Executables', '*.exe'], ['All files', '*'],];
					   my $file = $top ->
					     getOpenFile(-filetypes  => $types,
							 ##(not $is_windows) ?
							 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
							 -multiple   => 0,
							 -initialdir =>$path,
							 -title      => "Artemis: Select Feff executable");
					   return unless ($file and (-e $file));
					   $$rhash{$s}{$v}{new}=$file;
					   ($file = substr($file, 0, 7) . "..." . substr($file, -7)) if (length($file) > 15);
					   $$rhash{values}->configure(-text=>$file);
					   $$rhash{save} = 1;
					   $$rhash{apply} ->configure(-state=>'normal');
					   $$rhash{future}->configure(-state=>'normal');
					 })
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
    };

    ($$rhash{$s}{$v}{type} eq 'real') and do {
      $$rhash{values} = $frame -> Entry(-width=>12, -validate=>'key',
					-validatecommand=>[\&prefs_real, join(".", $s,$v), $rhash])
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      $$rhash{values} -> configure(-validate=>'none');
      $$rhash{values} -> insert('end', $$rhash{$s}{$v}{new});
      $$rhash{values} -> configure(-validate=>'key');
      last SWITCH;
    };

    ## need to set the save flag
    ($$rhash{$s}{$v}{type} eq 'positive integer') and do {
      $$rhash{values} = $frame -> NumEntry(-width=>4,
					   -orient=>'horizontal',
					   -foreground=>$config{colors}{foreground},
					   -textvariable=>\$$rhash{$s}{$v}{new},
					   -minvalue=>$$rhash{$s}{$v}{minint}||0,
					   -maxvalue=>$$rhash{$s}{$v}{maxint},
					  )
	-> grid(-row=>3, -column=>1, -sticky=>'w');
      $$rhash{values} -> configure( -value=>$$rhash{$s}{$v}{new});
      ## crufty solution to the lack of a callback for NumEntry
      $$rhash{apply}  -> configure(-state=>'normal');
      $$rhash{future} -> configure(-state=>'normal');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'integer') and do {
      $$rhash{values} = $frame -> NumEntry(-width=>4,
					   -orient=>'horizontal',
					   -foreground=>$config{colors}{foreground},
					   -textvariable=>\$$rhash{$s}{$v}{new},
					   -minvalue=>$$rhash{$s}{$v}{minint},
					   -maxvalue=>$$rhash{$s}{$v}{maxint},
					  )
	-> grid(-row=>3, -column=>1, -sticky=>'w');
      $$rhash{values} -> configure( -value=>$$rhash{$s}{$v}{new});
      ## crufty solution to the lack of a callback for NumEntry
      $$rhash{apply}  -> configure(-state=>'normal');
      $$rhash{future} -> configure(-state=>'normal');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'list') and do {
      my @vals = split(" ", $$rhash{$s}{$v}{values});
      $$rhash{values} = $frame -> Optionmenu(-font=>$config{fonts}{med},
					     -borderwidth=>1,
					     -textvariable=>\$$rhash{$s}{$v}{new}
					     )
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
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

    ($$rhash{$s}{$v}{type} eq 'atp') and do {
      my $atpdir = $paths{data0} -> find('atoms', 'atp_personal');
      opendir A, $atpdir;
      my @use = ();

      my @personal = grep {/atp$/} readdir A;
      closedir A;
      @personal = map {s/\.atp$//; $_} @personal;
      foreach (@personal) {
	local $/ = undef;
	my $this = $_ . ".atp";
	next unless open F, File::Spec->catfile($atpdir, $this);
	my $snarf = <F>;
	close F;
	push @use, $_ if ($snarf =~ /meta.*:feff/);
      };

      opendir S, $Xray::Atoms::atp_dir;
      my @system = grep {/atp$/} readdir S;
      closedir S;
      @system = map {s/\.atp$//; $_} @system;
      foreach (@system) {
	local $/ = undef;
	my $this = $_ . ".atp";
	next unless open F, File::Spec->catfile($Xray::Atoms::atp_dir, $this);
	my $snarf = <F>;
	close F;
	push @use, $_ if ($snarf =~ /meta.*:feff/);
      };

      ## see Perl Cookbook, recipe 4.6;
      my %seen = ();
      foreach my $item (@use) {
	$seen{$item}++;
      };
      my @vals = sort(keys %seen);

      $$rhash{values} = $frame -> Optionmenu(-font=>$config{fonts}{med},
					     -borderwidth=>1,
					     -textvariable=>\$$rhash{$s}{$v}{new}
					     )
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
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
					      -selectcolor=> $config{colors}{check},
					      -variable=>\$$rhash{$s}{$v}{new},
					      -command=>
					      sub{
						$$rhash{apply} ->configure(-state=>'normal');
						$$rhash{future}->configure(-state=>'normal');
						$$rhash{save} = 1;
					      })
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      last SWITCH;
    };
    ($$rhash{$s}{$v}{type} eq 'color') and do {
      my $color = $$rhash{$s}{$v}{new} || 'black';
      my ($r, $g, $b) = $frame -> rgb($color);
      my $acolor = sprintf("#%4.4x%4.4x%4.4x", int($r*0.85), int($g*0.85), int($b*0.85));
      ($acolor = "#300030003000") if ($acolor eq "#000000000000");
      $$rhash{values} = $frame -> Button(-background=>$color,
					 -activebackground=>$acolor,
					 -borderwidth=>1,
					 -command=>sub{
					   my $color = "";
					   #$top->Busy();
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
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
      last SWITCH;
    };

    ($$rhash{$s}{$v}{type} eq 'font') and do {
      $$rhash{values} = $frame -> Button(-foreground=>'black',
					 -borderwidth=>1,
					 -text=>'abc ABC 123',
					 -font=>$$rhash{$s}{$v}{new},
					 -command=>sub{Error("Changing fonts interactively is not yet supported.  You can edit ".$setup -> find('artemis', 'rc_personal')." by hand.")})
	-> grid(-row=>3, -column=>1, -sticky=>'ew');
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

  my $message = "Are you sure that you wish to restore ALL the default values, overwriting any configuration you may have already made to Artemis?  Doing so will only restore them within this dialog.  You will then need to click the buttons below to apply or save the default values.";
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => $message,
		   -title          => 'Artemis: preferences...',
		   -buttons        => [qw/Yes No/],
		   -default_button => 'Yes',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $response = $dialog->Show();
  unless ($response eq 'Yes') {
    Echo("Not restoring defaults for preferences.");
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
  my %old = (charsize    => $config{plot}{charsize},
	     charfont    => $config{plot}{charfont},
	     workspace   => $config{general}{workspace},
	     logstyle    => $config{log}{style},
	     layout      => $config{general}{layout},
	     mru_display => $config{general}{mru_display},
	    );

  my $rhash = $_[0];
  foreach my $s (@{$$rhash{order}}) {
    foreach my $v (@{$$rhash{$s}{order}}) {
      $config{$s}{$v} = $$rhash{$s}{$v}{new};
    };
  };
  $$rhash{save} = -1;
  ## certain parameters need to take effect immediately and so require
  ## some special care

  ## sanity checks for cormin, rmin, rmax, others
  ($config{data}{cormin} = 0) if ($config{data}{cormin} < 0);
  ($config{data}{cormin} = 1) if ($config{data}{cormin} > 1);
  (($config{data}{rmin}, $config{data}{rmax}) = ($config{data}{rmax}, $config{data}{rmin}))
    if ($config{data}{rmin} > $config{data}{rmax});
  ($config{warnings}{reff_margin} = 1) if ($config{warnings}{reff_margin} <= 0);

  ## set default analysis parameter values
  $setup -> SetDefault(fit_space => $config{data}{fit_space},
		       do_bkg    => ($config{data}{fit_bkg}) ? 'yes' : 'no',
		       kmin      => $config{data}{kmin},
		       kmax      => $config{data}{kmax},
		       dk        => $config{data}{dk},
		       k1        => ($config{data}{kweight} == 1),
		       k2        => ($config{data}{kweight} == 2),
		       k3        => ($config{data}{kweight} == 3),
		       rmin      => $config{data}{rmin},
		       rmax      => $config{data}{rmax},
		       dr        => $config{data}{dr},
		       kwindow   => $config{data}{kwindow},
		       rwindow   => $config{data}{rwindow},
		       cormin    => $config{data}{cormin},
		      );

  foreach my $k (qw(window_multiplier bg fg grid showgrid
		    c0 c1 c2 c3 c4 c5 c6 c7 c8 c9
		    datastyle fitstyle partsstyle
		    key_x key_y key_dy
		   )) {
    $plot_features{$k} = $config{plot}{$k};
  };
  $plot_features{rmax_out} = $config{data}{rmax_out};
  Ifeffit::put_scalar('&plot_key_x',  $config{plot}{key_x});
  Ifeffit::put_scalar('&plot_key_y0', $config{plot}{'key_y'});
  Ifeffit::put_scalar('&plot_key_dy', $config{plot}{key_dy});

  #$log_params{prefer} = $config{logview}{prefer};

  unless ($config{general}{layout} eq $old{layout}) {
    map {$_->packForget} ($fat, $skinny, $skinny2);
    &layout;
  };
  &set_recent_menu if ($old{mru_display} ne $config{general}{mru_display});

  ## handle general.projectbar parameter
  if ($config{general}{projectbar} eq 'none') {
    $projectbar -> packForget;
  } elsif ($config{general}{projectbar} eq 'file') {
    $project_label -> configure(-textvariable=>\$project_name);
    $projectbar -> pack(-side=>"top", -anchor=>'nw', -fill=>'x'); #, -after=>$menubar)
  } elsif ($config{general}{projectbar} eq 'title') {
    $project_label -> configure(-textvariable=>\$props{'Project title'});
    $projectbar -> pack(-side=>"top", -anchor=>'nw', -fill=>'x'); #, -after=>$menubar)
  };
  ## handle general.workspace parameter
  ##($config{general}{workspace} =~ s/\~/$ENV{HOME}/) unless ($is_windows);
  ##$stash_dir = $config{general}{workspace};
  ##&delete_project unless (same_directory($old{workspace}, $config{general}{workspace}));

  ## default log style
  @log_type = set_log_style($config{log}{style}) unless ($old{logstyle} eq $config{log}{style});

  $paths{data0} -> dispose("plot(charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})", $dmode)
    if (($old{charsize} != $config{plot}{charsize}) or ($old{charfont} != $config{plot}{charfont}));

  $file_menu -> menu -> entryconfigure(5, -state=>($config{general}{import_feffit}) ? 'normal' : 'disabled');

  ## manage_geometry($config{geometry}{main_width}, $config{geometry}{main_height});
  &manage_extended_params;
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


sub manage_geometry {
  my ($w, $h) = @_;
#  $skinny2 -> packPropagate(0);
  $fat -> packPropagate(1);
  $fat -> pack(-expand => 1);
  $fat -> configure(-width  => $w.'c', -height => $h.'c',);
  $top -> update;
  $fat -> pack(-expand => 0);
  $fat -> packPropagate(0);
#  $skinny2 -> packPropagate(1);

  my @geom = split(/[+x]/, $top->geometry);
  print join(" ", @geom), $/;
  my $extrabit = ($Tk::VERSION < 804) ? 30 : 0;
  ($extrabit = 0) if ($is_windows);
  $top -> minsize($geom[0], $geom[1]+$extrabit);
};


sub read_config {
  my $rhash = $_[0];
  my $config_file = $paths{data0} -> find('artemis', 'config');
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
	  $next =~ s/^ *\./\n\n   /;
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
	$line[1] =~ s/ENV___(\w*)___/$ENV{$1}/ if $is_windows;
	$$rhash{$current_section}{$current_variable}{windows} = $line[1];
	last SWITCH;
      };
      ## max value for integer or positive integer
      (/^maxint=/) and do {
	my @line = split(/=/, $_);
	($line[1] = " ") if ($line[1] eq '""');
	$$rhash{$current_section}{$current_variable}{maxint} = $line[1];
	last SWITCH;
      };
      ## min value for integer
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
  Echo("Read master configuration file $config_file");

};

## END OF THE PREFERENCES SUBSYSTEM

