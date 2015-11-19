# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## The Atoms interface


sub make_atoms {

  my $atoms = $_[0];

  $atoms_params{edge} = 'K';
  $atoms_params{elem} = 'H';
  my @help_button = (-foreground       => $config{colors}{activehighlightcolor},
		     -font	       => $config{fonts}{small},
		     -relief	       => 'flat',
		     -borderwidth      => 0,
		     -cursor	       => $mouse_over_cursor,
		     -activeforeground => $config{colors}{mbutton},
		    );

  my $fr = $atoms -> LabFrame(-label=>'Titles',
			      -foreground=>$config{colors}{activehighlightcolor},
			      -labelside=>'acrosstop')
    -> pack(-side=>'top', -fill=>'x');
  $widgets{atoms_titles} = $fr -> Scrolled("Text",
					   -scrollbars=>'e',
					   -height=>3)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{atoms_titles} -> Subwidget("yscrollbar")
    ->configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));
  &disable_mouse3($widgets{atoms_titles}->Subwidget("text"));


  my $main = $atoms -> Frame()
    -> pack(-side=>'top', -expand=>1, -fill=>'both');

  $fr = $main -> Frame()
    -> pack(-side=>'left', -anchor=>'n');

  ## space group
##   my $lfr = $fr -> LabFrame(-label=>'Space group',
## 			    -foreground=>$config{colors}{activehighlightcolor},
## 			    -labelside=>'acrosstop')
##     -> grid(-column=>0, -row=>0, -columnspan=>2, -padx=>2);
##   &labframe_help($lfr);
  $fr -> Button(@help_button,
		-text=>'Space group', -command=>[\&Echo, $click_help{'Space group'}])
    -> grid(-column=>0, -row=>0, -sticky=>'e', -padx=>2, -pady=>2);
  $widgets{atoms_space} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				       -validate=>'key',
				       -validatecommand=>[\&set_atoms_params, 'space'])
    -> grid(-column=>1, -row=>0, -padx=>2, -pady=>2);
##    -> pack(-padx=>4, -pady=>4);

  ## lattice constants
  $fr -> Button(@help_button, -text=>'A', -command=>[\&Echo, $click_help{'A'}])
    -> grid(-column=>0, -row=>1, -sticky=>'e', -padx=>2);
  $widgets{atoms_a} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				   -validate=>'key',
				   -validatecommand=>[\&set_atoms_params, 'a'])
    -> grid(-column=>1, -row=>1);
  $fr -> Button(@help_button, -text=>'B', -command=>[\&Echo, $click_help{'B'}])
    -> grid(-column=>0, -row=>2, -sticky=>'e', -padx=>2);
  $widgets{atoms_b} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				   -validate=>'key',
				   -validatecommand=>[\&set_atoms_params, 'b'])
    -> grid(-column=>1, -row=>2);
  $fr -> Button(@help_button, -text=>'C', -command=>[\&Echo, $click_help{'C'}])
    -> grid(-column=>0, -row=>3, -sticky=>'e', -padx=>2);
  $widgets{atoms_c} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				   -validate=>'key',
				   -validatecommand=>[\&set_atoms_params, 'c'])
    -> grid(-column=>1, -row=>3);

  ## lattice angles
  $fr -> Button(@help_button, -text=>'Alpha', -command=>[\&Echo, $click_help{'Alpha'}])
    -> grid(-column=>0, -row=>4, -sticky=>'e', -padx=>2);
  $widgets{atoms_alpha} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				       -validate=>'key',
				       -validatecommand=>[\&set_atoms_params, 'alpha'])
    -> grid(-column=>1, -row=>4);
  $fr -> Button(@help_button, -text=>'Beta', -command=>[\&Echo, $click_help{'Beta'}])
    -> grid(-column=>0, -row=>5, -sticky=>'e', -padx=>2);
  $widgets{atoms_beta} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				      -validate=>'key',
				      -validatecommand=>[\&set_atoms_params, 'beta'])
    -> grid(-column=>1, -row=>5);
  $fr -> Button(@help_button, -text=>'Gamma', -command=>[\&Echo, $click_help{'Gamma'}])
    -> grid(-column=>0, -row=>6, -sticky=>'e', -padx=>2);
  $widgets{atoms_gamma} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				       -validate=>'key',
				       -validatecommand=>[\&set_atoms_params, 'gamma'])
    -> grid(-column=>1, -row=>6);



  ## cluster size and edge
  $fr -> Button(@help_button,
		-text=>'Cluster size', -command=>[\&Echo, $click_help{'Cluster size'}])
    -> grid(-column=>0, -row=>7, -sticky=>'e', -padx=>2, -pady=>2);
  $widgets{atoms_rmax} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
				      -validate=>'key',
				      -validatecommand=>[\&set_atoms_params, 'rmax'])
    -> grid(-column=>1, -row=>7, -padx=>2);
  $fr -> Button(@help_button, -text=>'Edge', -command=>[\&Echo, $click_help{'Edge'}])
    -> grid(-column=>0, -row=>8, -sticky=>'e', -padx=>2, -pady=>2);
  $widgets{atoms_edge} = $fr -> Optionmenu(-options=>[qw/K L3 L2 L1 none/],
					   -textvariable=>\$atoms_params{edge},
					   -borderwidth=>1,
					   -command=>\&set_edge,
					  )
    -> grid(-column=>1, -row=>8, -sticky=>'w', -padx=>2);


  ## shift vector
  $fr -> Button(@help_button,
		-text=>'Shift vector', -command=>[\&Echo, $click_help{'Shift vector'}])
    -> grid(-column=>0, -row=>9, -sticky=>'e', -padx=>2);
  $widgets{atoms_shiftx} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
					-validate=>'key',
					-validatecommand=>[\&set_atoms_params, 'shiftx'])
    -> grid(-column=>1, -row=>9, -padx=>2);
  $widgets{atoms_shifty} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
					-validate=>'key',
					-validatecommand=>[\&set_atoms_params, 'shifty'])
    -> grid(-column=>1, -row=>10, -padx=>2);
  $widgets{atoms_shiftz} = $fr -> Entry(-width=>10, -font=>$config{fonts}{fixed},
					-validate=>'key',
					-validatecommand=>[\&set_atoms_params, 'shiftz'])
    -> grid(-column=>1, -row=>11, -padx=>2);



  ## scrolled hlist of atom sites
  my $atoms_list;
  $atoms_list = $main -> Scrolled("HList",
				  -columns    => 7,
				  -header     => 1,
				  -scrollbars => 'osoe',
				  -background => $config{colors}{background},
				  -font	      => $config{fonts}{fixed},
				  -selectmode => 'extended',
				  -selectbackground => $config{colors}{selected},
				  -browsecmd  => \&atoms_edit,
				  #-command    => sub{1;},
			       )
    -> pack(-side=>'right', -expand=>1, -fill=>'both');
  $widgets{atoms_list} = $atoms_list;

  $atoms_styles{header}   = $atoms_list -> ItemStyle('text',
						     -font=>$config{fonts}{small},
						     -anchor=>'center',
						     -foreground=>$config{colors}{activehighlightcolor});
  $atoms_styles{normal}   = $atoms_list -> ItemStyle('text',
						     -font=>$config{fonts}{fixed},
						     -foreground=>$config{colors}{foreground},
						     -selectforeground=>$config{colors}{foreground},
						     -background=>$config{colors}{background});
  $atoms_styles{centered} = $atoms_list -> ItemStyle('text',
						     -font=>$config{fonts}{fixed},
						     -anchor=>'center',
						     -foreground=>$config{colors}{foreground},
						     -selectforeground=>$config{colors}{foreground},
						     -background=>$config{colors}{background});

  $atoms_list -> Subwidget("hlist") -> headerCreate(0, -text=>"",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(1, -text=>"Core",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(2, -text=>"El",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(3, -text=>"X",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(4, -text=>"Y",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(5, -text=>"Z",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);
  $atoms_list -> Subwidget("hlist") -> headerCreate(6, -text=>"Tag",
						    -style=>$atoms_styles{header},
						    -headerbackground=>$config{colors}{background},);

  $atoms_list -> Subwidget("hlist") -> columnWidth(0, -char=>3);
  ##$atoms_list -> Subwidget("hlist") -> columnWidth(2, -char=>3);
  $atoms_list -> Subwidget("hlist") -> columnWidth(3, -char=>8);
  $atoms_list -> Subwidget("hlist") -> columnWidth(4, -char=>8);
  $atoms_list -> Subwidget("hlist") -> columnWidth(5, -char=>8);
  $atoms_list -> Subwidget("hlist") -> columnWidth(6, -char=>10);

  $atoms_styles{normal}   = $atoms_list -> ItemStyle('text',
						     -font=>$config{fonts}{fixed},
						     -foreground=>$config{colors}{foreground},
						     -selectforeground=>$config{colors}{foreground},
						     -background=>$config{colors}{background});
  $atoms_styles{centered} = $atoms_list -> ItemStyle('text',
						     -font=>$config{fonts}{fixed},
						     -anchor=>'center',
						     -foreground=>$config{colors}{foreground},
						     -selectforeground=>$config{colors}{foreground},
						     -background=>$config{colors}{background});


  $atoms_list->bind('<ButtonPress-3>',\&atoms_post_menu);
  BindMouseWheel($atoms_list);
  $atoms_list -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $atoms_list -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));

  my $edit = $atoms -> LabFrame(-label=>'Edit selected site',
				-foreground=>$config{colors}{activehighlightcolor},
				-labelside=>'acrosstop' )
    -> pack(-side=>'top', -padx=>2);
  $fr = $edit -> Frame()
    -> pack(-side=>'top', -expand=>1, -fill=>'x', -padx=>2);

  #if ($config{atoms}{elem} eq 'menu') {
  #  my @elem_list;
  #  $widgets{atoms_elem} = $fr -> BrowseEntry(-label => "Element ",
#					      -disabledforeground => $config{colors}{foreground},
#					      -state => 'readonly',
#					      -font=>$config{fonts}{small},
#					      -foreground=>$config{colors}{activehighlightcolor},
#					      -width=>5,
#					      -variable => \$atoms_params{elem},
#					      ##-choices => \@elem_list,
#					      -browsecmd=>sub{1;},
#					     );
#    map { $widgets{atoms_elem}-> insert('end', get_symbol($_)) } (1..9);
#    $widgets{atoms_elem}  -> pack(-side=>'left');
#  } else {
  $fr -> Label(-text=>'Element:',
	       -font=>$config{fonts}{small},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
    $widgets{atoms_elem} = $fr -> Entry(-width=>5)
      -> pack(-side=>'left');
  #};

  $fr -> Frame(-width=>8)
    -> pack(-side=>'left');


  $fr -> Label(-text=>'Tag:',
	       -font=>$config{fonts}{small},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  $widgets{atoms_tag} = $fr -> Entry(-width=>10)
    -> pack(-side=>'left');
  $fr -> Frame()
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $fr -> Button(-text=>"Define", @button2_list, -width=>15,
		-command=>\&atoms_define)
    -> pack(-side=>'left', -anchor=>'e', -padx=>8);

  $fr = $edit -> Frame()
    -> pack(-side=>'top', -expand=>1, -fill=>'x', -pady=>2, -padx=>2);
  $fr -> Label(-text=>'X:',
	       -font=>$config{fonts}{small},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  $widgets{atoms_x} = $fr -> Entry(-width=>7)
    -> pack(-side=>'left');
  $fr -> Label(-text=>'Y:',
	       -font=>$config{fonts}{small},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  $widgets{atoms_y} = $fr -> Entry(-width=>7)
    -> pack(-side=>'left');
  $fr -> Label(-text=>'Z:',
	       -font=>$config{fonts}{small},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  $widgets{atoms_z} = $fr -> Entry(-width=>7)
    -> pack(-side=>'left');
  $fr -> Frame()
    -> pack(-side=>'left', -expand=>1, -fill=>'x');


  $fr -> Button(-text=>"New", @button2_list, -width=>15,
		-command=>\&atoms_new_site)
    -> pack(-side=>'right', -anchor=>'e', -padx=>8);

  foreach (qw(elem x y z tag)) {
    $widgets{"atoms_".$_} -> bind("<KeyPress-Return>", \&atoms_define);
  };


  ## run and document buttons
  $fr = $atoms -> Frame()
    -> pack(-side=>'bottom', -fill=>'x');
  $widgets{help_runfeff} =
    $fr -> Button(-text=>"Document: Atoms",  @button2_list, -width=>1,
		     -command=>sub{pod_display("artemis_atoms.pod")} )
	-> pack(-side=>'right', -fill=>'x', -padx=>2, -pady=>2, -expand =>1);
  $fr -> Button(-text=>'Run Atoms', @button2_list, -width=>1,
		-command=>\&run_atoms)
    -> pack(-side=>'left', -fill=>'x', -padx=>2, -pady=>2, -expand =>1);
};


sub new_atoms {
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Do you want to import an existing atoms.inp file or start with a blank page?",
		   -title          => 'Artemis: Question...',
		   -buttons        => ['Import atoms.inp', 'Blank page', 'Cancel'],
		   -default_button => 'Blank page',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $answer = $dialog->Show();
 SWITCH: {
    ($answer eq 'Import atoms.inp') and do {
      Echo("Importing Atoms data");
      &import_atoms;
      return;
    };
    ($answer eq 'Blank page') and do {
      Echo("Opening blank Atoms page");
      last SWITCH;
    };
    ($answer eq 'Cancel') and do {
      Echo("Canceled new Atoms page");
      return;
    };
  };

  my $data = $paths{$current}->data;
  ## assign an id to this feff calc
  my $id = $data . '.feff' . $n_feff;

  ## &initialize_project(0);
  ## make a project feff folder
  my $project_feff_dir = &initialize_feff($id);

  $paths{$id} = Ifeffit::Path -> new(id	    => $id,
				     type	    => 'feff',
				     path	    => File::Spec->catfile($project_folder, $id),
				     data	    => $data,
				     lab	    => 'FEFF'.$n_feff,
				     family      => \%paths,
				     atoms_atoms => [],
				    );
  &clear_atoms;
  initialize_atoms($id);
  $paths{$id} -> make(mode=>1);
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
  Echo("Made new atoms page");


};


sub clear_atoms {
  my $feff = $paths{$current}->feff;
  return unless $feff;
  $widgets{atoms_list} -> delete('all');
  $paths{$feff} -> make(atoms_atoms=>[]);
  foreach (qw(elem x y z tag a b c alpha beta gamma shiftx shifty shiftz space rmax)) {
    $widgets{"atoms_".$_}->delete(0, 'end');
    $paths{$feff} -> make("atoms_".$_ => "");
  };
  $widgets{atoms_titles}->delete('1.0', 'end');
  $paths{$feff} -> make(atoms_titles=>"");
  $atoms_params{edge} = 'K';
  $paths{$feff} -> make(atoms_edge=>'K');
};


sub initialize_atoms {
  my $this = $_[0];
  foreach my $k (qw(a b c alpha beta gamma shiftx shifty shiftz)) {
    $paths{$this} -> make("atoms_$k"=>0);
  };
  $paths{$this} -> make(atoms_space  => "");
  $paths{$this} -> make(atoms_rmax   => 6);
  $paths{$this} -> make(atoms_titles => "");
  $paths{$this} -> make(atoms_edge   => "K");
  $atoms_params{natoms} = 0;
  $atoms_params{edge}   = "K";
};



sub import_atoms {

  my ($file, $just_parse, $this_feff) = @_;
  unless ($file and (-e $file)) {
    ##local $Tk::FBox::a;
    ##local $Tk::FBox::b;
    my $path = $current_data_dir || cwd;
    my $types = [['Atoms input files',    '*.inp'],
		 ['CIF files',            '*.cif'],
		 ['Atoms and CIF files', ['*.inp','*.cif']],
		 ['All files',            '*'],];
    $file ||= $top -> getOpenFile(-filetypes=>$types,
				  ##(not $is_windows) ?
				  ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				  -initialdir=>$path,
				  -title => "Artemis: Open an Atoms input file");
    return unless ($file);
  };
  ## take care that this is really an atoms.inp file
  Error("\"$file\" is not an Atoms input file"), return unless ((Ifeffit::Files->is_atoms($file)) or
								(Ifeffit::Files->is_cif($file)) );

  track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
  my $data = ($this_feff) ? (split(/\./, $this_feff))[0] : $paths{$current}->data;
  my ($nm, $pth, $sff) = fileparse($file,".inp",".INP",".Inp",".cif", ".CIF",".Cif");
  push_mru($file, 1, "atoms") unless ($just_parse);

  my $record_number = 0;
  #if ($STAR::Parser and ($sff =~ /cif/i)) {
  if ($STAR_Parser_exists and Ifeffit::Files->is_cif($file)) {
    my @data = STAR::Parser->parse($file);
    my $n = $#data+1;
    if ($#data) {
      my $db = $top->DialogBox(-title=>"Artemis: multi-record CIF file",
			       -buttons=>['OK', 'Cancel'],
			       -default_button=>'OK',);
      $db->add('Label', -text=>"$nm contains $n records.",
	       -foreground=>$config{colors}{activehighlightcolor},)
	-> pack();
      $db->add('Label', -text=>"Which do you want to import?",
	       -foreground=>$config{colors}{activehighlightcolor},)
	-> pack();
      my $i = 0;
      foreach my $d (@data) {
	$db->add('Radiobutton',
		 -text     => $d->get_item_data(-item=>"_chemical_name_systematic") || basename($file),
		 -value    => $i,
		 -variable => \$record_number, )
	-> pack(-anchor=>'w');
	++$i;
      };
      &posted_Dialog;
      my $response = $db->Show;
      Echo("CIF import canceled"), return if ($response eq 'Cancel');
    };
  };

  ## assign an id to this feff calc
  my $id = $this_feff || $data . '.feff' . $n_feff;

  Echo("Importing crystallography file ... ");
  ## &initialize_project(0);
  ## make a project feff folder
  unless ($just_parse) {
    $paths{$id} = Ifeffit::Path
      -> new(id=>$id, type=>'feff', mode=>0,
	     data=>$data, lab=>'FEFF'.$n_feff, family=>\%paths,
	    );
    $paths{$id} -> make(path=>File::Spec->catfile($project_folder, $id));
    $paths{$id} -> make(mode => $paths{$id}->get('mode')+1);
    my @autoparams;
    $#autoparams = 6;
    (@autoparams = autoparams_define($id, $n_feff, 0, 0)) if $config{autoparams}{do_autoparams};
    $paths{$id} -> make(autoparams=>[@autoparams]);
  };

  my $project_feff_dir = ($paths{$id}->get('linkto')) ? $paths{$id}->get('path') : &initialize_feff($id);


  my $project_atoms = ($STAR_Parser_exists and Ifeffit::Files->is_cif($file)) ?
    File::Spec->catfile($project_feff_dir, "$nm.cif") :
	File::Spec->catfile($project_feff_dir, "atoms.inp");
  copy($file, $project_atoms) unless ($file eq $project_atoms);
  initialize_atoms($id);

  ## =============================== parse the input file,
  my $keywords = Xray::Atoms -> new();
  $keywords -> make('identity'=>"Artemis $VERSION", die=>0, quiet=>1);
  if ($STAR_Parser_exists and ($sff =~ /cif/i)) {
    $keywords -> parse_input($project_atoms, 0, 'cif', $record_number);
  } else {
    $keywords -> parse_input($project_atoms, 0, 'inp');
  };
  ## any problems???

  $paths{$id} -> make(atoms_core=>"");
  foreach my $k (qw(a b c alpha beta gamma edge core rmax space)) {
    $paths{$id} -> make("atoms_$k"=>$keywords->{$k});
  };
  my ($i, $cr) = (0,0);
  @atoms = ();
  foreach my $s (@{$keywords->{'sites'}}) {
    $atoms[$i] = $s;
    ($cr ||= $i) if (lc($paths{$id}->get('atoms_core')) eq lc($$s[0]));
    ($cr   = $i) if (lc($paths{$id}->get('atoms_core')) eq lc($$s[4]));
    ++$i;
  };
  $paths{$id} -> make("atoms_atoms"=>[@atoms]);
  ##populate_atoms($id);

  $cr ||= 0;
  my $abs = $atoms[$cr]->[0];
  $paths{$id}->make(atoms_edge=>(get_Z($abs) > 57) ? "L3" : "K")
    unless (lc($paths{$id}->get('atoms_edge')) =~ /(k|l[123])/);
  my $titles = join("<NL>", @{$keywords->{'title'}});
  #foreach my $t (@{$keywords->{'title'}}) {
  #  $titles .= $t . "<NL>";
  #};
  $paths{$id} -> make(atoms_titles=>$titles);
  my @shiftvec = @{$keywords->{shift}};
  $paths{$id} -> make(atoms_shiftx=>$shiftvec[0], atoms_shifty=>$shiftvec[1], atoms_shiftz=>$shiftvec[2]);

  undef $keywords;

  unless ($just_parse) {
    $list -> add($id, -text=>'FEFF'.$n_feff, -style=>$list_styles{noplot});
    $list -> setmode($id, 'close');
    $list -> setmode($paths{$data}->get('id'), 'close')
      if ($list -> getmode($paths{$data}->get('id')) eq 'none');


    if ($pth and (-e File::Spec->catfile($pth, "feff.inp"))) {
      my $dialog =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => "There is a feff.inp in this folder.  Would you like to import it as well?",
		       -title          => 'Artemis: Question importing atoms.inp...',
		       -buttons        => ['Yes', 'No'],
		       -default_button => 'Yes',
		       -font           => $config{fonts}{med},
		       -popover        => 'cursor');
      &posted_Dialog;
      my $response = $dialog->Show();
      if ($response eq 'Yes') {
	my $project_feff = File::Spec->catfile($project_feff_dir, "feff.inp");
	copy(File::Spec->catfile($pth, "feff.inp"), $project_feff);
	$paths{$id} -> make(mode => $paths{$id}->get('mode')+2);
      };
    };

    &set_fit_button('fit');
    display_page($id);
    project_state(0);
    ++$n_feff;
    $fefftabs -> raise('Atoms');
  };
  Echo("Importing crystallography file ... done!");
  if (Ifeffit::Files->is_cif($file)) {
    run_atoms("atoms", File::Spec->catfile($project_feff_dir, "atoms.inp"));
    unlink File::Spec->catfile($project_feff_dir, "feff.inp");
    Echo("You imported a CIF file.  Don't forget to set the absorber!");
  };
};


sub populate_atoms {
  my $this = $_[0];

  $widgets{atoms_list}->delete('all');

  @atoms = @{ $paths{$current}->get("atoms_atoms") };
  my $row = 0;
  $atoms_params{core} = 0;
  foreach my $s (@atoms) {
    my $n = $row+1;
    $widgets{atoms_list} -> add($row);
    $widgets{atoms_list} -> itemCreate($row, 0, -text=>$n,
				       -style=>$atoms_styles{centered});
    $widgets{atoms_list} -> itemCreate($row, 1, -itemtype=>'window',
				       -widget=>$widgets{atoms_list}->Radiobutton(-variable	  => \$atoms_params{core},
										  -foreground	  => $config{colors}{foreground},
										  -activeforeground => $config{colors}{foreground},
										  -selectcolor	  => $config{colors}{check},
										  -value	  => $row,
										  -text		  => "",
										  -command	  => \&set_core));
    $widgets{atoms_list} -> itemCreate($row, 2, -text=>$s->[0],
				       -style=>$atoms_styles{normal});
    $widgets{atoms_list} -> itemCreate($row, 3, -text=>$s->[1],
				       -style=>$atoms_styles{normal});
    $widgets{atoms_list} -> itemCreate($row, 4, -text=>$s->[2],
				       -style=>$atoms_styles{normal});
    $widgets{atoms_list} -> itemCreate($row, 5, -text=>$s->[3],
				       -style=>$atoms_styles{normal});
    $widgets{atoms_list} -> itemCreate($row, 6, -text=>$s->[4],
				       -style=>$atoms_styles{normal});
    ($atoms_params{core} = $row) if (($s->[4] eq $paths{$current}->get("atoms_core")) or
				     ($s->[0] eq $paths{$current}->get("atoms_core")));
    ++$row;
  };
  $atoms_params{natoms} = $row;
  ## clear out the edit area
  foreach (qw(elem x y z tag)) {
    $widgets{"atoms_".$_}->delete(0, 'end');
  };
  $widgets{atoms_list} -> selectionClear;
  $widgets{atoms_list} -> anchorClear;
};


sub set_edge {
  $paths{$current} -> make(atoms_edge=>$atoms_params{edge});
};

sub set_atp_menu {
  my (%atp, @menu);
  foreach my $d ($Xray::Atoms::atp_dir, $setup->find('atoms', 'atp_personal')) {
    opendir A, $d;
    foreach (grep /(.+)\.atp$/, readdir A) {
      my $key = substr($_, 0, -4);
      ++$atp{$key};
    };
    closedir A;
  };
  my $menu = $feff_menu -> cget('-menu') -> entrycget('  Write special output', '-menu');
  foreach my $a (sort(keys(%atp))) {
    next if ($a =~ /(dafs|powder|template)/);
    $menu -> add('command', -label=>$a, @menu_args,
		 -command=>sub{&run_atoms($a)});
  };
  #my $menu = $feff_menu -> Menu(-menuitems=>\@menu);
  #$feff_menu -> menu -> entryconfigure(12, -menuitems=>\@menu, -state=>'normal');
};


sub set_atoms_params {

  my ($k, $entry, $prop) = (shift, shift, shift);

  if ($k =~ /^([abc]|rmax)/) {
    ($entry =~ /^\s*$/) and ($entry = 0);	     # error checking ...
    ($entry =~ /^\s*\.\s*$/) and ($entry = 0); # a sole .
    ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
    ($entry < 0) and return 0;
  } elsif (($k eq 'alpha') or ($k eq 'beta') or ($k eq 'gamma')) {
    ($entry =~ /^\s*$/) and ($entry = 0);	     # error checking ...
    ($entry =~ /^\s*\.\s*$/) and ($entry = 0); # a sole .
    ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
    ($entry < 0) and return 0;
    ($entry > 180) and return 0;
  } elsif ($k =~ /(elem|tag)_(\d+)/) {
    my $key = join("_", "atoms", "core", $2);
    $paths{$current} -> make("atoms_$k"=>$entry);
    $widgets{$key} -> configure(-value =>
				lc($paths{$current}->get("atoms_tag_$2"))  ||
				lc($paths{$current}->get("atoms_elem_$2")) ||
				$2 );

  } elsif ($k =~ /^shift/) {	# skip check to allow writing
                                # fractions, just check later
    1;
  };
  ## also skip the check on the space group symbol

  $paths{$current} -> make("atoms_$k"=>$entry);
  project_state(0);
  return 1;
};


sub atoms_edit {
  my $row = $widgets{atoms_list}->info('anchor');
  foreach (qw(elem x y z tag)) {
    $widgets{"atoms_".$_}->delete(0, 'end');
  };
  #if ($config{atoms}{elem} eq 'menu') {
  #  $atoms_params{elem} = $widgets{atoms_list} -> itemCget($row, 2, '-text');
  #} else {
  $widgets{atoms_elem} -> insert('end', $widgets{atoms_list} -> itemCget($row, 2, '-text') || "");
  #};
  $widgets{atoms_x}    -> insert('end', $widgets{atoms_list} -> itemCget($row, 3, '-text') || "");
  $widgets{atoms_y}    -> insert('end', $widgets{atoms_list} -> itemCget($row, 4, '-text') || "");
  $widgets{atoms_z}    -> insert('end', $widgets{atoms_list} -> itemCget($row, 5, '-text') || "");
  $widgets{atoms_tag}  -> insert('end', $widgets{atoms_list} -> itemCget($row, 6, '-text') || "");
  $widgets{atoms_x}    -> focus();
};

sub atoms_define {
  my $row;
  Error("You did not supply an element symbol."), return if (lc($widgets{atoms_elem}->get()) =~ /^\s*$/);
  unless (lc($widgets{atoms_elem}->get()) =~ /^$Ifeffit::Files::elem_regex$/) {
    Error($widgets{atoms_elem}->get() . " is not a valid element symbol.");
    $widgets{atoms_elem}->focus;
    $widgets{atoms_elem}->selectionRange(0, 'end');
    return;
  };
  ## this is true if redefining an old site, false if this is a new site
  my $redefine = $widgets{atoms_list}->info('anchor');
  if (defined $redefine and ($redefine ne "")) {
    $row = $redefine;
  } else {
    $row = $atoms_params{natoms};
    $widgets{atoms_list} -> add($row);
  };

  my $tag = $widgets{atoms_tag}->get();
  $tag =~ s/\s//g;
  $widgets{atoms_tag}->delete(qw(0 end));
  $widgets{atoms_tag}->insert('end', $tag);
  ## fill the data structure
  $atoms[$row] = [ucfirst(lc($widgets{atoms_elem}->get())),
		  $widgets{atoms_x}->get(),
		  $widgets{atoms_y}->get(),
		  $widgets{atoms_z}->get(),
		  $tag,
		  1
		 ];

  ## fill in the table
  $widgets{atoms_list} -> itemCreate($row, 1, -itemtype=>'window',
				     -widget=>$widgets{atoms_list}->Radiobutton(-variable	  => \$atoms_params{core},
										-foreground	  => $config{colors}{foreground},
										-activeforeground => $config{colors}{foreground},
										-selectcolor	  => $config{colors}{check},
										-value		  => $row,
										-text		  => "",
										-command	  => \&set_core));
  $widgets{atoms_list} -> itemCreate($row, 2, -text=>ucfirst(lc($widgets{atoms_elem}->get())),
				     -style=>$atoms_styles{normal});
  $widgets{atoms_list} -> itemCreate($row, 3, -text=>$widgets{atoms_x}->get()||0,
				     -style=>$atoms_styles{normal});
  $widgets{atoms_list} -> itemCreate($row, 4, -text=>$widgets{atoms_y}->get()||0,
				     -style=>$atoms_styles{normal});
  $widgets{atoms_list} -> itemCreate($row, 5, -text=>$widgets{atoms_z}->get()||0,
				     -style=>$atoms_styles{normal});
  $widgets{atoms_list} -> itemCreate($row, 6, -text=>$tag,
				     -style=>$atoms_styles{normal});
  unless (defined $redefine and ($redefine ne "")) {
    ++$atoms_params{natoms};
    $widgets{atoms_list} -> itemCreate($row, 0, -text=>$atoms_params{natoms},
				       -style=>$atoms_styles{centered});
  };
  $paths{$current}->make(atoms_atoms=>[@atoms]);
  project_state(0);
  $atoms_params{core} = 0 if ($atoms_params{natoms} == 1);
  my $n = $row+1;
  Echo("Defined " . ucfirst(lc($widgets{atoms_elem}->get())) . " at site " . $n);
};

## callback attached to the core radiobuttons
sub set_core {
  $paths{$current}->make(atoms_core=>$atoms[$atoms_params{core}]->[4]||$atoms[$atoms_params{core}]->[0]);
  project_state(0);
};

sub atoms_new_site {
  foreach (qw(elem x y z tag)) {
    $widgets{"atoms_".$_}->delete(0, 'end');
  };
  $widgets{atoms_list} -> selectionClear;
  $widgets{atoms_list} -> anchorClear;
  $widgets{atoms_elem} -> focus;
};


sub post_sgb {
  Error("Sorry!  The space group browser is currently broken.  It'll get fixed eventually.");
  return;
  if (ref($sgb) =~ /SGB/) {
    ($sgb->state() eq "normal") ? $sgb->raise : $sgb->deiconify;
    $top -> update;
    return;
  }
  my @feff = &all_feff;
  Error("Viewing the space group browser requires that at least one Feff calculation exist"),
    return unless @feff;
  my @sgb_args = (-sgbActive    => $config{colors}{activehighlightcolor},
		  -sgbGroup     => $config{colors}{mbutton},
		  -button       => $config{colors}{button},
		  -buttonActive => $config{colors}{activebutton},
		  -buttonLabel  => $config{colors}{warning_fg},
		  -buttonFont   => $config{fonts}{small},
		  -sgbFont      => $config{fonts}{med},
		 );
  $sgb = $top
    -> SGB(-SpaceWidget=>\$widgets{atoms_space});
  $sgb->configure(@sgb_args);
  $sgb->Show;
};

sub atoms_post_menu {

  ## figure out where the user clicked
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my $entry = $w->GetNearest($Ev->y, 1);
  return unless (defined($entry) and length($entry));

  ## select and anchor the right-clicked parameter
  my @which = $w->selectionGet();
  $w->anchorSet($entry);
  my $clicked = $w->info('anchor');
  if (grep {/^$clicked$/} @which) {
    ## right click within the current extended selection
    1;
  } else {
    ## right clicked outside the current extended selection
    $w->selectionClear;
    $w->selectionSet($entry);
    @which = $w->selectionGet();
  };
  &atoms_edit;

  ## post the message with parameter-appropriate text
  my ($name, $index, $type);
  my @sites = @{ $paths{$current}->get("atoms_atoms") };
  if ($#which > 0) {
    $index = $w->info('anchor');
    $name = "these atoms";
    $type = 'extended';
  } else {
    $index = $which[0];
    $name = ($sites[$index]->[4]) ? '"'.$sites[$index]->[4].'"' : '"'.$sites[$index]->[0].'"';
  };
  my $anchor = ($sites[$index]->[4]) ? '"'.$sites[$index]->[4].'"' : '"'.$sites[$index]->[0].'"';
  my ($X, $Y) = ($Ev->X, $Ev->Y);
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[
		      [ cascade=>"Move $anchor ...",
		       -tearoff=>0,
		       -menuitems=>[
				    [ command=>"before ...",
				      -command=>sub{atoms_move("before")}],
				    [ command=>"after ...",
				      -command=>sub{atoms_move("after")}],
				   ]],
		      [ command=>"Copy $anchor",
		       -command=>[\&atoms_copy, $index]],
		      [ command=>"Discard $name",
		       -command=>[\&atoms_delete, \@which]],
		     ])
	-> Post($X, $Y);
  $w -> break;
};


sub atoms_save_page {
  my $which = $_[0] || $current;
  ## store the sites
  $paths{$which} -> make(atoms_atoms=>[@atoms]);
  ## store the entry box parameters
  foreach my $k (qw(a b c alpha beta gamma rmax space)) {
    $paths{$which} -> make("atoms_$k" => $widgets{"atoms_$k"}->get());
  };
  ## store non-entry widgets
  $paths{$which} -> make(atoms_edge => $atoms_params{edge});
  $paths{$which} -> make(atoms_core => $atoms[$atoms_params{core}]->[4] || $atoms[$atoms_params{core}]->[0]);
  ## store the titles
  my $titles = $widgets{atoms_titles}->get('1.0', 'end');
  $titles =~ s/\n/<NL>/g;
  $paths{$which} -> make(atoms_titles=>$titles);
};


sub atoms_move {
  my $which = $_[0];
  my $where = "";
  my $whch = $widgets{atoms_list}->info('anchor');
  my $row   = (ref($whch) eq 'ARRAY') ? $$whch[0] : $whch;
  if (($which eq 'before') or ($which eq 'after')) {
    my $tomove = $atoms[$row]->[4] || $atoms[$row]->[0];
    my $label = "Move \"$tomove\" $which site number: ";
    my $dialog = get_string($dmode, $label, \$where);
    $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
    return unless ($where);
    Error("Specify a site index as the target when moving a site."), return unless ($where =~ /^\d+$/);
  } elsif ($which eq 'up') {
    return unless $row;
    $where = $row;
    $which = 'before';
    Echo("This site is at the top of the list."), return if ($where == 0);
  } elsif ($which eq 'down') {
    return unless $row;
    $where = $row + 1;
    $which = 'after';
    Echo("This site is at the bottom of the list."), return if ($where == $#atoms+1);
  };

  ## have the target, identify location in @atoms array
  my $target = $where-1;
  ($target = $#atoms) if ($target > $#atoms);
  ($target = 1)       if ($target < 1);

  --$target if ($row < $target);
  my $save = splice(@atoms, $row, 1);
  if ($which eq 'before') {
    @atoms = (@atoms[0..$target-1], $save, @atoms[$target..$#atoms]);
  } elsif ($which eq 'after')  {
    @atoms = (@atoms[0..$target], $save, @atoms[$target+1..$#atoms]);
    $target += 1;
  };
  $paths{$current}->make(atoms_atoms=>[@atoms]);
  project_state(0);
  populate_atoms();
  $widgets{atoms_list}->selectionClear;
  $widgets{atoms_list}->anchorSet($target);
  $widgets{atoms_list}->selectionSet($target);
  atoms_edit();
};

sub atoms_copy {
  my $which = $_[0];
  splice(@atoms, $which, 1, $atoms[$which], $atoms[$which]);
  $paths{$current}->make(atoms_atoms=>[@atoms]);
  populate_atoms($current);
  my $message = "Made a copy of ";
  $message .= $atoms[$which]->[4]||$atoms[$which]->[0];
  $message .= " and inserted it at site ";
  ++$which;
  $widgets{atoms_list} -> selectionSet($which);
  $widgets{atoms_list} -> anchorSet($which);
  &atoms_edit;
  project_state(0);
  ++$which;
  Echo($message.$which);
};

sub atoms_delete {
  my $which = $_[0];
  my $i = 0;
  foreach my $w (@$which) {
    my $ww = $w-$i;
    my $elem = $atoms[$ww]->[0];
    splice(@atoms, $ww, 1);
    $paths{$current}->make(atoms_atoms=>[@atoms]);
    populate_atoms($current);
    ++$w; ++$i;
    Echo("Discarded the $elem atom at site $w");
  };
  project_state(0);
  ($atoms_params{core}=0) if ($atoms_params{core} > $#atoms);
  $plotr_button -> focus();
};

sub run_atoms {

  my $atp  = $_[0];
  my $file = $_[1];
  #print "in run_atoms: $atp\n";
  Echo("Running atoms ... ");

  ## read titles and edge -- which is ok since the current must be
  ## showing, but also need to update them in case of clicking away
  ## and back before running
  atoms_new_site();
  $top->focus;
  atoms_save_page($current);
  Echo("Refreshed atoms parameters ...");

  ## autosave
  &save_project(0,1);

  ## are there lattice constants?
  my $is_ok = 0;
  foreach my $x (qw(a b c)) {
    my $val = $widgets{"atoms_$x"} -> get;
    ++$is_ok if (($val =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) and ($val > 0));
  };
  Error("Atoms aborted! You did not specify any lattice constants."), return unless $is_ok;

  Error("Atoms aborted! You must select an absorber atom by clicking on its button in the \"Core\" column."),
    return if ((not $paths{$current}->get("atoms_core")) or
	       ($paths{$current}->get('atoms_core') eq '^^nothing^^') or
	       ($paths{$current}->get('atoms_core') =~ /^\s*$/));
  my $core_ok = "";
  $core_ok = $paths{$current}->get('atoms_core') || "";
  Error("Atoms aborted! You did not identify the atomic species of the site you selected as the absorber."),
    return if (($core_ok =~ /^\s*$/) or ($core_ok =~ /^\d+$/));


  $top -> Busy();
  ## fill the Cell object
  my $cell = Xray::Xtal::Cell -> new();
  $cell -> make( Space_group=>$paths{$current}->get('atoms_space') );
  my ($this_sg) = $cell -> attributes('Space_group');
  unless ($this_sg) {
    $top -> Unbusy();
    Error("Invalid space group.  Atoms aborted.");
    return;
  };
  foreach my $param (qw(a b c alpha beta gamma)) {
    next unless ($paths{$current}->get("atoms_$param") =~ /^\s*(\d+\.?\d*|\.\d+)\s*$/);
    $cell -> make( $param=>$paths{$current}->get("atoms_$param") );
  };
  ## fill the Site objects
  my (@sites, @ksites);
  my $nsites = 0;
  my $keywords = Xray::Atoms -> new(die=>1);
  my $tag_bad = 0;
  my $xtal_warnings = q{};
  ##foreach my $k (sort (grep /^atoms_elem_\d+$/, (keys %widgets))) {
  my $count = 0;
  foreach my $s (@{ $paths{$current}->get("atoms_atoms") }) {
    check_for_third($s, $count);
    ++$count;
  };
  atoms_save_page($current);
  foreach my $s (@{ $paths{$current}->get("atoms_atoms") }) {
    $sites[$nsites] = Xray::Xtal::Site -> new($nsites);
    ## this mess allows for simple fractions and such
    $sites[$nsites] -> make(Element=>$s->[0],
			    X=>Xray::Atoms::number($s->[1],  1) +
			       Xray::Atoms::number($paths{$current}->get('atoms_shiftx'),1),
			    Y=>Xray::Atoms::number($s->[2],  1) +
			       Xray::Atoms::number($paths{$current}->get('atoms_shifty'),1),
			    Z=>Xray::Atoms::number($s->[3],  1) +
			       Xray::Atoms::number($paths{$current}->get('atoms_shiftz'),1), );
    if ($s->[4]) {
      $sites[$nsites] -> make(Tag=>$s->[4]);
      $tag_bad = 1 if ($s->[4] =~ /^\d+$/);
    };
    ($s->[5]) && ( $sites[$nsites] -> make(Occupancy=>$s->[5]) );
    $xtal_warnings .= $sites[$nsites] -> {message_buffer};
    $sites[$nsites] -> reset_message_buffer;
    ++$nsites;
    push @{$keywords->{sites}}, $s;
  };
  if ($tag_bad) {
    $top -> Unbusy;
    Error("Atoms aborted! A site tag cannot be an integer.");
    return;
  };
  my ($ed, $abs, $is_odd) = odd_edge_absorber($current);
  if ($is_odd) {
    my $message = "Measuring the $ed edge of $abs seems odd.  Is this correct?";

    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => $message,
		     -title          => 'Artemis: Question...',
		     -buttons        => ['Yes, continue', 'No, cancel'],
		     -default_button => 'No, cancel',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    my $answer = $dialog->Show();
    if ($answer eq 'No, cancel') {
      $top -> Unbusy;
      Echo("Aborting Atoms due to odd edge/absorber combination.");
      return;
    };
  };
  if ($xtal_warnings) {
    Error("There are possible problems reading the crystallographic data.");
    post_message($xtal_warnings, 'Error messages');
    $xtal_warnings = q{};
  };

  ## load all the values back into an Atoms keyword object
  $keywords -> make(identity => "Artemis $VERSION",
		    die      => 1,
		    quiet    => 1,
		    program  => 'Artemis',
		    edge     => $paths{$current}->get('atoms_edge'),
		    core     => $paths{$current}->get('atoms_core'),
		    space    => $paths{$current}->get('atoms_space'),
		    a	     => $paths{$current}->get('atoms_a'),
		    b	     => $paths{$current}->get('atoms_b'),
		    c	     => $paths{$current}->get('atoms_c'),
		    alpha    => $paths{$current}->get('atoms_alpha'),
		    beta     => $paths{$current}->get('atoms_beta'),
		    gamma    => $paths{$current}->get('atoms_gamma'),
		    rmax     => $paths{$current}->get('atoms_rmax'),
		    argon    => 0,
		    krypton  => 0,
		    nitrogen => 0,
		    );
  $keywords -> make(shift => $paths{$current}->get('atoms_shiftx'),
		             $paths{$current}->get('atoms_shifty'),
		             $paths{$current}->get('atoms_shiftz'),);
  map { $keywords -> make(title=>$_) } (split(/<NL>/, $paths{$current}->get('atoms_titles')));
  Echo("Read crystallographic parameters ...");

  ## =============================== error check, populate the cell, set rmax
  $cell -> verify_cell();
  $cell -> populate(\@sites);
  my $trouble = $keywords -> verify_keywords($cell, \@sites, 1);
  if ($trouble) {
    $top -> Unbusy();
    Error("Trouble found among the parameters.  Atoms aborted.");
    return;
  };

  my $message = "";
  $message .= $cell -> warn_shift();
  $message .= $cell -> cell_check();
  post_message($message, 'Atoms warnings') if $message;
  Echo("Processed crystallographic parameters ...");


  my (@cluster, @neutral);
  my ($atoms, $feff) = "";
  if ($atp) {
    build_cluster($cell, $keywords, \@cluster, \@neutral);
    my ($default_name, $is_feff) =
      &parse_atp($atp, $cell, $keywords, \@cluster, \@neutral, \$atoms);
    Echo("Made ATP output ($atp)");
    if ($file) {
      open A, ">".$file;
      print A $atoms;
      close A;
    } else {
      $notes{files} -> delete(qw(1.0 end));
      $notes{files} -> insert('end', $atoms);
      $notes{files} -> yviewMoveto(0);
      $current_file = $default_name;
      $top -> update;
      $generic_name = $default_name;
      raise_palette('files');
    };
  } else {
    my $echomsg = "Made ATP output (";
    build_cluster($cell, $keywords, \@cluster, \@neutral);
    my ($default_name, $is_feff) =
      &parse_atp('atoms', $cell, $keywords, \@cluster, \@neutral, \$atoms);
    $echomsg .= "atoms ";
    my $feffv = $config{atoms}{template};
    ## my $feffv = "feff";
    ## ($feffv = 'feff7') if ($config{atoms}{feff_version} == 7);
    ## ($feffv = 'feff8_exafs') if ($config{atoms}{feff_version} == 8);
    ($default_name, $is_feff) =
      &parse_atp($feffv, $cell, $keywords, \@cluster, \@neutral, \$feff);
    $echomsg .= "$feffv) ...";
    Echo($echomsg);
  };

  ## refill Path object and widgets with results from the atoms run
  my @lattice = $cell -> attributes("A", "B", "C", "Alpha", "Beta", "Gamma");
  $paths{$current}->make(atoms_a     => $lattice[0]);
  $paths{$current}->make(atoms_b     => $lattice[1]);
  $paths{$current}->make(atoms_c     => $lattice[2]);
  $paths{$current}->make(atoms_alpha => $lattice[3]);
  $paths{$current}->make(atoms_beta  => $lattice[4]);
  $paths{$current}->make(atoms_gamma => $lattice[5]);
  foreach my $p (qw(a b c alpha beta gamma)) {
    $widgets{"atoms_$p"} -> configure(-validate=>'none');
    $widgets{"atoms_$p"} -> delete(0, 'end');
    $widgets{"atoms_$p"} -> insert('end', $paths{$current}->get("atoms_$p"));
    $widgets{"atoms_$p"} -> configure(-validate=>'key');
  };

  ## skip this block if this is just some ol' atp output
  unless ($atp) {

    ## save the atoms.inp and feff.inp files
    my $id = $paths{$current}->get('id');
    my $atoms_file = File::Spec->catfile($project_folder, $id, "atoms.inp");
    open ATOMSFILE, ">".$atoms_file or die "could not open $atoms_file for writing";
    print ATOMSFILE $atoms;
    close ATOMSFILE;
    my $feff_file = File::Spec->catfile($project_folder, $id, "feff.inp");
    open FEFFFILE, ">".$feff_file or die "could not open $feff_file for writing";
    print FEFFFILE $feff;
    close FEFFFILE;

    ## send the feff.inp to its tab and display that tab
    #$widgets{feff_inptext} -> delete('1.0', 'end');
    #$widgets{feff_inptext} -> insert('1.0', $feff);
    $widgets{feff_inptext} -> Load(File::Spec->catfile($project_folder, $id, "feff.inp"));
    $widgets{feff_inptext} -> tagAdd("feffinp", qw(1.0 end));
    $widgets{feff_inptext} -> ResetUndo;
    $fefftabs -> pageconfigure('feff.inp', -state=>'normal');
    $fefftabs -> raise('feff.inp');

    $paths{$current} -> make(mode => $paths{$current}->get('mode')+2) unless
      ($paths{$current}->get('mode') & 2);
  };

  project_state(0);

  $top -> Unbusy();
  Echo("Running atoms ... done!");
}

## these cutoffs are a bit arbitrary
sub odd_edge_absorber {
  my $this = $_[0];
  my $edge = $paths{$this}->get('atoms_edge');
  my $tag  = $paths{$this}->get('atoms_core');
#  print "core=",$tag, $/;
  my $absorber = "";
  foreach my $s (@{ $paths{$current}->get("atoms_atoms") }) {
    my $this = lc($s->[4]) || lc($s->[0]);
    ($absorber = $s->[0]), last if (lc($tag) eq $this);
  };
  my $z = get_Z($absorber);
#  print "z=",$z, $/;
#  print "absorber=",$absorber, $/;

  my $is_odd = 0;
  ($is_odd = 1) if (($z > 59) and ($edge =~ /k/i)); # K edge above praseodymium
  ($is_odd = 1) if (($z < 45) and ($edge =~ /l/i)); # L edge below rhodium

  #print "$edge $absorber $z\n";
  return ($edge, $absorber, $is_odd);
};

sub check_for_third {
  my ($site, $row) = @_;
  my @col = (q{}, qw(x y z));
  foreach my $coord (1, 2, 3) {
    my $val = Xray::Atoms::number($site->[$coord], 1);	# watch out for fractions
    my $diff = abs($val - THIRD);
    my $id = $site->[4] || $site->[0];
    if ( ($diff < DELTA) and ($diff > EPSILON) ) {
      my $dialog =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => "The $col[$coord] coordinate of $id is very close to 1/3.  Atoms and Feff operate at 5 digits of precision.  Do you want to use the value $site->[$coord] or should Artemis change this value to 1/3?",
		       -title          => 'Artemis: Question...',
		       -buttons        => ["Use $site->[$coord]", 'Change to 1/3'],
		       -default_button => 'Change to 1/3',
		       -font           => $config{fonts}{med},);
      &posted_Dialog;
      #$dialog->Subwidget("message")->configure(-width=>100);
      my $answer = $dialog->Show();
      if ($answer eq "Change to 1/3") {
	$widgets{atoms_list} -> itemConfigure($row, $coord+2, -text=>"1/3");
	$atoms[$row]->[$coord] = 0.33333;
      };
    };
    $diff = abs($val - TWOTH);
    if ( ($diff < DELTA) and ($diff > EPSILON) ) {
      my $dialog =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => "The $coord coordinate of $id is very close to 2/3.  Atoms and Feff operate at 5 digits of precision.  Do you want to use the value $site->[$coord] or should Artemis change this value to 2/3?",
		       -title          => 'Artemis: Question...',
		       -buttons        => ["Use $site->[$coord]", 'Change to 2/3'],
		       -default_button => 'Change to 2/3',
		       -font           => $config{fonts}{med},);
      &posted_Dialog;
      my $answer = $dialog->Show();
      if ($answer eq "Change to 2/3") {
	$widgets{atoms_list} -> itemConfigure($row, $coord+2, -text=>"2/3");
	$atoms[$row]->[$coord] = 0.66667;
      };
    };
  };
};
