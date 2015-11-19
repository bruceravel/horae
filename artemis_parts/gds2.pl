# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006, 2008 Bruce Ravel
##

###===================================================================
### GDS page, version 2
###===================================================================

## still to do:
##  1. multiple selection + functionality
##  2. separator entry (hmmmm.....)


sub make_gds2 {

  my $parent = $_[0];

  my $gds2 = $parent -> Frame(-relief=>'flat',
			      -borderwidth=>0,
			      #@window_size,
			      -highlightcolor=>$config{colors}{background});

  #$gds2 -> packPropagate(0);

  #$gds2 -> Label(-text=>"Parameters and Restraints", @title2)
  #  -> pack(-side=>'top', -anchor=>'w', -padx=>6);

  my $gds2list;
  $gds2list = $gds2 -> Scrolled("HList",
				-columns    => 4,
				-header	    => 1,
				-scrollbars => 'se',
				-background => $config{colors}{background},
				-font	    => $config{fonts}{fixed},
				-selectmode => 'extended',
				-selectbackground=>$config{colors}{selected},
				-browsecmd  => sub {&gds2_update_mathexp($gds2list, \%gds_selected);
						    &gds2_browse($gds2list, \%gds_selected)
						  },
				-command    => \&gds2_annotation,
			       )
    -> pack(-side=>'top', -expand=>1, -fill=>'both');
  $widgets{gds2list} = $gds2list;
  $gds_styles{header} = $gds2list -> ItemStyle('text',
					       -font=>$config{fonts}{small},
					       -anchor=>'w',
					       -foreground=>$config{colors}{activehighlightcolor});

  ## parameter styles
  foreach my $p (qw(guess def set restrain skip after merge)) {
    my $key = $p . "_color";
    ## normal styles
    $gds_styles{$p}      = $gds2list -> ItemStyle('text',
						  -font=>$config{fonts}{fixed},
						  -foreground=>$config{gds}{$key},
						  -selectforeground=>$config{gds}{$key},
						  -background=>($p eq 'merge') ? $config{gds}{merge_background} : $config{colors}{background});
    ## highlighted styles
    $gds_styles{$p."_h"} = $gds2list -> ItemStyle('text',
						  -font=>$config{fonts}{fixed},
						  -foreground=>$config{gds}{$key},
						  -selectforeground=>$config{gds}{$key},
						  -background=>$config{gds}{highlight});
    ## column 2 styles
    $gds_styles{$p."_n"} = $gds2list -> ItemStyle('text',
						  -font=>$config{fonts}{fixed},
						  -foreground=>$config{gds}{$key},
						  -selectforeground=>$config{gds}{$key},
						  -background=>($p eq 'merge') ? $config{gds}{merge_background} : $config{colors}{background2});
  };
  $gds_styles{sep}   = $gds2list -> ItemStyle('text',
					      -font=>$config{fonts}{fixed},
					      -background=>$config{colors}{background},
					     );
  $gds_styles{sep_n} = $gds2list -> ItemStyle('text',
					      -font=>$config{fonts}{fixed},
					      -background=>$config{colors}{background2});

  $gds2list -> Subwidget("hlist") -> headerCreate(0, -text=>"#",   -style=>$gds_styles{header},
			    -headerbackground=>$config{colors}{background},);
  $gds2list -> Subwidget("hlist") -> headerCreate(1, -text=>"   ", -style=>$gds_styles{header},
			    -headerbackground=>$config{colors}{background},);
  $gds2list -> Subwidget("hlist") -> headerCreate(2, -text=>"Name", -style=>$gds_styles{header},
			    -headerbackground=>$config{colors}{background},);
  $gds2list -> Subwidget("hlist") -> headerCreate(3, -text=>"Math Expression", -style=>$gds_styles{header},
			    -headerbackground=>$config{colors}{background},);

  $gds2list->bind('<ButtonPress-3>',\&gds2_post_menu);
  BindMouseWheel($gds2list);
  $gds2list -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $gds2list -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));

  $gds2list -> Subwidget("hlist") -> columnWidth(0, -char=>4);
  $gds2list -> Subwidget("hlist") -> columnWidth(1, -char=>3);
  $gds2list -> Subwidget("hlist") -> columnWidth(2, "");
  ##$gds2list -> Subwidget("hlist") -> columnWidth(2, -char=>12);
  ##$gds2list -> Subwidget("hlist") -> columnWidth(3, -char=>37);


  $widgets{gds2_show} =
    $gds2 -> Button(-text=>'Show editing area', @button2_list, -width=>1,
		    -command=>sub{$widgets{gds2_show}->packForget;
				  $widgets{gds2_editarea}->pack(-side=>=>'top', -fill=>'x', -padx=>4, -pady=>2);
				  $gds_selected{showing}="edit";});

  $widgets{gds2_editarea} = $gds2 -> LabFrame(-label=>'Edit selected parameter',
					     -foreground=>$config{colors}{activehighlightcolor},
					     -labelside=>'acrosstop' )
    -> pack(-side=>'top', -fill=>'x', -padx=>4, -pady=>2);

  ## presentation of name and math expression
  my $fr = $widgets{gds2_editarea} -> Frame()
    -> pack(-side=>=>'top', -expand=>1, -fill=>'both');
  $widgets{gds2_name} = $fr -> Entry(-width=>10, -textvariable=>\$gds_selected{name})
    -> pack(-side=>'left', -padx=>4);
  $fr -> Label(-text=>'=')
    -> pack(-side=>'left');
  $widgets{gds2_mathexp} = $fr -> Entry(-width=>10, -textvariable=>\$gds_selected{mathexp})
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>4);

  $widgets{gds2_name}    -> bind("<KeyPress-Return>", sub{gds2_define($gds2list, \%gds_selected);
							  $widgets{gds2_mathexp}->focus();
							  $widgets{gds2_mathexp}->icursor('end');
							});
  $widgets{gds2_mathexp} -> bind("<KeyPress-Return>", sub{gds2_define($gds2list, \%gds_selected)});


  ## radio buttons for setting parameter type
  $fr = $widgets{gds2_editarea} -> Frame()
    -> pack(-side=>=>'top', -expand=>1, -fill=>'both');
  foreach (qw(Guess Def Set Skip Restrain After)) {
    $widgets{"gds2_$_"} = $fr -> Radiobutton(-text=>$_,
					     -value=>lc($_),
					     -selectcolor=>$config{colors}{check},
					     -variable=>\$gds_selected{type},
					     -command=>\&gds2_alter)
      -> pack(-side=>'left', -fill=>'x', -expand=>1);
  };

  ## command buttons
  $fr = $widgets{gds2_editarea} -> Frame()
    -> pack(-side=>=>'top', -expand=>1, -fill=>'both');
  $fr -> Button(-text=>'Undo edit', @button2_list, -width=>1,
		-command=>sub{gds2_browse($gds2list, \%gds_selected)})
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2);
  $fr -> Button(-text=>'New', @button2_list, -width=>1,
		-command=>\&gds2_new)
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2);
  $widgets{gds2_grab} = $fr -> Button(-text=>'Grab', @button2_list,
				      -width=>1,
				      -state=>'disabled',
				      -command=>sub{grab_gds2($gds2list, \%gds_selected)})
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2);
  $fr -> Button(-text=>'Discard', @button2_list, -width=>1,
		-command=>\&gds2_discard)
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2);
  $fr -> Button(-text=>'Hide', @button2_list, -width=>1,
		-command=>sub{$widgets{gds2_editarea}->packForget;
			      $widgets{gds2_show}->pack(-side=>=>'top', -fill=>'x', -padx=>2, -pady=>2);
			      $gds_selected{showing}="show";})
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2);

  $widgets{help_gds} =
    $widgets{gds2_editarea}
      -> Button(-text=>"Document: Guess, Def, Set",  @button2_list,
		-command=>sub{pod_display("artemis_gds.pod")} )
    -> pack(-side=>'bottom', -fill=>'x', -padx=>2);

  if ($config{gds}{start_hidden}) {
    $widgets{gds2_editarea}->packForget;
    $widgets{gds2_show}->pack(-side=>=>'top', -fill=>'x', -padx=>2, -pady=>2);
    $gds_selected{showing}="show";
  };

  Echo("Showing new GDS page");
  $top -> update;
  return $gds2;
};

sub gds2_display {
  $widgets{gds2list} -> selectionClear;
  $widgets{gds2list} -> selectionSet($_[0]);
  $widgets{gds2list} -> anchorSet($_[0]);
  gds2_browse($widgets{gds2list}, \%gds_selected);
  $widgets{gds2list} -> see($_[0]);
};

## this is the callback for clicking on an item in the list
sub gds2_browse {
  my ($list, $rhash) = @_;
  my $wh = $list->info('anchor');
  my $which = (ref($wh) eq 'ARRAY') ? $$wh[0] : $wh;
  my $type = $list->itemCget($which, 1, '-text') || "";
  my $is_sep = ($type =~ /^\-/);
  $$rhash{which}   = $which;
  $$rhash{name}    = ($is_sep) ? "" : $list->itemCget($which, 2, '-text');
  $$rhash{mathexp} = ($is_sep) ? "" : $list->itemCget($which, 3, '-text');
 S: {
    $$rhash{type} = 'guess',    last S if ($type =~ /^g/);
    $$rhash{type} = 'def',      last S if ($type =~ /^d/);
    $$rhash{type} = 'set',      last S if ($type =~ /^s/);
    $$rhash{type} = 'restrain', last S if ($type =~ /^r/);
    $$rhash{type} = 'skip',     last S if ($type =~ /^\s*$/);
    $$rhash{type} = 'after',    last S if ($type =~ /^a/);
    $$rhash{type} = 'merge',    last S if ($type =~ /^m/);
    $$rhash{type} = 'sep',      last S if $is_sep;
  };
  $widgets{gds2_grab} -> configure(-state=>($$rhash{type} eq 'guess') ? 'normal' : 'disabled');
  if ($is_sep) {
    map {$widgets{"gds2_$_"}    -> configure(-state=>'disabled')}
      (qw(name mathexp Guess Def Set Skip Restrain After));
  } else {
    map {$widgets{"gds2_$_"}    -> configure(-state=>'normal')}
      (qw(name mathexp Guess Def Set Skip Restrain After));
    $widgets{gds2_mathexp} -> focus();
  };
  Echo($gds[$which-1]->note) if ($current_canvas eq 'gsd');
};


sub gds2_new {
  &gds2_update_mathexp($widgets{gds2list}, \%gds_selected);
  $widgets{gds2list}->selectionClear;
  $widgets{gds2list}->anchorClear;
  $gds_selected{type}    = "";
  $gds_selected{name}    = "";
  $gds_selected{mathexp} = "";
  $gds_selected{which}   = 0;
  $widgets{gds2_name} -> focus();
};


sub gds2_exists {
  foreach (@gds) {
    return 1 if (lc($_[0]) eq lc($_->name));
  };
  return 0;
};

sub gds2_update_mathexp {
  my ($list,$rhash) = @_;
  return if ($$rhash{name} =~ /^\s*$/);
  my $i = 0;
  foreach (@gds) {
    if (lc($$rhash{name}) eq lc($_->name)) {
      $gds[$i]->make(mathexp=>$$rhash{mathexp});
      $list -> itemConfigure($i+1, 3, -text=>$$rhash{mathexp}, -style=>($gds[$i]->highlight & 2) ? $gds_styles{$$rhash{type}."_h"} : $gds_styles{$$rhash{type}});
      return;
    }
    ++$i;
  };
  return 0;
};


## this is the callback for the Define button -- make a new variable
sub gds2_define {
  my ($list, $rhash) = @_;
  $$rhash{type} ||= "guess";	# sanity checking...
  my $type = $$rhash{type};
  my $tag  = ($type eq 'skip') ? "" : substr($type, 0, 1).":";
  my $which  = $list->info('anchor');
  my $row = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  my $ip   = -1;
  $$rhash{name}    =~ s/\s//g;	# sanity checking...
  $$rhash{mathexp} =~ s/\n//g;
  Error("That math expression has mismatched parentheses!"), return if check_parens($$rhash{mathexp});
  if ($$rhash{mathexp} =~ /(\w+)\(/) {
    my $fun = $1;
    Error("\"$fun\" is not a valid function in Ifeffit!"), return
      unless ($1 =~ /^$function_regex$/);
  };
  ($$rhash{mathexp} = '0') if ($$rhash{mathexp} =~ /^\s*$/);
  Error("\"$$rhash{name}\" is not a valid parameter name!"), return
    unless ($$rhash{name} =~ /^[a-z_][a-z_0-9]*$/i);

  if ($row) {
    my $ret = &gds2_alter;
    return if ($ret == -1);
  } else {
    my $found = 0;
    map { ++$found if (lc($_->name) eq lc($$rhash{name})) } (@gds);
    Error("You already have a variable named \"$$rhash{name}\"!"), return if $found;
    push @gds, Ifeffit::Parameter->new(type=>$type,
				       name=>$$rhash{name},
				       mathexp=>$$rhash{mathexp},
				       bestfit=>$$rhash{mathexp},
				       modified=>1,
				       note=>"$$rhash{name}: ",
				       autonote=>1,
				      );
    $row = $#gds+1;
    $list -> add($row);
    $list -> itemCreate($row, 0, -text=>$row,             -style=>$gds_styles{$type});
    $list -> itemCreate($row, 1, -text=>$tag,             -style=>$gds_styles{$type});
    $list -> itemCreate($row, 2, -text=>$$rhash{name},    -style=>$gds_styles{$type."_n"});
    $list -> itemCreate($row, 3, -text=>$$rhash{mathexp}, -style=>$gds_styles{$type});
    $widgets{gds2_grab} -> configure(-state=>($$rhash{type} eq 'guess') ? 'normal' : 'disabled');
  };
  $list->see($row);
  $list->selectionSet($row);
  $list->anchorSet($row);
  project_state(0);
  $parameters_changed = 1;
  Echo("Defined the $type variable $$rhash{name} as $$rhash{mathexp}");
};


## update the currently selected parameter
sub gds2_alter {
  #my ($list, $rhash) = ;
  my $which = $widgets{gds2list}->info('anchor');
  my $row   = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  Error("That math expression has mismatched parentheses!"), return -1 if check_parens($gds_selected{mathexp});
  if ($gds_selected{mathexp} =~ /(\w+)\(/) {
    my $fun = $1;
    Error("\"$fun\" is not a valid function in Ifeffit!"), return -1 unless ($1 =~ /^$function_regex$/);
  };
  my $found = 0;
  my $r = $row || 0;
  foreach my $i (0..$r-2, $r..$#gds) { ++$found if (lc($gds[$i]->name) eq lc($gds_selected{name})) };
  Error("There is another variable named \"$gds_selected{name}\"!"), return -1 if $found;
  my $type = $gds_selected{type};
  my $tag  = ($type eq 'skip') ? "" : substr($type, 0, 1).":";
  gds2_define($widgets{gds2list}, \%gds_selected), return 0 unless $row;
  my $ip = $row-1;
  $gds[$ip]->make(type	   => $type,
		  name	   => $gds_selected{name},
		  mathexp  => $gds_selected{mathexp},
		  bestfit  => $gds_selected{mathexp},
		  modified => 1);
  $widgets{gds2list}  -> itemConfigure($row, 0, -text=>$row,             -style=>$gds_styles{$type});
  $widgets{gds2list}  -> itemConfigure($row, 1, -text=>$tag,             -style=>$gds_styles{$type});
  $widgets{gds2list}  -> itemConfigure($row, 2, -text=>$gds_selected{name},    -style=>($gds[$ip]->highlight & 1) ? $gds_styles{$type."_h"} : $gds_styles{$type."_n"});
  $widgets{gds2list}  -> itemConfigure($row, 3, -text=>$gds_selected{mathexp}, -style=>($gds[$ip]->highlight & 2) ? $gds_styles{$type."_h"} : $gds_styles{$type});
  $widgets{gds2_grab} -> configure(-state=>($gds_selected{type} eq 'guess') ? 'normal' : 'disabled');
  project_state(0);
  $parameters_changed = 1;
  return 0;
};


## callback for Grab button on the GDS page -- this queries Ifeffit
## for the best fit value of a guess variable
sub grab_gds2 {
  my ($list, $rhash) = @_;
  my $which = $list->info('anchor');
  my $row   = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  my $ip = $row-1;
  Error($gds[$ip]->name." is not a guess!"), return unless ($gds[$ip]->type eq 'guess');
  Error("You have not yet run a fit!"), return if ($gds[$ip]->error =~ /^\s*$/);
  (my $best = $gds[$ip]->bestfit) =~ s/ \(.*\)//;
  $$rhash{mathexp} = "$best (" . $gds[$ip]->error . ")";
  $gds[$ip]->make(mathexp=>$$rhash{mathexp});
  &gds2_alter;
};


sub grab_all_best_fits {
  foreach my $p (@gds) {
    next unless ($p->type eq 'guess');
    (my $best = $p->bestfit) =~ s/ \(.*\)//;
    $p->make(mathexp=>"$best (" . $p->error . ")");
  };
  my $which = $widgets{gds2list} -> selectionGet();
  my $current = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  repopulate_gds2();
  if ($current) {
    $widgets{gds2list} -> selectionSet($current);
    $widgets{gds2list} -> anchorSet($current);
  };
  $top -> update;
  project_state(0);
  $parameters_changed = 1;
};


## convert all guesses to sets
sub gds2_guess_to_set {
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Are you quite sure you want to convert all guesses to sets?",
		   -title          => 'Artemis: Verifying...',
		   -buttons        => [qw/Convert Cancel/],
		   -default_button => 'Cancel',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $response = $dialog->Show();
  Echo("Leaving guesses intact."), return if ($response eq 'Cancel');
  Echo("Changing guesses to sets ...");
  foreach my $p (@gds) {
    next unless ($p->type eq 'guess');
    $p->make(type=>"set");
  };
  my $which   = $widgets{gds2list} -> selectionGet();
  my $current = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  repopulate_gds2();
  if ($current) {
    $widgets{gds2list} -> selectionSet($current);
    $widgets{gds2list} -> anchorSet($current);
  };
  $top -> update;
  project_state(0);
  $parameters_changed = 1;
  Echo("Changing guesses to sets ... done!");
};


sub gds2_def_to_other {
  my ($changeto, $rlist) = @_;
  foreach my $n (@$rlist) {
    foreach my $p (@gds) {
      next unless (lc($p->name) eq lc($n));
      $p->make(type=>$changeto);
    };
  };
  repopulate_gds2();
  project_state(0);
  $parameters_changed = 1;
};

## make a copy of the anchored parameter
sub gds2_copy {
  my $which = $widgets{gds2list} -> info('anchor') - 1;
  my $count = 1;
  my $orig  = $gds[$which]->name;
  my $name  = join("", $orig, "_c", $count);
  my $ok    = 0;
  while (not $ok) {		# find a unique name
    $ok = 1;
  LOOP: foreach my $g (@gds) {
      if (lc($g->name) eq lc($name)) {
	$ok = 0;
	$name = join("", $orig, "_c", ++$count);
	last LOOP;
      };
    };
  };
  splice(@gds, $which, 1, $gds[$which],
	 Ifeffit::Parameter->new(type	  => $gds[$which]->type,
				 name	  => $name,
				 mathexp  => $gds[$which]->mathexp,
				 bestfit  => 0,
				 modified => 1,
				 note	  => "$name: ",
				 autonote => 1,
				));
  repopulate_gds2();
  project_state(0);
  $parameters_changed = 1;
  $which+=2;
  &gds2_display($which);
  $widgets{gds2_name} -> focus;
  $widgets{gds2_name} -> selectionRange(0, 'end');
  Echo("Made a copy of parameter \"$orig\".  You may wish to rename it.");
};

## annotate the anchored parameter
sub gds2_annotation {
  my $which	 = $widgets{gds2list}->info('anchor');
  my $row	 = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  my $ip	 = $row-1;
  ## return if ($gds[$ip]->type eq 'sep');
  my $annotation = $gds[$ip]->note;
  my $prior	 = $gds[$ip]->note;
  my $label	 = ($gds[$ip]->type eq 'sep') ?
    "Annotate this separator : " : "Describe : " . $gds[$ip]->name;
  my $dialog	 = get_string($dmode, $label, \$annotation);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  return if ($annotation eq $prior); # unchanged
  if ($gds[$ip]->type eq 'sep') {
    $gds[$ip]->make(note=>$annotation);
    my $n = 17 - length($annotation);
    ($annotation .= " " . "-" x $n) if ($n > 0);
    $gds[$ip]->make(mathexp=>"----- " . $annotation . "---");
    repopulate_gds2();
  } else {
    ## turn off automatic annotation in favor of the user supplied one
    $gds[$ip]->make(note=>$annotation, autonote=>0);
    ## turn automatic annotation back on if $annotation is blank
    $gds[$ip]->make(autonote=>1) if ($annotation =~ /^\s*$/);
  };
  project_state(0);
  Echo($annotation) if ($current_canvas eq 'gsd');
}


## insert all parameters in @gds into the list on the GDS page
sub populate_gds2 {
  my $i = 1;
  foreach my $p (@gds) {
    my $type = $p->type;
    my $tag  = ($type eq 'skip') ? "" : substr($type, 0, 1).":";
    ($tag = "--") if ($type eq 'sep');
    $widgets{gds2list} -> add($i);
    $widgets{gds2list} -> itemCreate($i, 0, -text=>$i,          -style=>$gds_styles{$type});
    $widgets{gds2list} -> itemCreate($i, 1, -text=>$tag,        -style=>$gds_styles{$type});
    $widgets{gds2list} -> itemCreate($i, 2, -text=>$p->name,    -style=>($p->highlight & 1) ? $gds_styles{$type."_h"} : $gds_styles{$type."_n"});
    $widgets{gds2list} -> itemCreate($i, 3, -text=>$p->mathexp, -style=>($p->highlight & 2) ? $gds_styles{$type."_h"} : $gds_styles{$type});
    ++$i;
  };
  $gds_selected{which} ||= 1;
};

sub clear_gds2 {
  $widgets{gds2list} -> delete('all');
  $gds_selected{which} = 0;
};

sub repopulate_gds2 {
  my $which = $gds_selected{which};
  clear_gds2();
  populate_gds2();
  $gds_selected{which} = ($which <= $#gds+1) ? $which : 1;
  if (@gds) {
    $gds_selected{which} ||= 1;
    gds2_display($gds_selected{which});
  };
};



## no not make a new set of autoparams if this is a cloned feff calc
## force all autoparams to be set if this is an older project that
## does not contain autoparams
sub autoparams_define {
  my ($id, $n, $is_clone, $force_set) = @_;
  my @roman_lower = ("", qw(ii iii iv v vi vii viii ix x xi xii xii xiv xv
			    xvi xvii xviii xix xx xxi xxii xxiii xxiv xxv xxvi));
  my @roman_upper = ("", qw(II III IV V VI VII VIII IX X XI XII XII XIV XV
			    XVI XVII XVIII XIX XX XXI XXII XXIII XXIV XXV XXVI));
  my $tag = "_" . $n;
 INC: {
    $tag = "",                     last INC if ($n == 0);
    $tag = "_" . $n,               last INC if ($n > 26);
    last INC if $config{autoparams}{data_increment} eq 'numbers';
    $tag = "_" . chr(96+$n),       last INC
      if $config{autoparams}{data_increment} eq 'letters';
    $tag = "_" . chr(64+$n),       last INC
      if $config{autoparams}{data_increment} eq 'LETTERS';
    $tag = "_" . $roman_lower[$n], last INC
      if $config{autoparams}{data_increment} eq 'roman';
    $tag = "_" . $roman_upper[$n], last INC
      if $config{autoparams}{data_increment} eq 'ROMAN';
  };
  my @list = ();
  foreach my $p (qw(s02 e0 delr sigma2 ei third fourth)) {
    my $this = $config{autoparams}{$p} . $tag;
    push @list, ($config{autoparams}{$p}) ? $this : "";
    next if (gds2_exists($this)); # do nothing else if this vble already exists
    next unless $config{autoparams}{$p};
    my $value = "0";
    ($value = "1")     if ($p eq 's02');
    ($value = "0.003") if ($p eq 'sigma2');
    my $type = ($force_set) ? 'set' : $config{autoparams}{$p.'_type'};
    jump_to_variable($this, $type, 1, $value) unless $is_clone;
  };
  return @list;
};


## actually just flag them all as updated, this will force artemis to
## read from the GDS page rather than from ifeffit
sub reset_all_variables {
  foreach (@gds) { $_->make(modified => 1) };
  Echo("The initial guesses for all variables will be used rather than the best fit values the next time they are needed.");
};


sub clear_all_variables {
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Are you quite sure you want to discard all your variables?",
		   -title          => 'Artemis: Verifying...',
		   -buttons        => [qw/Discard Cancel/],
		   -default_button => 'Cancel',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $response = $dialog->Show();
  Echo("Not discarding variables"), return if ($response eq 'Cancel');
  clear_gds2();
  $#gds = -1;
  project_state(0);
  $parameters_changed = 1;
  $widgets{gds2_grab}    -> configure(-state=>"disabled");
  $widgets{gds2_name}    -> configure(-text=>"");
  $widgets{gds2_mathexp} -> configure(-text=>"");
  $widgets{gds2_name}    -> focus();
  Echo("Discarded all variables.");
};


sub gds2_discard {
  my @which = $widgets{gds2list} -> selectionGet();
  my $this  = $which[0] - 1;
  my $name = ($#which > 0) ? "these parameters" : $gds[$this]->name;
  ($name = "this separator") if (($#which == 0) and ($gds[$this]->type eq 'sep'));
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Do you really want to discard $name?",
		   -title          => 'Artemis: Verifying...',
		   -buttons        => [qw/Discard Cancel/],
		   -default_button => 'Cancel',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $response = $dialog->Show();
  Echo("Not discarding $name"), return if ($response eq 'Cancel');
  my $count = 0;
  foreach my $w (@which) {
    my $this  = $w - 1 - $count;
    splice(@gds, $this, 1);
    ++$count;
  };
  repopulate_gds2();
  $widgets{gds2_mathexp} -> focus();
  project_state(0);
  $parameters_changed = 1;
  $name =~ s/these parameters/several parameters/;
  Echo("Discarded $name");
};


## highlight parameters and mathexps that match a regex
sub gds2_highlight {
  my $regex;
  my $dialog = get_string($dmode, "Highlight all parameters matching",
			  \$regex, \@gds_regex);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Highlight aborted"), return unless $regex;
  &gds2_clear_highlights;
  my $re;
  my $is_ok = eval '$re = qr/$regex/i';
  Error("Oops!  \"$regex\" is not a valid regular expression"), return unless $is_ok;
  foreach my $i (0 .. $#gds) {
    next if ($gds[$i]->type eq 'sep');
    if ($gds[$i]->name =~ $re) {
      $gds[$i]->highlight(1);	# toggle the name bit
      my $type = $gds[$i]->type . "_h";
      $widgets{gds2list}->itemConfigure($i+1, 2, -style=>$gds_styles{$type});
    };
    if ($gds[$i]->mathexp =~ $re) {
      $gds[$i]->highlight(2);	# toggle the mathexp bit
      my $type = $gds[$i]->type . "_h";
      $widgets{gds2list}->itemConfigure($i+1, 3, -style=>$gds_styles{$type})
    };
  };
  push @gds_regex, $regex;
  Echo("Highlighted all parameters and math expressions matching /$regex/");
};

sub gds2_clear_highlights {
  foreach my $i (0 .. $#gds) {
    $gds[$i]->make(highlight=>0);
    my $type = $gds[$i]->type;
    $widgets{gds2list}->itemConfigure($i+1, 2, -style=>$gds_styles{$type."_n"});
    $widgets{gds2list}->itemConfigure($i+1, 3, -style=>$gds_styles{$type});
  };
};


sub gds2_move {
  my $which = $_[0];
  my $where = "";
  my $whch = $widgets{gds2list}->info('anchor');
  my $row   = (ref($whch) eq 'ARRAY') ? $$whch[0] : $whch;
  my $ip    = $row-1;
  if (($which eq 'before') or ($which eq 'after')) {
    my $label = "Move " . $gds[$ip]->name . " $which (name or number): ";
    my $dialog = get_string($dmode, $label, \$where);
    $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
    return unless ($where);
  } elsif ($which eq 'up') {
    return if ($ip == 0);
    $where = $row - 1;
    $which = 'before';
  } elsif ($which eq 'down') {
    return if ($ip == $#gds);
    $where = $row + 1;
    $which = 'after';
  };

  ## have the target, identify location in @gds array
  my $target = -1;
  if ($where =~ /^\d+$/) {	# target was a parameter index
    $target = $where-1;
    ($target = $#gds) if ($target > $#gds);
    ($target = 0)     if ($target < 0);
  } else {			# target was a parameter name
    foreach my $i (0..$ip-1, $ip+1..$#gds) {
      ($target = $i), last if (lc($gds[$i]->name) eq lc($where));
    };
  };
  Error("\"$where\" is not in the parameter list.\""), return if ($target == -1);

  --$target if ($ip < $target);
  my $save = splice(@gds, $ip, 1);
  if ($which eq 'before') {
    @gds = (@gds[0..$target-1], $save, @gds[$target..$#gds]);
    $target += 1;
  } elsif ($which eq 'after')  {
    @gds = (@gds[0..$target], $save, @gds[$target+1..$#gds]);
    $target += 2;
  };
  repopulate_gds2();
  gds2_display($target);
  $widgets{gds2_mathexp} -> focus();
};


sub gds2_find {
  my $whch  = $widgets{gds2list}->info('anchor');
  my $row   = (ref($whch) eq 'ARRAY') ? $$whch[0] : $whch;
  my $ip    = $row-1;
  my $which = $gds[$ip]->name;
  my $message = "";

  ## check for this variable's use in all def, set, and restraints
  ## make sure the gsd data structures are up to date
  my @all = map { $_->name } @gds;

  foreach my $p (@gds) {
    ($message .= "\tthe def parameter ".$p->name."\n") if
      (($p->type eq 'def') and ($p->mathexp =~ /(^|\W)$which($|\W)/i));
    ($message .= "\tthe set parameter ".$p->name."\n") if
      (($p->type eq 'set') and ($p->mathexp =~ /(^|\W)$which($|\W)/i));
    ($message .= "\tthe restraint ".$p->name."\n") if
      (($p->type eq 'restrain') and ($p->mathexp =~ /(^|\W)$which($|\W)/i));
  };


  ## check for the parameter's use in all math expressions
  my @paths = grep /feff\d+\.\d+/, keys(%paths);	# fetch path list
  foreach my $f (&path_list) {
    next unless (ref($paths{$f}) =~ /Ifeffit/);
    next unless ($paths{$f}->type eq 'path');
    my $descriptor = $paths{$f}->descriptor();
    foreach my $p (qw(s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
      ($message .= "\tthe $p of $descriptor\n") if
	($paths{$f}->get($p) =~ /(^|\W)$which($|\W)/i);
    };
  };

  Error("\"$which\" is not used in any math expression."), return
    unless $message;
  $message = "The parameter \"$which\" is used in:\n\n" . $message;
  post_message($message, "Use of $which");

};



## normally this is called from t he context menu in the GDS list.
## The arguments allow this to be called as part of an import
## of a feffit.inp file
sub gds2_search_replace {
  my ($specified, $replacement) = @_;;
  my $whch  = $specified || $widgets{gds2list}->info('anchor');
  my $row   = (ref($whch) eq 'ARRAY') ? $$whch[0] : $whch;
  my $ip    = $row-1;
  my $which = $gds[$ip]->name;

  my $label   = "New name for parameter \"$which\": ";
  my $newname = $replacement || $which;
  if (not $replacement) {
    my $dialog  = get_string($dmode, $label, \$newname, \@rename_buffer);
    $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
    Echo("Not renaming ". $which), return if ($which eq $newname);
    Echo("Not renaming ". $which), return if ($newname =~ /^\s*$/);
  };
  Error("There is already a parameter called \"$newname\""), return if (grep {$_->name() =~ /^$newname$/} @gds);

  $gds[$ip] -> make(name => $newname);
  foreach my $p (@gds) {
    if ($p->mathexp =~ /\b$which\b/) {
      my $me = $p->mathexp;
      $me =~ s/\b$which\b/$newname/g;
      $p -> make(mathexp => $me);
    };
  };

  foreach my $f (&path_list) {
    next unless (ref($paths{$f}) =~ /Ifeffit/);
    next unless ($paths{$f}->type eq 'path');
    foreach my $p (qw(s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
      my $me = $paths{$f}->get($p);
      if ($me =~ /\b$which\b/) {
	$me =~ s/\b$which\b/$newname/g;
	$paths{$f} -> make($p => $me);
      };
    };
  };

  repopulate_gds2();
  project_state(0);
  Echo("Renamed \"$which\" as \"$newname\" and replaced it throughout the project.");
};

sub gds2_locate {
  my $label = "Name of variable to locate: ";
  my $name = "";
  my $dialog = get_string($dmode, $label, \$name);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  return if ($name =~ /^\s*$/);
  my $found = -1;
  my $i = 0;
  foreach my $p (@gds) {
    next if ($p->type eq 'sep');
    ($found = $i), last if (lc($p->name) eq lc($name));
    ++$i;
  };

  Error("You don't have a variable called \"$name\""), return if ($found == -1);
  gds2_display($found+1);
};


sub gds2_show {
  my $string = "";

  $notes{messages} -> delete(qw(1.0 end));
  my $len = 0;
  foreach (@gds) {
    ($len = length($_->name)) if (length($_->name) > $len);
  };
  my $sep = "-" x ($len+25);
  $len = '%-' . $len . "s";
  foreach (@gds) {
    if ($_->type eq 'sep') {
      $notes{messages} -> insert('end', "-" x 9);
    } else {
      $notes{messages} -> insert('end', sprintf("%-8s ", $_->type), $_->type);
    };
    if ($_->type eq 'skip') {
      $notes{messages} -> insert('end', sprintf($len, $_->name), 'skip');
      $notes{messages} -> insert('end', sprintf(" = %s\n", $_->mathexp), 'skip');
    } elsif ($_->type eq 'guess') {
      $notes{messages} -> insert('end', sprintf($len, $_->name), 'guess2');
      $notes{messages} -> insert('end', sprintf(" = %s\n", $_->mathexp), 'guess2');
    } elsif ($_->type eq 'sep') {
      $notes{messages} -> insert('end', $sep . "\n");
    } else {
      $notes{messages} -> insert('end', sprintf($len, $_->name));
      $notes{messages} -> insert('end', sprintf(" = %s\n", $_->mathexp));
    };
  };
  $notes{messages} -> yviewMoveto(0);
  $top -> update;
  raise_palette('messages');
};



sub gds2_up {
  return unless ($current_canvas eq 'gsd');
  gds2_move('up');
};
sub gds2_down {
  return unless ($current_canvas eq 'gsd');
  gds2_move('down');
};

sub gds2_post_menu {

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
  gds2_browse($w, \%gds_selected);

  ## post the message with parameter-appropriate text
  my ($name, $index, $type);
  if ($#which > 0) {
    $index = $w->info('anchor') - 1;
    $name = "these parameters";
    $type = 'extended';
  } else {
    $index = $which[0] - 1;
    $name = '"'.$gds[$index]->name.'"';
    $type = $gds[$index]->type;
  };
  return if ($gds[$index]->type eq 'sep');
  my $anchor = '"'.$gds[$index]->name.'"';
  my ($X, $Y) = ($Ev->X, $Ev->Y);
  ## my $isare = ($#which>0) ? "are" : "is";
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[
		      (($gds_selected{showing} eq 'show') ?
		       ([ command=>"Edit $anchor",
			 #-state  =>($#which>0) ? 'disabled' : 'normal',
			 -command=>sub{$widgets{gds2_show}->packForget;
				       $widgets{gds2_editarea}->pack(-side=>=>'top', -fill=>'x', -padx=>4, -pady=>2);
				       $gds_selected{showing}="edit";}],
		       ) :
		       ()),
		      [ cascade=>"Make $name ...",
		       -tearoff=>0,
		       -menuitems=>[
				    [ command => "guess",
				     -command => [\&gds2_make, 'guess']],
				    [ command => "def",
				     -command => [\&gds2_make, 'def']],
				    [ command => "set",
				     -command => [\&gds2_make, 'set']],
				    [ command => "skip",
				     -command => [\&gds2_make, 'skip']],
				    [ command => "restraint",
				     -command => [\&gds2_make, 'restrain']],
				    [ command => "after",
				     -command => [\&gds2_make, 'after']],
				   ]],
		      [ cascade=>"Move $anchor ...",
		       -tearoff=>0,
		       #-state  =>($#which>0) ? 'disabled' : 'normal',
		       -menuitems=>[
				    [ command=>"before ...",
				      -command=>sub{gds2_move("before")}],
				    [ command=>"after ...",
				      -command=>sub{gds2_move("after")}],
				   ]],
		      [ cascade=>"Insert separator ...",
		       -tearoff=>0,
		       ##-state  =>'disabled',
		       -menuitems=>[
		      		    [ command=>"before ...",
		      		      -command=>sub{gds2_sep("before")}],
		      		    [ command=>"after ...",
		      		      -command=>sub{gds2_sep("after")}],
		      		   ]],
		      [ command=>"Copy $anchor",
		       -command=>\&gds2_copy],
		      "-",
		      [ command=>"Build restraint from $anchor",
		       -command=>\&gds2_build_restraint,
		       -state  =>($gds[$index]->type =~ /(def|guess)/) ? 'normal' : 'disabled'],
		      [ command=>"Annotate $anchor",
		       #-state  =>($#which>0) ? 'disabled' : 'normal',
		       -command=>\&gds2_annotation],
		      [ command=>"Grab best fit for $anchor",
		       #-state=>($type eq 'guess') ? 'normal' : 'disabled'
		       -command=>sub{grab_gds2($widgets{gds2list}, \%gds_selected)},],
		      "-",
		      [ command=>"Find where $anchor is used",
		       #-state  =>($#which>0) ? 'disabled' : 'normal',
		       -command=>\&gds2_find],
		      [ command=>"Change name of $anchor globally",
		       #-state  =>($#which>0) ? 'disabled' : 'normal',
		       -command=>\&gds2_search_replace],
		      "-",
		      [ command=>"Discard $name",
		       -command=>\&gds2_discard],
		     ])
	-> Post($X, $Y);
  $w -> break;
};

sub gds2_sep {
  my $which = $widgets{gds2list} -> info('anchor') - 1;
  --$which if ($_[0] eq 'before');

  splice(@gds, $which, 1, $gds[$which],
	 Ifeffit::Parameter->new(type => "sep",));

  repopulate_gds2();
  project_state(0);
  Echo("Inserted separator $_[0] ");
};

sub gds2_build_restraint {
  my $which = $widgets{gds2list} -> info('anchor') - 1;
  my $name  = $gds[$which]->name;

  my %restraint;
  $restraint{min} = int(Ifeffit::get_scalar($name)/10) || 0;
  my $bf = $gds[$which]->bestfit; # watch out for math expressions
  ($bf =~ /-?(\d+\.?\d*|\.\d+)/) or ($bf = 0);
  $restraint{max} = int(Ifeffit::get_scalar($name)*2)  || 2*$bf || 10;
  $restraint{amp} = int(Ifeffit::get_scalar("chi_reduced")/20)*100 || 1000;


  my $db = $top -> DialogBox(-title=>"Artemis: Restraint builder",
			     -buttons=>['Build restraint', 'Cancel'],
			     -default_button=>'Build restraint');
  my $fr = $db->Frame(-borderwidth=>2, -relief=>'flat')->pack(-pady=>5);
  $fr -> Label(-text=>"Restrain \"$name\" to be within these boundaries",
	       -font=>$config{fonts}{large},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top');
  $fr = $db->Frame(-borderwidth=>2, -relief=>'groove')
    -> pack(-fill=>'x', -expand=>1, -padx=>2);
  $fr -> Label(-text=>'Minimum value:',
	       -font=>$config{fonts}{large},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'w', -pady=>2);
  $fr -> Entry(-textvariable=>\$restraint{min},
	       -width=>8)
    -> grid(-row=>0, -column=>1, -sticky=>'e', -pady=>2);

  $fr -> Label(-text=>'Maximum value:',
	       -font=>$config{fonts}{large},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'w', -pady=>2);
  $fr -> Entry(-textvariable=>\$restraint{max},
	       -width=>8)
    -> grid(-row=>1, -column=>1, -sticky=>'e', -pady=>2);

  $fr -> Label(-text=>'Amplifier:',
	       -font=>$config{fonts}{large},
	       -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'w', -pady=>2);
  $fr -> Entry(-textvariable=>\$restraint{amp},
	       -width=>8)
    -> grid(-row=>2, -column=>1, -sticky=>'e', -pady=>2);
  &posted_Dialog;
  my $answer = $db -> Show;
  return 0 if ($answer eq 'Cancel');

  push @gds, Ifeffit::Parameter->new(type     => "restrain",
				     name     => "res_".$name,
				     mathexp  => "penalty($name, $restraint{min}, $restraint{max}) * $restraint{amp}",
				     bestfit  => 0,
				     modified => 1,
				     note     => "$name: ",
				     autonote => 1);
  repopulate_gds2();
  project_state(0);
  $parameters_changed = 1;
  $which = $#gds + 1;
  &gds2_display($which);
  $widgets{gds2_name} -> focus;
  $widgets{gds2_name} -> icursor('end');
  $widgets{gds2_name} -> selectionRange(0, 'end');

  Echo("Built restraint " . $gds[-1]->name . " = " . $gds[-1]->mathexp);
};

sub gds2_make {
  my @list = $widgets{gds2list}->selectionGet;
  foreach my $w (@list) {
    gds2_display($w);
    $gds_selected{type}=$_[0];
    &gds2_alter
  }
  $widgets{gds2list}->selectionClear;
  map {$widgets{gds2list}->selectionSet($_)} @list;
};


sub gds2_keyboard_type {
  return unless ($current_canvas eq 'gsd');
  my $who = $top->focusCurrent;
  $multikey = "";
  Echo("Make parameter [gsdkra] (g=guess  s=set  d=def  k=skip  r=restraint  a=after)");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who -> focus;
  Echo("$multikey is not a parameter type (guess=g  set=s  def=d  skip=k  restraint=r  after=a)"), return unless (lc($multikey) =~ /^[degksr]$/);
 SWITCH: {
    $gds_selected{type} = 'guess',    last SWITCH if (lc($multikey) eq 'g');
    $gds_selected{type} = 'def',      last SWITCH if (lc($multikey) eq 'd');
    $gds_selected{type} = 'set',      last SWITCH if (lc($multikey) eq 's');
    $gds_selected{type} = 'skip',     last SWITCH if (lc($multikey) eq 'k');
    $gds_selected{type} = 'restrain', last SWITCH if (lc($multikey) eq 'r');
    $gds_selected{type} = 'after',    last SWITCH if (lc($multikey) eq 'a');
  };
  &gds2_alter;
  Echo("Made parameter a $gds_selected{type}");
};



## various sanity checks to be done before a fit

sub verify_number_of_variables {
  my $total = 0;
  foreach my $p (@gds) {
    ++$total if ($p->type eq 'guess')
  };
  my $bkg = 0;
  foreach my $d (&all_data) {
    next unless ($paths{$d}->get('do_bkg') eq 'yes');
    my $deltak = $paths{$d}->get('kmax') - $paths{$d}->get('kmin');
    my $deltar = $paths{$d}->get('rmax') - $paths{$d}->get('rmin');
    my $this   = int( 2 * $deltak * $deltar / PI );
    ($this = 5) if ($this < 5);
    ($this = $limits{spline_knots}) if ($this > $limits{spline_knots});
    $total += $this;
    $bkg += $this;
  };
  if ($total > $limits{variables}) {
    my $string = "You have used $total guess parameters";
    $string   .= ($bkg) ? " and $bkg background parameters.\n" : ".\n";
    $string   .= "This exceeds Ifeffit's limit of $limits{variables} variable parameters.";
    return $string;
  };
  return "";
}


sub verify_parameters {
  my @params = ();
  foreach my $p (@gds) {
    push @params, lc($p->name) unless ($p->type =~ /(after|sep|skip)/);
  };
  my @def_restraint = ();
  foreach my $p (@gds) {
    push @def_restraint, lc($p->name) if ($p->type =~ /(def|restrain)/)
  }
  my $param_regex = lc(join("|", @params, '_^@_'));

  my (%not_defined, %used, %functions);
  my @unused_defs = ();
  ## look at all the path parameters ...
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'path');
    next unless ($paths{$k}->get('include'));
    my $this_data = $paths{$k}->data;
    next unless ($paths{$this_data}->get('include'));
    foreach my $p (qw(s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
      my $str = $paths{$k}->get($p);
      if ($str and ($str !~ /^\s+$/)) {
	$str =~ s/[ \t]+//g;	# remove spaces
	$str =~ s/\(/\( /g;	# put a space after an open paren
	foreach my $w (split(/[^a-zA-Z_0-9.\(]+/, $str)) {
	  next if (lc($w) =~ /(etok|pi|reff)/);    # special words
	  next if ($w =~ /^(\d+\.?\d*|\.\d+)$/);   # a number or float
	  next if ($w eq ""); # this happens with a leading minus sign
	  if ($w =~ /\($/) {	# this was a function, e.g. debye(
	    my $ww = lc(substr($w, 0, -1));
	    push @{$functions{$ww}}, $paths{$k}->get('lab');
	    next;
	  };
	  ## push this path onto the list of paths using this bogus variable
	  (lc($w) =~ /^($param_regex)$/) or
	    push @{$not_defined{lc($w)}}, "the $p of " . $paths{$k}->descriptor();
	  ++$used{lc($w)};	# mark it as used
	};
      };
    };
  };
  ## ... then look at all the def expressions
  foreach my $d (@def_restraint) {
    my ($type, $str);
    foreach my $p (@gds) {
      next unless (lc($p->name) eq lc($d));
      $type = $p->type;
      $str  = $p->mathexp;
      last;
    };
    #print join("|", $d, $type, $str), $/;
    if ($str and ($str !~ /^\s+$/)) {
      $str =~ s/[ \t]+//g;	# remove spaces
      $str =~ s/\(/\( /g;	# put a space after an open paren
      foreach my $w (split(/[^a-zA-Z_0-9.\(]+/, $str)) {
	next if (lc($w) =~ /(etok|pi|reff)/);    # special words
	next if ($w =~ /^(\d+\.?\d*|\.\d+)$/);   # a number or float
	next if ($w eq ""); # this happens with a leading minus sign
	if ($w =~ /\($/) {	# this was a function, e.g. debye(
	  my $ww = lc(substr($w, 0, -1));
	  push @{$functions{$ww}},
	    ($type eq 'def') ? "the def parameter \`$d\'" :
	      "the restraint \`$d\'";
	  next;
	};
	## push this path onto the list of paths using this bogus variable
	(lc($w) =~ /^($param_regex)$/) or
	  push @{$not_defined{lc($w)}},
	    ($type eq 'def') ? "the def parameter \`$d\'" :
	      "the restraint \`$d\'";
	++$used{lc($w)};	# mark it as used
      };
    };
  };
  my $message = "";
  foreach my $p (@params) {	# unused guess parameters
    next if $used{lc($p)};
    my $this;
    foreach my $pp (@gds) {
      next unless ($pp->name eq $p);
      $this = $pp;
      last;
    };
    next unless $this;
    my $choice = $this->type;
    next if ($choice =~ /(after|restrain|set)/);
    $message .= " \`$p\' was defined as a $choice but not used\n";
    push @unused_defs, $p if ($choice eq 'def');
  };
  foreach my $p (keys %not_defined) { # undefined parameters in math expressions
    $message .= " \`$p\' was not defined but was used in:\n    " .
      join("\n    ", @{$not_defined{lc($p)}});
    $message .= $/;
  };
  foreach my $f (keys %functions) { # unknown functions
    next if ($f =~ /^($function_regex)$/);
    next if ($f =~ /^\s*$/);
    $message .= " \`$f\' is not a valid Ifeffit function but was used in:\n    " .
      join("\n    ", @{$functions{lc($f)}});
    $message .= $/;
  };
  if ($message) {
    $message = "Errors in parameters and math expressions:\n\n" .
      $message .
	"\n\nRemember that set parameter are evaluated once at the\n" .
	  "beginning of the fit, def parameters are re-evaluated\n" .
	    "as the fit progresses, and after parameters are evaluated\n" .
	      "after the fit is finished.";
  };
  return ($message, \@unused_defs);
  #print "used: ", join(" ", %used), $/;
  #print "not_defined: ", join(" ", keys %not_defined), $/;
}


## see http://www.perlmonks.org/index.pl?node_id=38942
sub check_parens {
  my $count = 0;
  foreach my $c (split(//, $_[0])) {
    ++$count if ($c eq '(');
    --$count if ($c eq ')');
    return $count if $count < 0;
  };
  return $count;
};


sub verify_parens {
  my @trouble = ();
  ## check the params for balanced parens
  foreach my $p (@gds) {
    next if ($p->type =~ /s(e|ki)p/);
    my $tag = "\tthe " . $p->type . " variable " . $p->name;
    ($tag = "\tthe restraint " . $p->name) if ($p->type eq 'restrain');
    push @trouble, $tag if check_parens($p->mathexp);
  };
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'path');
    next unless ($paths{$k}->get('include'));
    foreach my $p (qw (s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
      next unless defined $paths{$k}->get($p);
      next if ($paths{$k}->get($p) =~ /^\s*$/);	# could be empty string
      next unless $paths{$k}->get($p); # could be 0
      my $tag = "\tthe $p for \"" . $paths{$k}->descriptor() . "\"";
      push @trouble, $tag if check_parens($paths{$k}->get($p));
    };
  };
  return "" unless @trouble;
  return "These math expressions seem to have unbalanced parentheses:\n" .
    join("\n", @trouble) .
      "\n\n";
};

sub verify_operators {
  my @trouble = ();
  my $repeats = '\+\+|\-\-|\/\/|\*\*\*|\^\^';
  foreach my $p (@gds) {
    next if ($p->type =~ /s(e|ki)p/);
    next unless ($p->mathexp =~ /($repeats)/);
    push @trouble, sprintf("\tthe %s parameter \"%s\" has: %s",
			   $p->type, $p->name, $1);
  };
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'path');
    next unless ($paths{$k}->get('include'));
    foreach my $p (qw (s02 e0 delr sigma^2 ei 3rd 4th dphase k_array phase_array amp_array)) {
      next unless defined $paths{$k}->get($p);
      my $mathexp = $paths{$k}->get($p);
      next if ($mathexp =~ /^\s*$/);	# could be empty string
      next unless $mathexp; # could be 0
      next unless ($mathexp =~ /($repeats)/);
      push @trouble, sprintf("\tthe %s expression for path \"%s\" has: %s",
			     $p, $paths{$k}->descriptor, $1);
    };
  };
  return q{} unless @trouble;
  return "These math expressions have invalid binary operators:\n" .
    join("\n", @trouble) .
      "\n\n";
};


## do not allow GDS parameters to take the names of ifeffit's program
## variables.  the $progvar_regex list are the pre-defined batch of
## program variables.  The delta_* and correl_*_* program variables
## will be generated by feffit()ing or minimize()ing.  The feff\d_\d_*
## variables are generated by get_path().  in fact the regex for that
## last one is incorrect -- it covers parts of the namespace that
## might not be used (feff087620_7652000_ei, for example), but it is a
## nice 'n' simple regex and an uncommon string for a GDS name.  note
## also that "feff\d+_\d+" matches Artemis' convention for path group
## names.
sub verify_ifeffit_program_variables {
  my $progvar_regex =		# all of feffit's pre-defined program variables
      "c(hi_(reduced|square)|or(e_width|rel_min)|ursor_[xy])"
    . "|d([kr]|ata_(set|total)|k([12]|1_spl|2_spl)|r[12])"
    . "|e(0|dge_step|psilon_[kr]|tok)"
    . "|k(m(ax(|_s(pl|uggest))|in(|_spl))|w(eight(|_spl)|indow))"
    . "|n(_(idp|varys)|column_label|knots|orm([12]|_c[012]))"
    . "|p(ath_index|i|re([12]|_(offset|slope)))"
    . "|q(max_out|sp)"
    . "|r(_factor|bkg|m(ax(|_out)|in)|sp|w(eight|in(|dow)))"
    . "|toler";
  my $path_param_regex = "d(e(gen|lr)|phase)|e[0i]|fourth|reff|s(02|igma2)|third";

  my @params = ();
  foreach my $p (@gds) {
    push @params, lc($p->name) unless ($p->type =~ /(sep|skip)/);
  };
  my $param_regex = lc(join("|", @params, '_^@_'));
  my @match = ();
  foreach my $p (@params) {
    push @match, $p if (lc($p) =~ /^($progvar_regex)$/);
    push @match, $p if (lc($p) =~ /^delta_($param_regex)$/);
    push @match, $p if (lc($p) =~ /^correl_($param_regex)_($param_regex)$/);
    push @match, $p if (lc($p) =~ /^feff\d+_\d+_($path_param_regex)$/);
  };
  return q{} unless @match;
  my $common = "One common example of this sort is a variable named \"dr1\", which\nshould be changed to something like \"dr_1\" or \"drone\".\n\n";
  if ($#match) {
    return "These parameters use names which have special meaning in Ifeffit:\n\t" .
      join("\n\t", @match) .
	"\nYou must change those parameter names before attempting to fit.\n" .
	  $common;
  } else {
    return "This parameter uses a name which has special meaning in Ifeffit:\n\t" .
      join("\n\t", @match) .
	"\nYou must change this parameter name before attempting to fit.\n" .
	  $common;
  }
};

## return a list of the number of merges and the index of the first
## merge in the list
sub count_merge {
  my $total = 0;
  my $first = 0;
  foreach my $p (@gds) {
    ++$first unless $total;
    next unless ($p->type eq 'merge');
    ++$total;
  };
  return ($total, $first);
};

sub check_idp {
  my ($nidp, $ndat, $nvar) = (0,0,0);
  foreach my $data (&all_data) {
    my $deltak = $paths{$data}->get('kmax') - $paths{$data}->get('kmin');
    my $deltar = $paths{$data}->get('rmax') - $paths{$data}->get('rmin');
    $nidp     += int( 2 * $deltak * $deltar / PI );
    ++$ndat;
  };
  foreach my $p (@gds) {
    next if ($p->name =~ /^\s*$/);
    ++$nvar if ($p->type eq 'guess');
  };
  my $s = ($ndat >1) ? "s" : q{};
  return ($nidp < $nvar) ?
    "ERROR!  You have used $nvar variables but only have $nidp independent\nmeasurements in $ndat data set$s.\n" :
      "";
};


sub gds2_import_text {
  my $path = $current_data_dir || cwd;
  my $types = [['Exported variables', '*.variables'], ['All files', '*']];
  my $file = $top -> getOpenFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -title => "Artemis: Import a list of variables");
  return unless ($file);
  my ($name, $feff_path, $suffix) = fileparse($file);
  $current_data_dir = $feff_path;

  my $view = $#gds+2;
  open V, $file or die "could not open $file for reading variables\n";
  while (<V>) {
    next unless (/^\s*(after|def|guess|merge|restrain|s(et|ep|kip))\b/);
    chomp;
    my @line = split(/\s*[ \t=]\s*/, $_);
    my $type = shift @line;
    my $name = shift @line;
    my $val  = join("", @line);
    $val =~ s/[!%#].*$//;	# ease puts end-of-line comments on
                                # guess lines
    my $which = -1;
    my $see = 0;
    foreach (@gds) {
      ++$see;
      $which = $_, last if ($_->name =~ /^$name$/i);
    };
    ## or for the end of the list
    if ($which == -1) {
      if ($type eq 'sep') {
	push @gds, Ifeffit::Parameter->new(type => "sep",);
      } else {
	push @gds, Ifeffit::Parameter->new(type	    => $type,
					   name	    => $name,
					   mathexp  => $val,
					   bestfit  => 0,
					   modified => 1,
					   note	    => "$name: ",
					   autonote => 1,
					  );
      };
      $see = $#gds;
      $which = $gds[$see];
      ++$see;
    };
  };
  ($view = 1) if ($view > $#gds+1);
  repopulate_gds2();
  gds2_display($view);
  display_page("gsd");
  project_state(0);
  $parameters_changed = 1;

  close V;

};


sub gds2_export_text {
  my $path = $current_data_dir || cwd;
  my $types = [['All Files', '*'],['Text Files', '*.txt']];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialfile=>'artemis.variables',
				 -initialdir=>$path,
				 -title => "Artemis: Export a list of variables");
  return unless ($file);
  my ($name, $feff_path, $suffix) = fileparse($file);
  $current_data_dir = $feff_path;

  my $len = 0;
  foreach (@gds) {
    ($len = length($_->name)) if (length($_->name) > $len);
  };
  $len++;

  open V, '>'.$file or die "could not open $file for writing variables\n";
  print V "# List of parameters from Artemis\n";
  print V "# ", $props{'Project title'}, $/, $/;

  my $pattern = "%-9s %-" . $len . "s = %s\n";
  #print $len, " --- ", $pattern, $/;
  foreach (@gds) {
    printf V $pattern, $_->type, $_->name, $_->mathexp;
  };
  close V;
};

##  END OF THE SECTION ON THE GDS PAGE

