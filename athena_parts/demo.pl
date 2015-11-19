
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This file demonstrates how to add a new analysis feature to Athena


##  0.  Write all the subroutines needed to perform this chore.
##      Typically the sub that presents the view in the main window is
##      in the same file as all the subs that are needed to perform
##      the chore.  Add your new file to the file list used to build
##      athena.pl from its parts in Makefile.PL and in the mkathena
##      utility.

##  1.  Follow the example in this file for preparing your page.
##      Populate it with widgets as desired.  Try to maintain some
##      visual consistency with other views, unless, of course, you
##      have a beter idea

##  2.  Make an entry in the appropriate menu.  if you add to the Data
##      or File menus, you will need to take care with the indeces
##      used to enable/disable menu items.  this is mostly done in the
##      first part of set_properties

##  3.  Add an entry to the FAT block at the end of set_properties
##      that will correctly handle any chores that need doing whenever
##      the current group changes

##  4.  You should try to make use of the current and marked groups as
##      a way of selecting groups for analysis.  from a UI perspective
##      it is a bad idea to make special ways of incorporating data
##      into the analysis.  the one exception is the use of an
##      optionmenu to define the "standard" for the analysis chore

##  5.  Add a section to athena.config with any configuration
##      variables that your users might need.  feel free to add new
##      colors or fonts to athena.config, but do try to reuse the ones
##      that are already there

##  6.  If any of the configuration parameters require special
##      handling at the time they are reconfigured, add that to the
##      end of the prefs_apply subroutine

##  7.  Add key binding data to the set_key_data subroutine following
##      the commented out example.  at the very least, you should add
##      your top level function so that the view can be accessed from
##      the keyboard.  it would be best to provide bindings to every
##      button click on your page

##  8.  If you add this function to the Analysis or Data menus, you
##      should add a help balloon hint.  this is done in head.pl near
##      the menubutton_attach subroutine

##  9.  Write a document section and add a link to it in athena.pod.
##      Also add a menu entry to your new pod in the document sections
##      cascade in the $help_menu

## 10.  It is ok to add new parameters to the Group object which have
##      to do with this analysis chore.  This can usually be done
##      without harming any other part of the code.  It would be a
##      good idea to follow a naming scheme for your new object
##      parameters -- something like 'foobar_spiffyparam'.  It is
##      probably not necessary to initialize these new parameters in
##      Group.pm, however you may need to add some code to the file
##      reading or group initializing code to deal with those
##      parameters.  Cerrtainly it is ok to modify other object
##      parameters in your analysis functions.


sub foobaricate {

  ## generally, we do not change modes unless there is data.
  ## exceptions include things like the prefernces and key bindings,
  ## which are data-independent
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");

  ## this is a way of testing the current list of data groups for some
  ## necessary property.  for the demo, this will just be the list of
  ## groups
  # my @keys = ();
  # foreach my $k (&sorted_group_list) {
  #   ($groups{$k}->{is_xmu}) and push @keys, $k;
  # };
  # Echo("You need two or more xmu groups to foobar"), return unless ($#keys >= 1);
  my @keys = &sorted_group_list;

  ## you must define a hash which will contain the parameters needed
  ## to perform the task.  the hash_pointer global variable will point
  ## to this hash for use in set_properties.  you might draw these
  ## values from configuration parameters, as in the commented out
  ## example
  my %foobar_params;
  $foobar_params{string}       = "Hi mom!";
  $foobar_params{boolean}      = 1;
  ## $foobar_params{blah}        = $config{foobar}{blah};

  ## let's just assume the first group is the standard and the second
  ## is the unknown
  $foobar_params{standard}     = $keys[0];
  $foobar_params{standard_lab} = $groups{$keys[0]}->{label};

  ## you probably do not want the standard and the unknown to be the
  ## same group
  set_properties(1, $keys[1], 0) if ($current eq $keys[0]);
  $foobar_params{unknown}      = $current;

  ## you may wish to provide a better guess for which should be the
  ## standard and which the unknown.  you may also want to adjust the
  ## view of the groups list to show the unknown -- the following
  ## works...
  my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
  ($here < 0) and ($here = 0);
  my $full = ($list->bbox(@skinny_list))[3] + 5;
  $list -> yview('moveto', $here/$full);


  ## The Athena standard for analysis chores that need a specialized
  ## plotting range is to save the plotting range from the main view
  ## and restore it when the main view is restored
  # my @save = ($plot_features{emin}, $plot_features{emax});
  # $plot_features{emin} = $config{foobar}{emin};
  # $plot_features{emax} = $config{foobar}{emax};

  ## these two global variables must be set before this view is
  ## displayed.  these are used at the level of set_properties to
  ## perform chores appropriate to this dialog when changing the
  ## current group
  $fat_showing = 'demo';
  $hash_pointer = \%foobar_params;

  ## disable many menus.  this makes the chore of managing the views
  ## much easier.  the idea is that the main view is "home base".  if
  ## you want to do a different analysis chore, you must first return
  ## to the main view
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);

  ## this removes the currently displayed view without destroying its
  ## contents
  $fat -> packForget;

  ## define the parent Frame for this analysis chore and pack it in
  ## the correct location
  my $foobar = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$foobar -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $foobar;

  ## the standard label along the top identifying this analysis chore
  $foobar -> Label(-text=>"Foobaricate your data",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## at this point it is common to make an optionmenu defining the
  ## standard for this data analysis chore and a label identifying
  ## which data group is currently being work on (i.e. the one
  ## highlighted in orange in the groups list)

  ## a good solution to organizing widgets is to stack frames, so
  ## let's make a frame for the standard and the other.  note that the
  ## "labels" are actually flat buttons which display hints in the
  ## echo area
  my $frame = $foobar -> Frame(-borderwidth=>2, -relief=>'sunken')
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Button(-text=>"Standard: ", @label_button,
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   -command=>[\&Echo, "The spectrum serving as the foobarication standard."]
		  )
    -> grid(-row=>0, -column=>0, -sticky=>'e', -ipady=>2);
  my $menu = $frame -> Optionmenu(-textvariable => \$foobar_params{standard_lab},
				  -borderwidth=>1, )
    -> grid(-row=>0, -column=>1, -sticky=>'w');
  foreach my $s (@keys) {
    $menu -> command(-label => $groups{$s}->{label},
		     -command=>sub{$foobar_params{standard}=$s;
				   $foobar_params{standard_lab}=$groups{$s}->{label};
				   ## do the analysis chore
				 });
  };

  ## the group for alignment is the current group in the group list.
  ## note that the key for the %widget hash identifies the analysis
  ## chore.  this will make searches through this hash much easier in
  ## other parts Athena -- it's a good convention to stick to
  $frame -> Button(-text=>"Other: ",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   @label_button,
		   -command=>[\&Echo, "The group currently selected for foobarication."]
		  )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{foobar_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					    -foreground=>$config{colors}{button})
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);



  ## this is a spacer frame which pushes all the widgets to the top
  $foobar -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $foobar -> Button(-text=>'Return to the main window',  @button_list,
		    -background=>$config{colors}{background2},
		    -activebackground=>$config{colors}{activebackground2},
		    -command=>sub{## clean-up chores, for instance you
                                  ## may need to toggle update_bkg or
                                  ## one of the others

		                  ## restore the plot ranges is they
		                  ## were changed
		                  ## finally restore the main view
		                  &reset_window($foobar, "foobarication", 0);
		                  #&reset_window($foobar, "foobarication", \@save);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $foobar -> Button(-text=>'Document section: foobaricating data', @button_list,
		   -command=>sub{Echo("Display this document section");
				 ## get rid of the preceding line
				 ## and uncomment the next line
				 ## pod_display("process::foobar.pod");
			       })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  ## now begin setting up the widgets you need for your new analysis
  ## feature

  ## now a new frame for our two dummy widgets
  $frame = $foobar -> Frame(-borderwidth=>2, -relief=>'sunken')
    -> pack(-side=>'top', -fill=>'x');
  $widget{foobar_string} = $frame -> Entry(-width=>20,
					   -textvariable=>\$foobar_params{string})
    -> pack(-side=>'top');
  $widget{foobar_boolean} = $frame -> Checkbutton(-text=>"Do super foobarication",
						  -variable=>\$foobar_params{boolean})
    -> pack(-side=>'bottom');



  ## do you need to run one of your analysis subroutines immediately?
  ## now is a good time...

  ## and finally....
  $top -> update;

};


## END OF DEMO SUBSECTION
##########################################################################################
