# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## THE FEFF CALCULATION PAGE

sub make_feff {
  my $parent = $_[0];

  my $c = $parent -> Frame(-relief=>'flat',
			   -borderwidth=>0,
			   #@window_size,
			   -highlightcolor=>$config{colors}{background});

  $fefftabs = $c -> NoteBook(-backpagecolor	 => $config{colors}{background},
			     -inactivebackground => $config{colors}{inactivebackground},
			     -font		 => $config{fonts}{med},)
    -> pack(-fill => 'both', -expand=>1, -side => 'bottom');
  foreach (qw/Atoms feff.inp Interpretation/) {
    $feffcard{$_} = $fefftabs -> add($_, -label=>$_, -anchor=>'center',
				     -raisecmd=>[\&set_feff_showing, $_]
				    );
  };


  my @start = (-foreground=>$config{colors}{activehighlightcolor},
	       -font=>$config{fonts}{med});

  my $t = "";			# used for clicky help
  ##   $header{current} = $c ->
  ##     Label(@title2, -text=>"FEFF Calculation",)
  ##       -> pack(-side=>'top', -anchor=>'w', -padx=>6);

  ## atoms information
  &make_atoms($feffcard{Atoms});


  ## feff.inp file
  ##(my $fn = $config{intrp}{unimported}) =~ s/ italic//;
  my $fn = $config{fonts}{fixedsm};
  $widgets{feff_inptext} = $feffcard{'feff.inp'} ->
    Scrolled('TextUndoQuiet',
	     -scrollbars => 'se',
	     -wrap	 => 'none',
	     -font	 => $fn)
      -> pack(-side=>'top', -expand=>1, -fill=>'both', -padx=>3, -pady=>3);
  $widgets{feff_inptext} -> Subwidget("xscrollbar")
    ->configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));
  $widgets{feff_inptext} -> Subwidget("yscrollbar")
    ->configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));
  $widgets{feff_inptext} -> tagConfigure("feffinp", -font=>$fn);
  $widgets{feff_inptext} -> tagConfigure("feffwarn", -font=>$fn, -foreground=>'red3');
  BindMouseWheel($widgets{feff_inptext});

  my $bfr = $feffcard{'feff.inp'} -> Frame ()
    -> pack(-side=>'bottom', -fill=>'x');

  $widgets{help_runfeff} =
    $bfr -> Button(-text=>"Document: Feff and it's input file",  @button2_list,
		   -command=>sub{pod_display("artemis_feffinp.pod")},
		   -width=>1)
	-> pack(-side=>'right', -fill=>'x', -expand=>1, -padx=>2, -pady=>2);

  $widgets{feff_run} = $bfr -> Button(-text=>'Run Feff', @button2_list,
				      -command => sub{&run_feff($current)},
				      -width=>1)
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2, -pady=>2);



  ## Interpretation of Feff calculation

  ##   $t = $feffcard{Interpretation} ->
  ##     Button(@start, -activeforeground=>$config{colors}{mbutton},
  ## 	   -text=>'Interpretation of the FEFF calculation',
  ## 	   -relief=>'flat', -borderwidth=>0,
  ## 	   -command=>[\&Echo, $click_help{'Interpretation of the FEFF calculation'}])
  ##       -> pack(-side=>'top', -anchor=>'c');

  $widgets{feff_intrp_headerbox} = $feffcard{Interpretation} ->
    LabFrame(-label=>'Interpretation of the FEFF Calculation',
	     -foreground=>$config{colors}{activehighlightcolor},
	     -labelside=>'acrosstop')
      -> pack(-side=>'top', -anchor=>'c', -fill=>'x');
  $widgets{feff_intrp_header} = $widgets{feff_intrp_headerbox} ->
    Scrolled('ROText', -height=>5, -scrollbars=>'e',
	     -cursor => $mouse_over_cursor,)
      -> pack(-side=>'top', -anchor=>'c', -fill=>'x');
  $widgets{feff_intrp_header} -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  disable_mouse3($widgets{feff_intrp_header}->Subwidget("rotext"));
  $widgets{feff_intrp_header} -> bind('<ButtonPress-3>',\&intrp_header_menu);
  BindMouseWheel($widgets{feff_intrp_header});



  $widgets{feff_intrp} = $feffcard{Interpretation} ->
    Scrolled('HList',
	     -columns	       => 6,
	     -header	       => 1,
	     -scrollbars       => 'osoe',
	     -selectmode       => 'extended',
	     -selectbackground => $config{colors}{selected},
	     -font	       => $config{fonts}{fixed},
	     -command	       =>
	     sub{
	       my $which   = $widgets{feff_intrp}->selectionGet();
	       my $this;
	       my $nnnn    = sprintf("feff%4.4d.dat", $widgets{feff_intrp}->itemCget($which, 0, '-text'));
	       foreach my $k (sort (keys %paths)) {
		 next unless (ref($paths{$k}) =~ /Ifeffit/);
		 next unless ($paths{$k}->type eq 'path');
		 next unless ($paths{$k}->get('parent') eq $current);
		 $this = $paths{$k}->get('id'), last
		   if ($paths{$k}->get('feff') eq $nnnn);
	       };
	       ($list->selectionIncludes($this)) ?
		 $list->selectionClear($this) : $list->selectionSet($this);
	     })
      -> pack(-side=>'top', -expand=>1, -fill=>'both', -padx=>3, -pady=>3);

  $widgets{feff_intrp} -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $widgets{feff_intrp} -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $widgets{feff_intrp} -> bind('<ButtonPress-3>',\&snarf_path);


  $intrp_styles{header} = $widgets{feff_intrp} ->
    ItemStyle('text', -font=>$config{fonts}{smbold}, -anchor=>'w',
	      -foreground=>$config{colors}{foreground});
  foreach my $s (qw(normal ss focus)) {
    my $color = ($s eq 'normal') ? $config{colors}{background} : $config{intrp}{$s};
    my @list = ('text',
		-font		  => $config{fonts}{fixed},
		-background	  => $color,
		#-cursor		  => $mouse_over_cursor,
		-selectbackground => $color,
		-activebackground => $color);
    ## styles for included paths
    $intrp_styles{$s}           = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'center', -foreground => $config{colors}{foreground});
    $intrp_styles{$s."_amp"}    = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'e', -foreground => $config{colors}{foreground});
    $intrp_styles{$s."_path"}   = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'w', -foreground => $config{colors}{foreground});

    ## styles for excluded paths
    $intrp_styles{$s."_x"}      = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'center', -foreground => $config{intrp}{excluded}, -selectforeground => $config{intrp}{excluded});
    $intrp_styles{$s."_amp_x"}  = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'e', -foreground => $config{intrp}{excluded}, -selectforeground => $config{intrp}{excluded});
    $intrp_styles{$s."_path_x"} = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'w', -foreground => $config{intrp}{excluded}, -selectforeground => $config{intrp}{excluded});

    ## styles for absent paths
    $intrp_styles{$s."_a"}      = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'center', -foreground => $config{intrp}{absent}, -font => $config{intrp}{unimported}, -selectforeground => $config{intrp}{absent});
    $intrp_styles{$s."_amp_a"}  = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'e', -foreground => $config{intrp}{absent}, -font => $config{intrp}{unimported}, -selectforeground => $config{intrp}{absent});
    $intrp_styles{$s."_path_a"} = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'w', -foreground => $config{intrp}{absent}, -font => $config{intrp}{unimported}, -selectforeground => $config{intrp}{absent});

    ## styles for unimported paths
    $intrp_styles{$s."_u"}      = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'center', -foreground => $config{colors}{foreground}, -font => $config{intrp}{unimported});
    $intrp_styles{$s."_amp_u"}  = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'e', -foreground => $config{colors}{foreground}, -font => $config{intrp}{unimported});
    $intrp_styles{$s."_path_u"} = $widgets{feff_intrp} ->
      ItemStyle(@list,  -anchor => 'w', -foreground => $config{colors}{foreground}, -font => $config{intrp}{unimported});

  };


  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(0,
							     -text=>"#",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});
  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(1,
							     -text=>"Deg.",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});
  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(2,
							     -text=>"Reff",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});
  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(3,
							     -text=>"amp.",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});
  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(4,
							     -text=>"fs",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});
  $widgets{feff_intrp} -> Subwidget("hlist") -> headerCreate(5,
							     -text=>"Scattering Path",
							     -style=>$gds_styles{header},
							     -headerbackground=>$config{colors}{background});


  BindMouseWheel($widgets{feff_intrp});

  $widgets{help_intrp} =
    $feffcard{Interpretation}
      -> Button(-text=>'Document: Feff interpretation',  @button2_list,
		-command=>sub{pod_display("artemis_intrp.pod")} )
	-> pack(-side=>'bottom', -fill=>'x', -pady=>2);

  return $c;
};


sub set_feff_showing {
  return unless defined($widgets{feff_inptext}->Subwidget("yscrollbar"));
  $paths{$current}->make(feff_showing=>$_[0],
			 feff_inp_location=>
			 ($widgets{feff_inptext}->Subwidget("yscrollbar")->get())[0],
			 feff_intrp_location=>
			 ($widgets{feff_intrp}  ->Subwidget("yscrollbar")->get())[0]
			);
};



sub intrp_header_menu {
  my $w = shift;
  my $Ev = $w->XEvent;
  my ($X, $Y) = ($Ev->X, $Ev->Y);
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[
		      [ command => "View log of feff run",
			-command => [\&display_file, 'feff', 'feff.run']],
		      [ command => "View misc.dat",
			-command => [\&display_file, 'feff', 'misc.dat']],
		      [ command => "View files.dat",
			-command => [\&display_file, 'feff', 'files.dat']],
		      [ command => "View paths.dat",
			-command => [\&display_file, 'feff', 'paths.dat']],
		     ])
      -> Post($X, $Y);
  $w -> break;
  return;
};



sub snarf_path {

  ## figure out where the user clicked
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my $entry = $w->GetNearest($Ev->y, 1);
  return unless (defined($entry) and length($entry));

  ## select and anchor the right-clicked parameter
  my @sel = $w->selectionGet();
  $w->anchorSet($entry);
  my $clicked = $w->info('anchor');
  if (grep {/^$clicked$/} @sel) {
    ## right click within the current extended selection
    1;
  } else {
    ## right clicked outside the current extended selection
    $w->selectionClear;
    $w->selectionSet($entry);
    @sel = $w->selectionGet();
  };

  ## post the message with path-appropriate text
  my $which   = $w->infoAnchor;
  my $nnnn    = sprintf("feff%4.4d.dat", $w->itemCget($which, 0, '-text'));
  my ($X, $Y) = ($Ev->X, $Ev->Y);

  my $file = File::Spec->catfile($paths{$current}->get('path'), $nnnn);
  my $lab = "";
  my ($this, @these) = ("", ());
  ## the use of sort here is crufty, but it should mean that the first
  ## example of a path in the list which uses the feffNNNN.dat file
  ## indicated by $nnnn will be first

  ## These next two blocks map the anchor and the selection on the
  ## intrp to the corresponding paths in DPL.
  foreach my $k (sort (keys %paths)) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'path');
    next unless ($paths{$k}->get('parent') eq $current);
    ($lab,$this) = ($paths{$k}->get('lab'), $paths{$k}->get('id')), last
      if ($paths{$k}->get('feff') eq $nnnn);
  };
  my $anchor = $lab;
  if ($#sel>0) {
    $lab = "these paths";
    my $ii = 0;
    foreach my $s (@sel) {
      my $nnnn    = sprintf("feff%4.4d.dat", $w->itemCget($s, 0, '-text'));
    INNER: foreach my $k (sort (keys %paths)) {
	next unless (ref($paths{$k}) =~ /Ifeffit/);
	next unless ($paths{$k}->type eq 'path');
	next unless ($paths{$k}->get('parent') eq $current);
	push(@these, $paths{$k}->get('id')), last INNER
	  if ($paths{$k}->get('feff') eq $nnnn);
      };
      $these[$ii] ||= 0;
      ++$ii;
    };
  } else {
    ## if the selection and the anchor are the same, put the anchor
    ## and it's path in these arrays
    $lab = "\"" . $lab . "\"";
    @these = ($this);
    @sel = ($which);
  };

  ## some menu items are greyed out for multiple selection, some are
  ## greyed out for excluded paths
  if ($this) {
    $top ->
      Menu(-tearoff=>0,
	   -menuitems=>[['cascade' => "Plot data and $lab in ...",
			 -state=>($paths{$this}->get('include')) ? 'normal' : 'disabled',
			 -tearoff  => 0,
			 -menuitems=> [[ command => 'k',
				        -command => sub{&plot_path(\@these, 'k')}],
				       [ command => 'R',
				        -command => sub{&plot_path(\@these, 'R')}],
				       [ command => 'q',
				        -command => sub{&plot_path(\@these, 'q')}]]],
			['command' => "Jump to \"$anchor\"",
			 #-state => ($#sel>0) ? 'disabled' : 'normal',
			 -command  => sub{display_page($this)}],
			['command' =>
			 ($paths{$this}->get('include')) ? "Exclude $lab" : "Include $lab",
			 -command  => sub{
			   my $onoff = $paths{$this}->get('include');
			   foreach my $p (0..$#these) {
			     next unless exists $paths{$these[$p]};
			     if ($onoff) {
			       &select_paths('off', $these[$p], 1);
			     } else {
			       &select_paths('on',  $these[$p], 1);
			     };
			   };
			   &display_properties;
			   map {$widgets{feff_intrp}->selectionSet($_)} @sel;
			 }],
			['command' =>
			 (grep {$_ eq $this} $list->info('selection')) ? "Deselect $lab" : "Select $lab",
			 -state=>($paths{$this}->get('include')) ? 'normal' : 'disabled',
			 -command  => sub{my $how = (grep {$_ eq $this} $list->info('selection')) ? 1 : 0;
					  &path_select($how)}],
			['command' => "Plot $lab after fit",
			 -command  => sub{
			   foreach my $p (keys %paths) {
			     next unless ($paths{$p}->type eq 'path');
			     set_plotpath($p, 0);
			   };
			   foreach my $p (0..$#these) {
			     next unless (exists $paths{$these[$p]});
			     set_plotpath($these[$p], 1);
			   };
			 }],
			['command' => "Mark \"$anchor\" as current",
			 #-state => (($#sel>0) or not $paths{$this}->get('include')) ? 'disabled' : 'normal',
			 -command  => sub{&set_path_index($this)}],
			"-",
			['cascade' => "Edit path parameters",
			 -tearoff  => 0,
			 -menuitems=> [[ command => 'label',
				        -command => sub{&add_mathexp('label')}],
				       [ command => 'S02',
				        -command => sub{&add_mathexp('S02')}],
				       [ command => 'delE0',
				        -command => sub{&add_mathexp('E0')}],
				       [ command => 'delR',
				        -command => sub{&add_mathexp('delR')}],
				       [ command => 'sigma^2',
				        -command => sub{&add_mathexp('sigma^2')}],
				       [ command => 'Ei',
				        -command => sub{&add_mathexp('Ei')}],
				       [ command => '3rd',
				        -command => sub{&add_mathexp('3rd')}],
				       [ command => '4th',
				        -command => sub{&add_mathexp('4th')}],
					]],
			"-",
			[ command => "Show geometry for \"$anchor\"",
			 -command => [\&display_path_header, $this]],
			[ command => "View \"$anchor\"",
			 #-state => ($#sel>0) ? 'disabled' : 'normal',
			 -command => [\&display_file, 'path', $nnnn]],
			"-",
			['command' => "Discard $lab",
			 -command  => sub{
			   foreach my $p (0..$#these) {
			     next unless exists $paths{$these[$p]};
			     my $style = 'normal';
			     $style = "focus" if ($widgets{feff_intrp} -> itemCget($sel[$p],4,'-text') =~ /\d/);
			     $style = "ss"    if ($paths{$these[$p]} -> get('nleg') == 2);
			     &delete_path($these[$p]);
			   };
			   &display_properties;
			   map {$widgets{feff_intrp}->selectionSet($_)} @sel;
			 }],
		       ])
	-> Post($X,$Y);
  } elsif (-e $file) {
    my $text = ($#sel>0) ? "these paths" : $nnnn;
    $top ->
      Menu(-tearoff=>0,
	   -menuitems=>[[ command => "Add $text to the path list",
			 -command => sub {
			   foreach my $w (0..$#sel) {
			     next if ((exists $these[$w]) and (exists $paths{$these[$w]}));
			     my $nnnn    = sprintf("feff%4.4d.dat", $widgets{feff_intrp}->itemCget($sel[$w], 0, '-text'));
			     my $file = File::Spec->catfile($paths{$current}->get('path'), $nnnn);
			     add_a_path($file, 1, 0);
			   };
			   &display_properties;
			   map {$widgets{feff_intrp}->selectionSet($_)} @sel;
			 }],
			[ command => "Add and jump to $nnnn",
			 -state   => ($#sel>0) ? 'disabled' : 'normal',
			 -command => sub {
			   foreach my $w (0..$#sel) {
			     next if ((exists $these[$w]) and (exists $paths{$these[$w]}));
			     my $nnnn    = sprintf("feff%4.4d.dat", $widgets{feff_intrp}->itemCget($sel[$w], 0, '-text'));
			     my $file = File::Spec->catfile($paths{$current}->get('path'), $nnnn);
			     add_a_path($file, 0, 0);
			   };
			 }],
			(($config{histogram}{use}) ?
			 ("-",
			  [ command => "Make histogram using $nnnn",
			   -state   => ($#sel>0) ? 'disabled' : 'normal',
			   -command => [\&histogram, $lab]]) : ()),
			"-",
			[ command => "Show geometry for $anchor",
			 -command => sub {
			   $paths{toss} = Ifeffit::Path -> new(id     => "toss",
							       lab    => $nnnn,
							       type   => 'path',
							       feff   => $nnnn,
							       parent => $current,
							       path   => $paths{$current}->{path},
							       data   => $paths{$current}->{data},
							       family => \%paths);
			   my $header = nnnn_header("toss", File::Spec->catfile($paths{$current}->get('path'),
								   $nnnn));
			   $paths{toss} -> make(header => $header);
			   display_path_header("toss");
			   delete $paths{toss};
			 }],
			[ command => "View $anchor",
			 #-state => ($#sel>0) ? 'disabled' : 'normal',
			 -command => [\&display_file, 'path', $nnnn]],
		       ])
	-> Post($X, $Y);
  } else {
    $top ->
      Menu(-tearoff=>0, -disabledforeground => 'black',
	   -menuitems=>[[ command => "The file $nnnn does not exist.",
			 -state   => 'disabled',
			],
			[ command => "Perhaps you should rerun Feff.",
			 -state   => 'disabled',
			]])
	-> Post($X, $Y);
  };
};


sub path_select {
  my $how = $_[0];
  my @which   = $widgets{feff_intrp}->selectionGet();
  my $this;
  foreach my $w (@which) {
    my $nnnn    = sprintf("feff%4.4d.dat", $widgets{feff_intrp}->itemCget($w, 0, '-text'));
    foreach my $k (sort (keys %paths)) {
      next unless (ref($paths{$k}) =~ /Ifeffit/);
      next unless ($paths{$k}->type eq 'path');
      next unless ($paths{$k}->get('parent') eq $current);
      $this = $paths{$k}->get('id'), last
	if ($paths{$k}->get('feff') eq $nnnn);
    };
    ($how) ? $list->selectionClear($this) : $list->selectionSet($this);
  };
};

sub populate_feff {
  my $this = $_[0];

  $fefftabs -> pageconfigure('Atoms',          -state=>'disabled');
  $fefftabs -> pageconfigure('feff.inp',       -state=>'disabled');
  $fefftabs -> pageconfigure('Interpretation', -state=>'disabled');

  ## there is atoms data associated with this feff calc
  if ($paths{$current}->{mode} & 1) {
    $fefftabs -> pageconfigure('Atoms', -state=>'normal');
    $atoms_params{edge} = ucfirst($paths{$current}->get('atoms_edge'));
    $atoms_params{core} = lc($paths{$current}->get('atoms_core'));
    $atoms_params{core} ||= "^^nothing^^";

##     foreach my $k (grep /^atoms_core/, keys(%widgets)) {
##       $widgets{$k} -> configure(-value => "");
##       my $n = (split(/_/, $k))[2];
##       $widgets{$k} -> configure(-value => $n);
##       next unless ($paths{$current}->get("atoms_elem_$n") and
## 		   ($paths{$current}->get("atoms_elem_$n") !~ /^\s*$/));
##       $widgets{$k} -> configure(-value => lc($paths{$current}->get("atoms_tag_$n"))  ||
## 				          lc($paths{$current}->get("atoms_elem_$n")) ||
## 			                  $n );
##     };

    ## populate the table of sites
    populate_atoms($current);
    $atoms_params{edge} = $paths{$current}->get("atoms_edge");

    ## transfer the atoms_* values to the atoms_* widgets
    foreach my $k (grep /^atoms_/, keys(%{$paths{$current}})) {
      next if ($k =~ /_(atoms|edge|occ|core|titles)/);
      $widgets{$k} -> configure(-validate=>'none');
      $widgets{$k} -> delete(0, 'end');
      $widgets{$k} -> configure(-validate=>'key'), next
	if (($k =~ /(a|b|c|alpha|beta|gamma)$/) and ($paths{$current}->get($k) =~ /^(\s*|0)$/));
      $widgets{$k} -> configure(-validate=>'key'), next
	if (($k =~ /(alpha|beta|gamma)$/)       and ($paths{$current}->get($k) =~ /^(\s*|90)$/));
      $widgets{$k} -> insert('end', $paths{$current}->get($k));
      $widgets{$k} -> configure(-validate=>'key');
    };
    $widgets{atoms_titles} -> delete('1.0', 'end');
    my $titles = $paths{$current}->get('atoms_titles');
    $titles =~ s/<NL>/\n/g;
    $titles ||= "";
    $widgets{atoms_titles} -> insert('end', $titles);
  };


  ## there is a feff.inp file associated with this feff calc.
  if ($paths{$current}->get('mode') & 2) {
    $fefftabs -> pageconfigure('feff.inp', -state=>'normal');
    $widgets{feff_inptext} -> delete('1.0', 'end');
    if (-e $paths{$current}->get('feff.inp')) {
      local $/ = undef;
      open FI, $paths{$current}->get('feff.inp');
      $widgets{feff_inptext} -> insert('1.0', <FI>, "feffinp");
      $widgets{feff_inptext} -> FindAndReplaceAll("-regexp", "-nocase", "\r", "") if not $is_windows;
      close FI;
    } else {
      $widgets{feff_inptext} -> insert('1.0', "No feff.inp file found for this Feff calculation.", "feffwarn");
    };
    $widgets{feff_inptext} -> yviewMoveto($paths{$current}->get('feff_inp_location')||0);
    $widgets{feff_inptext} -> ResetUndo;
  };

  ## feff has been run and the intrp box needs to be filled
  if ($paths{$current}->get('mode') & 4) {
    $fefftabs -> pageconfigure('Interpretation', -state=>'normal');
    intrp_fill($current);
  };

  if ($paths{$current}->get('feff_showing')) {
    $fefftabs -> raise($paths{$current}->get('feff_showing'));
  } elsif ($paths{$current}->get('mode') & 4) {
    $fefftabs -> raise('Interpretation');
  } elsif ($paths{$current}->get('mode') & 2) {
    $fefftabs -> raise('feff.inp');
  } else {
    $fefftabs -> raise('Atoms');
  };

};



sub intrp_fill {
  my $which = $_[0];
  $widgets{feff_intrp} -> delete('all');
  $widgets{feff_intrp_header} -> delete(qw(1.0 end));
  my $i = 1;
  foreach my $l (split(/\n/, $paths{$which}->get('intrp'))) {

    next if ($l =~ /^\#\s*$/);
    next if ($l =~ /^\#\s*---/);
    next if ($l =~ /^\#\s*degen/);
    ## this is a header line
    ($l =~ /^\#/) and do {
      $l =~ s{\r}{};
      $widgets{feff_intrp_header} -> insert('end', $l."\n");
      next;
    };

    $widgets{feff_intrp}->add($i);
    my @line = split(" ", $l);
    shift @line;

    ## determine if this line describes a path which is included,
    ## excluded, absent, or unimported
    my $nnnn = "feff" . $line[0] . ".dat";
    my $style = "_u";
    my $file = File::Spec->catfile($paths{$current}->get('path'), $nnnn);
    if (-e $file) {
      my $this;
      ## the use of sort here is crufty, but it should mean that the first
      ## example of a path in the list which uses the feffNNNN.dat file
      ## indicated by $nnnn will be first
      foreach my $k (sort (keys %paths)) {
	next unless (ref($paths{$k}) =~ /Ifeffit/);
	next unless ($paths{$k}->type eq 'path');
	next unless ($paths{$k}->get('parent') eq $current);
	if ($paths{$k}->get('feff') eq $nnnn) {
	  $style = ($paths{$k}->get('include')) ? "" : "_x";
	  last;
	};
      };
    } else {
      $style = "_a";
    };

  SWITCH: {			# the $style variable tells us how to
                                # do the font, this switch is about
                                # the background (SS|focused|neither)

      ## this is a SS path
      ($l =~ /^2/) and do {
	$widgets{feff_intrp} -> itemCreate($i, 0, -text=>sprintf("%-3d", shift @line),
					   -style=>$intrp_styles{"ss".$style});
	$widgets{feff_intrp} -> itemCreate($i, 1, -text=>shift @line,
					   -style=>$intrp_styles{"ss".$style});
	$widgets{feff_intrp} -> itemCreate($i, 2, -text=>shift @line,
					   -style=>$intrp_styles{"ss".$style});
	$widgets{feff_intrp} -> itemCreate($i, 3, -text=>shift @line,
					   -style=>$intrp_styles{"ss_amp".$style});
	$widgets{feff_intrp} -> itemCreate($i, 4, -text=>"",
					   -style=>$intrp_styles{"ss".$style});
	shift @line;
	$widgets{feff_intrp} -> itemCreate($i, 5, -text=>join(" ", @line),
					   -style=>$intrp_styles{"ss_path".$style});
	last SWITCH;
      };

      ## this is a focussed MS path
      ($l =~ /[1-9] :/) and do {
	$widgets{feff_intrp} -> itemCreate($i, 0, -text=>sprintf("%-3d", shift @line),
					   -style=>$intrp_styles{"focus".$style});
	$widgets{feff_intrp} -> itemCreate($i, 1, -text=>shift @line,
					   -style=>$intrp_styles{"focus".$style});
	$widgets{feff_intrp} -> itemCreate($i, 2, -text=>shift @line,
					   -style=>$intrp_styles{"focus".$style});
	$widgets{feff_intrp} -> itemCreate($i, 3, -text=>shift @line,
					   -style=>$intrp_styles{"focus_amp".$style});
	$widgets{feff_intrp} -> itemCreate($i, 4, -text=>shift @line,
					   -style=>$intrp_styles{"focus".$style});
	shift @line;
	$widgets{feff_intrp} -> itemCreate($i, 5, -text=>join(" ", @line),
					   -style=>$intrp_styles{"focus_path".$style});
	last SWITCH;
      };

      ## this is a line that could not be interpretted
      ($l =~ /^\s*Could/) and do {
	## this should never happen if feff is run within Artemis,
	## deal with a flawed imported calculation when the time comes
	last SWITCH;
      };

      ## this is a normal line
      do {
	$widgets{feff_intrp} -> itemCreate($i, 0, -text=>sprintf("%-3d", shift @line),
					   -style=>$intrp_styles{"normal".$style});
	$widgets{feff_intrp} -> itemCreate($i, 1, -text=>shift @line,
					   -style=>$intrp_styles{"normal".$style});
	$widgets{feff_intrp} -> itemCreate($i, 2, -text=>shift @line,
					   -style=>$intrp_styles{"normal".$style});
	$widgets{feff_intrp} -> itemCreate($i, 3, -text=>shift @line,
					   -style=>$intrp_styles{"normal_amp".$style});
	$widgets{feff_intrp} -> itemCreate($i, 4, -text=>"",
					   -style=>$intrp_styles{"normal".$style});
	shift @line;
	$widgets{feff_intrp} -> itemCreate($i, 5, -text=>join(" ", @line),
					   -style=>$intrp_styles{"normal_path".$style});
	last SWITCH;
      };
    };

    ++$i;
  };

};


sub feff_template {

  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Do you want to import an existing feff.inp file or start with a blank page?",
		   -title          => 'Artemis: Question...',
		   -buttons        => ['Import feff.inp', 'Blank page', 'Cancel'],
		   -default_button => 'Blank page',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $answer = $dialog->Show();
  if ($answer eq 'Cancel') {
    Echo("Canceled new Feff");
    return;
  } elsif ($answer eq 'Import feff.inp') {
    Echo("Importing Feff file");
    read_feff(0);
    return;
  } else {
    Echo("Making Feff template");
  };


  ## =============================== empty data structures
  my $cell = Xray::Xtal::Cell -> new();
  my $keywords = Xray::Atoms -> new();
  $keywords -> make(identity=>"the Feff template generator in Artemis $VERSION",
		    die=>0);

  ## =============================== make the template
  my $contents = "";
  my (@cluster, @neutral);
  my $atp = "template".$config{atoms}{feff_version};
  ($atp = 'template8_exafs') if ($config{atoms}{feff_version} eq '8');
  my ($default_name, $is_feff) =
    &parse_atp($atp, $cell, $keywords, \@cluster, \@neutral, \$contents);

  ## this is a new feff calc, so make an object and a space to
  ## display it
  my $data = $paths{$current}->data;
  ## assign an id to this feff calc
  my $id = $data . '.feff' . $n_feff;

  ## &initialize_project(0);
  ## make a project feff folder
  my $project_feff_dir = &initialize_feff($id);

  $paths{$id} = Ifeffit::Path -> new(id		 => $id,
				     type	 => 'feff',
				     path	 => File::Spec->catfile($project_folder, $id),
				     data	 => $data,
				     lab	 => 'FEFF'.$n_feff,
				     family	 => \%paths,
				     atoms_atoms => []
				    );
  initialize_atoms($id);
  $paths{$id} -> make(mode=>2);
  my @autoparams;
  $#autoparams = 6;
  (@autoparams = autoparams_define($id, $n_feff, 0, 0)) if $config{autoparams}{do_autoparams};
  $paths{$id} -> make(autoparams=>[@autoparams]);



  $list -> add($id, -text=>'FEFF'.$n_feff, -style=>$list_styles{noplot});
  $list -> setmode($id, 'close');
  $list -> setmode($paths{$data}->get('id'), 'close')
    if ($list -> getmode($paths{$data}->get('id')) eq 'none');

  &set_fit_button('fit');
  display_page($id);
  project_state(0);
  ++$n_feff;


  ## and save it top a file in the project space
  my $feff_file = File::Spec->catfile($project_folder, $id, "feff.inp");
  open  FEFFFILE, ">".$feff_file or die "could not open $feff_file for writing";
  print FEFFFILE $contents;
  close FEFFFILE;



  $widgets{feff_inptext} -> Load(File::Spec->catfile($project_folder, $id, "feff.inp"));
  $widgets{feff_inptext} -> tagAdd("feffinp", qw(1.0 end));
  $widgets{feff_inptext} -> ResetUndo;
  $fefftabs -> pageconfigure('feff.inp', -state=>'normal');
  $fefftabs -> raise('feff.inp');

  undef $cell;
  undef $keywords;

  Echo("Generated a template feff.inp for feff$config{atoms}{feff_version}");


};



# sub change_path {
#   my $parent = $current;
#   $parent = $paths{$current}->get('parent') if ($paths{$current}->type eq "path");
#   ## what about case of current = data or fit|diff|bkg|res???
#   #$parent = $paths{$current}->get('parent') if ($paths{$current}->type eq "path");
#
#   #my $start = $paths{$parent}->get('path') || $current_data_dir;
#   #(-d $start) or ($start = $current_data_dir);
#   my $dir = "";
#   if ($Tk::VERSION < 804) {
#     $dir = $top -> DirSelect(-width=>40, -dir=>$current_data_dir,
# 			     -title=> "Artemis: Select a directory",
# 			     -text => "Select the correct path to your FEFF calculation",
# 			    ) -> Show;
#   } else {
#     $dir = $top -> chooseDirectory;
#   };
#   return 0 unless $dir;
#   ($dir =~ /^\/\//) and ($dir = substr($dir, 1)); # single leading slash
#   ($dir =~ /\/$/) or ($dir .= '/'); # trailing slash
#   ($is_windows) and ($dir =~ s/\//\\/g); # windows-ify slashes
#
#   my $which = "";
#   if ($paths{$current}->type =~ /(bkg|data|diff|fit|res)/) {
#     my $d = $1;
#     foreach my $p (keys %paths) {
#       next unless (ref($paths{$p}) =~ /Ifeffit/);
#       next unless $paths{$p}->type;
#       next unless ($p =~ /feff\d$/);
#       next unless ($paths{$p}->data eq $d);
#       $paths{$p} -> make(path=>$dir);
#       $paths{$p} -> make(mode=>2) if (-e $paths{$p}->get('feff.inp'));
#       my $intrp_ok = &do_intrp($p);
#       $paths{$p} -> make(mode=>$paths{$p}->get('mode')+4) if $intrp_ok;
#       $which = $p;
#     };
#   } else {
#     $paths{$parent} -> make(path=>$dir);
#     $paths{$parent} -> make(mode=>2) if (-e $paths{$parent}->get('feff.inp'));
#     my $intrp_ok = &do_intrp($parent);
#     $paths{$parent} -> make(mode=>$paths{$parent}->get('mode')+4) if $intrp_ok;
#     $which = $parent;
#   };
#
#   ## fixy up the path headers
#   foreach my $p (keys %paths) {
#     next unless (ref($paths{$p}) =~ /Ifeffit/);
#     next unless $paths{$p}->type;
#     next unless ($paths{$p}->get('parent') eq $which);
#
#     my $fname = $paths{$p}->{feff};
#     if (-e File::Spec->catfile($paths{$which}->get('path'), $fname)) {
#       $paths{$p} -> make(feff=>$fname);
#     ## try it lower case
#     } elsif (-e File::Spec->catfile($paths{$which}->get('path'), lc($fname))) {
#       $paths{$p} -> make(feff=>lc($fname));
#     ## try it upper case
#     } elsif (-e File::Spec->catfile($paths{$which}->get('path'), uc($fname))) {
#       $paths{$p} -> make(feff=>uc($fname));
#     ## try it capitalized
#     } elsif (-e File::Spec->catfile($paths{$which}->get('path'), uc($fname))) {
#       $paths{$p} -> make(feff=>ucfirst($fname));
#     ## uh oh!
#     } else {
#       1;
#     };
#
#
#     my $file = File::Spec->catfile($paths{$which}->get('path'), $paths{$p}->get('feff'));
#     if (-e $file) {
#       $paths{$p} -> make(header=>nnnn_header($p, $file));
#     } else {
#       $paths{$p} -> make(header=>"", include=>0);
#       $list -> entryconfigure($p, -style => $list_styles{$paths{$p}->pathstate("disabled")});
#     };
#   };
#
#   $current_data_dir = $dir;
#   display_properties;
# };


sub do_intrp {
  my $id = $_[0];
  my $retval = 0;
  Echo("Doing intrp for " . $paths{$id}->get('lab') . " ...");
#  $widgets{feff_intrp} -> delete(qw(1.0 end));
  if ((-e $paths{$id}->get('feff.inp')) and (-e $paths{$id}->get('files.dat')) and
      (-e $paths{$id}->get('paths.dat'))) {
    $paths{$id}->make(intrp=>$paths{$id}->intrp($config{intrp}{betamax},
						$config{intrp}{core_token}));
    my $data = $paths{$id}->data;
    if (lc($paths{$data}->get('pcelem')) eq 'h') {
      $paths{$data}->make(pcelem=>$paths{$id}->get('central'),
			  pcedge=>$paths{$id}->get('edge'));
    };
    #intrp_fill($id);
    $retval = 1;
  } else {
    my @files = grep { ! -e $paths{$id}->get($_) } (qw(feff.inp files.dat paths.dat));
    my $string = reverse(join(", ", @files));
    $string =~ s/,/ro\/dna ,/;
    $string = reverse $string;
    ##Echo("Could not find " . $string);
    $paths{$id}->make(intrp=>" Could not find " . $string);
  };
  Echo("Doing intrp for " . $paths{$id}->get('lab') . " ... done!");
  return $retval;
};


sub fetch_nnnn {
  my ($parent, $pathto, $f, $data) = @_;
  my $file = File::Spec->catfile($pathto,$f);
  next unless (-e $file);
  my $was_mac = $paths{data0} ->
    fix_mac($file, $stash_dir, lc($config{general}{mac_eol}), $top);
  Echo("\"$file\" had Macintosh EOL characters and was skipped."), return if ($was_mac == -1);
  if ($was_mac) {
    Echo("\"$file\" had Macintosh EOL characters and was fixed.");
    $file = $was_mac;
  };

  ##my $parent = $list -> infoParent($id);
  my $id = $list -> addchild($parent);
  $paths{$id} = Ifeffit::Path -> new(id	      => $id,
				     type     => 'path',
				     # group	 => $id,
				     file     => $f,
				     include  => 1,
				     plotpath => 0,
				     parent   => $parent,
				     do_k     =>  1,
				     data     => $data||$paths{$current}->data,
				     family   => \%paths);
  $paths{$id} -> make(header=>nnnn_header($id, $file));
  foreach my $l (split(/\n/, $paths{$parent}->get('intrp'))) {
    my $ss = substr($f,4,4);
    $paths{$id} -> make(feff_index=>sprintf('%d', $ss));
    $paths{$id} -> make(intrpline=>substr($l, 2)), last
      if ($l =~ /^\d\s+$ss/);
  };
  $paths{$id} -> pathlabel($config{paths}{label});
  my @autoparams = @{$paths{$parent}->get('autoparams')};
  foreach my $p (qw(s02 e0 delr sigma^2 ei 3rd 4th)) {
    my $this = shift @autoparams;
    $paths{$id} -> make($p=>$this);
  };
  $file_menu -> menu -> entryconfigure($save_index+4, -state=>($Tk::VERSION > 804) ? 'normal' : 'disabled'); # all paths
  project_state(0);
  return $id;
};


## the chomp; chop; thing is an attempt to handle the strange
## situation of running artemis on unix and having run feff on
## windows.  in that case a ^M (\015, \r) character gets left at the
## end of each line after chomping.
sub nnnn_header {
  my ($id, $file) = @_;
  my $nnnn = sprintf("%d", substr($paths{$id}->get('feff'), 4, 4));
  my $parent = $paths{$id}->get('parent');
  my $header = '';
  if (-e $paths{$parent}->get('paths.dat')) {
    open F, $paths{$parent}->get('paths.dat');
  PATHSDAT: while (<F>) {
      next unless (/index, nleg, degeneracy, r/);
      next unless (/^\s+$nnnn\b/);
      chomp; chop if (/\r$/);
      my @words = split(" ", $_);
      $paths{$id} -> make(nleg  => $words[1]||1,
			  reff  => $words[7]||0,
			  deg   => defined($words[2]) ? int($words[2]) : 0,
			  zcwif => 0);
      $header = sprintf(" %s legs  Reff=%s  degeneracy=%d\n\n",
			$paths{$id}->get('nleg'),
			$paths{$id}->get('reff'),
			$paths{$id}->get('deg'),);
      my $continue = 1;
      my $ileg = 1;
      while ($continue) {
	my $line = <F>;
	last PATHSDAT unless $line;
	chomp $line; chop $line if (/\r$/);
	if ($line =~ /^\s*x/) {
	} elsif ($line =~ /index, nleg, degeneracy, r/) {
	  $continue = 0;
	} else {
	  my @parts = split("'", $line);
	  $parts[1] ||= " ";
	  $parts[2] ||= "0 0 0";
	  my $coords = sprintf("%9.5f %9.5f %9.5f %d ", split(" ", $parts[0]));
	  my @pp = split(" ", $parts[2]);
	  my $angles = ($pp[2] > 0) ?
	    sprintf("       rleg=%s  beta=%7.3f  eta=%7.3f\n", @pp) :
	      sprintf("       rleg=%s  beta=%7.3f\n", @pp[0,1]);
	  $header .= "leg $ileg: " . $coords . $parts[1] . "\n" . $angles;
	  my @words = split(" ", $line);
	  if ($words[3] eq 0) {
	    $paths{$id} -> make(element=>$1) if ($line =~ /'(.*)\s*'/);
	  };
	  ++$ileg;
	};
      };
      last PATHSDAT;
    };
  } else {
    $paths{$id} -> make(nleg=>0, reff=>0, deg=>0, element=>" ", zcwif=>0);
  };
  close F;
  ## the ZCWIF isn't in the header, so I have to go read files.dat
  ## each time through.  sigh....
  my $filesdat = $paths{$id}->get('files.dat');
  my $thisnnnn = basename($file);
  if (-r $filesdat) {
    open FILES, $filesdat;
    ## or die "could not open $filesdat for reading in nnnn_header\n";
    while (<FILES>) {
      next unless (/^\s*$thisnnnn/);
      my @line = split(" ", $_);
      $paths{$id} -> make(zcwif=>$line[2]||0);
      last;
    };
  };
  close FILES;
  my $zcwif = $paths{$id}->get('zcwif');
  $header =~ s/degeneracy/amp=$zcwif  degen/;
  return $header;
};



## delete the currently selected feff calc and select/anchor the previous
## what if I want to delete entire calc from a path canvas
sub delete_feff {
  my $this   = $_[0] || $current;
  my $force  = $_[1];
  my $delete = $_[2] || 1;		# 0=compactify folder
				# 1=delete folder
				# 2=keep folder, delete groups (restore previous fit)
  my $label = $paths{$this}->get('lab');
  Echo('\"$label\" is not a FEFF calculation.'), return unless ($this =~ /feff\d+$/);
  unless ($force) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "Are you sure you want to discard \"$label\" and all its paths?",
		     -title          => 'Artemis: Verifying...',
		     -buttons        => [qw/Discard Cancel/],
		     -default_button => 'Discard',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    Echo("Not discarding \"$label\""), return unless ($response eq 'Discard');
  };
  ## remove the autoparams if they still exist
  my @names = (); my @indeces = ();
  foreach my $a (@{$paths{$this}{autoparams}}) {
    my $i = 0;
    foreach my $p (@gds) {
      if (lc($a) eq lc($p->{name})) {
	push(@names,   $a);
	push(@indeces, $i);
	last;
      };
      ++$i;
    };
  };
  if (@names) {
    my $response = "";
    if ($force) {
      ## do not want to see this dialog when discarding entire project
      ## or data set
      $response = "Discard";
    } else {
      my @vars = grep {defined($_) and ($_ !~ m{^\s*$})} @names;
      if (@vars) {
	my $addendum = join(",  ", @vars);
	my $dialog =
	  $top -> Dialog(-bitmap         => 'questhead',
			 -text           => "Do you want to discard the variables $addendum",
			 -title          => 'Artemis: Verifying...',
			 -buttons        => [qw/Discard Keep/],
			 -default_button => 'Discard',
			 -font           => $config{fonts}{med},
			 -popover        => 'cursor');
	&posted_Dialog;
	$response = $dialog->Show();
      } else {
	$response = "Keep";
      };
    };
    if ($response eq 'Discard') {
      my $offset = 0;		# needed because the list gets
                                # shorter each time
      foreach my $i (@indeces) {
	splice(@gds, $i-$offset, 1);
	++$offset;
      };
      $gds_selected{type}    = "guess";
      $gds_selected{name}    = "";
      $gds_selected{mathexp} = "";
      $gds_selected{which}   = 0;
      repopulate_gds2();
      @names = grep {defined($_) and ($_ !~ m{^\s*$})} @names;
      Echo("Discarded variables " . join(",  ", @names)) if @names;
    } else {
      Echo("Not discarding variables");
    };
  };
  $this = ($this =~ /feff\d+$/) ? $this : $paths{$this}->get('parent');

  if ($delete==0) {
    my $project_feff_folder = File::Spec->catfile($project_folder, $this);
    rmtree($project_feff_folder) if (-d $project_feff_folder);
  } elsif ($delete==1) {
    ## compact this directory, but don't delete it.  it needs to stick
    ## around in case the use should want to revert the fitting model to
    ## a fit that used it.
    feff_compactify($this);
  };

  my $new = $paths{$this}->data;
  my $message = $paths{$this}->descriptor();
  $list->delete('offsprings',$this);
  $list->delete('entry',$this);
  foreach (keys %paths) {
    next unless (ref($paths{$_}) =~ /Ifeffit/);
    next unless ($paths{$_}->type eq 'path');
    next unless ($paths{$_}->get('parent') eq $this);
    #$paths{$_}->dispose($paths{$_}->blank_path, $dmode); # unset this path
    $paths{$_}->drop;
    delete $paths{$_};
  };
  delete $paths{$this};

  if ($this eq $current) {
    $current = $new;
    project_state(0);
    display_page($new);
  };
  Echo("Discarded $message");
};


sub identify_feff {
  my $this = ($paths{$current}->type eq 'feff') ? $current : $paths{$current}->get('parent');
  Echo("This Feff: $this    This project: $project_folder");
};

sub rename_feff {
  Error("There are no feff calculations."), return unless $n_feff;
  my $this = $current;
  ($this = $paths{$current}->get('parent')) if ($paths{$current}->type eq 'path');
  if ($paths{$current}->type =~ /(bkg|data|diff|fit|res)/) {
    my $data = $current;
    ($data = $paths{$current}->data) if ($paths{$current}->type =~ /(bkg|diff|fit|res)/);
    my $n = 0;
    while ($n <= $n_feff) {
      ($this = "feff$n"), last if (($paths{$data.".feff".$n}->get('lab')) and
				   ($paths{$data.".feff".$n}->data eq $data));
      ++$n;
    };
  };
  my $oldname = $paths{$this}->get('lab');
  my $newname = $_[0];
  unless ($_[0]) {
    $newname = $oldname;
    my $label = "New name for \"$oldname\": ";
    my $dialog = get_string($dmode, $label, \$newname, \@rename_buffer);
    $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
    Echo("Not renaming ". $oldname), return if ($oldname eq $newname);
    $newname =~ s{[\"\']}{}g;
    my $exists = 0;
    foreach my $f (&all_feff) {
      $exists = 1, last if ($newname eq $paths{$f}->get('lab'));
    };
    Error("There is already a Feff calculation named \"$newname\"!"), return if $exists;
  };
  push @rename_buffer, $newname;
  project_state(0);
  $paths{$this} -> make(lab=>$newname);
  $list -> itemConfigure($this, 0, -text=>$newname);
  Echo("Renamed \"$oldname\" to \"$newname\".");
};


sub all_feff {
  return (sort (grep /^data\d+\.feff\d+$/, (keys %paths) ));
};


sub run_feff {
  my $this = $_[0];
  my $how_many = $_[1];
  my $feff_folder = File::Spec->catfile($project_folder, $paths{$this}->get('id'), "");
  my $feff_file = File::Spec->catfile($project_folder, $paths{$this}->get('id'), "feff.inp");
  my $was = cwd();

  Echo("Preparing to run FEFF ...");
  ## save the feff.inp file
  #Echo("Saving feff.inp file");
  #$widgets{feff_inptext} -> Save($feff_file);

  ## autosave
  &save_project(0,1);

  ## clean up the previous feff calculation
  opendir F, $feff_folder;
  my @nnnn = grep(/feff\d{4}\.dat/i, readdir F);
  closedir F;
  my $rerun_feff = 0;
  if (@nnnn) {
    Echo("Deleting old feffNNNN.dat files");
    map {unlink File::Spec->catfile($feff_folder, $_)} @nnnn;
    $rerun_feff = 1;
  };

  ## make the project feff folder the current working directory
  chdir $feff_folder;

  ## run feff (need to capture stdout and send to messages buffer)
  ##   raise_palette('messages');
  Running("Running feff (this could take a few minutes, please be patient) ... ");
  ##$top -> Busy();
  #my $feff_messages = `feff6`; # $config{feff}{feff_executable};

  ###  run feff --- PLATFORM DEPENDENT CODE ---

  ###  ------------------------------------------------
  ###  ---- *NIX --------------------------------------
  ###  ------------------------------------------------
  $notes{messages} -> delete(qw(1.0 end));
  raise_palette('messages');
  $top->update;
  unless ($is_windows) { # avoid problems if feff->feff_executable isn't
    my $which = `which $config{feff}{feff_executable}`;
    chomp $which;
    unless (-x $which) {
      Echo("Uh oh!  That Feff calculation did not run successfully.");
      $notes{messages}->insert('end', Ifeffit::ParseFeff -> error_4, 'warning');
      $notes{messages}->insert('end', "\n\tCurrent, incorrect value of feff->feff_executable:\n\t\t$config{feff}{feff_executable}\n\n", 'warning');
      $notes{messages}->see('1.0');
      $update->raise;
      return;
    };
  };
  ## fork the feff process
  my $pid = open(WRITEME, "$config{feff}{feff_executable} |");
  $notes{messages} -> grab;
  $| = 1;			      # unbuffer its output
  while (<WRITEME>) {		      # and display it in the message buffer
    $notes{messages} -> insert('end', $_);
    $notes{messages} -> yviewMoveto(1);
    $top -> update;
  };
  close WRITEME;
  $notes{messages} -> grabRelease;
  ###  ------------------------------------------------

  ###  ------------------------------------------------
  ###  ---- WINDOWS ----
  ###  ------------------------------------------------
  ## the fork seems to work on Windows, bless those perl developer elves!
  ###  ------------------------------------------------

  ## make sure that the run log is there
  unless (-e File::Spec->catfile($project_folder, $paths{$this}->get('id'), "feff.run")) {
    open LOG, ">".File::Spec->catfile($project_folder, $paths{$this}->get('id'), "feff.run");
    print LOG $notes{messages} -> get('1.0', 'end');
    close LOG;
  };
  ##$top -> Unbusy();

  ## uh oh!  problems running feff
  my $fefferr = File::Spec->catfile($project_folder, $paths{$this}->get('id'), "feff.err");
  my $err = Ifeffit::ParseFeff -> recognize( $notes{messages}->get(qw(1.0 end)) );
  if (($err eq 9) or ($err eq 11)) { # atoms close together OR heap exceeded
    $top -> Unbusy();
    $notes{messages}->insert('end', "\n");
    $notes{messages}->insert('end', Ifeffit::ParseFeff -> describe($err), 'warning');
    $notes{messages}->see('end');
    $update->raise;
  } elsif ($err) {
    ##&display_file('file', $fefferr);
    $top -> Unbusy();
    Error("Uh oh!  That Feff calculation did not run successfully.");
    $notes{messages}->insert('end', "\n");
    $notes{messages}->insert('end', Ifeffit::ParseFeff -> describe($err), 'warning');
    $notes{messages}->see('end');
    $update->raise;
    return;
  } else {
    Echo("Running feff ... done!");
  };

  my @nnnnlist;
  opendir D, $feff_folder or die "cannot read directory $feff_folder\n";
  @nnnnlist = sort grep /feff\d{4}\.dat/i, readdir D;
  closedir D;
  unless (@nnnnlist) {
    Error("There are no feffNNNN.dat files!  Something has gone wrong with your Feff calculation!");
    if ($config{feff}{feff_executable} =~ /feff7/i) {
      $notes{messages}->insert('end', "\n");
      $notes{messages}->insert('end', Ifeffit::ParseFeff -> describe(12), 'warning');
      $notes{messages}->see('end');
      $update->raise;
    };
    $top -> Unbusy();
    return;
  };
  $#nnnnlist = -1;

  ## snarf the list of paths to import
  my $response = $how_many;
  unless ($how_many) {
    my $text = "How many feff paths do you want to import right now?";
    $text .= "  (You seem to have run feff once before ... the best choice is probably \"No paths\")"
      if $rerun_feff;
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => $text,
		     -title          => 'Artemis: Question...',
		     -buttons        => ['No paths',
					 'Just the first',
					 "The first $config{paths}{firstn}",
					 'All paths'],
		     -default_button => ($rerun_feff) ? 'No paths' : 'All paths',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    $response = $dialog->Show();
    Echo("Importing " . lc($response));
  };
  my $is_busy = grep (/Busy/, $top->bindtags);
  $is_busy or $top -> Busy();
  $paths{$this} -> make(path=>$feff_folder);

  ## do intrp
  my $intrp_ok = &do_intrp($this);
  if ($intrp_ok) {
    my $m = $paths{$this}->get('mode');
    ($m += 4) unless ($m & 4);
    $paths{$this}->make(mode=>$m);
  };

  ## set display and increment feff counter
  $file_menu -> menu -> entryconfigure($save_index+6, -state=>'normal');
  $file_menu -> menu -> entryconfigure($save_index+4, -state=>($Tk::VERSION > 804) ? 'normal' : 'disabled'); # all paths
  &set_fit_button('fit');
  display_page($this);
  project_state(0);
  $fefftabs->raise('Interpretation');

  unless ($response eq 'No paths') {
    ## fetch list of feffNNNN.dat files
    opendir D, $feff_folder or die "cannot read directory $feff_folder\n";
    @nnnnlist = sort grep /feff\d{4}\.dat/i, readdir D;
    closedir D;
    ($#nnnnlist = 0) if ($response eq 'Just the first');
    ($#nnnnlist = $config{paths}{firstn}-1) if (($response =~ /^The first/) and
						($#nnnnlist > $config{paths}{firstn}-1));

    ## fetch all the paths to import
    my $i = 0;
    foreach my $f (sort {lc($a) cmp lc($b)} (@nnnnlist)) {
      (!$i) or ($i % 10) or Echo("Reading the ${i}th feffNNNN.dat file");
      my $kid = fetch_nnnn($this, $feff_folder, $f);
      $list -> entryconfigure($kid, -style=>$list_styles{$paths{$kid}->pathstate("enabled")},
			      -text=>$paths{$kid}->get('lab'));
      ++$i;
    };
  };
  intrp_fill($this);

  if ($err eq 11) {
    Error("See the message buffer for a warning about that Feff calculation.");
  } else {
    Echo("All done running FEFF.");
  };
  ## return the cwd and unbusy
  chdir $was;
  $is_busy or $top -> Unbusy();
};


## cloning feff calculations:  link and copy

sub clone_feff {
  my $type = $_[0];
  return unless (ref($paths{$current}) =~ /Ifeffit/);
  return if ($paths{$current}->type eq 'gsd');
  my @calcs = grep { (ref($paths{$_}) =~ /Ifeffit/) and ($paths{$_}->type eq 'feff') } (&path_list);
  my $data  = $paths{$current}->data;
  my $clone = $calcs[0];

  ## select a feff calculation to clone
  my $db = $top -> DialogBox(-title          => "Clone a Feff calculation",
			     -buttons        => [qw(OK Cancel)],
			     -default_button => 'OK');
  $db -> add('Label',
	     -text	 => "Which Feff calculcation would you like",
	     -font	 => $config{fonts}{med},
	     -foreground => $config{colors}{activehighlightcolor},)
    -> pack();
  $db -> add('Label',
	     -text	 => "to $type and add to " . $paths{$data}->get('lab') . "?",
	     -font	 => $config{fonts}{med},
	     -foreground => $config{colors}{activehighlightcolor},)
    -> pack();
  foreach my $c (@calcs) {
    $db -> add('Radiobutton', -text=>$paths{$c}->descriptor(),
	       -value=>$c,
	       -variable=>\$clone)
      -> pack(-anchor=>'w');
  };
  &posted_Dialog;
  my $answer = $db -> Show;
  Echo("Not cloning Feff calculation"), return if ($answer eq 'Cancel');
  Echo("Cloning Feff calculation");

  ## assign an id to the clones feff calc and make its object
  my $id = $data . '.feff' . $n_feff;
  my $project_feff_dir = "";
  $paths{$id} = Ifeffit::Path -> new(id     => $id,
				     group  => $id,
				     type   => 'feff',
				     data   => $data,
				     lab    => 'FEFF'.$n_feff,
				     family => \%paths,
				     linkto => ($type eq 'copy') ? 0 : $clone,
				     atoms_atoms => []);
  ## clone the properties of the feff calc, including all the atoms_ properties
  foreach my $k (qw(intrp path include mode edge central lab
		    feff.inp feff.run atoms.inp paths.dat misc.dat file.dat)) {
    $paths{$id} -> make($k => $paths{$clone}->get($k));
  };
  foreach my $a (keys %{$paths{$clone}}) {
    next unless ($a =~ /^atoms_/);
    $paths{$id} -> make($a => $paths{$clone}->get($a));
  };
  my @autoparams;
  $#autoparams = 6;
  (@autoparams = autoparams_define($id, $n_feff, 1, 0)) if $config{autoparams}{do_autoparams};
  $paths{$id} -> make(autoparams=>[@autoparams]);

  ## a link uses the files from an existing feff calculation, a copy
  ## copies all files from the other feff calc
  if ($type eq 'copy') {
    $project_feff_dir = &initialize_feff($id);
    $paths{$id} -> make(path=>$project_feff_dir);
    opendir F, $paths{$clone}->get('path');
    my @list = grep { -f File::Spec->catfile($paths{$clone}->get('path'),$_) } readdir F;
    closedir F;
    map { copy(File::Spec->catfile($paths{$clone}->get('path'),$_),
	       $project_feff_dir) } @list;
  };

  ## put the clone in the paths list
  $list -> add($id, -text=>$paths{$id}->{lab}, -style=>$list_styles{noplot});
  $list -> setmode($id, 'close');
  $list -> setmode($paths{$data}->get('id'), 'close')
    if ($list -> getmode($paths{$data}->get('id')) eq 'none');

  ## clone each of the paths corresponding to this path
  foreach my $p (&path_list) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless ($paths{$p}->type eq 'path');
    next unless ($paths{$p}->get('parent') eq $clone);
    ## add the cloned path to the list and make its object
    my $kid = $list -> addchild($id);
    $paths{$kid} = Ifeffit::Path -> new(id	 => $kid,
					type	 => 'path',
					parent   => $id,
					plotpath => 0,
					do_k	 => 1,
					data	 => $data,
					family   => \%paths);
    foreach my $k (qw(3rd 4th amp_array deg delr dphase e0 edge ei
		      element feff header include intrpline
		      k_array lab label nleg phase_array reff s02
		      setpath sigma^2 zcwif)) {
      $paths{$kid} -> make($k => $paths{$p}->get($k));
    };
    $list -> entryconfigure($kid,
			    -style=>$list_styles{$paths{$kid}->pathstate},
			    -text=>$paths{$kid}->get('lab'));
  };

  ## display this newly linked feff calculation
  ++$n_feff;
  $file_menu -> menu -> entryconfigure($save_index+6, -state=>'normal');
  $file_menu -> menu -> entryconfigure($save_index+4, -state=>($Tk::VERSION > 804) ? 'normal' : 'disabled'); # all paths
  display_page($id);
  project_state(0);
};


sub hide_branch {
  my ($path, $action) = @_;
  ##print join(" ", $path, $action), $/;
  if ($action eq '<Activate>') { # mouse button release
    if ($list -> getmode($path) eq 'close') {
      ## deselect any paths that are in the branch being closed

      ## closing a feff branch
      if ($paths{$path}->type eq 'feff') {
	foreach my $p ($list->info('selection')) {
	  next unless (ref($paths{$p}) =~ /Ifeffit/);
	  next unless ($paths{$p}->type eq 'path');
	  next unless ($paths{$p}->get('parent') eq $path);
	  $list->selectionClear($p);
	};

      ## closing a data branch
      } elsif ($paths{$path}->type eq 'data') {
	foreach my $p ($list->info('selection')) {
	  my $pp = $p;
	  ($pp = $1 . "_" . ("fit", "res", "bkg")[$2]) if $p =~ /(data\d)\.(\d)/;
	  next unless (ref($paths{$pp}) =~ /Ifeffit/);
	  if ($paths{$pp}->type eq 'path') {
	    next unless ($paths{$pp}->data eq $path);
	    $list->selectionClear($p);
	  } elsif ($paths{$pp}->type =~ '(bkg|fit|res)') {
	    next unless ($paths{$pp}->get('sameas') eq $path);
	    $list->selectionClear($p);
	  };
	};
      };

      $list -> close($path);

    } elsif ($list -> getmode($path) eq 'open') {
      $list -> open($path);
    };
  };
};

sub feff_compactify {
  my $feff = $_[0] || $paths{$current}->feff;
  Echo($paths{$feff}->descriptor . " is not a feff calculation or path"), return
    unless ($paths{$feff}->type =~ /(feff|path)/);
  Echo("Compacting " . $paths{$feff}->descriptor . " ...");
  my $folder = File::Spec->catfile($project_folder, $feff);
  my @to_delete;
  opendir F, $folder;
  foreach my $file (readdir F) {
    next if ($file =~ /^\./);
    next if (lc($file) =~ /^(atoms\.inp|f(eff(\.(inp|run)|_run\.log)|iles\.dat)|misc\.dat|path(00\.dat|s\.dat))$/);
    next if &path_used($folder, $file);
    push @to_delete, $file;
  };
  foreach my $td (@to_delete) {
    unlink File::Spec->catfile($folder, $td);
  };
  my $n = $#to_delete+1;
  Echo("Compacting " . $paths{$feff}->descriptor . " ... (deleted $n files) done!");
};


##  END OF THE SECTION ON THE FEFF PAGE

