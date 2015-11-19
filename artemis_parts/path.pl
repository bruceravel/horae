# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## THE PATH PAGE


sub make_path {
  my $parent = $_[0];
  my $x_bitmap = '#define noname_width 13
#define noname_height 13
static char noname_bits[] = {
 0x00,0x00,0x0c,0x1c,0x18,0x0e,0x30,0x07,0xe0,0x03,0xc0,0x01,0xe0,0x01,0x70,
 0x03,0x38,0x06,0x1c,0x0c,0x0c,0x18,0x00,0x00,0x00,0x00};
';
  my $x_X = $top -> Bitmap('x', -data=>$x_bitmap,
			   -foreground=>$config{colors}{activehighlightcolor});
  my @x=(-image=>$x_X);

  my $c = $parent -> Frame(-relief=>'flat',
			   -borderwidth=>0,
			   #@window_size,
			   -highlightcolor=>$config{colors}{background},
			  );

  my $t = "";			# used for clicky help
  my @start = (-foreground=>$config{colors}{activehighlightcolor},
	       -font=>$config{fonts}{med});
  my @bold   = (-foreground => $config{colors}{mbutton},
		-background => $config{colors}{activebackground},
		-cursor     => $mouse_over_cursor,
		-font       => $config{fonts}{med});
  my @normal = (-foreground => $config{colors}{activehighlightcolor},
		-background => $config{colors}{background},
		-font       => $config{fonts}{med});
  ## header
  ##$header{current} = $c -> Label(@title2, -text=>"Path Description",)
  ##  -> pack(-side=>'top', -anchor=>'w', -padx=>6);


  #my $fr = $c -> Frame()
  #  -> pack(-side=>'top', -anchor=>'w', -fill=>'x',  -padx=>6);
  $widgets{path_label} = $c -> Label(-font        => $config{fonts}{bold},
				     -foreground  => $config{colors}{button},
				     -background  => $config{colors}{background2},
				     -borderwidth => 2,
				     -relief      => 'groove',
				     -anchor      => 'w',
				     )
    -> pack(-side=>'top', -anchor=>'w', -pady=>0, -fill=>'x');

  my $fr = $c -> Frame()
    -> pack(-side=>'top', -anchor=>'e', -fill=>'x',  -padx=>6);
  $widgets{path_include} = $fr -> Checkbutton(-text		=> "Include in the fit",
					      -font		=> $config{fonts}{med},
					      -foreground	=> $config{colors}{activehighlightcolor},
					      -activeforeground	=> $config{colors}{activehighlightcolor},
					      -selectcolor	=> $config{colors}{check},
					      -command		=> \&toggle_include,
					     )
    -> pack(-side=>'right', -anchor=>'w');
  $widgets{path_plotpath} = $fr -> Checkbutton(-text		 => "Plot after the fit",
					       -font		 => $config{fonts}{med},
					       -foreground	 => $config{colors}{activehighlightcolor},
					       -activeforeground => $config{colors}{activehighlightcolor},
					       -selectcolor	 => $config{colors}{check},
					       -command		 => \&toggle_plotpath,
					      )
    -> pack(-side=>'left', -anchor=>'e');
  $fr = $c -> Frame()
    -> pack(-side=>'top', -anchor=>'e', -fill=>'x',  -padx=>6);
  $widgets{path_setpath} = $fr -> Checkbutton(-text		=> "Make this path the default after the fit",
					      -font		=> $config{fonts}{med},
					      -foreground	=> $config{colors}{activehighlightcolor},
					      -activeforeground	=> $config{colors}{activehighlightcolor},
					      -selectcolor	=> $config{colors}{check},
					      -command		=> sub{&set_path_index($current)},
					     )
    -> pack(-side=>'left', -anchor=>'e');

  $widgets{path_header_box} =
    $c-> LabFrame(-label      => '',
		  -font	      => $config{fonts}{med},
		  -foreground => $config{colors}{activehighlightcolor},
		  -labelside  => 'acrosstop')
      -> pack(-side=>'top', -pady=>3, -padx=>6, -fill=>'x');
  $widgets{path_header} = $widgets{path_header_box}
    -> ROText(-width=>49, -height=>10, relief=>'flat',
	      -wrap=>'none', -font=>$config{fonts}{fixed})
    -> pack();
  &disable_mouse3($widgets{path_header});
  my ($font, $red, $grey) = ($config{fonts}{fixedit}, $config{colors}{button}, $config{colors}{disabledforeground});
  $widgets{path_header} -> tagConfigure('absorber', -foreground=>$red);
  $widgets{path_header} -> tagConfigure('angles',   -font=>$font, -foreground=>$grey);
  #$widgets{path_header} -> insert('end', 'This box will contain the feffNNNN.dat header');

  ## Entry widgets for path parameters
  ##my $one_page = 1;		# 0=use NoteBook, 1=all on one page
  my ($fr2, $frind);
  ##if ($one_page) {
  my $labframe = $c -> LabFrame(-label	    => 'Path parameter math expressions',
				-font	    => $config{fonts}{med},
				-foreground => $config{colors}{activehighlightcolor},
				-labelside  => 'acrosstop')
    -> pack(-side=>'top', -pady=>3, -padx=>6, -fill=>'both', -expand=>1);
  $fr = $labframe -> Scrolled('Pane', -relief=>'flat', -borderwidth=>2,
			      -scrollbars=>'oe', -height=>1)
    -> pack(-expand=>1, -fill=>'both');
  $fr->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					  ($is_windows) ? () : (-width=>8));
  my $i = 0;
  ## feff
  foreach my $pp (qw(label S02 E0 delR sigma^2 Ei 3rd 4th dphase k_array phase_array amp_array)) {
    my $tn;
    if ($pp eq 'S02') {		# insert degen box
      $tn = $fr -> ROText()
	-> grid(-column=>0, -row=>$i, -sticky=>'e');
      $widgets{'path_me_N'} = $fr -> PathparamEntry(-width=>3, -validate=>'key',
						    -validatecommand=>[\&set_pathparam, 'N'])
	-> grid(-column=>1, -row=>$i, -sticky=>'w');
      $fr -> Label(@x)
	-> grid(-column=>2, -row=>$i);
      $t = $fr -> ROText()
	-> grid(-column=>3, -row=>$i, -sticky=>'w');
      $widgets{'path_me_'.$pp} = $fr -> PathparamEntry(-width=>30,
						       -validate=>'key',
						       -validatecommand=>[\&set_pathparam, $pp])
	-> grid(-column=>4, -row=>$i, -sticky=>'ew');
    } else {
      $t = $fr -> ROText()
	-> grid(-column=>0, -row=>$i, -sticky=>'e');
      $widgets{'path_me_'.$pp} = $fr -> PathparamEntry(-validate=>'key',
						       -validatecommand=>[\&set_pathparam, $pp])
	-> grid(-column=>1, -row=>$i, -sticky=>'ew', -columnspan=>4);
    };
    foreach my $tt ($tn, $t) {
      next unless $tt;
      $tt -> configure(-relief		  => 'flat',
		       -height		  => 1,
		       -width		  => ($pp eq 'S02') ? 4 : 11,
		       -highlightcolor	  => $config{colors}{background},
		       -selectbackground  => $config{colors}{background},
		       -selectforeground  => $config{colors}{activehighlightcolor},
		       -selectborderwidth => 0,
		       -foreground	  => $config{colors}{activehighlightcolor},
		       -font		  => $config{fonts}{med});
      my @t_bindtags = $tt -> bindtags;
      $tt -> bindtags([$t_bindtags[1]]); ## bindtags([@t_bindtags[1,0,2,3]]);
      $tt -> tagConfigure('label', -justify=>'right');
      $tt -> tagBind('label', "<Any-Enter>", sub {shift->configure(@bold)});
      $tt -> tagBind('label', "<Any-Leave>", sub {shift->configure(@normal)});
      ## button one echos a little help message unless a fit has been
      ## run and this path parameter has been evaluated, in which case
      ## the evaluation is echoed
      $tt -> tagBind('label', "<Button-1>",  sub {my $tt = shift->get(qw(1.0 end));
						  chomp $tt;
						  my $ttt = $click_help{$tt} || "$tt ???";
						  my $pp = substr($tt,0,-1);
						  my $p = ($pp eq 'delE0') ? 'E0' : $pp;
						  $ttt = join(" ",
							      $paths{$current}->descriptor() ,
							      "---",
							      $pp,
							      "evaluated to",
							      $paths{$current}->get("value_".lc($p)),
							      "in the last fit."
							     )
						    if ($paths{$current}->get("value_".lc($p)));
						  Echo($ttt); });
      $t -> tagBind('label', "<Button-3>", [\&post_pathparam_menu, $pp, Ev('X'), Ev('Y')]);
      $widgets{'path_lab_'.$pp} = $tt;
      ## button three to raise a menu for setting other pathparams
    };

    $widgets{'path_me_'.$pp} -> bind("<Button-3>", [\&snarf_variable, $pp,
						    Ev('x'), Ev('y'),
						    Ev('X'), Ev('Y')]);


    $tn and $tn -> insert('end', 'N:', 'label');
    $tn and $tn -> configure(-width=>10);
    my $ppp = $pp;
    $ppp = "delE0" if ($pp eq 'E0');
    $t -> insert('end', $ppp.':', 'label');
    ++$i;
  };
  #$fr -> gridColumnconfigure(1, -weight=>1);
  #$fr -> gridColumnconfigure(4, -weight=>1);

  &manage_extended_params;
  $c -> Frame()
    -> pack(-side=>'top', -pady=>3, -padx=>6, -fill=>'both', -expand=>1);
  $widgets{help_path} =
    $c-> Button(-text => "Document: Paths and path parameters", @button2_list,
		-command=>sub{pod_display("artemis_path.pod")},
	       )
      -> pack(-side=>'top', -pady=>3, -padx=>1, -fill=>'x',);


  return $c;
};


## this is the call-back for the checkbutton in the paths menu for
## showing the "extended path parameters".  These are the odd ones,
## dphase + (k|amp|phase)_array, which only the experts should be
## using. This sub hides them by gridForget-ing or replaces them by
## gridding them back onto the paths view.
sub manage_extended_params {
  my $row = 9;
  foreach my $p (qw(dphase k_array amp_array phase_array)) {
    if (($config{paths}{extpp}) and (not $widgets{'path_me_'.$p} -> gridInfo)) {
      $widgets{'path_lab_'.$p} ->
	grid(-column=>0, -row=>$row, -sticky=>'w', -columnspan=>4);
      $widgets{'path_me_'.$p} ->
	grid(-column=>1, -row=>$row++, -sticky=>'ew', -columnspan=>4);
    } elsif ((not $config{paths}{extpp}) and ($widgets{'path_me_'.$p} -> gridInfo)) {
      $widgets{'path_lab_'.$p} -> gridForget();
      $widgets{'path_me_'.$p} -> gridForget();
    };
  };
};


## this is the callback to a mouse-3 click in the entry box for math
## expressions on the path page
sub snarf_variable {
  my ($t, $p, $x, $y, $xm, $ym) = @_;
  return if (($p eq 'feff') or ($p eq 'label'));
  #$widgets{'path_me_'.$p}
  $t -> eventGenerate("<Button-1>", '-x'=>$x, '-y'=>$y);
  $t -> eventGenerate("<ButtonRelease-1>", '-x'=>$x, '-y'=>$y);
  $t -> MouseSelect($x,'word','sel.first');
  return unless $t -> selectionPresent;
  my $this = $t -> SelectionGet;
  $t -> selectionClear, return if ($this =~ /[- \t\n\r\f(),+*\/]/);
  $t -> selectionClear, return if ($this eq 'reff');
  $t -> selectionClear, return if ($this =~ /^(\d+\.?\d*|\.\d+)$/);
  $t -> selectionClear, return if ($this =~ /^($function_regex)$/);
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[
		      ['command' => "Make \`$this\' a guess and jump",
		       -command  => sub{&jump_to_variable($this, 'guess', 0)}],
		      ['command' => "Make \`$this\' a guess and stay",
		       -command  => sub{&jump_to_variable($this, 'guess', 1)}],
		      "-",
		      ['command' => "Make \`$this\' a def and jump",
		       -command  => sub{&jump_to_variable($this, 'def', 0)}],
		      ['command' => "Make \`$this\' a def and stay",
		       -command  => sub{&jump_to_variable($this, 'def', 1)}],
		      "-",
		      ['command' => "Make \`$this\' a set and jump",
		       -command  => sub{&jump_to_variable($this, 'set', 0)}],
		      ['command' => "Make \`$this\' a set and stay",
		       -command  => sub{&jump_to_variable($this, 'set', 1)}],
		      "-",
		      ['command' => "Make \`$this\' a skip and jump",
		       -command  => sub{&jump_to_variable($this, 'skip', 0)}],
		      ['command' => "Make \`$this\' a skip and stay",
		       -command  => sub{&jump_to_variable($this, 'skip', 1)}],
		     ]
	 ) ->Post($xm,$ym);
  $t -> break;
};


## and this disposes of the snarfed variable
sub jump_to_variable {
  my ($this, $gds, $stay, $value) = @_;
  my $which = -1;
  ## search for this variable ...
  my $see = 0;
  foreach (@gds) {
    ++$see;
    $which = $_, last if ($_->name =~ /^$this$/i);
  };
  ## or for the end of the list
  if ($which == -1) {
    push @gds, Ifeffit::Parameter->new(type=>$gds,
				       name=>$this,
				       mathexp=>'0',
				       bestfit=>0,
				       modified=>1,
				       note=>"$this: ",
				       autonote=>1,
				      );
    $see = $#gds;
    $which = $gds[$see];
    ++$see;
  };
  $which->make(type=>$gds,
	       modified=>1);
  Echo("Made \"$this\" a $gds parameter");
  if (defined $value) {
    $which->make(mathexp=>$value);
  } elsif ($stay) {
    $which->make(mathexp=>'0');
  };
  $which->make(note=>$which->name.": ") if ($which->note =~ /^\s*$/);
  repopulate_gds2();
  gds2_display($see);
  return if $stay;
  &display_page("gsd");
  project_state(0);
  $parameters_changed = 1;
};


## This sub posts the menu of path parameter operations when the path
## parameter label is mouse-3 clicked.
sub post_pathparam_menu {
  my ($t, $p, $X, $Y) = @_;
  #$p = $t->get(qw(1.0 end));
  #$p = substr($p, 0, index($p, ':'));
  my $pp = uc $p;
  if (@_ < 3) {
    my $e = $t->XEvent;
    ($X, $Y) = ($e->X, $e->Y);
  };

  my $d = $paths{$current}->data;
  my $f = $paths{$current}->get('parent');
  my @all = &all_data;
  my $ndata = $#all;
  @all = &all_feff;
  my $nfeff = $#all;
  @all = grep /^$d\.feff\d+$/, (keys %paths);
  my $this_nfeff = $#all;


  my $pathparam_menu = $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[#(($p eq 'feff') ?
		      # (['command' => "Read a feffNNNN.dat file",
		      #	 -command  => [\&Echo, "Read a feffNNNN.dat file"]],"-" ) : ()),
		      ['command' => "Edit $pp for many paths",
		       -command  => [\&add_mathexp, $p]],
		      ['command' => "Clear $pp for this path",
		       -command  => sub{$paths{$current}->get($p) = "";
					$widgets{'path_me_'.$p} -> delete(qw(0 end));
				        project_state(0);}],
		      "-",
		      ['command' =>
		       "Export this $pp to every path in THIS feff calculation",
		       -command  =>
		       [\&add_to_paths, $pp, $widgets{'path_me_'.$p}->get(), 'this']],
		      ['command' =>
		       "Export this $pp to every path in EACH feff with THIS data set",
		       -state => ($this_nfeff) ? 'normal' : 'disabled',
		       -command  =>
		       [\&add_to_paths, $pp, $widgets{'path_me_'.$p}->get(), 'data']],
		      ['command' =>
		       "Export this $pp to every path in EACH feff calculation",
		       -state => ($nfeff) ? 'normal' : 'disabled',
		       -command  =>
		       [\&add_to_paths, $pp, $widgets{'path_me_'.$p}->get(), 'each']],
		      ['command' =>
		       "Export this $pp to SELECTED paths",
		       -command  =>
		       [\&add_to_paths, $pp, $widgets{'path_me_'.$p}->get(), 'sel']],
		      "-",
		      ['command' => "Grab $pp from the previous path",
		       -command  => [\&grab_from_path, $p, 'prev']],
		      ['command' => "Grab $pp from the next path",
		       -command  => [\&grab_from_path, $p, 'next']],
		      (($p eq 'sigma^2') ?
		       ("-",
			['command' => "Insert Einstein function",
			 -command  => sub{sigsqr_model('eins') }],
			['command' => "Insert Debye function",
			 -command  => sub{sigsqr_model('debye')}],
		       ) : ())
		     ] );
  $pathparam_menu->Post($X,$Y);
  $t -> break;
};


sub populate_path {
  my $this   = $_[0];
  my $parent = $paths{$this}->get('parent');
  $widgets{path_header} -> delete(qw(1.0 end));
  my $i = 0;
  foreach my $l (split(/\n/, $paths{$this}->get('header'))) {
    ## the look-ahead assertion is required because it is easy to mix
    ## up the letter O and the number 0 in a feff potentials list
    if ($l =~ / 0 +(?=\w)/) {
      $widgets{path_header} -> insert('end', $l, 'absorber');
    } elsif ($l =~ /beta/) {
      $widgets{path_header} -> insert('end', $l, 'angles');
    } else {
      $widgets{path_header} -> insert('end', $l);
    };
    $widgets{path_header} -> insert('end', "\n");
    ++$i;
  };
  $widgets{path_header} -> configure(-height=>$i);
  my $label = $paths{$this}->get('intrpline');
  $widgets{path_header_box} -> configure(-label=>substr($label, index($label, ':')+1));

  $widgets{path_include} -> deselect();
  $widgets{path_include} -> select() if ($paths{$this}->get('include'));
  ##my $thislab = $paths{$this}->get('lab');
  ##($thislab = substr($thislab, 0, 15) . " ... ") if (length($thislab) > 16);
  ##$widgets{path_include} -> configure(-text=>"Include \`$thislab\' in the fit");

  $widgets{path_setpath} -> deselect();
  $widgets{path_setpath} -> select() if ($paths{$this}->get('setpath'));

  $widgets{path_plotpath} -> deselect();
  $widgets{path_plotpath} -> select() if ($paths{$this}->get('plotpath'));

  $widgets{path_label} -> configure(-text=>"  ".$paths{$this}->descriptor());

  ##feff
  foreach (qw(label N S02 E0 delR sigma^2 Ei 3rd 4th dphase k_array phase_array amp_array)) {
    my $key = "path_me_".$_;
    $widgets{$key} -> configure(-validate=>'none');
    $widgets{$key} -> delete(qw(0 end));
    $widgets{$key} -> insert(0, ($_ eq 'N') ?
			     $paths{$this}->get('deg') :
			     $paths{$this}->get(lc($_)));
    $widgets{$key} -> configure(-validate=>'key');
  };
};


sub set_pathparam {
  my ($k, $entry, $prop) = (shift, shift, shift);
#  print "$current $k $entry\n";
  (lc($k) eq 'n') and ($entry !~ /^(|\d+\.?\d*|\.\d+)$/) and return 0;
  $paths{$current} -> make(lc($k)=>$entry);
  (lc($k) eq 'feff') and $paths{$current} -> make(file=>$entry);
  (lc($k) eq 'n')    and $paths{$current} -> make(deg =>$entry);
  unless (($entry eq 'label') or ($entry eq 'header')) {
    $paths{$current} -> make(do_k=>1);
  };
  project_state(0);
  return 1;
  ## need to flag that fit needs to be redone and that project needs
  ## to be saved
};


sub add_a_path {
  my $data = $paths{$current}->data;
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;
  my $path = $current_data_dir || cwd;
  my $types = [['feffNNNN.dat files', 'feff*.dat'],
	       ['All Files', '*'],];
  my $file      = $_[0];
  my $noanchor  = $_[1];
  my $force_new = $_[2];
  ($file and (-e $file)) or
    ($file = $top -> getOpenFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				 -title => "Artemis: Open a feffNNNN.dat file"));
  return unless ($file);
  Error("\"$file\" is not a feffNNNN.dat file"), return unless Ifeffit::Files->is_feffnnnn($file);
  my ($name, $feff_path, $suffix) = fileparse($file);
  ($current_data_dir = $feff_path) unless sub_directory($feff_path, $project_folder);

  my $id = '';
  ## need to figure out if this path is from a calculation that has
  ## already been used with this data set
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'feff');
    next unless same_directory($paths{$k}->get('path'), $feff_path);
    next unless ($paths{$k}->data eq $data);
    $id = $paths{$k}->get('id');
    last;
  };

  if ($force_new or (not $id)) {
    $id = $data . '.feff' . $n_feff;

##     ## import this feff calc into the project by copying all files
##     ## &initialize_project(0);
##     my $project_feff_dir = &initialize_feff($id);
##     ## copy all these feff files to the project feff folder
##     opendir F, $feff_path;
##     my @list = grep { (-f File::Spec->catfile($feff_path,$_)) and
## 			(lc($_) =~ /\.(bin|dat|inp|log|run)$/) } readdir F;
##     closedir F;
##     map { copy(File::Spec->catfile($feff_path,$_), $project_feff_dir) } @list;
##     ## make sure that the feff.inp file is "feff.inp"
##     copy($file, File::Spec->catfile($project_feff_dir, 'feff.inp'));

    ## instantiate and list a new feff object
    $paths{$id} = Ifeffit::Path -> new(id     => $id,
				       lab    => 'FEFF'.$n_feff,
				       type   => 'feff',
				       path   => $feff_path,
				       data   => $data,
				       family => \%paths);
    $paths{$id}->make(mode=>2) if (-e $paths{$id}->get('feff.inp'));
    my @autoparams;
    $#autoparams = 6;
    (@autoparams = autoparams_define($id, $n_feff, 0, 0)) if $config{autoparams}{do_autoparams};
    $paths{$id} -> make(autoparams=>[@autoparams]);
    $list -> add($id, -text=>'FEFF'.$n_feff, -style=>$list_styles{noplot});
    $list -> setmode($id, 'close');
    $list -> setmode($data, 'close') if ($list->getmode($data) eq 'none');
    my $intrp_ok = &do_intrp($id);
    $paths{$id} -> make(mode=>$paths{$id}->get('mode')+4) if $intrp_ok;
    ++$n_feff;
  };

  my $descr = $paths{$id}->descriptor();
  Echo("Adding $descr ...");
  #my $kid = $list -> addchild($id); #, -after=>$current);
  my $kid = fetch_nnnn($id, $feff_path, $name);
  $list -> entryconfigure($kid,
			  -style => $list_styles{$paths{$kid}->pathstate("enabled")},
			  -text  => $paths{$kid}->get('lab'));
  display_page($kid) unless $noanchor;
  Echo("Adding $descr ... done!");
  return $kid;
};



sub rename_path {
  Error("This isn't a path."), return unless ($paths{$current}->type eq 'path');
  my $this = $paths{$current}->get('lab');
  my $newname = $this;
  my $label = "New name for path \"".$paths{$paths{$current}->get('parent')}->get('lab').": $this\": ";
  my $dialog = get_string($dmode, $label, \$newname, \@rename_buffer);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Not renaming ". $this), return if ($this eq $newname);
  $newname =~ s{[\"\']}{}g;
  push @rename_buffer, $newname;
  project_state(0);
  $paths{$current} -> make(lab=>$newname);
  $list -> itemConfigure($current, 0, -text=>$newname);
  $widgets{path_label} -> configure(-text=>"  ".$paths{$current}->descriptor());
};


sub clone_this_path {
  my $old    = $paths{$current}->get('lab');
  my $parent = $paths{$current}->get('parent');
  my $this = $list -> addchild($parent, -after=>$current);
  $paths{$this} = Ifeffit::Path -> new(id       => $this,
				       type     => 'path',
				       family   => \%paths,
				       plotpath => 0);
  foreach my $k (keys %{$paths{$current}}) {
    next if ($k =~ /(id|type|group|file)/);
    $paths{$this}->make($k=>$paths{$current}->get($k));
  };

  my $lab = $paths{$this}->pathlabel($old);
  #$paths{$this}->make(lab=>$lab);

  ## halve the degeneracy of the current and the clone
  $paths{$this}->make(deg=>$paths{$current}->get('deg')/2);
  $paths{$current}->make(deg=>$paths{$this}->get('deg'));

  $list -> entryconfigure($this,
			  -style => $list_styles{$paths{$this}->pathstate("enabled")},
			  -text  => $lab);
  $paths{$this} -> pathgroup(\%paths);
  display_page($this);
  Echo("Cloned $old and called it \"$lab\"");
};




sub toggle_include {
  $paths{$current}->make(include=> not $paths{$current}->get('include'));
  project_state(0);
  my $this = $paths{$current}->data;
  return unless $paths{$this}->{include};
  my $style = $list_styles{$paths{$current}->pathstate};
  $list -> entryconfigure($current, -style => $style);
  $paths{$current}->get('include') ?
    Echo("Include " . $paths{$current}->descriptor() . " in the fit.") :
      Echo("Exclude " . $paths{$current}->descriptor() . " from the fit.");
};

sub toggle_plotpath {
  $paths{$current}->make(plotpath=> not $paths{$current}->get('plotpath'));
  project_state(0);
};
sub set_plotpath {
  my ($which, $val) = @_;
  $paths{$which}->make(plotpath=>$val);
  project_state(0);
};


sub set_path_index {
  my $which = $_[0];
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq "path");
    $paths{$k}->make(setpath => 0);
  };
  $paths{$which}->make(setpath => 1);
  Echo($paths{$which}->descriptor() . " marked as Ifeffit's current path");
};

## return the one marked as the default or the first included path if
## the default is not included
sub which_set_path {
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq "path");
    return $k if (($paths{$k}->get('setpath')) and $paths{$k}->get('include'));
  };
  foreach my $k (sort (keys %paths)) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq "path");
    return $k if $paths{$k}->get('include');
  };
};


###===================================================================
### math expression utilities
###===================================================================

sub add_mathexp {
  my $which = $_[0];
  my $red = $config{colors}{check};
  my $calcs = 'this';
  my $ren = $top -> Toplevel(-title=>'Artemis: read math expression', -class=>'horae');
  $ren -> protocol(WM_DELETE_WINDOW => sub{$ren->destroy;});
  #$ren -> iconbitmap('@'.$iconbitmap);
  $ren -> iconimage($iconimage);
  $ren -> Label(-text=>"Math expression for $which",
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top');
  my $entry = $ren -> Entry(-justify=>'left',-width=>50)
    -> pack(-side=>'top', -expand=>1, -fill=>'x', -padx=>10);
  $entry -> insert('end', $widgets{'path_me_'.$which}->get) if ($paths{$current}->type eq 'path');
  $entry -> selectionRange(qw(0 end));
  $entry -> bind("<KeyPress-Return>",
		 sub{&add_to_paths($which, $entry->get(), $calcs); $ren->destroy;});

  # buttons at the bottom
  my @props = (-selectcolor=>$red,
	       -foreground=>$config{colors}{activehighlightcolor});
  my $fr = $ren -> Frame(-relief=>'flat')
    -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
  $fr -> Button(-text=>'Document: edit math expression',  @button2_list,
		-command=>sub{pod_display("artemis_editme.pod")})
    -> pack(-side=>'right', -expand=>1, -fill=>'x');
  $fr = $ren -> Frame(-relief=>'flat')
    -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
  $fr -> Button(-text=>'OK',  @button2_list,
		-command=>sub{&add_to_paths($which, $entry->get(), $calcs); $ren->destroy;})
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $fr -> Button(-text=>'Cancel',  @button2_list,
		-command=>sub{$ren->destroy;})
    -> pack(-side=>'right', -expand=>1, -fill=>'x');
  ## this radio above the buttons
  $fr = $ren -> Frame(-relief=>'flat')
    -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
  my $data = $fr -> Radiobutton(-text=>'Add to EACH feff in THIS data set', @props,
		     -activeforeground=>$config{colors}{activehighlightcolor},
		     -value=>'data', -variable=>\$calcs)
    -> pack(-side=>'left');
  my $sel = $fr -> Radiobutton(-text=>'Add to all selected paths', @props,
		     -activeforeground=>$config{colors}{activehighlightcolor},
		     -value=>'sel', -variable=>\$calcs)
    -> pack(-side=>'right');
  ## and these radios underneath entry box
  $fr = $ren -> Frame(-relief=>'flat')
    -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
  my $this = $fr -> Radiobutton(-text=>'Add to THIS feff calculation only', @props,
		     -activeforeground=>$config{colors}{activehighlightcolor},
		     -value=>'this', -variable=>\$calcs)
    -> pack(-side=>'left');
  my $each = $fr -> Radiobutton(-text=>'Add to EACH feff calculation', @props,
				-activeforeground=>$config{colors}{activehighlightcolor},
				-value=>'each', -variable=>\$calcs)
    -> pack(-side=>'right');

  ## disable the radiobuttons as appropriate
  my $d = $paths{$current}->data;
  my $f = $paths{$current}->get('parent');
  my @all = &all_data;
  ($#all) or ($data -> configure(-state=>'disabled'));
  @all = &all_feff;
  ($#all) or ($each -> configure(-state=>'disabled'));
  @all = grep /^$d\.feff\d+$/, (keys %paths);
  ($#all) or ($data -> configure(-state=>'disabled'));

  $entry -> focus;
  my $str = sprintf("+%d+%d", 0.35*$top->screenwidth(), 0.4*$top->screenheight());
  $ren -> geometry($str);
  $ren -> raise;
  $ren -> grab;
};

## this data each sel
sub add_to_paths {
  my ($which, $mathexp, $calcs) = @_;
  my ($dt, $f, $curr) = split(/\./,$current);
  my $data = $paths{$current}->data;
  my $feff = $paths{$current}->feff; #get('parent');
  my $message = "";
  if ($mathexp eq '^^clear^^') {
    $mathexp = "";
    $message = "Cleared \`$which\' for all paths.";
  };
  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless ($paths{$p}->type eq "path");
    my %tokens = (i => $paths{$p}->get('feff_index'),
		  I => sprintf("%4.4d", $paths{$p}->get('feff_index')),
		  r => $paths{$p}->get('reff'),
		  d => $paths{$p}->get('deg'),
		  D => "debye(temp, thetad)",
		  E => "eins(temp, thetae)",
		 );
    (my $mesub = $mathexp) =~ s/\%([iIrdDE])/$tokens{$1}/g;
  SWITCH: {
      ($calcs eq 'this') and do { # this feff calculation
	last SWITCH unless ($paths{$p}->get('parent') eq $feff); # this or each?
	$paths{$p} -> make($which, $mesub);
	$message = "Set \`$which\' to \`$mathexp\' in all paths in this feff calculation.";
	last SWITCH;
      };
      ($calcs eq 'data') and do { # all feff calcs with this data set
	last SWITCH unless ($paths{$p}->data eq $data);
	$paths{$p} -> make($which, $mesub);
	$message = "Set \`$which\' to \`$mathexp\' in all paths for this data set.";
	last SWITCH;
      };
      ($calcs eq 'each') and do { # all feff calcs used
	$paths{$p} -> make($which, $mesub);
	$message = "Set \`$which\' to \`$mathexp\' in all paths in each feff calculation.";
	last SWITCH;
      };
      ($calcs eq 'sel') and do { # selected paths
	last SWITCH unless  grep {$p eq $_} $list->info('selection');
	$paths{$p} -> make($which, $mesub);
	$message = "Set \`$which\' to \`$mathexp\' in the selected paths.";
	last SWITCH;
      };
    };
  };
  display_properties;
  project_state(0);
  Echo($message);
};

## copy all path parameters from current to others
sub copy_pps {
  my $how = $_[0];
  my $data = $paths{$current}->data;
  my $feff = $paths{$current}->feff;

  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless ($paths{$p}->type eq "path");

    next if (($how eq 'this') and ($paths{$p}->feff ne $feff));
    next if (($how eq 'data') and ($paths{$p}->data ne $data));
    next if (($how eq 'sel')  and not (grep {$p eq $_} $list->info('selection')));

    foreach (qw(label S02 E0 delR sigma^2 Ei 3rd 4th dphase k_array phase_array amp_array)) {
      my $exp = $widgets{'path_me_'.$_}->get();
      $paths{$p} -> make($_, $exp);
    };

  };
  my $which = "paths in this Feff calculation";
  ($which = "paths for this data set") if ($how eq 'data');
  ($which = "all paths")               if ($how eq 'each');
  ($which = "selected paths")          if ($how eq 'sel');
  Echo("Set all parameters for $which to the values of the current path");
};


sub grab_from_path {
  my ($p, $which) = @_;
  my $from = $list->info($which, $current);
  ## exception handling
  Echo("This is the last path"), return if (not $from and ($which eq 'next'));
  Echo("This is the last path in this feff calculation"), return
    if (($from =~ /^feff\d+$/)  and ($which eq 'next'));
  Echo("This is the first path in this feff calculation"), return
    if (($from =~ /^feff\d+$/)  and ($which eq 'previous'));
  ## insert the value
  my $value = $paths{$from} -> get(lc($p));
  ($which eq 'prev') and ($which = 'previous');
  Echo("The $which value of $p is blank"), return unless (defined $value);
  Echo("The $which value of $p is blank"), return if ($value =~ /^\s*$/);
  $paths{$current} -> make($p => $value);
  $widgets{'path_me_'.$p} -> delete(0, 'end');
  $widgets{'path_me_'.$p} -> insert('end', $value);
  $widgets{'path_me_'.$p} -> icursor('end');
  $widgets{'path_me_'.$p} -> focus();
  project_state(0);
  my $pp = uc $p;
  Echo("Grabbed \`$value\' for $pp from the $which path");
};


sub select_paths {
  my ($how, $crit, $nodisplay) = @_;
  my ($data, $feff, $curr) = split(/\./,$current);
  $feff = ($current =~ /(feff\d+)/) ? $1 : "";
  my $parent;
  my $this = $current;

  ## get the list of paths that follow the current one in the list,
  ## but which are still of the same feff calculation.  this is done
  ## for the sake of "exclude after current".  This way cloned
  ## paths, which have a higher X as in dataN.feffM.X are considered
  ## in their place in the list
  my @following = ();
  if ($paths{$current}->type eq 'path') {
    my $pth = $current;
    while ($list->infoNext($pth)) {
      $pth = $list->infoNext($pth);
      push(@following, $pth)
	if (($paths{$pth}->type eq 'path') and
	    ($paths{$pth}->get('parent') eq $paths{$current}->get('parent')));
    };
  };

  $parent = $paths{$current}->feff;
  return unless $parent;

  my $message;
  if (($how eq 'nlegs') and (not $crit)) {
    $crit = &get_nlegs;
    Echo("Canceling path selection"), return if ($crit eq 'Cancel');
    Echo("Selecting all paths of $crit legs and fewer");
  } elsif (($how eq 'r') and (not $crit)) {
    $crit = &get_r;
    Echo("Canceling path selection"), return if ($crit eq 'Cancel');
    Echo("Selecting all paths of distance $crit and shorter");
  } elsif (($how eq 'amp') and (not $crit)) {
    $crit = &get_zcwif;
    Echo("Canceling path selection"), return if ($crit eq 'Cancel');
    Echo("Selecting all paths of amplitude $crit and higher");
  };

  ## check the data this path is associated with to see if it is
  ## included in the fit

  if ($how eq 'toggle')  {
    my $data = $paths{$crit}->data;
    $paths{$crit}->make(include => not $paths{$crit}->get('include'));
    if ($paths{$data}->get('include')) {
      $list -> entryconfigure($paths{$crit}->get('id'),
			      -style=>$list_styles{$paths{$crit}->pathstate});
    };
    my $onoff = ($paths{$crit}->get('include')) ? 'on' : 'off';
    $message  = "Toggled $onoff \"" . $paths{$crit}->descriptor() .
      "\" for fitting.";
  } elsif ($how eq 'on')  {
    my $data = $paths{$crit}->data;
    $paths{$crit}->make(include => 1);
    if ($paths{$data}->get('include')) {
      $list -> entryconfigure($paths{$crit}->get('id'),
			      -style=>$list_styles{$paths{$crit}->pathstate("enabled")});
    };
    $message  = "Toggled on \"" . $paths{$crit}->descriptor() . "\" for fitting.";
  } elsif ($how eq 'off')  {
    my $data = $paths{$crit}->data;
    $paths{$crit}->make(include => 0);
    if ($paths{$data}->get('include')) {
      $list -> entryconfigure($paths{$crit}->get('id'),
			      -style=>$list_styles{$paths{$crit}->pathstate("disabled")});
    };
    $message  = "Toggled off \"" . $paths{$crit}->descriptor() . "\" for fitting.";
  } else {
    foreach my $p (keys %paths) {
      next unless (ref($paths{$p}) =~ /Ifeffit/);
      next unless ($paths{$p}->type eq 'path');
    SWITCH: {
	($how =~ /^all/) and do {
	  last SWITCH if (($how =~ /this/) and ($p !~ /$parent/));
	  $paths{$p} -> make(include=>1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style => $list_styles{$paths{$p}->pathstate("enabled")});
	  };
	  $message = "Included all paths for fitting.";
	  last SWITCH;
	};
	($how =~ /^none/) and do {
	  last SWITCH if (($how =~ /this/) and ($p !~ /$parent/));
	  $paths{$p} -> make(include=>0);
	  $list -> entryconfigure($paths{$p}->get('id'),
				  -style => $list_styles{$paths{$p}->pathstate("disabled")});
	  $message = "Excluded all paths from fitting.";
	  last SWITCH;
	};
	($how =~ /^invert/) and do {
	  last SWITCH if (($how =~ /this/) and ($p !~ /$parent/));
	  $paths{$p} -> make(include=>($paths{$p}->get('include')) ? 0 : 1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate});
	  };
	  $message = "Inverted the included paths.";
	  last SWITCH;
	};
	($how eq 'current') and do {
	  last SWITCH if ($paths{$p}->get('parent') ne $parent);
	  $paths{$p} -> make(include=>(grep /^$p$/, @following) ? 0 : 1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate});
	  };
	  $message = "Excluded all paths after \"" .
	    $paths{$current}->descriptor() . "\" from fitting.";
	  last SWITCH;
	};
	($how eq 'nlegs') and do {
	  last SWITCH if ($paths{$p}->get('parent') ne $parent);
	  $paths{$p} -> make(include=>($paths{$p}->get('nleg') > $crit) ? 0 : 1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate});
	  };
	  $message = "Excluded all paths with more than $crit legs from fitting.";
	  last SWITCH;
	};
	($how eq 'r') and do {
	  last SWITCH if ($paths{$p}->get('parent') ne $parent);
	  $paths{$p} -> make(include=>($paths{$p}->get('reff')>$crit) ? 0 : 1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate});
	  };
	  $message = "Excluded all paths longer than $crit from fitting.";
	  last SWITCH;
	};
	($how eq 'amp') and do {
	  last SWITCH if ($paths{$p}->get('parent') ne $parent);
	  $paths{$p} -> make(include=>($paths{$p}->get('zcwif')<$crit) ? 0 : 1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate});
	  };
	  $message = "Excluded all paths with amplitude smaller than $crit from fitting.";
	  last SWITCH;
	};
	($how eq 'selon') and do {
	  my $selected = grep {$p eq $_} $list->info('selection');
	  last SWITCH unless ($selected);
	  $paths{$p} -> make(include=>1);
	  my $data = $paths{$p}->data;
	  if ($paths{$data}->get('include')) {
	    $list -> entryconfigure($paths{$p}->get('id'),
				    -style=>$list_styles{$paths{$p}->pathstate("enabled")});
	  };
	  $message = "Included selected paths for fitting.";
	  last SWITCH;
	};
	($how eq 'seloff') and do {
	  my $selected = grep {$p eq $_} $list->info('selection');
	  last SWITCH unless ($selected);
	  $paths{$p} -> make(include=>0);
	  $list -> entryconfigure($paths{$p}->get('id'),
				  -style=>$list_styles{$paths{$p}->pathstate("disabled")});
	  $message = "Excluded selected paths from fitting.";
	  last SWITCH;
	};
      }; # end of SWITCH
    }; # end of loop over paths
  }; # end of if/else
  display_properties unless $nodisplay;
  project_state(0);
  Echo($message);
};


sub plot_path {
  my $these = $_[0];
  my $space = $_[1];
  my $data = $paths{$these->[0]}->data;
  $list->selectionClear;
  $list->selectionSet($data);
  foreach my $p (@$these) {
    $list->selectionSet($p);
  };
  &plot($space, 0);
};

sub set_degeneracy {
  my $how = $_[0];
  my $this = ($paths{$current}->type eq 'feff') ? $current : $paths{$current}->get('parent');
 SWITCH: {
    ($how eq '1') and do {
      foreach my $p (keys %paths) {
	next unless (ref($paths{$p}) =~ /Ifeffit/);
	next unless ($paths{$p}->type eq 'path');
	next unless ($paths{$p}->get('parent') eq $this);
	$paths{$p} -> make(deg=>1);
      };
      Echo('All degeneracies were set to 1 for "' . $paths{$this}->descriptor . '"');
      last SWITCH;
    };
    ($how eq 'feff') and do {
      my $pathto = $paths{$this}->get('path');
      Echo("You need to reset the path to FEFF"), return unless (-d $pathto);
      $top -> Busy;
      foreach my $p (keys %paths) {
	next unless (ref($paths{$p}) =~ /Ifeffit/);
	next unless ($paths{$p}->type eq 'path');
	next unless ($paths{$p}->get('parent') eq $this);
	my $file = File::Spec->catfile($pathto, $paths{$p}->get('feff'));
	next unless (-e $file);
	my $degen;
	open F, $file or die "could not open feffNNNN.dat file $file for reading\n";
	while (<F>) {
	  next unless (/nleg, deg, reff/);
	  $degen = (split(" ", $_))[1];
	  last;
	};
	close F;
	$paths{$p} -> make(deg=>int($degen));
      };
      $top -> Unbusy;
      Echo('All degeneracies were reset to their values from FEFF');
      last SWITCH;
    };
  };
  display_properties;
  project_state(0);
};


sub sigsqr_model {
  my $name  = ($_[0] eq 'eins') ? "Einstein" : "Debye";
  my $which = ($_[0] eq 'eins') ? "bond" : "material";

  ## use the autoparameter suffix for this feff calc
  my $parent = $paths{$current}->get('parent');
  my $suffix = "";
  ($suffix = $1) if  ($paths{$parent}->{autoparams}->[0] =~ /(_.+)/);
  my $theta = ($_[0] eq 'eins') ? "thetae" : "thetad";
  my $value = $_[0] . "(temp$suffix, $theta$suffix)";

  ## define the guess and set parameters if needed
  my $found = 0;
  map { ++$found if (lc($_->name) eq "temp$suffix") } (@gds);
  unless ($found) {
    push @gds, Ifeffit::Parameter->new(type=>"set",
				       name=>"temp$suffix",
				       mathexp=>"300",
				       bestfit=>"300",
				       modified=>1,
				       note=>"The temperature of the measurement",
				       autonote=>0,
				      );
    my $row = $#gds+1;
    $widgets{gds2list} -> add($row);
    $widgets{gds2list} -> itemCreate($row, 0, -text=>$row,          -style=>$gds_styles{set});
    $widgets{gds2list} -> itemCreate($row, 1, -text=>"s:",          -style=>$gds_styles{set});
    $widgets{gds2list} -> itemCreate($row, 2, -text=>"temp$suffix", -style=>$gds_styles{set});
    $widgets{gds2list} -> itemCreate($row, 3, -text=>"300",         -style=>$gds_styles{set});
  };
  $found = 0;
  map { ++$found if (lc($_->name) eq "$theta$suffix") } (@gds);
  unless ($found) {
    push @gds, Ifeffit::Parameter->new(type=>"guess",
				       name=>"$theta$suffix",
				       mathexp=>"350",
				       bestfit=>"350",
				       modified=>1,
				       note=>"The $name temperature of the $which",
				       autonote=>0,
				      );
    my $row = $#gds+1;
    $widgets{gds2list} -> add($row);
    $widgets{gds2list} -> itemCreate($row, 0, -text=>$row,            -style=>$gds_styles{guess});
    $widgets{gds2list} -> itemCreate($row, 1, -text=>"g:",            -style=>$gds_styles{guess});
    $widgets{gds2list} -> itemCreate($row, 2, -text=>"$theta$suffix", -style=>$gds_styles{guess});
    $widgets{gds2list} -> itemCreate($row, 3, -text=>"350",           -style=>$gds_styles{guess});
  };

  ## define the path parameter
  $paths{$current} -> make('sigma^2' => $value);
  $widgets{'path_me_sigma^2'} -> delete(0, 'end');
  $widgets{'path_me_sigma^2'} -> insert('end', $value);

  Echo("Using the $name model for this path.");
};


###===================================================================
### deletion of project parts
###===================================================================

sub delete_path {
  #Echo("Want to delete paths -- $_[0].");

  my ($how, $crit) = @_;
  my $redisplay = 1;
  my ($data, $feff, $curr) = split(/\./,$current);
  $feff = ($current =~ /feff(\d+)/) ? $1 : "";
  my $message = "No paths were deleted!";
  if ($how eq 'nlegs') {
    $crit = &get_nlegs;
    return if ($crit eq 'Cancel');
  } elsif ($how eq 'r') {
    $crit = &get_r;
    return if ($crit eq 'Cancel');
  } elsif ($how eq 'amp') {
    $crit = &get_zcwif;
    return if ($crit eq 'Cancel');
  };

  ## get the list of paths that follow the current one in the list,
  ## but which are still of the same feff calculation.  this is done
  ## for the sake of "discard after current".  This way cloned
  ## paths, which have a higher X as in dataN.feffM.X are considered
  ## in their place in the list
  my @following = ();
  if ($paths{$current}->type eq 'path') {
    my $pth = $current;
    while ($list->info("next",$pth)) {
      $pth = $list->info("next",$pth);
      push(@following, $pth)
	if (($paths{$pth}->type   eq 'path') and
	    ($paths{$pth}->get('parent') eq $paths{$current}->get('parent')));
    };
  };

  my $new = ($paths{$current}->type eq 'feff') ? $current : $paths{$current}->get('parent');
  #($how eq 'nlegs') and ($new = $paths{$current}->feff.".0");
  ($how eq 'current') and ($new = $current); # not strictly correct
  my @delete_them;
  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless ($paths{$p}->type eq 'path');
  SWITCH: {
      ($how eq 'all') and do {
	push @delete_them, $p;
	$message = "Discarded all paths";
	last SWITCH;
      };
      ($how eq 'this') and do {
	next unless ($p eq $current);
	$new   = $list->info('next', $p);
	$new ||= $list->info('prev', $p);
	push @delete_them, $p;
	$message = "Discarded path \"" . $paths{$current}->descriptor() . "\"";
	last SWITCH;
      };
      ($how eq 'r') and do {
	if ($paths{$p}->get('reff') < $crit) {
	  $new = $p;
	} else {
	  push @delete_them, $p;
	};
	$message = "Discarded all paths with more than $crit legs";
	last SWITCH;
      };
      ($how eq 'amp') and do {
	if ($paths{$p}->get('zcwif') > $crit) {
	  $new = $p;
	} else {
	  push @delete_them, $p;
	};
	$message = "Discarded all paths with amplitude less than $crit";
	last SWITCH;
      };
      ($how eq 'nlegs') and do {
	next unless ($paths{$p}->get('nleg') > $crit);
	push @delete_them, $p;
	$message = "Discarded all paths longer than $crit";
	last SWITCH;
      };
      ($how eq 'current') and do {
	## my $this = (split(/\./,$p))[2];
	## next if ($this<=$curr);
	push @delete_them, $p if (grep /^$p$/, @following);
	$message = "Discarded all paths after \"" . $paths{$current}->descriptor() . "\"";
	last SWITCH;
      };
      ($how eq 'sel') and do {
	my $selected = grep {$p eq $_} $list->info('selection');
	next unless $selected;
	push @delete_them, $p;
	$message = "Discarded all selected paths.";
	last SWITCH;
      };
      (exists $paths{$how}) and do {
	$redisplay = 0;
	next unless ($p eq $how);
	push @delete_them, $p;
	$message = "Discarded path \"" . $paths{$current}->descriptor() . "\"";
	last SWITCH;
      };
    };
  };
  ## clean up evidence of deleted paths
  foreach my $p (@delete_them) {
    $list->delete('entry',$p);
    ##($paths{$p}->get('group')) and
    $paths{$p}->dispose("erase \@group ".$paths{$p}->get('group'), $dmode) if $paths{$p}->get('group');
    $paths{$p}->drop;		# release it's index
    delete $paths{$p};
    project_state(0);
  };
  if ($redisplay) {
    $current = $new;
    $list->focus();
    display_page($new);
  };
  Echo($message);
  return;
};



sub show_path {
  if ($paths{$current}->type eq "path") {
    my $error = "";
    $error   .= &verify_parens;
    if ($error) {
      post_message($error, "Error Messages");
      Error("cannot show path due to errors in parameters and math expressions");
      return;
    };
    ##&read_gds2(1);
    my $command = "";
    if ($parameters_changed) {
      map { $command .= $_ -> write_gsd } (@gds);
      $parameters_changed = 0;
    };

    #my $n = $1 + 1;
    my $ii = $paths{$current}->index;
    my $pathto = $paths{$current}->get('path');
    $command .= $paths{$current} -> write_path($ii, $pathto, $config{paths}{extpp}, $stash_dir);
    $paths{$current} -> dispose($command, $dmode);
    &show_things('path '.$ii);
    $paths{$current} ->dispose("get_path($ii, t___emp)", 1);
    my $r = sprintf ("%.6f", Ifeffit::get_scalar("t___emp_reff") +
		     Ifeffit::get_scalar("t___emp_delr"));
    $paths{$current} ->
      dispose("### ifeffit group for path $ii = ".$paths{$current}->get('group'), $dmode)
	if ($paths{$current}->get('group'));
    foreach (qw(s02 e0 ei delr sigma2 third fourth degen reff)) {
      $paths{$current} ->dispose("erase t___emp_$_", 1);
    };
    Echo("Showing path \"" . $paths{$current}->descriptor() . "\"");
  }
};


sub display_path_header {
  my $this = $_[0];
  $notes{messages} -> delete(qw(1.0 end));
  $notes{messages} -> insert('end', $paths{$this}->descriptor(), "bold");
  $notes{messages} -> insert('end', "\n\n");
  foreach my $l (split(/\n/, $paths{$this}->get('header'))) {
    if ($l =~ / 0 /) {
      #print "abs\n";
      $notes{messages} -> insert('end', $l, 'absorber');
    } elsif ($l =~ /beta/) {
      #print "angle\n";
      $notes{messages} -> insert('end', $l, 'angles');
    } else {
      #print "nothing\n";
      $notes{messages} -> insert('end', $l);
    };
    $notes{messages} -> insert('end', "\n");
  };
  $top      -> update;
  raise_palette('messages');
  Echo("Showing header for \"" . $paths{$this}->descriptor() . "\"");
};

sub verify_number_of_paths {
  my $message = "";
  my $total = 0;
  my %seen;
  foreach my $d (&all_data) {
    my $n = 0;
    foreach my $k (keys %paths) {
      next unless (ref($paths{$k}) =~ /Ifeffit/);
      next unless ($paths{$k}->type eq "path");  # not a path
      next unless ($paths{$k}->data eq $d);	   # not from this data set
      next unless  $paths{$k}->get('include');	   # not included in the fit
      ++$n;
      ++$total;
    };
    if ($n > $limits{paths_per_set}) {
      $message .= "You have exceeded the per-path limit of $limits{paths_per_set} paths in data set\n";
      $message .= "\t" . $paths{$d}->descriptor();
    };
  };
  if ($total > $limits{total_paths}) {
    $message .= "You have used $total paths, exceeding Ifeffit's total-fit limit of $limits{total_paths} paths.\n";
  };
};


## this returns the list of paths in the order that they are
## displayed.
sub path_list {
  my $this = 'gsd';
  my @foo = ($this);
  while ($list->infoNext($this)) {
    $this = $list->infoNext($this);
    push @foo, $this;
  };
  return @foo;
};


## this returns a list of the first 5 paths in each feff calculation
## for a data set
sub pcpath_list {
  my $data = $_[0];
  my $this = 'gsd';
  my $count = 0;
  my @foo = ($this);
  while ($list->infoNext($this)) {
    $this = $list->infoNext($this);
    next unless (ref($paths{$this}) =~ /Ifeffit/);
    ($count = 0) if ($paths{$this}->type eq 'feff');
    next unless ($paths{$this}->type eq 'path');
    next unless ($paths{$this}->data eq $data);
    ++$count;
    next if ($count > 5);
    push @foo, $this;
  };
  return @foo;
};

sub path_used {
  my ($path, $file) = @_;
  foreach my $p (keys %paths) {
    next unless ($paths{$p}->type eq 'path');
    my $thispath = File::Spec->catfile($project_folder, $paths{$p}->get('parent'));
    next unless same_directory($thispath, $path);
    next unless ($file eq $paths{$p}->get('feff'));
    return 1;
  };
  return 0;
};


##  END OF THE SECTION ON THE PATH PAGE

