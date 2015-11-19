## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  Athena's plugin registry

sub registry {

  my %reg_params = ();

  $fat_showing = 'registry';
  $hash_pointer = \%reg_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $reg = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  $which_showing = $reg;

  $reg -> Label(-text=>"Plugin Registry",
		-font=>$config{fonts}{large},
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## table of available plugins
  my $plugin_list;
  $plugin_list = $reg -> Scrolled('HList',
				  -scrollbars	    => 'osoe',
				  -header	    => 1,
				  -columns	    => 3,
				  -borderwidth	    => 0,
				  -relief           => 'flat',
				  -cursor           => $mouse_over_cursor,
				  -selectbackground => $config{colors}{background},
				  -highlightcolor   => $config{colors}{background},
				  -browsecmd        =>
				  sub {	# Echo a bit of info on a click
				    my $pick = $plugin_list -> selectionGet;
				    ($pick = $pick->[0]) if (ref($pick) =~ /ARRAY/); # Tk 800 returns a scalar
				                                                     # Tk 804 returns an array ref
				    my $id = "Ifeffit/Plugins/Filetype/Athena/".$plugins[$pick].".pm";
				    my $message = ($INC{$id})
				      ? "System plugin: $INC{$id}"
					: "Private plugin: " . File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'userfiletypedir'), $plugins[$pick].".pm");
				    Echo($message);
				  },
				  -command          =>
				  sub {	# display pod on double-click
				    my $pick = $plugin_list -> selectionGet;
				    ($pick = $pick->[0]) if (ref($pick) =~ /ARRAY/); # Tk 800 returns a scalar
				                                                     # Tk 804 returns an array ref
				    my $id = "Ifeffit/Plugins/Filetype/Athena/".$plugins[$pick].".pm";
				    my $file = $INC{$id} || File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'userfiletypedir'), $plugins[$pick].".pm");
				    pod_display($file);
				  })
    -> pack(-side=>'top', -fill =>'both', -expand=>1, -padx=>4, -pady=>4);
  $plugin_list -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $plugin_list -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $plugin_list -> Subwidget("hlist")
    -> bind('<ButtonPress-2>', sub{anchor_registry($plugin_list)});
  $plugin_list -> Subwidget("hlist")
    -> bind('<ButtonPress-3>', sub{anchor_registry($plugin_list)});

  my $style = $plugin_list -> ItemStyle('text',
					-font=>$config{fonts}{small},
					-anchor=>'w',
					-foreground=>$config{colors}{activehighlightcolor});
  $plugin_list -> headerCreate(0,
			       -text=>q{}, # Enable button
			       -style=>$style,
			       -headerbackground=>$config{colors}{background},);
  $plugin_list -> headerCreate(1,
			       -text=>"Plugin",
			       -style=>$style,
			       -headerbackground=>$config{colors}{background},);
  $plugin_list -> headerCreate(2,
			       -text=>"Description",
			       -style=>$style,
			       -headerbackground=>$config{colors}{background},);

  $style = $plugin_list -> ItemStyle('text',
				     -font=>$config{fonts}{small},
				     -anchor=>'w',
				     -foreground=>$config{colors}{foreground});

  my @button = ();
  foreach my $i (0 .. $#plugins) {
    $plugin_list -> add($i);
    $button[$i] = $plugin_list -> Checkbutton(-variable    => \$plugin_params{$plugins[$i]}{_enabled},
					      -selectcolor => $config{colors}{single},
					      -command     => sub{ # Enable plugin
						my $file = $groups{"Default Parameters"} -> find('athena', 'plugins');
						tied( %plugin_params )->WriteConfig($file);
						if ($plugin_params{$plugins[$i]}{_enabled}) {
						  Echo("Registered plugin $plugins[$i] for use.");
						} else {
						  Echo("Un-registered plugin $plugins[$i].");
						};
					      },
					     );
    $plugin_list -> itemCreate($i, 0, -itemtype=>'window', -widget=>$button[$i]);
    $plugin_list -> itemCreate($i, 1, -itemtype=>'text',   -text=>$plugins[$i], -style=>$style);
    my $description = eval "\$Ifeffit::Plugins::Filetype::Athena::$plugins[$i]::description";
    $plugin_list -> itemCreate($i, 2, -itemtype=>'text',   -text=>$description, -style=>$style);
  };

  ## utilities at bottom of page
  $reg -> Button(-text		   => 'Return to the main window',
		 @button_list,
		 -background	   => $config{colors}{background2},
		 -activebackground => $config{colors}{activebackground2},
		 -command	   => sub{ &reset_window($reg, "plugin registry", 0) })
    -> pack(-side=>'bottom', -fill=>'x');
  $reg -> Button(-text=>'Document section: plugins', @button_list,
		 -command=>sub{pod_display("import::plugin.pod")})
    -> pack(-side=>'bottom', -fill=>'x');
  my $fr = $reg -> Frame()
    -> pack(-side=>'bottom', -fill=>'x');
  $fr -> Button(-text    => 'Register all',
		-width   => 12,
		-command => sub{
		  foreach my $i (0..$#plugins) { $button[$i] -> select; };
		  my $file = $groups{"Default Parameters"} -> find('athena', 'plugins');
		  tied( %plugin_params )->WriteConfig($file);
		  Echo("Registered all plugins for use.");
		})
    -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $fr -> Button(-text    => 'Un-register all',
		-width   => 12,
		-command => sub{
		  foreach my $i (0..$#plugins) { $button[$i] -> deselect; };
		  my $file = $groups{"Default Parameters"} -> find('athena', 'plugins');
		  tied( %plugin_params )->WriteConfig($file);
		  Echo("Un-registered all plugins.");
		})
    -> pack(-side=>'left', -fill=>'x', -expand=>1)

};

  sub anchor_registry {
    ## this first bit swiped from HList.pm
    my $w = shift;
    my $Ev = $w->XEvent;
    delete $w->{'shiftanchor'};
    #my $entry = $w->GetNearest($Ev->y, 1);
    my $entry = $w->nearest($Ev->y);
    return unless (defined($entry) and ($entry >= 0));
    print $entry, $/;
    $w->anchorSet($entry);
    $w->selectionSet($entry);
    my $pick = $w -> selectionGet;
    ($pick = $pick->[0]) if (ref($pick) =~ /ARRAY/); # Tk 800 returns a scalar
                                                     # Tk 804 returns an array ref
    my $id = "Ifeffit/Plugins/Filetype/Athena/".$plugins[$pick].".pm";
    my $file = $INC{$id} || File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'userfiletypedir'), $plugins[$pick].".pm");
    pod_display($file);
  };



## END OF PLUGIN REGISTRY SUBSECTION
##########################################################################################
