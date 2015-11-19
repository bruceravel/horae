## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This file contains the dialog for making a series of copies of a data group

sub series {

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
  my %series_params;
  $series_params{group} = $current;
  $series_params{label} = $groups{$current}->{label};

  ## you may wish to provide a better guess for which should be the
  ## standard and which the unknown.  you may also want to adjust the
  ## view of the groups list to show the unknown -- the following
  ## works...
  my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
  ($here < 0) and ($here = 0);
  my $full = ($list->bbox(@skinny_list))[3] + 5;
  $list -> yview('moveto', $here/$full);


  ## these two global variables must be set before this view is
  ## displayed.  these are used at the level of set_properties to
  ## perform chores appropriate to this dialog when changing the
  ## current group
  $fat_showing = 'series';
  $hash_pointer = \%series_params;

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
  my $series = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$series -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $series;

  ## the standard label along the top identifying this analysis chore
  $series -> Label(-text=>"Create a series of data group copies",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## a good solution to organizing widgets is to stack frames, so
  ## let's make a frame for the standard and the other.  note that the
  ## "labels" are actually flat buttons which display hints in the
  ## echo area
  my $frame = $series -> Frame(-borderwidth=>2, -relief=>'sunken')
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Label(-text=>"Group:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>0, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_group} = $frame -> Label(-anchor=>'w', -textvariable=>\$series_params{label})
    -> grid(-row=>0, -column=>1, -sticky=>'ew', -pady=>3);



  ## this is a spacer frame which pushes all the widgets to the top
  $series -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $series -> Button(-text=>'Return to the main window',  @button_list,
		    -background=>$config{colors}{background2},
		    -activebackground=>$config{colors}{activebackground2},
		    -command=>sub{## clean-up chores, for instance you
                                  ## may need to toggle update_bkg or
                                  ## one of the others

		                  ## restore the plot ranges is they
		                  ## were changed
		                  ## finally restore the main view
		                  &reset_window($series, "series", 0);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $series -> Button(-text=>'Document section:  copying groups', @button_list,
		    -command=>sub{pod_display("ui::glist.pod") })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  tie my %params, "Tie::IxHash";
  %params = ('bkg_e0'    => 'Background removal E0',
	     'bkg_rbkg'  => 'Background removal R_bkg',
	     'bkg_kw'    => 'Background removal k-weight',
	     'bkg_pre1'  => 'Lower end of pre-edge range',
	     'bkg_pre2'  => 'Upper end of pre-edge range',
	     'bkg_nor1'  => 'Lower end of normalization range',
	     'bkg_nor2'  => 'Upper end of normalization range',
	     'bkg_spl1'  => 'Lower end of spline range',
	     'bkg_spl2'  => 'Upper end of spline range',
	     'fft_kmin'  => 'Fourier tranform minimum k',
	     'fft_kmax'  => 'Fourier tranform maximum k',
	     'fft_dk'    => 'Fourier tranform sill width',
	     'bft_rmin'  => 'Back tranform minimum R',
	     'bft_rmax'  => 'Back tranform maximum R',
	     'bft_dr'    => 'Back tranform sill width',
	    );
  $series_params{param} = 'bkg_rbkg';
  $series_params{plab}  = $params{'bkg_rbkg'};
  $frame -> Label(-text=>"Parameter:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>1, -column=>0, -sticky=>'e', -pady=>3);
  $widget{series_param} = $frame -> Optionmenu(-font=>$config{fonts}{small},
					       -textvariable => \$series_params{plab},
					       -borderwidth=>1,
					      )
    -> grid(-row=>1, -column=>1, -sticky=>'ew', -pady=>3);
  foreach my $i (keys %params) {
    $widget{series_param} -> command(-label => $params{$i},
				     -command =>
				     sub{
				       $series_params{param}   = $i;
				       $series_params{plab}    = $params{$i};
				       $series_params{current} = sprintf("%.3f", $groups{$current}->{$i});
				       $series_params{begin}   = sprintf("%.3f", $groups{$current}->{$i});
				       $series_params{inc}     = ($i eq 'bkg_e0') ? 5 : sprintf("%.3f", abs($groups{$current}->{$i}) / 10);
				     });
  };

  $series_params{current} = $groups{$current}->{'bkg_rbkg'};
  $frame -> Label(-text=>"Current value:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>2, -column=>0, -sticky=>'e', -pady=>3);
  $widget{series_current} = $frame -> Label(-anchor=>'w',
					    -textvariable=>\$series_params{current})
    -> grid(-row=>2, -column=>1, -sticky=>'ew', -pady=>3);

  $series_params{begin} = $groups{$current}->{'bkg_rbkg'};
  $frame -> Label(-text=>"Beginning value:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>3, -column=>0, -sticky=>'e', -pady=>3);
  $widget{series_begin} = $frame -> Entry(-textvariable=>\$series_params{begin})
    -> grid(-row=>3, -column=>1, -sticky=>'ew', -pady=>3);

  $series_params{number} = 4;
  $frame -> Label(-text=>"Number of copies:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>4, -column=>0, -sticky=>'e', -pady=>3);
  $widget{series_number} = $frame -> Entry(-textvariable=>\$series_params{number})
    -> grid(-row=>4, -column=>1, -sticky=>'ew', -pady=>3);

  $series_params{inc} = 0.1;
  $frame -> Label(-text=>"Increment:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>5, -column=>0, -sticky=>'e', -pady=>3);
  $widget{series_inc} = $frame -> Entry(-textvariable=>\$series_params{inc})
    -> grid(-row=>5, -column=>1, -sticky=>'ew', -pady=>3);

  $frame -> Button(-text=>'Make copies', @button_list,
		   -command=>
		   sub{
		     Echo("Series of copied groups ($series_params{plab}) ...");
		     my $save = $series_params{begin};
		     $top -> Busy;
		     series_copy(\%series_params);
		     series_plot(\%series_params);
		     Echo("Series of copied groups ($series_params{plab}) ... done!");
		     $series_params{begin} = $save;
		     $top -> Unbusy;
		   },
		  )
    -> grid(-row=>6, -column=>0, -columnspan=>2, -sticky=>'ew', -pady=>3);


  ## do you need to run one of your analysis subroutines immediately?
  ## now is a good time...

  ## and finally....
  $top -> update;

};


sub series_copy {
  my ($rparams) = @_;
  ##print join(" ", %$rparams), $/;
  my $was   = $current;
  my ($p, $begin, $inc) = ($rparams->{param}, $rparams->{begin}, $rparams->{inc});
  mark('none');
  mark('this');
  foreach my $i (1 .. $rparams->{number}) {
    my $new = &copy_group;
    my $val = $begin+($i-1)*$inc;
    my $pp  = (split(/_/, $p))[1];
    $groups{$new} -> make($p => $val);
    my $label = $groups{$was}->{label} . " - $pp=$val";
    rename_group($dmode, $label, $new);
    set_properties(0, $was);
  };
};

sub series_plot {
  my ($rparams) = @_;
  my $type  = (split(/_/, $rparams->{param}))[0];
  plot_marked_k if ($type eq 'bkg');
  plot_marked_r if ($type eq 'fft');
  plot_marked_q if ($type eq 'bft');
};


## END OF SERIES COPY SUBSECTION
##########################################################################################
