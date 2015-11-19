## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  key bindings

sub set_key_data {
  %key_data = (File =>
	       {
		a001 =>
		["Open file",                        sub{read_file(0)},               "any", 'Ctrl-o'],
		a004 =>
		["Open many files",                  sub{read_file(1)},               "any", 'Alt-o'],
		a008 =>
		["Open most recent file",            sub{read_file(0, $mru{mru}{1})}, "any"],
		a011 =>
		["Open second most recent file",     sub{read_file(0, $mru{mru}{2})}, "any"],
		a014 =>
		["Open third most recent file",      sub{read_file(0, $mru{mru}{3})}, "any"],
		a018 =>
		["Open fourth most recent file",     sub{read_file(0, $mru{mru}{4})}, "any"],
		a021 =>
		["Open URL",                         \&fetch_url,                     "any"],
		a024 =>
		["Save entire project",              sub{&save_project('all quick')}, "any", 'Ctrl-s'],
		a028 =>
		["Save entire project as",           sub{&save_project('all')},       "any"],
		a031 =>
		["Save marked groups as a project" , sub{&save_project('marked')},    "any"],
		a033 =>
		['Prompt for save space',            sub{&dispatch_space('save')},    "any"],
		a034 =>
		['Save mu(E)',                       sub{save_chi('e')},              "any"],
		a038 =>
		['Save norm(E)',                     sub{save_chi('n')},              "any"],
		a041 =>
		['Save deriv(E)',                    sub{save_chi('d')},              "any"],
		a044 =>
		['Save chi(k)',                      sub{save_chi('k')},              "any"],
		a048 =>
		['Save chi(R)',                      sub{save_chi('R')},              "any"],
		a051 =>
		['Save chi(q)',                      sub{save_chi('q')},              "any"],
		a054 =>
		["Save marked groups as mu(E)",      sub{save_marked('e')},           "any"],
		a058 =>
		["Save marked groups as norm(E)",    sub{save_marked('n')},           "any"],
		a061 =>
		["Save marked groups as deriv(E)",   sub{save_marked('d')},           "any"],
		a064 =>
		["Save marked groups as chi(k)",     sub{save_marked('k')},           "any"],
		a068 =>
		["Save marked groups as |chi(R)|",   sub{save_marked('rm')},          "any"],
		a071 =>
		["Save marked groups as Re[chi(R)]", sub{save_marked('rr')},          "any"],
		a074 =>
		["Save marked groups as Im[chi(R)]", sub{save_marked('ri')},          "any"],
		a078 =>
		["Save marked groups as |chi(q)|",   sub{save_marked('qm')},          "any"],
		a081 =>
		["Save marked groups as Re[chi(q)]", sub{save_marked('qr')},          "any"],
		a084 =>
		["Save marked groups as Im[chi(q)]", sub{save_marked('qi')},          "any"],
		#a088 =>
		#["Close project",                    sub{reset_window($which_showing, $fat_showing)
		#					   unless ($fat_showing eq 'normal');
		#					 delete_many($list, $dmode, 0)}, "any", 'Ctrl-w'],
		a091 =>
		['Quit',                             \&quit_athena,                   "any", 'Ctrl-q'],
	       },
	       Edit =>
	       {
		a001 =>
		["Display Ifeffit buffer", sub{raise_palette('ifeffit'); $top->update;},                "any", 'Ctrl-1']  ,
		a004 =>
		["Show group's titles", sub{raise_palette('titles');  $top->update;},                   "any", 'Ctrl-2'],
		a008 =>
		["Edit data as text", \&setup_data,                                                     "any", 'Ctrl-3'],
		a011 =>
		["Show group's arrays", sub{Echo('No data!'), return unless ($current);
					    raise_palette('ifeffit');
					    return if ($current eq "Default Parameters");
					    $setup->dispose("show \@group $current\n", $dmode);
					    $top->update},                                            "any"],
		a014 =>
		["Show all strings", sub{raise_palette('ifeffit');
					 $setup->dispose("show \@strings\n", $dmode);
					 $top->update},                                               "any"],
		a018 =>
		["Show all macros",                       sub{raise_palette('ifeffit');
							      $setup->dispose("show \@macros\n", $dmode);
							      $top->update},                         "any"],
		a021 =>
		["Display echo buffer",                   sub{raise_palette('echo'); $top->update;},    "any", 'Ctrl-4'],
		a024 =>
		["Record a macro",                        sub{raise_palette('macro'); $top->update;},   "any", 'Ctrl-5'],
		a028 =>
		["Load a macro"				, \&load_macro,                          "any"],
		a031 =>
		["Write in project journal",              sub{raise_palette('journal'); $top->update;}, "any", 'Ctrl-6'],
		a034 =>
		["Write an Excel report (all groups)",    sub{&report_excel('all')},                    "any"],
		a038 =>
		["Write an Excel report (marked groups)", sub{&report_excel('marked')},                 "any"],
		a041 =>
		["Write a CSV report (all groups)",       sub{&report_csv('all')},                      "any"],
		a044 =>
		["Write a CSV report (marked groups)",    sub{&report_csv('marked')},                   "any"],
		a048 =>
		["Write an ascii report (all groups)",    sub{&report_ascii('all')},                    "any"],
		a051 =>
		["Write an ascii report (marked groups)", sub{&report_ascii('marked')},                 "any"],
	       },

	       Group =>
	       {
		a001 =>
		["Copy group",                   \&copy_group,                       "any", 'Ctrl-y'],
		a004 =>
		["Make detector groups",         \&make_detectors,                   "any"],
		a008 =>
		["Make background group",        \&make_background,                  "any"],
		a011 =>
		["Change group label",           \&get_new_name,                     "any", 'Ctrl-l'],
		a014 =>
		["Remove group",                 sub{delete_group($list, $dmode);},  "any"],
		a018 =>
		["Identify group's record type", \&identify_group,                   "any"],
		a021 =>
		["Move group up",                \&group_up,                         "any", 'Alt-k'],
		a024 =>
		["Move group down",              \&group_down,                       "any", 'Alt-j'],
		a028 =>
		["Remove marked groups",         sub{delete_many($list, $dmode, 1)}, "any"],
		a031 =>
		["Set all groups'  values to the current", sub{Echo('No data!'), return unless ($current);
							       Echo("Parameters for all groups reset to \`$current\'");
							       my $orig = $current;
							       foreach my $x (keys %marked) {
								 next if ($x eq 'Default Parameters');
								 next if ($x eq $current);
								 $groups{$x}->set_to_another($groups{$current});
								 set_properties(1, $x, 0);
							       }
							       ;
							       set_properties(1, $orig, 0);
							       Echo(@done);}, "any"],
		a034 =>
		["Set all marked groups'  values to the current", sub{Echo('No data!'), return unless ($current);
								      Echo("Parameters for all marked groups reset to \`$current\'");
								      my $orig = $current;
								      foreach my $x (keys %marked) {
									next if ($x eq 'Default Parameters');
									next if ($x eq $current);
									next unless ($marked{$x});
									$groups{$x}->set_to_another($groups{$current});
									set_properties(1, $x, 0);
								      }
								      ;
								      set_properties(1, $orig, 0);
								      Echo(@done);}, "any"],
		a038 =>
		["Set current groups'  values to their defaults", sub{Echo('No data!'), return unless ($current);
								      my @keys = grep {/^(bft|bkg|fft)/} (keys %widget);
								      set_params('def', @keys);
								      set_properties(1, $current, 0);
								      Echo("Reset all values for this group to their defaults");}, "any"],
		a041 =>
		["Reset E0 for this group",      sub{set_edge($current, 'edge')},   "any"],
		a044 =>
		["Set E0 to a set fraction of the edge step", sub{set_edge($current, 'fraction')},   "any"],
		a048 =>
		["Set E0 to atomic value",       sub{set_edge($current, 'atomic')}, "any"],
	       },

	       Plot =>
	       {
		a0001 =>
		['Prompt for space for plotting current group', sub{&dispatch_space('plot_current')}, "any"],
		a0005 =>
		['Prompt for space for plotting marked groups', sub{&dispatch_space('plot_marked')}, "any"],


		a001 =>
		['Plot merge+standard deviation', sub{my $group = $groups{$current}->{group};
						      my $space = $groups{$current}->{is_merge};
						      &plot_merge($group, $space);}, "any"],
		a004 =>
		['Plot chi(E)', sub{my $str = 'k' . $plot_features{k_w} . 'e';
				    $groups{$current}->plotk($str,$dmode,\%plot_features, \@indicator) }, "any"],
		a008 =>
		['Plot chi(E), marked', sub{my $str = $plot_features{k_w} . 'e';
					    $groups{$current}->plot_marked($str,$dmode,\%groups,
									   \%marked, \%plot_features,
									   $list, \@indicator) }, "any"],
		a011 =>
		['Zoom',                \&zoom,                 "any", 'Ctrl-='],
		a014 =>
		['Unzoom',              sub{&replot('replot')}, "any", 'Ctrl--'],
		a018 =>
		['Cursor',              \&cursor,               "any", 'Ctrl-.'],
		## save last plot as an image
		a021 =>
		['Print last plot',     sub{&replot('print')},  "any", 'Ctrl-p'],
		##a024 =>
		##['Detach plot buttons', \&detach_plot,          "any"],
	       },

	       Mark =>
	       {
		a001 =>
		['Mark all groups',          sub{mark('all')},     "any", 'Ctrl-a'],
		a004 =>
		['Invert marks',             sub{mark('toggle')},  "any", 'Ctrl-i'],
		a008 =>
		['Clear all marks',          sub{mark('none')},    "any", 'Ctrl-u'],
		a011 =>
		["Toggle this group's mark", sub{mark('this')},    "any", 'Ctrl-t'],
		a014 =>
		["Mark regex",               sub{mark('regex')},   "any", 'Ctrl-r'],
		a017 =>
		["Unmark regex",             sub{mark('unregex')}, "any"],
	       },

	       Data =>
	       {
		a011 =>
		["Open calibration dialog", \&calibrate, "normal"],
		a012 =>
		{"Calibrate" =>{
				a010 =>
				['Select a point', sub{$widget{calib_select}   ->invoke()}, "calibration"],
				a020 =>
				['Replot', sub{$widget{calib_replot}   ->invoke()}, "calibration"],
				a030 =>
				['Calibrate', sub{$widget{calib_calibrate}->invoke()}, "calibration"],
			       },
		},
		a031 =>
		['Open deglitching dialog', \&deglitch_palette, "normal"],
		a032 =>
		{"Deglitch" =>{
			       a010 =>
			       ["Choose a point", sub{$widget{deg_single}->invoke()}, "deglitching"],
			       a020 =>
			       ["Remove a point", sub{$widget{deg_point} ->invoke()}, "deglitching"],
			       a030 =>
			       ["Replot", sub{$widget{deg_replot}->invoke()}, "deglitch"],
			       a040 =>
			       ["Remove glitches", sub{$widget{deg_remove}->invoke()}, "deglitching"],
			      },
		},
		a051 =>
		['Open truncation dialog', \&truncate_palette, "normal"],
		a052 =>
		{"Truncate" =>{
			       a010 =>
			       ["Replot", sub{$widget{trun_replot}  ->invoke()}, "truncation"],
			       a020 =>
			       ["Truncate", sub{$widget{trun_truncate}->invoke()}, "truncation"],
			      },
		},
		a071 =>
		['Open smoothing dialog', \&smooth, "normal"],
		a072 =>
		{"Smooth" =>{
			     a010 =>
			     ["Choose iterative smoothing", sub{$widget{sm_it_button}->invoke()}, "smoothing"],
			     a020 =>
			     ["Choose Fourier filter smoothing", sub{$widget{sm_ff_button}->invoke()}, "smoothing"],
			     a030 =>
			     ["Plot data and smoothed spectrum", sub{$widget{sm_plot}->invoke()}, "smoothing"],
			     a040 =>
			     ["Put smoothed data into a group", sub{$widget{sm_save}->invoke()}, "smoothing"],
			    },
		},
		a900 =>
		['How many spline knots?', \&nknots, "any"],
	       },

	       Align =>
	       {
		a011 =>
		['Align scans', sub{&align_two($config{align}{align_default})}, "normal"],
		a012 =>
		{"Align" =>{
			    a010 =>
			    ["Auto align",    sub{$widget{align_auto}      ->invoke()}, "alignment"],
			    a020 =>
			    ["Replot",        sub{$widget{align_replot}    ->invoke()}, "alignment"],
			    a030 =>
			    ["plus 5",        sub{$widget{align_plus5}     ->invoke()}, "alignment"],
			    a040 =>
			    ["minus 5",       sub{$widget{align_minus5}    ->invoke()}, "alignment"],
			    a050 =>
			    ["plus 1",        sub{$widget{align_plus1}     ->invoke()}, "alignment"],
			    a060 =>
			    ["minus 1",       sub{$widget{align_minus1}    ->invoke()}, "alignment"],
			    a070 =>
			    ["plus 1/2",      sub{$widget{'align_plus0.5'} ->invoke()}, "alignment"],
			    a080 =>
			    ["minus 1/2",     sub{$widget{'align_minus0.1'}->invoke()}, "alignment"],
			    a090 =>
			    ["plus 1/10",     sub{$widget{'align_plu0.1'}  ->invoke()}, "alignment"],
			    a100 =>
			    ["minus 1/10",    sub{$widget{'align_minus0.1'}->invoke()}, "alignment"],
			    a110 =>
			    ["Restore value", sub{$widget{align_restore}   ->invoke()}, "alignment"],
			   }
		},
		a071 =>
		["Calibrate dispersive XAS", \&pixel, "normal"],
		a072 =>
		{"Dispersive XAS" => {
				      a010 =>
				      ["Refine alignment parameters",     sub{$widget{pixel_refine}	 ->invoke()}, "pixel"],
				      a020 =>
				      ["Toggle constraint button",        sub{$widget{pixel_constrain}	 ->invoke()}, "pixel"],
				      a030 =>
				      ["Reset offset",                    sub{$widget{pixel_linear_button} ->invoke()}, "pixel"],
				      a040 =>
				      ["Replot standard and pixel data",  sub{$widget{pixel_replot}	 ->invoke()}, "pixel"],
				      a050 =>
				      ["Make data group",                 sub{$widget{pixel_make}		 ->invoke()}, "pixel"],
				      a060 =>
				      ["Convert all marked pixel groups", sub{$widget{pixel_all}		 ->invoke()}, "pixel"],
				     },
		},
	       },

	       Merge =>
	       {
		a001 =>
		['Prompt for merge space', sub{&dispatch_space('merge')}, "normal"],
		a005 =>
		['Merge marked data in chi(k)',  sub{&merge_groups('k')}, "normal"],
		a010 =>
		['Merge marked data in norm(E)', sub{&merge_groups('n')}, "normal"],
		a015 =>
		['Merge marked data in mu(E)',   sub{&merge_groups('e')}, "normal"],
		a020 =>
		['Merge marked data in chi(R)',  sub{&merge_groups('r')}, "normal"],
		a025 =>
		['Merge marked data in chi(q)',  sub{&merge_groups('q')}, "normal"],
	       },

	       Diff =>
	       {
		a001 =>
		['Prompt for difference spectrum space', sub{&dispatch_space('difference')}, "normal"],
		a005 =>
		['Open difference spectra dialog: norm(E)', sub{&difference('n')}, "normal"],
		a010 =>
		['Open difference spectra dialog: chi(k)',  sub{&difference('k')}, "normal"],
		a015 =>
		['Open difference spectra dialog: mu(E)',   sub{&difference('e')}, "normal"],
		a020 =>
		['Open difference spectra dialog: chi(R)',  sub{&difference('r')}, "normal"],
		a025 =>
		['Open difference spectra dialog: chi(q)',  sub{&difference('q')}, "normal"],
		a030 =>
		{"Difference Spectra" => {
					  a010 =>
					  ["Integrate",				     sub{$widget{diff_integrate}->invoke()},   "difference spectrum"],
					  a020 =>
					  ["Replot",					     sub{$widget{diff_replot}->invoke()},      "difference spectrum"],
					  a030 =>
					  ["Make difference group",			     sub{$widget{diff_save}->invoke()},        "difference spectrum"],
					  a040 =>
					  ["Make difference groups from all marked groups", sub{$widget{diff_savemarked}->invoke()},  "difference spectrum"],
					  a050 =>
					  ["Toggle Integrate? button",			     sub{$widget{diff_savemarkedi}->invoke()}, "difference spectrum"],
					 },
		},
	       },

	       Analysis =>
	       {
		a021 =>
		['Open log-ratio dialog', \&log_ratio, "normal"],
		a022 =>
		{"Log-Ratio" => {
				 a010 =>
				 ["Fit",		    sub{$widget{lr_fit}  ->invoke()}, "log ratio"],
				 a020 =>
				 ["Plot log-ratio",	    sub{$widget{lr_lr}   ->invoke()}, "log ratio"],
				 a030 =>
				 ["Plot phase difference", sub{$widget{lr_pd}   ->invoke()}, "log ratio"],
				 a040 =>
				 ["Save ratio data",	    sub{$widget{lr_save} ->invoke()}, "log ratio"],
				 a050 =>
				 ["Write log file",	    sub{$widget{lr_log}  ->invoke()}, "log ratio"],
				 a060 =>
				 ["Plot in k",		    sub{$widget{lr_plotk}->invoke()}, "log ratio"],
				 a070 =>
				 ["Plot in R",		    sub{$widget{lr_plotr}->invoke()}, "log ratio"],
				 a080 =>
				 ["Plot in q",		    sub{$widget{lr_plotq}->invoke()}, "log ratio"],
				},
		},
		a041 =>
		['Open peak fitting dialog', \&peak_fit,  "normal"],
		a042 =>
		{"Peak fit" => {
				a010 =>
				["Toggle components button",		   sub{$widget{peak_components}->invoke()}, "peak fitting"],
				a020 =>
				["Toggle centroids button",		   sub{$widget{peak_show}      ->invoke()}, "peak fitting"],
				a030 =>
				["Fit and plot",			   sub{$widget{peak_fit}       ->invoke()}, "peak fitting"],
				a040 =>
				["Reset amplitudes and widths",	   sub{$widget{peak_reset}     ->invoke()}, "peak fitting"],
				a050 =>
				["Save best fit function as a data group",sub{$widget{peak_save}      ->invoke()}, "peak fitting"],
				a060 =>
				["Write a log file",			   sub{$widget{peak_log}       ->invoke()}, "peak fitting"],
			       },
		},

		a051 =>
		['Open linear combination fitting dialog', \&lcf, "normal"],
		a052 =>
		{"Linear combination fit" => {
					      a010 =>
					      ["Fit", sub{$widget{lcf_fit}->invoke()}, "linear combination fitting"],
					      a020 =>
					      ["Plot data and fit", sub{$widget{lcf_plot}->invoke()}, "linear combination fitting"],
					      a030 =>
					      ["Write a report", sub{$widget{lcf_report}->invoke()}, "linear combination fitting"],
					      a040 =>
					      ["Save fit as a group", sub{$widget{lcf_group}->invoke()}, "linear combination fitting"],
					      a050 =>
					      ["Reset", sub{$widget{lcf_reset}->invoke()}, "linear combination fitting"],
					      a060 =>
					      ["Toggle linear background", sub{$widget{lcf_linear}->invoke()}, "linear combination fitting"],
					     },
		},
	       },

	       ## Add key binding data for your new analysis chore
	       ## here

	       # a091 =>
	       # ['Open foobarication dialog', \&foobaricate,  "normal"],
	       # a092 =>
	       # {"Foobaricate" =>
	       #	{
	       #	 a005 => ["Do one thing",     \&sub_ref1, "demo"],
	       #	 a010 => ["Do another thing", \&sub_ref2, "demo"],
	       #	},
	       # },

	       Settings =>
	       {
		a005 =>
		['Swap panels',	      \&swap_panels,     "any", 'Ctrl-/'],
		a010 =>
		["Purge web download cache", \&purge_web_cache, "any"],
		a031 =>
		["Edit preferences",	      \&prefs,           "normal"],
		a032 =>
		{Preferences => {
				 a010 =>
				 ["Save all parameters to Athena's defaults", sub{$widget{prefs_all}    ->invoke()}, "preferences"],
				 a020 =>
				 ["Apply changes to this session",	       sub{$widget{prefs_apply}  ->invoke()}, "preferences"],
				 a030 =>
				 ["Save changes for future sessions",	       sub{$widget{prefs_future} ->invoke()}, "preferences"],
				},
		},
	       },

	       Help =>
	       {
		a010 =>
		['Document', sub{pod_display("index.pod")}, "any", 'Ctrl-m'],
		a020 =>
		['Import a demo projects', \&read_demo, "normal"],
		a030 =>
		['Show a hint', \&show_hint, "any", 'Ctrl-h'],
		a040 =>
		['About Ifeffit', sub{Echo("Using Ifeffit ". Ifeffit::get_string("\$&build"))}, "any"],
		a050 =>
		['About Athena', sub{Echo($About)}, "any"],
		a060 =>
		["Check Ifeffit's memory usage", sub{$groups{"Default Parameters"} -> memory_check($top, \&Echo, \%groups, $max_heap, 1, 0)}, "any"],
	       },
	      );
  ##   open FOO, ">foo";
  ##   $Data::Dumper::Indent = 2;
  ##   $Data::Dumper::Deparse=1;
  ##   print FOO Data::Dumper->Dump([\%key_data], [qw(*key_data)]);
  ##   $Data::Dumper::Indent = 0;
  ##   close FOO;
};


sub key_bindings {
  my %keys_params = ();
  $keys_params{save} = 0;
  $keys_params{modifier} = 'control';
  $keys_params{modifier_label} = "Ctrl-$config{general}{user_key}";
  $fat_showing = 'keys';
  $hash_pointer = \%keys_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $keys = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$keys -> packPropagate(0);
  $which_showing = $keys;
  $keys -> Label(-text=>"Edit Key Bindings",
		 -font=>$config{fonts}{large},
		 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');


  $keys -> Button(-text=>'Return to the main window',  @button_list,
		   -background=>$config{colors}{background2},
		   -activebackground=>$config{colors}{activebackground2},
		   -command=>sub{
		     if ($keys_params{save}) {
		       my $message = "Do you want to save your key bindings for future sessions?";
		       my $dialog =
			 $top -> Dialog(-bitmap         => 'questhead',
					-text           => $message,
					-title          => 'Athena: save key bindings?',
					-buttons        => ['Yes', 'No'],
					-default_button => 'Yes',);
		       my $response = $dialog->Show();
		       &keys_save if ($response eq 'Yes');
		     };
		     &reset_window($keys, "key bindings", 0)}
		  )
    -> pack(-side=>'bottom', -fill=>'x');
  $keys -> Button(-text=>'Document section: key bindings', @button_list,
		  -command=>sub{pod_display("ui::keys.pod")},)
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);



  my $labframe = $keys -> LabFrame(-label=>'All functions',
				    -labelside=>'acrosstop')
    -> pack(-side=>'top', -expand=>1, -fill=>'both');
  my $tree;
  $tree = $labframe -> Scrolled('Tree',
				-scrollbars => 'se',
				-width      => 45,
				-background => $config{colors}{hlist},
				-browsecmd  => sub{&keys_browse($tree, \%keys_params)}
			       )
    -> pack(-expand=>1, -fill=>'both');
  $tree->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					    ($is_windows) ? () : (-width=>8));
  $tree->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					    ($is_windows) ? () : (-width=>8));

  my $frame = $keys -> Frame(-relief=>'flat')
    -> pack(-side=>'top');

  $frame -> Label(-text=>'Category:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e', -columnspan=>3);
  $frame -> Label(-text=>' ', -width=>35, -justify=>'left',
		  -textvariable=>\$keys_params{category})
    -> grid(-row=>0, -column=>3, -sticky=>'e', -columnspan=>2);
  $frame -> Label(-text=>'Valid when showing:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e', -columnspan=>3);
  $frame -> Label(-text=>' ', -width=>35, -justify=>'left',
		  -textvariable=>\$keys_params{valid})
    -> grid(-row=>1, -column=>3, -sticky=>'e', -columnspan=>2);
  $frame -> Label(-text=>'Description:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e', -columnspan=>3);
  $frame -> Label(-text=>' ', -width=>35, -justify=>'left',
		  -textvariable=>\$keys_params{descr})
    -> grid(-row=>2, -column=>3, -sticky=>'e', -columnspan=>2);
  $frame -> Label(-text=>'Bound to:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e', -columnspan=>3);
  $frame -> Label(-text=>' ', -width=>35, -justify=>'left',
		  -textvariable=>\$keys_params{bound})
    -> grid(-row=>3, -column=>3, -sticky=>'e', -columnspan=>2);

  $frame -> Label(-text=>'Key:  ',
		  -justify=>'right',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $widget{keys_modifier} = $frame -> Optionmenu(-font=>$config{fonts}{small},
						-textvariable => \$keys_params{modifier_label},
						-width=>12,
						-borderwidth=>1,
						-state=>'disabled')
    -> grid(-row=>4, -column=>1);
  foreach my $i ("Ctrl-$config{general}{user_key}", "Alt-$config{general}{user_key}") {
    $widget{keys_modifier} -> command(-label => $i,
				      -command=>sub{
					$keys_params{modifier_label} = $i;
					$keys_params{modifier} = ($i =~ /^Ctrl/) ? 'control' : 'meta';
				      })
  };

  $widget{keys_key} = $frame -> KeyEntry(-width	  => 3,
					 -justify => 'center',
					 -font	  => $config{fonts}{fixed}
					 -state	  => 'disabled',)
    -> grid(-row=>4, -column=>2, -sticky=>'w');
  $widget{keys_bindit} = $frame
    -> Button(-text=>"Bind it!", @button_list,
	      -state => 'disabled',
	      -command=>sub{&keys_bind($tree, \%keys_params)})
    -> grid(-row=>4, -column=>3, -sticky=>'e', -padx=>2);
  $widget{keys_unbind} = $frame
    -> Button(-text=>"Unbind", @button_list,
	      -state => 'disabled',
	      -command=>sub{&keys_unbind($tree, \%keys_params)})
    -> grid(-row=>4, -column=>4, -sticky=>'w', -padx=>2);

  $frame -> Button(-text=>"Show all bindings",  @button_list,
		   -command=>\&keys_show_all)
    -> grid(-row=>5, -column=>0, -columnspan=>5, -sticky=>'ew');
  #$frame -> Button(-text=>"Apply key bindings to current session",  @button_list,
  #		   -command=>[\&Echo, "Apply."])
  #  -> grid(-row=>6, -column=>0, -columnspan=>4, -sticky=>'ew');
  $widget{keys_save} = $frame
    -> Button(-text=>"Save key bindings for future sessions",  @button_list,
	      -command=>\&keys_save,
	      -state=>'disabled')
    -> grid(-row=>7, -column=>0, -columnspan=>5, -sticky=>'ew');
  $frame -> Button(-text=>"Clear all key bindings",  @button_list,
		   -command=>\&keys_clear)
    -> grid(-row=>8, -column=>0, -columnspan=>5, -sticky=>'ew');

  &keys_fill_tree($tree, \%keys_params);
};


## the way the tree paths are chosen, infoAnchor can be split on the
## dots to yield the hash keys that get to the commands in %key_data
sub keys_fill_tree {
  my $tree = $_[0];
  foreach my $p (qw(File Edit Group Plot Mark Data Align Merge Diff
		    Analysis Settings Help)) {
    $tree -> add($p, -text=>$p, -data=>'category');
    foreach my $first (sort keys %{$key_data{$p}}) {
      if (ref($key_data{$p}->{$first}) eq 'ARRAY') {
	## these are commands in the menubar menus
	## $this is a concatination of the hash keys needed to get to
	## this command
	my $this = join(".", $p, $first);
	$tree -> add($this,
		     -text=>$key_data{$p}->{$first}->[0],
		     -data=>$key_data{$p}->{$first});
	$tree -> setmode($this, 'none');
      } elsif (ref($key_data{$p}->{$first}) eq 'HASH') {
	## these are commands on the various data processing views
	foreach my $second (sort keys %{$key_data{$p}->{$first}}) {
	  my $this = join(".", $p, $first);
	  $tree -> add($this, -text=>$second, -data=>'category');
	  foreach my $third (sort keys %{$key_data{$p}->{$first}->{$second}}) {
	    ## $child is a concatination of the hash keys needed to
	    ## get to this command
	    my $child = join(".", $p, $first, $third);
	    $tree -> add($child,
			 -text=>$key_data{$p}->{$first}->{$second}->{$third}->[0],
			 -data=>$key_data{$p}->{$first}->{$second}->{$third});
	    $tree -> setmode($child, 'none');
	  };
	  $tree -> setmode($this, 'close');
	  $tree -> close($this);
	};
      };
    };
    $tree -> setmode($p, 'close');
    $tree -> close($p);
  };
  $tree->autosetmode();
};

sub keys_browse {
  my ($tree, $rhash) = @_;
  my $this = $tree->infoAnchor;
  $widget{keys_key} -> delete(0, 'end');
  unless ($this) {		# clicking on [+] button
    $$rhash{category} = "";
    $$rhash{descr}    = "";
    $$rhash{function} = "";
    $$rhash{valid}    = "";
    $$rhash{bound}    = "";
    map { $widget{'keys_'.$_} -> configure(-state=>'disabled') } (qw(bindit unbind key modifier));
    return;
  };
  my $data = $tree->infoData($this);

  if (ref($data) eq 'ARRAY') {	# this is a command
    my @list = split(/\./, $this);
    if ($#list == 1) {
      $$rhash{category} = $list[0];
    } else {
      ## the ugly thing at the end of the next line is to pull the
      ## name of the sub-branch out of the %key_data data structure
      $$rhash{category} = $list[0] . ' -> ' . (keys %{$key_data{$list[0]}->{$list[1]}})[0];
    };
    $$rhash{descr}    = $$data[0];
    $$rhash{function} = $$data[1];
    $$rhash{valid}    = $$data[2] . " view";
    $$rhash{bound}    = $$data[3] || "";
    foreach my $k (keys %{$config{controlkeys}}) {
      if ($config{controlkeys}{$k} eq $this) {
	if ($$rhash{bound}) {
	  $$rhash{bound} .= "    Ctrl-$config{general}{user_key} $k";
	} else {
	  $$rhash{bound}  = "Ctrl-$config{general}{user_key} $k";
	};
      };
    };
    foreach my $k (keys %{$config{metakeys}}) {
      if ($config{metakeys}{$k} eq $this) {
	if ($$rhash{bound}) {
	  $$rhash{bound} .= "    Alt-$config{general}{user_key} $k";
	} else {
	  $$rhash{bound}  = "Alt-$config{general}{user_key} $k";
	};
      };
    };
    map { $widget{'keys_'.$_} -> configure(-state=>'normal') } (qw(bindit unbind key modifier));

  } else {			# category header
    $$rhash{category} = (split(/\./, $this))[0];
    $$rhash{descr}    = "";
    $$rhash{function} = "";
    $$rhash{valid}    = "";
    $$rhash{bound}    = "";
    map { $widget{'keys_'.$_} -> configure(-state=>'disabled') } (qw(bindit unbind key modifier));
  };
};


sub keys_bind {
  my ($tree, $rhash) = @_;
  my $key  = $widget{keys_key} -> get();
  return if ($key =~ /^\s+$/);
  my $modifier = $$rhash{modifier};
  my $mod = substr(uc($modifier), 0, 1);
  my $val  = $tree -> infoAnchor;
  $config{$modifier.'keys'}{$key} = $val;
  $widget{keys_save} -> configure(-state=>'normal');
  $$rhash{save} = 1;
  $tree -> KeyboardBrowse;
  $widget{keys_key} -> insert('end', $key);
  Echo("Bound $mod, - $key to \"$$rhash{descr}\"");
};


sub keys_unbind {
  my ($tree, $rhash) = @_;
  my $key  = $widget{keys_key} -> get();
  return if ($key =~ /^\s*$/);
  my $modifier = $$rhash{modifier};
  Error("$modifier-, $key is not bound to a function"), return unless exists $config{$modifier.'keys'}{$key};
  delete $config{$modifier.'keys'}{$key};
  $widget{keys_save} -> configure(-state=>'normal');
  $$rhash{save} = 1;
  $tree -> KeyboardBrowse;
  $widget{keys_key} -> insert('end', $key);
  my $mod = ($modifier eq 'control') ? "C" : "A";
  Echo("Removed binding to $mod-, $key");
};

sub keys_clear {
  foreach my $k (keys %{$config{controlkeys}}) {
    delete $config{controlkeys}{$k};
  };
  foreach my $k (keys %{$config{metakeys}}) {
    delete $config{metakeys}{$k};
  };
  Echo("Erase all bound keys for the current session.");
};


sub keys_show_all {
  my $message = "The following key sequences have been bound:\n\n";
  my $count = 0;
  foreach my $k (sort keys %{$config{controlkeys}}) {
    my @list = split(/\./, $config{controlkeys}{$k});
    my $category;
    if ($#list == 1) {
      $category = join(' -> ', $list[0], $key_data{$list[0]}->{$list[1]}->[0]);
    } else {
      ## the ugly thing at the end of the next line is to pull the
      ## name of the sub-branch out of the %key_data data structure
      my $branch = (keys %{$key_data{$list[0]}->{$list[1]}})[0];
      $category = join(' -> ', $list[0],
		       (keys %{$key_data{$list[0]}->{$list[1]}})[0],
		       $key_data{$list[0]}->{$list[1]}->{$branch}->{$list[2]}->[0]
		      );

    };
    $message .= "  C $config{general}{user_key} - $k:\t$category\n";
    ++$count;
  };
  foreach my $k (sort keys %{$config{metakeys}}) {
    my @list = split(/\./, $config{metakeys}{$k});
    my $category;
    if ($#list == 1) {
      $category = join(' -> ', $list[0], $key_data{$list[0]}->{$list[1]}->[0]);
    } else {
      ## the ugly thing at the end of the next line is to pull the
      ## name of the sub-branch out of the %key_data data structure
      my $branch = (keys %{$key_data{$list[0]}->{$list[1]}})[0];
      $category = join(' -> ', $list[0],
		       (keys %{$key_data{$list[0]}->{$list[1]}})[0],
		       $key_data{$list[0]}->{$list[1]}->{$branch}->{$list[2]}->[0]
		      );

    };
    $message .= "  A $config{general}{user_key} - $k:\t$category\n";
    ++$count;
  };
  ($message = "There currently are no defined key bindings.") unless $count;
  my $dialog =
    $top -> Dialog(-bitmap         => 'info',
		   -text           => $message,
		   -title          => 'Athena: key bindings',
		   -buttons        => ['OK'],
		   -default_button => 'OK',);
  my $response = $dialog->Show();
};


sub keys_save {
  my $rhash = $_[0];
  rename $personal_rcfile, $personal_rcfile.".bak";
  my $config_ref = tied %config;
  $config_ref -> WriteConfig($personal_rcfile);
  $$rhash{save} = 0;
  $widget{keys_save} -> configure(-state=>'disabled');
  Echo("Saved key bindings to \"$personal_rcfile\"");
};


sub keys_dispatch {
  my $modifier = $_[1];
  #print join(" ", @_), $/;
  my $mod = ($modifier eq 'control') ? "C" : "A";
  my $who = $top->focusCurrent;
  $multikey = "";
  Echonow("$mod-$config{general}{user_key} - <<waiting for end of key sequence...>>");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who -> focus;

  ##   my %nonalphanumerics = (period=>'.',
  ## 			  comma=>',',
  ## 			  bracketleft=>'[',
  ## 			  bracketright=>']',
  ## 			  semicolon=>';',
  ## 			  colon=>':',
  ## 			  equal=>'=',
  ## 			  plus=>'+',
  ## 			  minus=>'-',
  ## 			  slash=>'/',
  ## 			  apostrophe=>"\'",
  ## 			  backslash=>"\\",
  ## 			  grave=>'`',
  ## 			  space=>' ',
  ## 			 );
  ##   ($multikey = $nonalphanumerics{$multikey}) if exists $nonalphanumerics{$multikey};
  Error("$mod-, - $multikey   is not bound to a command"), return unless (exists $config{$modifier.'keys'}{$multikey});

  ## need to translate $multikey for the non-alphanumerics
  my @id = split(/\./, $config{$modifier.'keys'}{$multikey});
  my ($description, $function, $view);
  if ($#id == 1) {
    $description = $key_data{$id[0]}->{$id[1]}->[0];
    $function    = $key_data{$id[0]}->{$id[1]}->[1];
    $view        = $key_data{$id[0]}->{$id[1]}->[2];
  } else {
    my $branch = (keys %{$key_data{$id[0]}->{$id[1]}})[0];
    $description = $key_data{$id[0]}->{$id[1]}->{$branch}->{$id[2]}->[0];
    $function    = $key_data{$id[0]}->{$id[1]}->{$branch}->{$id[2]}->[1];
    $view        = $key_data{$id[0]}->{$id[1]}->{$branch}->{$id[2]}->[2];
  };

  ## check to make sure that this function can be called at this time.
 CHECKVIEW: {
    ($view eq "normal")and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the normal view"),
	return unless ($fat_showing eq "normal");
      last CHECKVIEW;
    };
    ($view eq "calibration") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the calibration view"),
	return unless ($fat_showing eq 'calibrate');
      last CHECKVIEW;
    };
    ($view eq "deglitching") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the deglitching view"),
	return unless ($fat_showing eq 'deglitch');
      last CHECKVIEW;
    };
    ($view eq "truncation") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the truncation view"),
	return unless ($fat_showing eq 'truncate');
      last CHECKVIEW;
    };
    ($view eq "smoothing") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the smoothing view"),
	return unless ($fat_showing eq 'smooth');
      last CHECKVIEW;
    };
    ($view eq "alignment") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the alignment view"),
	return unless ($fat_showing eq 'align');
      last CHECKVIEW;
    };
    ($view eq "difference spectrum") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the difference spectrum view"),
	return unless ($fat_showing eq 'diff');
      last CHECKVIEW;
    };
    ($view eq "log ratio") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the log ratio view"),
	return unless ($fat_showing eq 'lograt');
      last CHECKVIEW;
    };
    ($view eq "peak fitting") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the peak fitting view"),
	return unless ($fat_showing eq 'peakfit');
      last CHECKVIEW;
    };
    ($view eq "preferences") and do {
      Echo("$mod-, - $multikey aborted!  \"$description\" can only be called in the preferences view"),
	return unless ($fat_showing eq 'prefs');
      last CHECKVIEW;
    };
  };
  Echonow("$mod-, - $multikey    ( $description )");
  &$function;
};


## this is a generalized multiplexer for dispatching functions
## according to a space obtained from the keyboard.  for example, one
## might bind "C-, m" to this function for prompting for a mergeing
## space.  then the key chain "C-, m e" would merge the marked data in
## mu(E)
sub dispatch_space {
  my $function = $_[0];
  my $space;

  ## for merging and difference spectra, spaces are e=energy,
  ## n=normalize, k=chi(k), r=chi(R), q=chi(q)
  my $spaces = "enkrq";
  ## saving current group also has d=derivative
  ($spaces = "endkrq") if ($function eq 'save');
  ## plotting, dispatch these to the appropriate plotting functions
  if ($function =~ /^plot/) {
    &keyboard_plot       if ($function eq 'plot_current');
    keyboard_plot_marked if ($function eq 'plot_marked');
    return;
  };

  ## reuse the trick of giving the echo area the focus and capturing
  ## the next keystroke
  my $who = $top->focusCurrent;
  $multikey = "";
  Echonow(ucfirst($function) . " in which space? [$spaces]");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who  -> focus;

  Error("\"$multikey\" is not a $function space!"), return unless ($multikey =~ /[$spaces]/);
 FUNCTION: {
    &merge_groups($multikey), last FUNCTION if ($function eq 'merge');
    &difference($multikey),   last FUNCTION if ($function eq 'difference');
    &save_chi($multikey),     last FUNCTION if ($function eq 'save');
  };
};

##   my $message = "";
##   ($message = "Merge data in ...") if ($function eq 'merge');
##   ($message = "Make difference spectra in ...") if ($function eq 'diff');
##   my $hint ="\n\nm n k r & q are keyboard shortcuts for the buttons below";
##   my $dialog =
##     $top -> Dialog(-bitmap         => 'question',
## 		   -text           => $message.$hint,
## 		   -title          => 'Athena: choose space',
## 		   -buttons        => [qw/mu(E) norm(E) chi(k) chi(R) chi(q) cancel/],);
##   $dialog -> bind('<Key-m>' =>
## 		  sub{ (($dialog->children())[1]->children)[1] -> invoke });
##   $dialog -> bind('<Key-n>' =>
## 		  sub{ (($dialog->children())[1]->children)[2] -> invoke });
##   $dialog -> bind('<Key-k>' =>
## 		  sub{ (($dialog->children())[1]->children)[3] -> invoke });
##   $dialog -> bind('<Key-r>' =>
## 		  sub{ (($dialog->children())[1]->children)[4] -> invoke });
##   $dialog -> bind('<Key-q>' =>
## 		  sub{ (($dialog->children())[1]->children)[5] -> invoke });
##   my $response = $dialog->Show();
##   Echo("Aborted!"), return if ($response eq 'cancel');
##   ($space = 'm') if ($response eq 'mu(E)');
##   ($space = 'n') if ($response eq 'norm(E)');
##   ($space = 'k') if ($response eq 'chi(k)');
##   ($space = 'r') if ($response eq 'chi(R)');
##   ($space = 'q') if ($response eq 'chi(q)');
##   $message =~ s/\.\.\./$response/;
##   Echonow($message);



## END OF KEY BINDINGS SUBSECTION
##########################################################################################
