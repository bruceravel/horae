## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  setting up various parts of the display, such as menus and the
##  plot options cards


sub set_menus {

  ## ifeffit command modes:
  ##   bit 1: send to ifeffit
  ##   bit 2: store in ifeffit buffer
  ##   bit 3: display in ifeffit interaction buffer
  ##   bit 4: store in macro buffer
  ##   bit 5: write to STDOUT
  ## normal mode is 5, i.e. bits 1 and 3.

  @group_menuitems = (-menuitems =>
 		      [
		       [ command => "Copy group", -accelerator => 'Ctrl-y',
			-command => \&copy_group],
		       [ command => "Copy series",
			-command => \&series],
		       [ command => "About current group", -accelerator=>'Ctrl-b',
			-command => \&about_group],
		       [ command => "About marked groups", -accelerator=>'Ctrl-B',
			-command => sub{about_marked_groups(\%marked)}],
		       [ command => "Make detector groups", -command=>\&make_detectors,
			-state   => 'disabled'],
		       [ command => "Make background group", -command=>\&make_background,
			-state   => 'disabled'],
		       [ command => "Change group label", -accelerator => 'Ctrl-l',
			-command => \&get_new_name],
		       [ command => "Change record type",
			-command => \&change_record],
		       [ command => "Remove group",
			-command => sub{delete_group($list, $dmode, 0);}],
		       "-",
		       [ command => "Move group up", -accelerator => 'Alt-k',
			-command => \&group_up],
		       [ command => "Move group down", -accelerator => 'Alt-j',
			-command => \&group_down],
		       "-",
		       [ command => "Remove marked groups",
			-command => sub{delete_many($list, $dmode, 1)}],
		       [ command => "Close project", -accelerator=>'Ctrl-w',
			-command => \&close_project],
#		       "-",
 		      ]);


   @values_menuitems = (-menuitems =>
  		      [
		## if using Default Parameters... ----------------------------------------
		       (($use_default) ?
			(['command'=>"Set this group's values to default",
			 -command=>sub{
			   return if ($current eq "Default Parameters");
			   Echo("Resetting parameters for \`$current\' reset to Defaults");
			   $groups{$current}->set_to_another($groups{'Default Parameters'});
			   set_properties(1, $current, 0);
			   Echo(@done);}],
			['command'=>"Set marked groups'  values to default",
			 -command=>sub{
			   Echo("Parameters for marked groups reset to Default Parameters");
			   my $orig = $current;
			   foreach my $x (keys %marked) {
			     next if ($x eq 'Default Parameters');
			     next unless ($marked{$x});
			     $groups{$x}->set_to_another($groups{'Default Parameters'});
			     set_properties(1, $x, 0);
			   };
			   set_properties(1, $orig, 0);
			   Echo(@done);}],
			['command'=>"Set all groups'  values to default",
			 -command=>sub{
			   Echo("Parameters for all groups reset to Default Parameters");
			   my $orig = $current;
			   foreach my $x (keys %marked) {
			     next if ($x eq 'Default Parameters');
			     $groups{$x}->set_to_another($groups{'Default Parameters'});
			     set_properties(1, $x, 0);
			   };
			   set_properties(1, $orig, 0);
			   Echo(@done);}], ) : ()),
                ## end of this Deafult Parameters section --------------------------------

			['command'=>"Set all groups'  values to the current",
			-command=>sub{
			  Echo('No data!'), return unless ($current);
			  Echo("Parameters for all groups reset to \`$current\'");
			  my $orig = $current;
			  foreach my $x (keys %marked) {
			    next if ($x eq 'Default Parameters');
			    next if ($x eq $current);
			    $groups{$x}->set_to_another($groups{$current});
			    set_properties(1, $x, 0);
			  };
			  set_properties(1, $orig, 0);
			  Echo(@done);}],
		       ['command'=>"Set all marked groups'  values to the current",
			-command=>sub{
			  Echo('No data!'), return unless ($current);
			  Echo("Parameters for all marked groups reset to \`$current\'");
			  my $orig = $current;
			  foreach my $x (keys %marked) {
			    next if ($x eq 'Default Parameters');
			    next if ($x eq $current);
			    next unless ($marked{$x});
			    $groups{$x}->set_to_another($groups{$current});
			    set_properties(1, $x, 0);
			  };
			  set_properties(1, $orig, 0);
			  Echo(@done);}],
		       ['command'=>"Set current groups'  values to their defaults",
			-command=>sub{
			  Echo('No data!'), return unless ($current);
			  my @keys = grep {/^(bft|bkg|fft)/} (keys %widget);
			  set_params('def', @keys);
			  set_properties(1, $current, 0);
			  Echo("Reset all values for this group to their defaults");}],
		       "-",
		       ['cascade'=>'Freeze groups', -tearoff=>0,
			-menuitems=>[[ command => 'Toggle this group',    -accelerator => 'Ctrl-f',
				       -command => [\&freeze, 'this'], ],
				     [ command => 'Freeze all groups',    -accelerator => 'Ctrl-F',
				       -command => [\&freeze, 'all']],
				     [ command => 'Unfreeze all groups',  -accelerator => 'Ctrl-U',
				       -command => [\&freeze, 'none']],
				     [ command => "Freeze marked groups", -accelerator => 'Ctrl-M',
				       -command => [\&freeze, 'marked']],
				     [ command => "Unfreeze marked groups",
				       -command => [\&freeze, 'unmarked']],
				     [ command => "Freeze regex",         -accelerator => 'Ctrl-R',
				       -command => [\&freeze, 'regex']],
				     [ command => "Unfreeze regex",
				       -command => [\&freeze, 'unregex']],
				     [ command => 'Toggle all groups',
				       -command => [\&freeze, 'toggle']],
				    ]],
		       "-",
		       ["command"=>"Make current group's values the session defaults",
			-command => sub{
			  Echo("No data!"), return unless $current;
			  my @keys = grep {/^(bft|bkg|fft)/} (keys %widget);
			  session_defaults(@keys);
			  Echo("Made all values for this group the session defaults");
			}],
		       ["command"=>"Unset session defaults",
			-command => \&clear_session_defaults,
		       ],

                ## if using Default Parameters... ------------------------------------------
		       (($use_default) ?
			(['command'=>"Set Defaults to this group's values",
			  -command=>sub{
			    return if ($current eq "Default Parameters");
			    my $orig = $current;
			    Echo("Resetting Default Parameters to those of \`$current\'");
			    $groups{'Default Parameters'}->set_to_another($groups{$current});
			    set_properties(1, 'Default Parameters', 0);
			    set_properties(1, $orig, 0);
			    Echo(@done);}],) : ()),
                ## end of this Deafult Parameters section ---------------------------------

		       "-",
		       ['cascade'=>'Set E0 for THIS group to ...', -tearoff=>0,
			-menuitems=>[
				     [ command => "Ifeffit's default",
				      -command => sub{set_edge($current, 'edge');     autoreplot('e');}],
				     [ command => "zero-crossing of 2nd derivative",
				      -command => sub{set_edge($current, 'zero');     autoreplot('e');}],
				     [ command => "a set fraction of the edge step",
				      -command => sub{set_edge($current, 'fraction'); autoreplot('e');}],
				     [ command => "atomic value",
				      -command => sub{set_edge($current, 'atomic');   autoreplot('e');}],
				     [ command => "the peak of the white line",
				      -command => sub{autoreplot('e') if set_edge_peak($current);}],
				    ]],
		       ['cascade'=>'Set E0 for ALL groups to ...', -tearoff=>0,
			-menuitems=>[
				     [ command => "Ifeffit's default",
				      -command => sub{set_edges('edge', 'all');}],
				     [ command => "zero-crossing of 2nd derivative",
				      -command => sub{set_edges('zero', 'all');}],
				     [ command => "a set fraction of the edge step",
				      -command => sub{set_edges('fraction', 'all');}],
				     [ command => "atomic value",
				      -command => sub{set_edges('atomic', 'all');}],
				     [ command => "the peaks of the white lines",
				      -command => sub{set_edges('peak', 'all');}],
				    ]],
		       ['cascade'=>'Set E0 for MARKED groups to ...', -tearoff=>0,
			-menuitems=>[
				     [ command => "Ifeffit's default",
				      -command => sub{set_edges('edge', 'marked');}],
				     [ command => "zero-crossing of 2nd derivative",
				      -command => sub{set_edges('zero', 'marked');}],
				     [ command => "a set fraction of the edge step",
				      -command => sub{set_edges('fraction', 'marked');}],
				     [ command => "atomic value",
				      -command => sub{set_edges('atomic', 'marked');}],
				     [ command => "the peaks of the white lines",
				      -command => sub{set_edges('peak', 'marked');}],
				    ]],
		       "-",
		       [ command => "Tie reference channel",
			-command => \&tie_reference],
		       "-",
		       [ command => "Purge LCF results from project",
			-command => \&lcf_purge],
		      ]);

  @edit_menuitems = (-menuitems =>
		     [['command'=>"Display Ifeffit buffer", -accelerator => 'Ctrl-1',
		       -command=>sub{raise_palette('ifeffit'); $cmdbox->focus; $top->update;}],
		      ['command'=>"Show group's titles", -accelerator => 'Ctrl-2',
		       -command=>sub{raise_palette('titles');  $top->update;}],
		      ['command'=>"Edit data as text", -accelerator => 'Ctrl-3',
		       -command=>\&setup_data],
		      ['command'=>"Show group's arrays",
		       -command=>sub{Echo('No data!'), return unless ($current);
				     raise_palette('ifeffit');
				     return if ($current eq "Default Parameters");
				     $setup->dispose("show \@group $current\n", $dmode)}],
		      ['command'=>"Show all strings",
		       -command=>sub{raise_palette('ifeffit');
				     $setup->dispose("show \@strings\n", $dmode)}],
		      ['command'=>"Show all macros",
		       -command=>sub{raise_palette('ifeffit');
				     $setup->dispose("show \@macros\n", $dmode)}],
		      ['command'=>"Display echo buffer", -accelerator => 'Ctrl-4',
		       -command=>sub{raise_palette('echo'); }],
		      #"-",
		      ['command'=>"Record a macro", -accelerator => 'Ctrl-5',
		       -command=>sub{raise_palette('macro');}],
		      #['command'=>"Load a macro", -command=>\&load_macro],
		      #"-",
		      ['command'=>"Write in project journal", -accelerator => 'Ctrl-6',
		       -command=>sub{raise_palette('journal'); }],
		      ['cascade'=>"Write a report", -tearoff=>0,
		       -menuitems=>[
				    ['command'=>"Excel report (all groups)",
				     -command=>[\&report_excel, 'all']],
				    ['command'=>"Excel report (marked groups)",
				     -command=>[\&report_excel, 'marked']],
				    "-",
				    ['command'=>"CSV report (all groups)",
				     -command=>[\&report_csv, 'all']],
				    ['command'=>"CSV report (marked groups)",
				     -command=>[\&report_csv, 'marked']],
				    "-",
				    ['command'=>"text report (all groups)",
				     -command=>[\&report_ascii, 'all']],
				    ['command'=>"text report (marked groups)",
				     -command=>[\&report_ascii, 'marked']],
				    "-",
				    ['command'=>"Write an Xfit file",
				     -command=>[\&write_xfit_file]],

				   ]],
		     ]);
};


## This is very ugly, but very repititious.  On each card, there is a
## stack of frames.  In each frame there are two checkbuttons.  To the
## left is a button without text for selecting marked plots.  To the
## right is a button with text for selecting groups plots.
sub set_plotcards {

  ## colors need to be less dark on Windows than on linux.  Other unixes???
  my $red = $config{colors}{single};
  my $vio = $config{colors}{marked};

  ## energy-space options
  ## mu
  my $frame = $plotcard{e} -> Frame() -> pack(-fill=>'x');
  $frame -> Checkbutton(-text=>'mu(E)', -selectcolor=>$red, -command=>\&replot_group_e,
			-onvalue=>'m', -offvalue=>"", -variable=>\$plot_features{e_mu})
    -> grid(-row=>0, -column=>0, -pady=>0, -sticky=>'w');
  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_e,
			-value=>'e', -variable=>\$plot_features{e_marked})
    -> grid(-row=>0, -column=>1, -pady=>0, -sticky=>'w');
  ## mu0
  $frame -> Checkbutton(-text=>'background', -selectcolor=>$red, -command=>\&replot_group_e,
			-onvalue=>'z', -offvalue=>"", -variable=>\$plot_features{e_mu0})
    -> grid(-row=>1, -column=>0, -pady=>0, -sticky=>'w');
  ## pre
  $frame -> Checkbutton(-text=>'pre-edge line', -selectcolor=>$red, -command=>\&replot_group_e,
			-command=>
			sub{($plot_features{e_pre} eq 'p') and
			      (($plot_features{e_norm},$plot_features{e_der})=('',''));
			    &replot_group_e;},
			-onvalue=>'p', -offvalue=>"", -variable=>\$plot_features{e_pre})
    -> grid(-row=>2, -column=>0, -pady=>0, -sticky=>'w');
  ## post
  $frame -> Checkbutton(-text=>'post-edge line', -selectcolor=>$red,
			-command=>
			sub{($plot_features{e_post} eq 't') and
			      (($plot_features{e_norm},$plot_features{e_der})=('',''));
			    &replot_group_e;},
			-onvalue=>'t', -offvalue=>"", -variable=>\$plot_features{e_post})
    -> grid(-row=>3, -column=>0, -pady=>0, -sticky=>'w');
  ## norm
  $frame -> Checkbutton(-text=>'Normalized', -selectcolor=>$red,
			-command=>
			sub{($plot_features{e_norm} eq 'n') and
			      (($plot_features{e_pre},$plot_features{e_post})=('',''));
			    &replot_group_e;},
			-onvalue=>'n', -offvalue=>"", -variable=>\$plot_features{e_norm})
    -> grid(-row=>4, -column=>0, -pady=>0, -sticky=>'w');
  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_e,
			-value=>'n', -variable=>\$plot_features{e_marked})
    -> grid(-row=>4, -column=>1, -pady=>0, -sticky=>'w');
  ## deriv
  $frame -> Checkbutton(-text=>'Derivative', -selectcolor=>$red,
			-command=>
			sub{($plot_features{e_der} eq 'd') and
			      (($plot_features{e_pre},$plot_features{e_post})=('',''));
			    &replot_group_e;},
			-onvalue=>'d', -offvalue=>"", -variable=>\$plot_features{e_der})
    -> grid(-row=>5, -column=>0, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_e,
			-onvalue=>'d', -offvalue=>"", -variable=>\$plot_features{e_mderiv})
    -> grid(-row=>5, -column=>1, -pady=>0, -sticky=>'w');
  ## emin/emax
  my $frm = $frame -> Frame() # -> pack(-expand=>1, -fill=>'x');
    -> grid(-row=>6, -column=>0, -columnspan=>5, -padx=>1, -pady=>2, -sticky=>'we');
  $frm -> Label(-text=>'Emin:') -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{emin},
		   -state=>'normal',
		   -command=>[\&autoreplot,'e'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_emin"])
    -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{emax},
		   -state=>'normal',
		   -command=>[\&autoreplot,'e'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_emax"])
    -> pack(-side=>'right');
  $frm -> Label(-text=>'Emax:') -> pack(-side=>'right');

  ## k choices --------------------------------------------------------------
  $frame = $plotcard{k} -> Frame() -> pack(-fill=>'x', -expand=>1, -side=>'bottom');
#   $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_k,
# 			-value=>'w', -variable=>\$plot_features{k_w})
#     -> grid(-row=>0, -column=>1, -pady=>0, -sticky=>'w');
#   $frame -> Radiobutton(-text=>'chi*k^kw', -selectcolor=>$red, -command=>\&replot_group_k,
# 			-value=>'w', -variable=>\$plot_features{k_w})
#     -> grid(-row=>0, -column=>0, -pady=>0, -sticky=>'w');
#
#   $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_k,
# 			-value=>'0', -variable=>\$plot_features{k_w})
#     -> grid(-row=>1, -column=>1, -pady=>0, -sticky=>'w');
#   $frame -> Radiobutton(-text=>'chi', -selectcolor=>$red, -command=>\&replot_group_k,
# 			-value=>'0', -variable=>\$plot_features{k_w})
#     -> grid(-row=>1, -column=>0, -pady=>0, -sticky=>'w');
#
#   $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_k,
# 			-value=>'1', -variable=>\$plot_features{k_w})
#     -> grid(-row=>2, -column=>1, -pady=>0, -sticky=>'w');
#   $frame -> Radiobutton(-text=>'chi*k'  , -selectcolor=>$red, -command=>\&replot_group_k,
# 			-value=>'1', -variable=>\$plot_features{k_w})
#     -> grid(-row=>2, -column=>0, -pady=>0, -sticky=>'w');
#
#   $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_k,
# 			-value=>'2', -variable=>\$plot_features{k_w})
#     -> grid(-row=>3, -column=>1, -pady=>0, -sticky=>'w');
#   $frame -> Radiobutton(-text=>'chi*k^2', -selectcolor=>$red, -command=>\&replot_group_k,
# 			-value=>'2', -variable=>\$plot_features{k_w})
#     -> grid(-row=>3, -column=>0, -pady=>0, -sticky=>'w');
#
#   $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_k,
# 			-value=>'3', -variable=>\$plot_features{k_w})
#     -> grid(-row=>4, -column=>1, -pady=>0, -sticky=>'w');
#   $frame -> Radiobutton(-text=>'chi*k^3', -selectcolor=>$red, -command=>\&replot_group_k,
# 			-value=>'3', -variable=>\$plot_features{k_w})
#     -> grid(-row=>4, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Checkbutton(-text=>q{}, -selectcolor=>$vio, -command=>\&replot_marked_k,
			-onvalue=>'e', -offvalue=>q{}, -variable=>\$plot_features{chie})
    -> grid(-row=>4, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Plot chi(E)', -selectcolor=>$red, -command=>\&replot_group_k,
			-onvalue=>'e', -offvalue=>q{}, -variable=>\$plot_features{chie})
    -> grid(-row=>4, -column=>0, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Window', -onvalue=>'w', -offvalue=>q{}, -selectcolor=>$red,
			-variable=>\$plot_features{k_win}, -command=>\&replot_group_k,)
    -> grid(-row=>5, -column=>0, -pady=>0, -sticky=>'w');

  $frm = $frame -> Frame()
    -> grid(-row=>6, -column=>0, -columnspan=>5, -pady=>2, -sticky=>'we');
  $frm -> Label(-text=>'kmin:') -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{kmin},
		   -state=>'normal',
		   -command=>[\&autoreplot,'k'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_kmin"])
    -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{kmax},
		   -state=>'normal',
		   -command=>[\&autoreplot,'k'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_kmax"])
    -> pack(-side=>'right');
  $frm -> Label(-text=>'kmax:') -> pack(-side=>'right');


  ## R choices --------------------------------------------------------------
  $frame = $plotcard{r} -> Frame() -> pack(-fill=>'x');
  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_r,
			-value=>'rm', -variable=>\$plot_features{r_marked})
    -> grid(-row=>0, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Magnitude', -onvalue=>'m', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{r_mag},
			-command=> sub{$plot_features{r_env}=''; &replot_group_r; }, )
    -> grid(-row=>0, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Checkbutton(-text=>'Envelope', -onvalue=>'e', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{r_env},
			-command=> sub{$plot_features{r_mag}=''; &replot_group_r; }, )
    -> grid(-row=>1, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_r,
			-value=>'rr', -variable=>\$plot_features{r_marked})
    -> grid(-row=>2, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Real part', -onvalue=>'r', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{r_re}, -command=>\&replot_group_r)
    -> grid(-row=>2, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_r,
			-value=>'ri', -variable=>\$plot_features{r_marked})
    -> grid(-row=>3, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Imaginary part', -onvalue=>'i', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{r_im}, -command=>\&replot_group_r)
    -> grid(-row=>3, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_r,
			-value=>'rp', -variable=>\$plot_features{r_marked})
    -> grid(-row=>4, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Phase', -onvalue=>'p', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{r_pha}, -command=>\&replot_group_r)
    -> grid(-row=>4, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Checkbutton(-text=>'Window', -onvalue=>'w', -offvalue=>"", -selectcolor=>$red,
			      -variable=>\$plot_features{r_win}, -command=>\&replot_group_r)
    -> grid(-row=>5, -column=>0, -pady=>0, -sticky=>'w');

  $frm = $frame -> Frame() ->
    grid(-row=>6, -column=>0, -columnspan=>5, -pady=>2, -sticky=>'we');
  $frm -> Label(-text=>'Rmin:') -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{rmin},
		   -state=>'normal',
		   -command=>[\&autoreplot,'r'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_rmin"])
    -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{rmax},
		   -state=>'normal',
		   -command=>[\&autoreplot,'r'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_rmax"])
    -> pack(-side=>'right');
  $frm -> Label(-text=>'Rmax:') -> pack(-side=>'right');


  ## q choices --------------------------------------------------------------
  $frame = $plotcard{q} -> Frame() -> pack(-fill=>'x');
  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_q,
			-value=>'qm', -variable=>\$plot_features{q_marked})
    -> grid(-row=>0, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Magnitude', -onvalue=>'m', -offvalue=>"", -selectcolor=>$red,
			-command=>sub{$plot_features{q_env}=''; &replot_group_q;},
			-variable=>\$plot_features{q_mag})
    -> grid(-row=>0, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Checkbutton(-text=>'Envelope', -onvalue=>'e', -offvalue=>"", -selectcolor=>$red,
			-command=>sub{$plot_features{q_mag}=''; &replot_group_q;},
			-variable=>\$plot_features{q_env})
    -> grid(-row=>1, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_q,
			-value=>'qr', -variable=>\$plot_features{q_marked})
    -> grid(-row=>2, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Real part', -onvalue=>'r', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{q_re}, -command=>\&replot_group_q)
    -> grid(-row=>2, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_q,
			-value=>'qi', -variable=>\$plot_features{q_marked})
    -> grid(-row=>3, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Imaginary part', -onvalue=>'i', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{q_im}, -command=>\&replot_group_q)
    -> grid(-row=>3, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Radiobutton(-text=>'', -selectcolor=>$vio, -command=>\&replot_marked_q,
			-value=>'qp', -variable=>\$plot_features{q_marked})
    -> grid(-row=>4, -column=>1, -pady=>0, -sticky=>'w');
  $frame -> Checkbutton(-text=>'Phase', -onvalue=>'p', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{q_pha}, -command=>\&replot_group_q)
    -> grid(-row=>4, -column=>0, -pady=>0, -sticky=>'w');

  $frame -> Checkbutton(-text=>'Window', -onvalue=>'w', -offvalue=>"", -selectcolor=>$red,
			-variable=>\$plot_features{q_win}, -command=>\&replot_group_q)
    -> grid(-row=>5, -column=>0, -pady=>0, -sticky=>'w');

  $frm = $frame -> Frame() ->
    grid(-row=>6, -column=>0, -columnspan=>5, -pady=>2, -sticky=>'we');
  $frm -> Label(-text=>'qmin:') -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{qmin},
		   -state=>'normal',
		   -command=>[\&autoreplot,'q'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_qmin"])
    -> pack(-side=>'left');
  $frm -> RetEntry(-width=>5,
		   -textvariable=>\$plot_features{qmax},
		   -state=>'normal',
		   -command=>[\&autoreplot,'q'],
		   -validate=>'key',
		   -validatecommand=>[\&set_variable,"po_qmax"])
    -> pack(-side=>'right');
  $frm -> Label(-text=>'qmax:') -> pack(-side=>'right');

  ## Stack
  $frame = $plotcard{Stack} -> Frame() -> pack(-fill=>'x');
  $frame -> Label(-text=>"Set y-offset values for\nall MARKED groups",
		  -font=>$config{fonts}{small},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -columnspan=>2, -ipady=>5);
  $frame -> Label(-text=>"Initial value", -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $widget{sta_init} = $frame -> Entry(-width=>10, -validate=>'key',
				      -validatecommand=>[\&set_variable, 'sta_init'])
    -> grid(-row=>1, -column=>1, -sticky=>'w', -ipadx=>3);
  $frame -> Label(-text=>"Increment", -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $widget{sta_incr} = $frame -> Entry(-width=>10, -validate=>'key',
				      -validatecommand=>[\&set_variable, 'sta_incr'])
    -> grid(-row=>2, -column=>1, -sticky=>'w', -ipadx=>3);
  $widget{sta_init}->insert('end', 0);
  $widget{sta_incr}->insert('end', 0);
  $frame -> Button(-text=>'Set y-offset values',  @button_list, -borderwidth=>1,
		   -command=> [\&set_stacked_plot, $widget{sta_init}, $widget{sta_incr}],
		   )
    -> grid(-row=>3, -column=>0, -columnspan=>2, -sticky=>'ew', -pady=>3);
  $frame -> Button(-text=>'Reset',  @button_list, -borderwidth=>1,
		   -command=> [\&reset_stacked_plot, $widget{sta_init}, $widget{sta_incr}],
		   )
    -> grid(-row=>4, -column=>0, -columnspan=>2, -sticky=>'ew', -pady=>3);

  ## Plot indicators
  $plotcard{Ind} -> Label(-text=>"Plot indicators",
			  -font=>$config{fonts}{bold},
			  -foreground=>$config{colors}{activehighlightcolor})
     -> pack(-side=>'top');
  $indicator[0] = 0;
  $plotcard{Ind} -> Checkbutton(-text=>'Display indicators', -variable=>\$indicator[0], -selectcolor => $red,)
    -> pack(-expand=>1, -fill=>'x', -side=>'top');
  my $t = $plotcard{Ind} -> Scrolled('Pane',
				     -scrollbars  => 'e',
				     -width	  => 1,
				     -height	  => 1,
				     -borderwidth => 0,
				     -relief	  => 'flat')
    -> pack(-expand=>1, -fill=>'both', -side=>'top', -padx=>3, -pady=>3);
  $t -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  #BindMouseWheel($t);
  #disable_mouse3($t->Subwidget('rotext'));
  foreach my $r (1 .. $config{plot}{nindicators}) {
    $indicator[$r] = ["", " ", " "];
    $t -> Label(-text=>$r.":", -foreground=>$config{colors}{activehighlightcolor})
      -> grid(-row=>$r, -column=>0, -ipadx=>3);
    $t -> Label(-textvariable=>\$indicator[$r][1],
		-width=>3)
      -> grid(-row=>$r, -column=>1);
    my $this = $t -> Entry(-width=>10, -textvariable=>\$indicator[$r][2],
			   -validate=>'key',
			   -validatecommand=>[\&set_variable, "ind_$r"],
			  )
      -> grid(-row=>$r, -column=>2);
    $indicator[$r][0] = $t -> Button(@pluck_button, @pluck, -command=>sub{&indicator_pluck($r)})
      -> grid(-row=>$r, -column=>3);
  };

  ## Pointfinder
  $plotcard{PF} -> Label(-text=>"Point finder",
			 -font=>$config{fonts}{bold},
			 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top');
  $pointfinder{space} = $plotcard{PF} -> Label(-text=>"Last plot was in ?",
					       -font=>$config{fonts}{small})
    -> pack(-side=>'top', -pady=>2);
  $frame = $plotcard{PF} -> Frame()
    -> pack(-side=>'top');
  $frame -> Label(-text=>'X: ', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -padx=>1, -pady=>1);
  $pointfinder{'x'} = $frame -> Entry(-width=>8, -state=>'disabled',
				    -textvariable=>\$pointfinder{xvalue},
				    -validate=>'key', -validatecommand=>[\&set_variable,"pf_x"])
    -> grid(-row=>0, -column=>1, -padx=>1, -pady=>1);
  $pointfinder{xpluck} = $frame -> Button(@pluck_button, @pluck, -state=>'disabled',
					  -command=>sub{&pointfinder_pluck('x')})
    -> grid(-row=>0, -column=>2, -padx=>1, -pady=>1);
  $pointfinder{xfind} = $frame -> Button(-text=>'find Y', @button_list,
					 -state=>'disabled', -borderwidth=>1,
					 -command=>[\&pointfinder_find, 'x'])
    -> grid(-row=>0, -column=>3, -padx=>1, -pady=>1);

  $frame -> Label(-text=>'Y: ', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -padx=>1, -pady=>1);
  $pointfinder{'y'} = $frame -> Entry(-width=>8, -state=>'disabled',
				      -textvariable=>\$pointfinder{yvalue},
				      -validate=>'key', -validatecommand=>[\&set_variable,"pf_y"])
    -> grid(-row=>1, -column=>1, -padx=>1, -pady=>1);
  $pointfinder{ypluck} = $frame -> Button(@pluck_button, @pluck, -state=>'disabled',
					  -command=>sub{&pointfinder_pluck('y')})
    -> grid(-row=>1, -column=>2, -padx=>1, -pady=>1);
  $pointfinder{yfind} = $frame -> Button(-text=>'find X', @button_list,
					 -state=>'disabled', -borderwidth=>1,)
    -> grid(-row=>1, -column=>3, -padx=>1, -pady=>1);

  $pointfinder{clear} = $frame -> Button(-text=>'Clear', @button_list,
					 -state=>'disabled', -borderwidth=>1,
					 -command=>sub{$pointfinder{xvalue}="";
						       $pointfinder{yvalue}="";})
    -> grid(-row=>2, -column=>0, -columnspan=>4, -sticky=>'ew', -padx=>1, -pady=>1);

};


sub set_stacked_plot {
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my ($ini, $inc) = @_;
  my ($yvalue, $yinc) = ($ini->get(), $inc->get());
  ($yvalue = 0) if ($yvalue =~ /^\s*$/);
  ($yinc = 0)   if ($yinc   =~ /^\s*$/);
  my $message = "Set y-offsets for all marked groups starting at "
    . $yvalue . " & incrementing by " . $yinc
      . ". Now click a purple plot button.";
  my $n = 0;
  foreach my $k (&sorted_group_list) {
    next unless $marked{$k};
    ++$n;
    $groups{$k} -> MAKE(plot_yoffset=>sprintf("%.4f",$yvalue));
    $yvalue += $yinc;
  };
  set_properties (1, $current, 0);
  Error("No y-offset parameters were set because there were no marked groups."), return if ($n == 0);
  Error("Only one y-offset parameter was set because there was only one marked group."),
    return if ($n == 1);
  Echo($message);
};

sub reset_stacked_plot {
  my ($ini, $inc) = @_;
  $ini->delete(qw(0 end));
  $ini->insert('end', 0);
  $inc->delete(qw(0 end));
  $inc->insert('end', 0);
  foreach my $k (&sorted_group_list) {
    next unless $marked{$k};
    $groups{$k} -> MAKE(plot_yoffset=>0);
  };
  set_properties (1, $current, 0);
  Echo("Reset stacking parameters and y-offsets for all marked group to 0.");
};



sub indicator_pluck {
  my $which = $_[0];
  my $parent = $_[1] || $top;
  Error("You have not made a plot yet."), return 0 unless ($last_plot);

  Echonow("Select a point from the plot...");
  my ($cursor_x, $cursor_y) = (0,0);
  $indicator[$which][0] -> grab();
  $groups{$current}->dispose("cursor(crosshair=true)\n", $dmode);
  ($cursor_x, $cursor_y) = (Ifeffit::get_scalar("cursor_x"),
			    Ifeffit::get_scalar("cursor_y"));
  $groups{$current}->dispose("\n", $dmode);
  $indicator[$which][0] -> grabRelease();
  $indicator[$which][1] = ($last_plot =~ /[kq]/) ? $last_plot : uc($last_plot);
  $indicator[$which][2] = sprintf("%.3f", $cursor_x);
  Echo("Made an indicator at $indicator[$which][2] in $indicator[$which][1]");
  #$Data::Dumper::Indent = 2;
  #print Data::Dumper->Dump([\@indicator], [qw(indicator)]);
  #$Data::Dumper::Indent = 0;
};

sub pointfinder_pluck {
  my $which = $_[0];
  if ($which eq 'x') {
    Echonow("Select an x value from the plot...");
  } else {
    Echonow("Select a y value from the plot...");
  };
  $pointfinder{$which . 'pluck'}->grab();
  $groups{$current}->dispose("cursor(crosshair=true)\n", $dmode);
  my ($cursor_x, $cursor_y) = (Ifeffit::get_scalar("cursor_x"),
			       Ifeffit::get_scalar("cursor_y"));
  $groups{$current}->dispose("\n", $dmode);
  $pointfinder{$which . 'pluck'} -> grabRelease();
  if ($which eq 'x') {
    $pointfinder{xvalue} = sprintf("%.3f", $cursor_x);
    Echo("You selected an x-axis value of $pointfinder{xvalue}");
  } else {
    $pointfinder{yvalue} = sprintf("%.5f", $cursor_y);
    Echo("You selected a y-axis value of $pointfinder{yvalue}");
  };
};


sub pointfinder_find {
  Error("You haven't specified an $_[0] axis point"), return unless $pointfinder{$_[0].'value'};
  Echo("Not doing y to x yet"), return if ($_[0] eq 'y');
  my $which = $_[0];
  my $space = $$last_plot_params[2];
  my $last  = $$last_plot_params[3];
  my $group = $groups{$current}->{group};
  my $pmult = $groups{$current}->{plot_scale};
  my $yoff  = $groups{$current}->{plot_yoffset};
  my $x     = "";
  my $array = "";		# figure out what we are interpolating
                                # off of -- kinda tricky for energy space
 SWITCH: {
    ($space eq 'e') and do {
      $x = 'energy';
      ($array = "$group.flat+$yoff"),                                    last SWITCH if (($last =~ /m.*n/) and ($last !~ /d/) and $groups{$current}->{bkg_flatten});
      ($array = "$group.norm+$yoff"),                                    last SWITCH if (($last =~ /m.*n/) and ($last !~ /d/));
      ($array = "$pmult*deriv($group.flat)/deriv($group.energy)+$yoff"), last SWITCH if (($last =~ /m.*nd/) and $groups{$current}->{bkg_flatten});
      ($array = "$pmult*deriv($group.norm)/deriv($group.energy)+$yoff"), last SWITCH if  ($last =~ /m.*nd/);
      ($array = "$pmult*deriv($group.xmu)/deriv($group.energy)+$yoff"),  last SWITCH if (($last =~ /m.*d/) and ($last !~ /m.*n/));
      ($array = "$group.xmu+$yoff"),                                     last SWITCH if (($last =~ /m/) and ($last !~ /[nd]/));
      ($array = "$group.fbkg+$yoff"),                                    last SWITCH if (($last !~ /m/) and ($last =~ /z/) and $groups{$current}->{bkg_flatten});
      ($array = "$group.bkg+$yoff"),                                     last SWITCH if (($last !~ /m/) and ($last =~ /z/));
      last SWITCH;
    };
    ($space eq 'k') and do {
      $x = 'k';
      ($array = "$group.chi+$yoff"),             last SWITCH if ($last =~ /k0/);
      ($array = "$group.chi*$group.k+$yoff"),    last SWITCH if ($last =~ /k1/);
      ($array = "$group.chi*$group.k**2+$yoff"), last SWITCH if ($last =~ /k2/);
      ($array = "$group.chi*$group.k**3+$yoff"), last SWITCH if ($last =~ /k3/);
      last SWITCH;
    };
    ($space eq 'r') and do {
      $x = 'r';
      ($array = "$group.chir_mag+$yoff"), last SWITCH if ($last =~ /m/);
      ($array = "$group.chir_re+$yoff"),  last SWITCH if ($last =~ /r/);
      ($array = "$group.chir_im+$yoff"),  last SWITCH if ($last =~ /i/);
      ($array = "$group.chir_pha+$yoff"), last SWITCH if ($last =~ /p/);
      last SWITCH;
    };
    ($space eq 'q') and do {
      $x = 'q';
      ($array = "$group.chiq_mag+$yoff"), last SWITCH if ($last =~ /m/);
      ($array = "$group.chiq_re+$yoff"),  last SWITCH if ($last =~ /r/);
      ($array = "$group.chiq_im+$yoff"),  last SWITCH if ($last =~ /i/);
      ($array = "$group.chiq_pha+$yoff"), last SWITCH if ($last =~ /p/);
      last SWITCH;
    };
  };
  Error("The pointfinder cannot grab a point from the previous plot (" . join(" ", @$last_plot_params) . ")" ), return unless $array;


  $groups{$current} -> dispose("set $group.pf=$array", $dmode);
  my @x = Ifeffit::get_array("$group.$x");
  my @y = Ifeffit::get_array("$group.pf");

  if ($which eq 'x') {
    foreach my $i (0 .. $#x) {
      next if ($x[$i] < $pointfinder{xvalue});
      my $frac = ($pointfinder{xvalue} - $x[$i-1]) / ($x[$i] - $x[$i-1]);
      $pointfinder{yvalue} = sprintf("%.5f", $y[$i-1] + $frac*($y[$i] - $y[$i-1]));
      last;
    };
  } else {
    ### ????
  };
  $groups{$current} -> dispose($Ifeffit::Group::last_plot, $dmode);
  my $eshift = $groups{$current}->{bkg_eshift};

  my $command = "pmarker \"$group.$x+$eshift\", $group.pf, $pointfinder{xvalue}, $config{plot}{pointfinder}, " .
    "$config{plot}{pointfindercolor}, 0\n";
  $groups{$current} -> dispose($command, $dmode);
  $groups{$current} -> dispose("erase $group.pf", $dmode);
  Echo("Found the point ($pointfinder{xvalue},$pointfinder{yvalue})");
};


sub replot_group_e {
  return unless ($current);
  my $str = 'e';
  map {$str .= $plot_features{$_}} (qw/e_mu e_mu0 e_pre e_post e_norm e_der/);
  ($str =~ m{d\z})  and ($str .= "s" x $plot_features{smoothderiv});
  $groups{$current}->plotE($str,$dmode,\%plot_features, \@indicator);
  $last_plot='e';
  $last_plot_params = [$current, 'group', 'e', $str];
};
sub replot_marked_e {
  return unless ($current);
  $groups{$current}->plot_marked($plot_features{e_marked}, $dmode,
				 \%groups, \%marked, \%plot_features, $list,
				 \@indicator);
  $last_plot='e';
  $last_plot_params = [$current, 'marked', 'e', $plot_features{e_marked}];
};

sub replot_group_k {
  return unless ($current);
  my $str = 'k';
  map {$str .= $plot_features{$_}} (qw/k_w k_win/);
  $groups{$current}->plotk($str,$dmode,\%plot_features, \@indicator);
  $last_plot='k';
  $last_plot_params = [$current, 'group', 'k', $str];
};
sub replot_marked_k {
  return unless ($current);
  $groups{$current}->plot_marked($plot_features{k_w}, $dmode,
				 \%groups, \%marked, \%plot_features, $list,
				 \@indicator);
  $last_plot='k';
  $last_plot_params = [$current, 'marked', 'k', $plot_features{k_w}];
};

sub replot_group_r {
  return unless ($current);
  my $str = 'r';
  map {$str .= $plot_features{$_}} (qw/r_mag r_env r_re r_im r_pha r_win/);
  $groups{$current}->plotR($str,$dmode,\%plot_features, \@indicator);
  $last_plot='r';
  $last_plot_params = [$current, 'group', 'r', $str];
};
sub replot_marked_r {
  return unless ($current);
  $groups{$current}->plot_marked($plot_features{r_marked}, $dmode,
				 \%groups, \%marked, \%plot_features, $list,
				 \@indicator);
  $last_plot='r';
  $last_plot_params = [$current, 'marked', 'r', $plot_features{r_marked}];
};

sub replot_group_q {
  return unless ($current);
  my $str = 'q';
  map {$str .= $plot_features{$_}} (qw/q_mag q_env q_re q_im q_pha q_win/);
  $groups{$current}->plotq($str,$dmode,\%plot_features, \@indicator);
  $last_plot='q';
  $last_plot_params = [$current, 'group', 'q', $str];
};
sub replot_marked_q {
  return unless ($current);
  $groups{$current}->plot_marked($plot_features{q_marked}, $dmode,
				 \%groups, \%marked, \%plot_features, $list,
				 \@indicator);
  $last_plot='q';
  $last_plot_params = [$current, 'marked', 'q', $plot_features{q_marked}];
};


## END OF SETUP SUBSECTION
##########################################################################################
