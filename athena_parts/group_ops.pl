## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  groups operations and accounting and with displaying a newly
##  selected group


## merge all marked groups by simple averaging, take care to do the
## "right" thing for different spaces
sub merge_groups {
  my $space = lc($_[0]);
  my $doing_refs = $_[1] || 0;
  my $m = 0;
  my $curr = $current;
  my $all_ref = 1;
  map {$m += $_} values %marked;
  Error("Merging aborted.  There are no marked groups."),   return 1 unless ($m);
  Error("Merging aborted.  There is just 1 marked group."), return 1 if ($m==1);
  my $sp;
 SPACE: {
    ($sp = "energy"),  last SPACE if ($space eq 'e');
    ($sp = "energy (normalized)"),  last SPACE if ($space eq 'n');
    ($sp = "k-space"), last SPACE if ($space eq 'k');
    ($sp = "R-space"), last SPACE if ($space eq 'r');
    ($sp = "q-space"), last SPACE if ($space eq 'q');
  };
  Echo("Merging marked groups in $sp");
  $top -> Busy(-recurse=>1,);
  my ($group, $label) = group_name("merge");
  ($label = "  Ref ".$groups{$doing_refs}->{label}) if $doing_refs;
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  my ($file, $first, $is_detector, $is_xanes) =
    $groups{$group}->merge($space, $config{merge}{merge_weight}, $dmode, \%groups, \%marked, \%plot_features, $list);
  $groups{$group} -> make(file=>$file, is_xanes=>$is_xanes);
  # make parameters same as the first in the merge list
  $groups{$group} -> set_to_another($groups{$first});
  $groups{$group} -> make(bkg_z    => $groups{$first}->{bkg_z},
			  fft_edge => $groups{$first}->{fft_edge});
  # because a merged group is a merge of data that has been e0
  # shifted, the merge must NOT be e0 shifted.
  $groups{$group} -> {bkg_eshift} = 0;
 SWITCH: {
    ($space eq 'e') and do {
      $groups{$group} -> make(is_xmu=>1, is_chi=>0, is_rsp=>0, is_qsp=>0, update_bkg=>1);
      $groups{$group} -> make(is_xmu=>0, not_data=>1) if $is_detector;
      last SWITCH;
    };
    ($space eq 'n') and do {
      $groups{$group} -> make(is_xmu=>1, is_chi=>0, is_rsp=>0, is_qsp=>0, is_nor=>1,
			      update_bkg=>1, bkg_slope=>0, bkg_int=>0, bkg_step=>1,
			      bkg_fixstep=>1, bkg_fitted_step=>1);
      $groups{$group} -> make(is_xmu=>0, is_nor=>0, not_data=>1) if $is_detector;
      last SWITCH;
    };
    ($space eq 'k') and do {
      $groups{$group} -> dispose("set(___x = ceil($group.k))\n", 1);
      my $maxk = Ifeffit::get_scalar("___x");
      $groups{$group} -> make(is_xmu=>0, is_chi=>1, is_rsp=>0, is_qsp=>0, update_fft=>1,
			      update_bkg=>0, fft_kmax=>sprintf("%.2f", $maxk));
      last SWITCH;
    };
    ($space eq 'r') and do {
      $groups{$group} -> make(is_xmu=>0, is_chi=>0, is_rsp=>1, is_qsp=>0,
			      update_bft=>1, update_fft=>0, update_bkg=>0);
      last SWITCH;
    };
    ($space eq 'q') and do {
      $groups{$group} -> make(is_xmu=>0, is_chi=>0, is_rsp=>0, is_qsp=>1,
			      update_bft=>0, update_fft=>0, update_bkg=>0);
      last SWITCH;
    };
  };
  ++$line_count;
  $groups{$group} -> make(line=>$line_count);
  if ($sp eq 'energy') {
    $groups{$group} -> make(bkg_spl1=>$groups{$curr}->{bkg_spl1},
			    bkg_spl2=>$groups{$curr}->{bkg_spl2});
    # do not reset e0!!!
  };
  fill_skinny($list, $group, 1);

  ## merge reference spectra if all groups in the merge have references
  if ($space =~ m{[en]}) {
    if (not $doing_refs) {
      foreach my $m (keys %marked) {
	next if not $marked{$m};
	my $has_ref = $groups{$m}->{reference};
	$all_ref = ($all_ref and $has_ref);
	#print $groups{$m}->{label}, "  $all_ref $has_ref\n";
      };
      if ($all_ref) {
	my $ref_group = merge_refs($space, $group);
	$groups{$group}->{reference} = $ref_group;
	$groups{$ref_group}->{reference} = $group;
      };
      set_properties(1, $group, 0);
    };
  };
  return $group if $doing_refs;

  $marked{$group} = 1;
  ($space = "d") if $is_detector;
  plot_merge($group, $space);

  Echo("Merging marked groups in $sp ... done!");
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
  $top->Unbusy;
  return $group;
};


sub merge_refs {
  my ($space, $gp) = @_;
  my @list = ();
  ## set the marks to the reference channels
  foreach my $m (keys %marked) {
    push @list, $groups{$m}->{reference} if $marked{$m};;
    $marked{$m} = 0;
  };
  map { $marked{$_}=1 } @list;

  my $ref_group = merge_groups($space, $gp);

  ## set the marks back to the data
  @list = ();
  foreach my $m (keys %marked) {
    push @list, $groups{$m}->{reference} if $marked{$m};;
    $marked{$m} = 0;
  };
  map { $marked{$_}=1 } @list;
  $top->update;
  return $ref_group;
};



## generate a copy of the current group with a unique name
sub copy_group {
  Echo('No data!'), return unless ($current);
  Echo("Cannot copy defaults."), return if ($current eq "Default Parameters");
  my ($group, $label) = group_name("Copy of " . $groups{$current}->{label});
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  $groups{$group} -> set_to_another($groups{$current});
  $groups{$group} -> make(is_xmu   => $groups{$current}->{is_xmu},
			  is_chi   => $groups{$current}->{is_chi},
			  is_rsp   => $groups{$current}->{is_rsp},
			  is_qsp   => $groups{$current}->{is_qsp},
			  is_nor   => $groups{$current}->{is_nor},
			  is_bkg   => $groups{$current}->{is_bkg},
			  is_diff  => $groups{$current}->{is_diff},
			  is_pixel => $groups{$current}->{is_pixel},
			  is_xanes => $groups{$current}->{is_xanes},
			  not_data => $groups{$current}->{not_data},
			 );
  $groups{$group} -> make(file=>$groups{$current}->{file}, update_bkg=>1);
  my $mark = $marked{$current};
  my $original = $current;
 SWITCH: {			# handle each space appropriately
    (($groups{$group}->{is_xmu}) or ($groups{$group}->{is_chi})) and do {
      my $xsuff = ($groups{$group}->{is_xmu}) ? ".energy" : ".k";
      my $ysuff = ($groups{$group}->{is_xmu}) ? ".xmu"    : ".chi";
      my @x = Ifeffit::get_array($current.$xsuff);
      my @y = Ifeffit::get_array($current.$ysuff);
      Ifeffit::put_array($group.$xsuff, \@x);
      Ifeffit::put_array($group.$ysuff, \@y);
      if ($groups{$current}->{i0}) {
	$groups{$group} -> make(i0 => "$group.i0");
	my @i0 = Ifeffit::get_array($current.$ysuff);
	Ifeffit::put_array("$group.i0", \@i0);
      };
      last SWITCH;
    };
    ($groups{$group}->{not_data}) and do {
      my $xsuff = ".energy";
      my $ysuff = ".det";
      my @x = Ifeffit::get_array($current.$xsuff);
      my @y = Ifeffit::get_array($current.$ysuff);
      Ifeffit::put_array($group.$xsuff, \@x);
      Ifeffit::put_array($group.$ysuff, \@y);
      last SWITCH;
    };
    (($groups{$group}->{is_rsp}) or ($groups{$group}->{is_qsp})) and do {
      my $x = ($groups{$group}->{is_rsp}) ? 'r' : 'q';
      my @x = Ifeffit::get_array($current.".$x");
      Ifeffit::put_array($group.".$x", \@x);
      foreach (qw(mag pha re im)) { # copy all four arrays
	my $suff = join("", ".chi", $x, "_", $_);
	my @y = Ifeffit::get_array($current.$suff);
	Ifeffit::put_array($group.$suff, \@y);
      };
      last SWITCH;
    };
  };
  ++$line_count;
  $groups{$group} -> make(line=>$line_count);
  fill_skinny($list, $group, 1, 1);
  $marked{$group} = $mark;
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
  return $group;
};


## This makes detector groups out of the numerator and denominator of
## an xmu group
sub make_detectors {
  my $group	  = $groups{$current}->{group};
  my $label	  = $groups{$current}->{label};
  my $e0	  = $groups{$current}->{bkg_e0};
  my $esh	  = $groups{$current}->{bkg_eshift};
  my $numerator	  = $groups{$current}->{numerator};
  my $denominator = $groups{$current}->{denominator};
  my @dets        = ();

  if ($numerator !~ /^\s*$/) {
    my ($num_group, $num_label) = group_name("num $label");
    $groups{$num_group} = Ifeffit::Group -> new(group=>$num_group, label=>$num_label);
    $groups{$num_group} -> make(is_xmu => 0, is_chi => 0, is_rsp => 0, is_qsp => 0,
				not_data => 1, bkg_e0 => $e0, bkg_eshift => $esh,
				file => "Numerator of $label");
    my $sets = "set($num_group.energy = $group.energy,\n";
    $sets   .= "    $num_group.det = $numerator,\n";
    $sets   .= "    ___ceil = ceil($num_group.det))";
    $groups{$num_group} -> dispose($sets, $dmode);
    my $scale = sprintf("%8.2e", 1/Ifeffit::get_scalar("___ceil"));
    ++$line_count;
    set_defaults($num_group, 'e', 0);
    $groups{$num_group} -> make(line=>$line_count, plot_scale=>sprintf("%f",$scale));
    fill_skinny($list, $num_group, 1);
    push @dets, $num_group;
  };
  if ($denominator !~ /^\s*$/) {
    my ($den_group, $den_label) = group_name("den $label");
    $groups{$den_group} = Ifeffit::Group -> new(group=>$den_group, label=>$den_label);
    $groups{$den_group} -> make(is_xmu => 0, is_chi => 0, is_rsp => 0, is_qsp => 0,
				not_data => 1, bkg_e0 => $e0, bkg_eshift => $esh,
				file => "Denominator of $label");
    my $sets = "set($den_group.energy = $group.energy,\n";
    $sets   .= "    $den_group.det = $denominator,\n";
    $sets   .= "    ___ceil = ceil($den_group.det))";
    $groups{$den_group} -> dispose($sets, $dmode);
    my $scale = sprintf("%8.2e", 1/Ifeffit::get_scalar("___ceil"));
    ++$line_count;
    set_defaults($den_group, 'e', 0);
    $groups{$den_group} -> make(line=>$line_count, plot_scale=>sprintf("%f",$scale));
    fill_skinny($list, $den_group, 1);
    push @dets, $den_group;
  };

  set_properties(1, $group, 0);
  $groups{$current}->make(detectors=>\@dets);
  my $memory_ok = $groups{$current}->memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};


## turn the background function for a group into it's own group so it
## can be displayed independently of its data.
sub make_background {
  my $group = $groups{$current}->{group};
  my $e0    = $groups{$current}->{bkg_e0};
  my $esh   = $groups{$current}->{bkg_eshift};
  my $step  = $groups{$current}->{bkg_step};
  ($groups{$current}->{update_bkg}) and $groups{$current}->dispatch_bkg($dmode);
  my ($bkg, $label) = group_name($groups{$current}->{label}." bkg");
  $groups{$bkg} = Ifeffit::Group -> new(group=>$bkg, label=>$label);
  $groups{$bkg} -> set_to_another($groups{$group});
  $groups{$bkg} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0, is_qsp => 0, is_bkg => 1,
			not_data => 0,
			file=>"Background from ".$groups{$current}->{label});
  #, bkg_e0 => $e0, bkg_eshift => $esh, bkg_step => $step);
  my $cmd = "set($bkg.energy = $group.energy,\n";
  if ($groups{$group}->{bkg_cl}) {
    $cmd .= "    $bkg.xmu = $group.f2)";
  } else {
    $cmd .= "    $bkg.xmu = $group.bkg)";
  };
  $groups{$bkg} -> dispose($cmd, $dmode);
  ++$line_count;
  fill_skinny($list, $bkg, 1);
  $groups{$bkg} -> plotE('em',$dmode,\%plot_features, \@indicator);
  my $memory_ok = $groups{$bkg} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};


## read a string from an entry box that temporarily replaces the echo
## area.  $label is the descriptive label to be written before the
## entry box.  $r_string is a ref to the string being prompted for.
## $r_arrow_buffer is a ref to a array containing a buffer of
## responses accessed via the up and down arrows
sub get_string {
  my ($mode, $label, $r_string, $r_arrow_buffer) = @_;
  $top -> packPropagate(0);
  $echo -> packForget;
  my $prior = $top -> focusCurrent;
  my $ren = $ebar -> Frame()
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -ipadx=>3);
  $ren -> Label(-text=>$label,
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  my $entry = $ren -> Entry(-justify=>'center', -background=>$config{colors}{current},
			    -textvariable=>$r_string)
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>10);
  if ($r_arrow_buffer) {
    my $pointer = $#{$r_arrow_buffer} + 1;
    $entry->bind("<KeyPress-Up>",	# previous command in history
		 sub{ --$pointer; ($pointer=0) if ($pointer<0);
		      $entry->delete(0,'end');
		      $entry->insert(0, $$r_arrow_buffer[$pointer]); });
    $entry->bind("<KeyPress-Down>", # next command in history
		 sub{ ++$pointer; ($pointer= $#{$r_arrow_buffer}) if
			($pointer>$#{$r_arrow_buffer});
		      $entry->delete(0,'end');
		      $entry->insert(0, $$r_arrow_buffer[$pointer]); });
  };
  my $pad = 0;
  $entry -> bind("<KeyPress-Return>", sub{&restore_echo($ren, $mode, $entry, $prior)});
  $ren -> Button(-text=>'OK',  @button_list, -font=>$config{fonts}{small}, -borderwidth=>1,
		 -command=>[\&restore_echo, $ren, $mode, $entry, $prior])
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  foreach ($ren, $entry) {
    my $this = $_;
    $this -> bindtags([($this->bindtags)[1,0,2,3]]);
    map {$this -> bind("<Control-$_>" => sub{$this->break;})}
      qw(a b h i f j k l m o p r s t u w y
	 period slash minus equal semicolon
	 Key-1 Key-2 Key-3 Key-4 Key-5 Key-6);
    map {$this -> bind("<Alt-$_>" => sub{$this->break;});
	 $this -> bind("<Meta-$_>" => sub{$this->break;});}
      qw(b B j k o d semicolon);
  };

  $entry -> selectionRange(qw(0 end));
  $entry -> icursor('end');
  $top   -> update;
  $ren   -> grab();
  $entry -> focus;
  return $ren;
};


## destroy the get_string dialog and return the echo area
sub restore_echo {
  my ($ren, $mode, $entry, $prior) = @_;
  $ren -> grabRelease;
  $ren -> packForget;
  $ren -> destroy;
  $ebar -> pack(-side=>"bottom", -fill=>'x');
  $echo -> pack(-side=>'left', -expand=>1, -fill=>'x', -pady=>2);
  if ($prior) { # and $prior->packInfo()) {
    $prior -> focus;
  } else {
    $b_red{E} -> focus;
  };
};



## pop up a top level asking the user to provide a string as the new
## name for a group.  then call rename_group.
sub get_new_name {
  Echo('No data!'), return unless ($current);
  Echo("You cannot rename the defaults"),
    return if ($current eq "Default Parameters");
  my $newname = $groups{$current}->{label};
  my $label = "New name for group \"" . $groups{$current}->{label} . "\": ";
  my $dialog = get_string($dmode, $label, \$newname, \@rename_history);

  my @list = &sorted_group_list;
  my $l = $#list+1;
  my $h = -1;
  foreach (@list) {
    ++$h;
    last if ($_ eq $current);
  };
  ($h -= 2) if ($h > 1);
  $list -> yview('moveto', $h/$l);

  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  rename_group($dmode, $newname);
};




## rename a group -- actually just reset its label and display the new
## label in the skinny panel
sub rename_group {
  my ($mode, $newname, $which) = @_;
  $which ||= $current;
  Echo("Not renaming '$groups{$which}->{label}'", 0), return if ($newname =~ /^\s*$/);
  Echo("Not renaming '$groups{$which}->{label}'", 0), return if ($newname eq $groups{$which}->{label});
  my $oldname = $groups{$which}->{label};
  Echo("Renaming \"$oldname\" to \"$newname\"");
  push @rename_history, $newname;
  my $quote_message = q{};
  if ($newname =~ m{[\"\']}) {
    $newname =~ s{[\"\']}{}g;
    $quote_message = " (quote marks removed from group name)";
  };
  ## need to verify that this name is not already used
  $groups{$which} -> MAKE(label=>$newname);
  ## fix up the skinny panel entry
  my $tag = $groups{$which}->{bindtag};
  my @bold   = (-fill => $config{colors}{activehighlightcolor},
		#-font => $config{fonts}{large},
	       );
  my @normal = (-fill => $config{colors}{foreground},
		#-font => $config{fonts}{med},
	       );
  my @rect_in  = (-fill => $config{colors}{activebackground}, -outline=>$config{colors}{activebackground});
  my @rect_out = (-fill => $config{colors}{background},       -outline=>$config{colors}{background});
  $list -> bind($tag, '<1>' => [\&set_properties, $which, 0]);
  $list -> bind($tag, '<3>' => [\&GroupsPopupMenu, $which, Ev('X'), Ev('Y')]);
  ## change text size/color unless passing over the current group
  $list -> bind($tag, '<Any-Enter>'=>sub{my $this = shift;
					 return if not exists($groups{$which}->{bindtag});
					 if ($this->itemcget('current', '-tags')->[0] ne $groups{$which}->{bindtag}) {
					   #$this->itemconfigure('current', @bold  );
					   my $x = $this->find(below=>'current');
					   $this->itemconfigure($x, @rect_in,);
					 }
				       });
  $list -> bind($tag, '<Any-Leave>'=>\&Leave);
  $list -> itemconfigure($groups{$which}->{text}, -text=>$newname, -tag=>$tag);
  $groups{$which}->{checkbutton} -> configure(-variable=>\$marked{$which});
  $list -> coords($groups{$which}->{rect}, $list->bbox($groups{$which}->{text}));
  ## deal with reference channel
  my $ref = $groups{$which}->{reference};
  if ($ref                            and
      #not $groups{$which}->{is_ref} and
      ($groups{$ref}->{label} =~ m{^ *Ref +$oldname$})) {
    $groups{$ref} -> MAKE(label=>"   Ref " . $newname);
    my $tag = $groups{$ref}->{bindtag};
    $list -> bind($tag, '<1>' => [\&set_properties, $ref, 0]);
    $list -> bind($tag, '<3>' => [\&GroupsPopupMenu, $ref, Ev('X'), Ev('Y')]);
    ## change text size/color unless passing over the reference group
    $list -> bind($tag, '<Any-Enter>'=>sub{my $this = shift;
					   #print join(" ", $this->itemcget('current', '-tags')), $/;
					   #print ">>>", $groups{$ref}->{bindtag}, $/;
					   if ($this->itemcget('current', '-tags')->[0] ne $groups{$which}->{bindtag}) {
					     my $x = $this->find(below=>'current');
					     $this->itemconfigure($x, @rect_in  )
					   };
					 });
    $list -> bind($tag, '<Any-Leave>'=>\&Leave);
    ##$list -> bind($tag, '<Any-Leave>'=>sub{shift->itemconfigure('current', @normal)});
    $list -> itemconfigure($groups{$ref}->{text}, -text=>$groups{$ref}->{label}, -tag=>$tag);
    $list -> coords($groups{$ref}->{rect}, $list->bbox($groups{$ref}->{text}));
  };
  set_properties(1, $which, 0);
  project_state(0);
  Echo("\"$oldname\" renamed to \"$newname\" $quote_message");
};


sub mark {
  my $how = $_[0];
 SWITCH: {
    ($how eq 'all') and do {
      map {$marked{$_} = 1} keys %marked;
      last SWITCH;
    };
    ($how eq 'none') and do {
      map {$marked{$_} = 0} keys %marked;
      last SWITCH;
    };
    ($how eq 'toggle') and do {
      map {$marked{$_} = !$marked{$_}} keys %marked;
      last SWITCH;
    };
    ($how eq 'this') and do {
      $marked{$current} = !$marked{$current};
      last SWITCH;
    };
    ($how eq 'regex') and do {
      mark_regex(1);
      last SWITCH;
    };
    ($how eq 'unregex') and do {
      mark_regex(0);
      last SWITCH;
    };
  };
};

sub mark_regex {
  my $mark = $_[0];
  my $regex = "";
  my $label = $mark ? "Mark" : "Unmark";
  $label   .= " all groups matching this perl regular expression: ";
  my $dialog = get_string($dmode, $label, \$regex, \@regex_history);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Aborting regex matching."), return if ($regex =~ /^\s*$/);
  my $given = $regex;
  my $re;
  if ($config{general}{match_as} eq 'perl') {
    my $is_ok = eval '$re = qr/$regex/i';
    Error("Oops!  \"$regex\" is not a valid regular expression"), return unless $is_ok;
  } else {
    $regex = glob_to_regex($given);
  };
  ##map {$marked{$_} = ($groups{$_}->{label} =~ /$regex/) ? 1 : 0} keys %marked;
  foreach my $k (keys %marked) {
    next unless ($groups{$k}->{label} =~ /$regex/);
    $marked{$k} = $mark;
  };
  push @regex_history, $given;
  my $what = $mark ? "Marked" : "Unmarked";
  Echo("$what all groups matching /$given/");
};


## reordering the groups list...
sub group_up   { group_move(-1); };
sub group_down { group_move(1);  };
sub group_move {
  my $dir = $_[0];
  my @keys = &sorted_group_list;
  Error("There aren't any groups!"), return unless (@keys);
  my $index = -1;
  foreach (@keys) {
    ++$index;
    last if ($_ eq $current);
  };
  Echo("$groups{$current}->{label} is at the top of the list"),    return if (($dir < 0) and ($index == 0));
  Echo("$groups{$current}->{label} is at the bottom of the list"), return if (($dir > 0) and ($index == $#keys));

  $index += $dir;
  my $other = $keys[$index];
  my $step = $config{list}{real_y};		# see $step in fill_skinny
  ## swap $current with the one above/below
  foreach ($current, $other) {
    my $dist = sprintf("%fc", ($_ eq $current) ? $dir*$step : -1*$dir*$step);
    my ($check, $text, $rect) = ($groups{$_}->{check}, $groups{$_}->{text},
				 $groups{$_}->{rect});
    $list->move($check, 0, $dist);
    $list->move($text,  0, $dist);
    $list->move($rect,  0, $dist);
  };

  # finally adjust the view
  my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
  ($here < 0) and ($here = 0);
  my $full = ($list->bbox(@skinny_list))[3] + 5;
  $list -> yview('moveto', $here/$full);
  project_state(0);
};


sub current_up   { &current_move(-1); };
sub current_down { &current_move(1);  };
sub current_move {
  my $dir = $_[0];
  my @keys = &sorted_group_list;
  Error("There aren't any groups!"), return unless (@keys);
  my $index = -1;
  foreach (@keys) {
    ++$index;
    last if ($_ eq $current);
  };
  Echo("$groups{$current}->{label} is at the top of the list"),    return if (($dir < 0) and ($index == 0));
  Echo("$groups{$current}->{label} is at the bottom of the list"), return if (($dir > 0) and ($index == $#keys));
  set_properties(1, $keys[$index+$dir], 0);
  # finally adjust the view
  my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
  ($here < 0) and ($here = 0);
  my $full = ($list->bbox(@skinny_list))[3] + 5;
  $list -> yview('moveto', $here/$full);
  ##project_state(0);
};


## get rid of the current group both in the GUI and in ifeffit
sub delete_group {
  #Error("You can only delete groups in the normal view."), return unless ($fat_showing eq 'normal');
  my $debug = 0;
  Echo('No data!'), return unless ($current);
  my ($c, $mode, $which) = @_;
  Echo("Cannot delete defaults."), return if ($current eq "Default Parameters");
  my $to_delete = $which || $current;
  my $group = $groups{$to_delete}->{group};
  my $label = $groups{$to_delete}->{label};
  print "Discarding $to_delete ($label)\n" if $debug;
  my $message = "Group \"$label\" removed from project.";
  Echonow("Removing group \"$label\" from project");
  ## what about title lines

  ## clear referent if this is a reference
  if ($groups{$to_delete}->{reference}) {
    if (exists($groups{$groups{$to_delete}->{reference}})) {
      Echonow("Untying referent \"" . $groups{$groups{$to_delete}->{reference}}->{label} . "\"");
      $groups{$groups{$to_delete}->{reference}}->MAKE(reference=>0);
    };
  };

  my @keys = &sorted_group_list;
  print "\tDisposing erase command to ifeffit\n" if $debug;
  $groups{$to_delete} -> dispose("erase \@group $group\n", $mode);
  print "\tRemoving widgets from groups list\n" if $debug;
  $c->delete($groups{$to_delete}->{check});
  $c->delete($groups{$to_delete}->{rect});
  $c->delete($groups{$to_delete}->{text});
  --$line_count;
  print "\tDeleting groups and marked hash entries\n" if $debug;
  delete $marked{$to_delete};
  delete $groups{$to_delete};
  $to_delete = "";
  my $prev = "Default Parameters";
  print "\tFinding location in groups list\n" if $debug;
  while (@keys) {
    my $this = shift @keys;
    last if ($this eq $group);
    $prev = $this;
  };
  print "\tSetting properties of newly selected group\n" if $debug;
  my $step = '-' . $config{list}{real_y} . 'c';		# see $step in fill_skinny
  print "\tMoving widgets of newly selected group\n" if $debug;
  foreach (@keys) {		# list only contains those below deleted group
    my ($check, $text, $rect) = ($groups{$_}->{check}, $groups{$_}->{text},
				 $groups{$_}->{rect});
    $c->move($check, 0, $step);
    $c->move($text,  0, $step);
    $c->move($rect,  0, $step);
  };

  my $h = ($list->bbox(@skinny_list))[3]  || 0;
  $h += 5;
  ($h < 200) and ($h = 200);
  $list -> configure(-scrollregion=>['0', '0', '150', $h]);
  unless ($which) {
    set_properties(1, "Default Parameters", 0), Echo($message), return "Default Parameters" unless $prev;
    set_properties(1, $prev, 0), Echo($message), return $prev unless @keys;
    set_properties(1, $keys[0], 0);
  };

  print "\tAlmost done\n" if $debug;
  project_state(0);
  Echonow("Group \"$label\" removed from project.");
  print "\tDone!\n" if $debug;
  return $prev;
};

## delete every group in the skinny canvas if the third arg is false
## delete only marked groups is the third arg is true
sub delete_many {
  #Error("You can only delete groups in the normal view."), return unless ($fat_showing eq 'normal');
  Echo('No data!'), return unless ($current);
  my ($c, $mode, $m) = @_;
  unless ($m) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "Save this project before closing?.",
		     -title          => 'Athena: Question...',
		     -buttons        => ['Save', 'Just close it', 'Cancel'],
		     -default_button => 'Save');
    my $response = $dialog->Show();
    return if $response eq 'Cancel';
    &save_project('all') if $response eq 'Save';
  };
  my $str = ($m) ? "Removing marked groups from project" : "Closing entire project";
  if ((not $m) and ($groups{"Default Parameters"} -> vstr($ifeffit_version) > 1.02008)) {
    $groups{"Default Parameters"} -> dispose("reset", $dmode);
    $groups{"Default Parameters"} -> dispose("set \&screen_echo = 0", $dmode);
    $groups{"Default Parameters"} -> dispose(&write_macros, $dmode);
    $groups{"Default Parameters"} -> dispose("startup", $dmode);
    #$ENV{PGPLOT_DIR} ||= '/usr/local/share/pgplot';
    #$ENV{PGPLOT_DEV} ||= '/XSERVE';
    #Ifeffit::Tools::reload("Ifeffit");
    #ifeffit("\&screen_echo = 0\n");
  };
  Echo($str);
  $top -> Busy(-recurse=>1,);
  my @keys = &sorted_group_list;
  my $show = "";
  my $sync = Ifeffit::get_scalar('&sync_level');
  ##$groups{"Default Parameters"} -> dispose('&sync_level = 0', $dmode);
  my $save_groupreplot = $config{general}{groupreplot};
  $config{general}{groupreplot} = 'none';
  while (@keys) {
    my $this = pop @keys;
    next if ($m and not $marked{$this});
    $show = delete_group($c, $mode, $this);
  };
  ##$groups{"Default Parameters"} -> dispose("\&sync_level = $sync\nsync()\n", $dmode);
  @keys = &sorted_group_list;
  $show = $keys[0] if (($show eq "Default Parameters") and @keys);

  $config{general}{groupreplot} = $save_groupreplot;
  ## there is a bug somewhere just prior to this and elements of
  ## %group are being vivified but not blessed.  this will remove
  ## those naughty hash pairs
  foreach my $g (keys %groups) {
    delete($groups{$g}) unless ref($groups{$g}) =~ /Ifeffit/;
  };
  ($m) or $notes{journal} -> delete(qw(1.0 end));

  my $h = ($list->bbox(@skinny_list))[3]  || 0;
  $h += 5;
  ($h < 200) and ($h = 200);
  $list -> configure(-scrollregion=>['0', '0', '150', $h]);

  $str .= " ... done!";
  ## unset this in deleting entire project
  ($project_name = "") unless $m;
  $plot_features{project} = $project_name;
  project_state(0);
  Echo($str);
  $top->update;
  ($m) ? set_properties(0, $show, 0) : set_properties(1, $show, 0);
  $top->Unbusy;
};



sub kw_button {
  foreach my $g (keys %marked) {
    $groups{$g}->MAKE(update_fft=>1);
  };
  if ($last_plot =~ /k/) {
    $last_plot_params->[3] = $plot_features{kw};
  };
  #$last_plot_params = [$current, 'marked', 'k', $str];
  if ($last_plot eq 'kq') {
    $b_red{kq}->invoke;
  } elsif ($last_plot eq 'e') {
    1; # do nothing
  } else {
    redo_plot();
  };
  section_indicators();
  $plot_features{k_w} = $plot_features{kw};
};


sub refresh_titles {
  my $self = $_[0];
  return unless (ref $self =~ /Ifeffit/);
  $self->{titles} = [];
  my $text = $notes{titles} -> get(qw(1.0 end));
  my @titles = ();
  foreach (split(/\n/, $text)) {
    next if ($_ =~ /^\s*$/);
    ## walk through the title line counting open and closed parens,
    ## skipping unmatched close parens
    my $count = 0;
    foreach my $i (0..length($_)) {
      ++$count if (substr($_, $i, 1) eq '(');
      --$count if ($count and (substr($_, $i, 1) eq ')'));
    };
    ## close all unmatched parens by appending close_parens to the string
    $_ .= ')' x $count;

    ## remove all parens
    ## $_ =~ s/[\(\)]//g;

    ## ! % and # in title lines seem to be a problem on Windows
    $_ =~ s/[!\%\#]//g;

    ## remove all unmatched open parens -- fragile!!
    ## while (/\([^\)]*$/) {
    ##   $_ =~ s/\(//;
    ## };

    push @titles, $_;
  };
  $self -> MAKE(titles=>\@titles);
  $self -> put_titles;
};

## This updates the current group in ways that aren't handled by other
## mechanisms
sub update_hook {
  my $this = $_[0] || $current;

  ## fixed step may not be up to date if the fixstep button was
  ## pressed, then the step size was edited
  $groups{$this} -> make(bkg_step => $widget{bkg_step}->cget('-value')) if $groups{$this}->{bkg_fixstep};
};


sub group_name {
  #my $this = lc($_[0]);
  my $this = $_[0];
  $this =~ s/[^A-Za-z0-9_&. ]/_/g;

  ## want to generate a unique label
  my $label = $this;
  my $found = 0;
  foreach my $g (keys %groups) {
    next unless exists $groups{$g};
    next unless exists $groups{$g}->{label};
    $found = 1 if ($label eq $groups{$g}->{label});
  };
  my $count = 2;
  while ($found) {
    $label = $this . " $count";
    $found = 0;
    foreach my $g (keys %groups) {
      next unless exists $groups{$g};
      next unless exists $groups{$g}->{label};
      $found = 1 if ($label eq $groups{$g}->{label});
    };
    ++$count;
  };

  my $gp = four_character_random_string();
  while (exists $groups{$gp}) {	# make sure to get a unique one!
    $gp = four_character_random_string();
  };
  $label =~ s{[\"\']}{}g;
  $label =~ s{^unmacify_}{};
  return ($gp, $label);
};


## 4 char keyspace is almost 1/2 million large
##  26^3 =     17576
##  26^4 =    456976
##  26^5 =  11881376
##  26^6 = 308915776
sub four_character_random_string {
  return chr(97 + int(rand(26))) . chr(97 + int(rand(26))) .
      chr(97 + int(rand(26))) . chr(97 + int(rand(26)));
};



sub set_edge {
  my $this = $_[0];
  my $how   = $_[1];
  ($how = "fraction") if ($how eq "half");
  my $message = "";
  Echo("No data"), return unless ($this);
  Echo("The group \"$groups{$this}->{label}\" is frozen."), return if ($groups{$this}->{frozen});
  return unless $groups{$this}->{is_xmu};

 SWITCH: {
    # ifeffit's e0 (near peak of 1st derivative)
    ($how eq 'edge') and do {
      $groups{$this}->reset_e0($dmode);
      $message = "E0 set to Ifeffit's default (near the peak of the 1st derivative) for \"$groups{$this}->{label}\"";
      last SWITCH;
    };

    # zero-crossing nearest to ifeffit's e0
    ($how eq 'zero') and do {
      my %params = (e0 => $groups{$this}->{bkg_e0}, str =>'em2', zero_skip_plot => 1);
      cal_zero($this, \%params);
      $groups{$this}->make(bkg_e0=>$params{e0}, update_bkg=>1);
      $message = "E0 set to zero-crossing of second derivative for \"$groups{$this}->{label}\"";
      last SWITCH;
    };

    # energy of the half edge step
    ($how eq 'fraction') and do {
      $top->Busy;
      $groups{$this}->e0_half_step($dmode, $config{bkg}{fraction});
      $top->Unbusy;
      $message = "E0 set to a fraction of the edge step for \"$groups{$this}->{label}\"";
      last SWITCH;
    };

    # tabulated atomic value
    ($how eq 'atomic') and do {
      Echo("Cannot fetch atomic e0 values."), return unless $absorption_exists;
      my ($z, $edge) = ($groups{$this}->{bkg_z}, $groups{$this}->{fft_edge});
      my $en = Xray::Absorption->get_energy($z, $edge);
      $groups{$this}->make(bkg_e0=>$en, update_bkg=>1);
      $message = sprintf("E0 set to the atomic value for the %s edge of %s for \"$groups{$this}->{label}\"", $edge, $z);
      last SWITCH;
    };

  };

  project_state(0);
  set_properties(1, $this, 0);
  #autoreplot('e');
  Echo($message)
};

sub set_edges {
  my ($how, $which) = @_;
  my $remember = $current;
  my @list = &sorted_group_list;
  foreach my $g (@list) {
    next if (($which eq 'marked') and (not $marked{$g}));
    if ($how eq "peak") {
      set_edge_peak($g);
      next;
    };
    set_edge($g, $how);
  };
  my $descr = "Ifeffit's default";
  $descr = "zero-crossing of second derivative" if ($how eq 'zero');
  $descr = "a fraction of the edge step" if ($how eq 'fraction');
  $descr = "the atomic value" if ($how eq 'atomic');
  set_properties(1, $remember, 0);
  my $message = "Set E0 to $descr for $which groups.";
  Echo($message);
};



sub set_edge_peak {
  my ($group) = @_;
  return 0 if not $groups{$group}->{is_xmu};
  my $zpref = get_Z($config{bkg}{ledgepeak});
  my $zthis = get_Z($groups{$group}->{bkg_z});
  #Echo("Cannot set e0 to white line peak, the bkg->ledgepeak parameter is not set to an element symbol"),
  #  return 0 if (not $zpref);
  Echo("Cannot set E0 to white line peak, \"$groups{$group}->{label}\" is frozen."),
    return 0 if ($groups{$group}->{frozen});
  #Echo("Cannot set E0 to white line peak, \"$groups{$group}->{label}\" is not an L2 or L3 edge."),
  #  return 0 if ($groups{$group}->{fft_edge} !~ /l[23]/i);
  #Echo("Cannot set E0 to white line peak, \"$groups{$group}->{label}\" is below the cutoff Z ($config{bkg}{ledgepeak}) for this algorithm"),
  #  return 0 if ($zthis < $zpref);

  $top->Busy;

  set_edge($group, 'edge');
  $groups{$group}->dispose("## computing derivative to set e0 to the white line peak\n", $dmode);
  $groups{$group}->dispose("set $group.yd = deriv($group.xmu)/deriv($group.energy)\n", $dmode);
  my @x = map {$_ + $groups{$group}->{bkg_eshift}} Ifeffit::get_array("$group.energy");
  my @y = Ifeffit::get_array("$group.yd");
  $groups{$group}->dispose("## arrays $group.energy and $group.yd were just slurped into Athena\n", $dmode);
  $groups{$group}->dispose("erase $group.yd\n", $dmode);

  my $e0index = 0;
  foreach my $e (@x) {
    last if ($e > $groups{$group}->{bkg_e0});
    ++$e0index;
  };
  my ($enear, $ynear) = ($x[$e0index], $y[$e0index]);
  my ($ratio, $i) = (1, 1);
  my ($above, $below) = (0,0);
  while (1) {			# find points that bracket the zero crossing
    (($above, $below) = (0,0)), last unless (exists($y[$e0index + $i]) and $y[$e0index]);
    $ratio = $y[$e0index + $i] / $y[$e0index]; # this ratio is negative for a points bracketing the zero crossing
    ($above, $below) = ($e0index+$i, $e0index+$i-1);
    last if ($ratio < 0);
    ++$i;
    return 0 if ($i == 4000);	# fail safe
  };
  my $wlpeak = sprintf("%.3f", $x[$below] - ($y[$below]/($y[$above]-$y[$below])) * ($x[$above] - $x[$below]));
  $groups{$group}->make(bkg_e0=>$wlpeak);

  project_state(0);
  set_properties(1, $group, 0);
  Echo("E0 set to the peak of the white line for \"$groups{$group}->{label}\"");
  $top->Unbusy;
  return 1;
};



#sub set_e0 {
#  Echo("No data"), return unless ($current);
#  $groups{$current}->make(bkg_e0=>$_[0], update_bkg=>1);
#  &set_properties(0, $current);
#  &Echo("E0 reset to the atomic value for the $_[2] edge of $_[1].")
#};


sub tie_reference {
  Echo("No data!"), return unless $current;
  my ($n, @g) = (0, ());
  foreach my $k (keys %marked) {
    if ($marked{$k}) {
      ++$n;
      push @g, $k;
    };
  };
  Error("You need exactly two marked groups to tie data and reference channel"), return unless ($n == 2);
  Echo("You cannot tie \"$groups{$g[0]}->{label}\".  It's a frozen group."), return if $groups{$g[0]}->{frozen};
  Echo("You cannot tie \"$groups{$g[1]}->{label}\".  It's a frozen group."), return if $groups{$g[1]}->{frozen};
  $groups{$g[0]} -> make(reference=>$g[1]);
  $groups{$g[1]} -> make(reference=>$g[0]);
  set_properties(1, $current, 0);
  project_state(0);
};


## refresh some display elements without calling set_properties
## again. also perform any chores that need attention as normal course
## of plotting. currently this is used to update the display of the
## edge step after redoing a background removal and to perform a
## memory check
sub refresh_properties {
  if ($groups{$current}->{is_xmu}) {
    $widget{bkg_step} -> configure(-validate=>'none', -state=>'normal');
    $widget{bkg_step} -> delete(qw/0 end/);
    $widget{bkg_step} -> insert(0, $groups{$current}->{bkg_step});
    $widget{bkg_step} -> configure(-validate=>'key', -state=>($groups{$current}->{frozen}) ? 'disabled' : 'normal');
    ## $widget{bkg_step} -> configure(-text=>sprintf "%.2f", $groups{$current}->{bkg_step});
  };
  my $memory_ok = $groups{$current}->memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};


sub change_record {
  Echo("Change record type");
  my $d = $top->DialogBox(-title   => "Artemis: change record type",
			  -buttons => ["mu(E)", "xanes", "norm(E)", "detector", "Cancel"],
			  -popover => 'cursor');
  my $how = $groups{$current}->{frozen} ? 'marked' : "this";
  $d -> add('Radiobutton',
	    -variable	=> \$how,
	    -value	=> "this",
	    -text	=> "Change record type of \"$groups{$current}->{label}\" to:",
	    -font	=> $config{fonts}{large},
	    -foreground	=> $config{colors}{activehighlightcolor},)
    -> pack(-anchor=>'w');
  $d -> add('Radiobutton',
	    -variable	=> \$how,
	    -value	=> "marked",
	    -text	=> "Change record type of marked groups to:",
	    -font	=> $config{fonts}{large},
	    -foreground	=> $config{colors}{activehighlightcolor},)
    -> pack(-anchor=>'w');

  my $this = $d -> Show();
  my $add = "";
  Echo("Not changing record type"), return if ($this eq 'Cancel');
  if ($how eq 'this') {
    Echo("Not changing record type, \"$groups{$current}->{label}\" is frozen."), return if ($groups{$current}->{frozen});
    if ($this eq "mu(E)") {
      $groups{$current} -> make(is_xmu=>1, is_xanes=>0, is_nor=>0, not_data=>0, update_bkg=>1);
    } elsif ($this eq "xanes") {
      $groups{$current} -> make(is_xmu=>1, is_xanes=>1, is_nor=>0, not_data=>0, update_bkg=>1);
    } elsif ($this eq "norm(E)") {
      $groups{$current} -> make(is_xmu=>1, is_xanes=>0, is_nor=>1, not_data=>0, update_bkg=>1);
    } elsif ($this eq "detector") {
      $groups{$current} -> make(is_xmu=>0, is_xanes=>0, is_nor=>0, not_data=>1, update_bkg=>1);
    };
    if ($groups{$current}->{reference}) {
      my $ref = $groups{$current}->{reference};
      if ($this eq "mu(E)") {
	$groups{$ref} -> make(is_xmu=>1, is_xanes=>0, is_nor=>0, not_data=>0, update_bkg=>1);
      } elsif ($this eq "xanes") {
	$groups{$ref} -> make(is_xmu=>1, is_xanes=>1, is_nor=>0, not_data=>0, update_bkg=>1);
      } elsif ($this eq "norm(E)") {
	$groups{$ref} -> make(is_xmu=>1, is_xanes=>0, is_nor=>1, not_data=>0, update_bkg=>1);
      } elsif ($this eq "detector") {
	$groups{$ref} -> make(is_xmu=>0, is_xanes=>0, is_nor=>0, not_data=>1, update_bkg=>1);
      };
      $add = " and reference";
    };
    Echo("Changed \"$groups{$current}->{label}\"$add to $this");
  } elsif ($how eq 'marked') {
    foreach my $g (keys (%marked)) {
      next unless $marked{$g};
      next if ($groups{$g}->{frozen});
      if ($this eq "mu(E)") {
	$groups{$g} -> make(is_xmu=>1, is_xanes=>0, is_nor=>0, not_data=>0, update_bkg=>1);
      } elsif ($this eq "xanes") {
	$groups{$g} -> make(is_xmu=>1, is_xanes=>1, is_nor=>0, not_data=>0, update_bkg=>1);
      } elsif ($this eq "norm(E)") {
	$groups{$g} -> make(is_xmu=>1, is_xanes=>0, is_nor=>1, not_data=>0, update_bkg=>1);
      } elsif ($this eq "detector") {
	$groups{$g} -> make(is_xmu=>0, is_xanes=>0, is_nor=>0, not_data=>1, update_bkg=>1);
      };
      if ($groups{$g}->{reference}) {
	my $ref = $groups{$g}->{reference};
	if ($this eq "mu(E)") {
	  $groups{$ref} -> make(is_xmu=>1, is_xanes=>0, is_nor=>0, not_data=>0, update_bkg=>1);
	} elsif ($this eq "xanes") {
	  $groups{$ref} -> make(is_xmu=>1, is_xanes=>1, is_nor=>0, not_data=>0, update_bkg=>1);
	} elsif ($this eq "norm(E)") {
	  $groups{$ref} -> make(is_xmu=>1, is_xanes=>0, is_nor=>1, not_data=>0, update_bkg=>1);
	} elsif ($this eq "detector") {
	  $groups{$ref} -> make(is_xmu=>0, is_xanes=>0, is_nor=>0, not_data=>1, update_bkg=>1);
	};
      };
    };
    Echo("Changed marked groups to $this");
  };
  set_properties(0, $current, 0);
  project_state(0);
};

sub freeze {
  my $how = $_[0];
  my $message;
 SWITCH: {
    ($how eq 'this') and do {	# toggle this group
      my $verb = $groups{$current}->{frozen} ? 'Unfroze' : 'Froze';
      ($groups{$current}->{frozen}) ? $groups{$current}->unfreeze : $groups{$current}->freeze;
      freeze_chores($current);
      $message = "$verb \"$groups{$current}->{label}\"";
      last SWITCH;
    };
    ($how eq 'all') and do {	# freeze all groups
      map {$groups{$_} -> freeze; freeze_chores($_)} (keys (%marked));
      $message = "Froze all groups";
      last SWITCH;
    };
    ($how eq 'none') and do {	# unfreeze all groups
      map {$groups{$_} -> unfreeze; freeze_chores($_)} (keys (%marked));
      $message = "Unfroze all groups";
      last SWITCH;
    };
    ($how eq 'toggle') and do {	# toggle all groups frozen-ness
      map {($groups{$_}->{frozen}) ? $groups{$_}->unfreeze : $groups{$_}->freeze; freeze_chores($_)} (keys (%marked));
      $message = "Toggled frozenness of all groups";
      last SWITCH;
    };
    ($how eq 'marked') and do {	# freeze marked groups
      map {$groups{$_}->freeze if $marked{$_}; freeze_chores($_) } (keys (%marked));
      $message = "Froze marked groups";
      last SWITCH;
    };
    ($how eq 'unmarked') and do { # unfreeze marked groups
      map {$groups{$_}->unfreeze if $marked{$_}; freeze_chores($_) } (keys (%marked));
      $message = "Unfroze marked groups";
      last SWITCH;
    };
    ($how =~ 'regex') and do {	# freeze/unfreeze groups with labels matching regex
      my $regex = "";
      my $what = ($how eq 'regex') ? 'Freeze' : 'Unfreeze';
      my $label = "$what all groups matching this perl regular expression: ";
      my $dialog = get_string($dmode, $label, \$regex, \@regex_history);
      $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
				# then we can move on...
      Echo("Aborting regex matching."), return if ($regex =~ /^\s*$/);
      my $given = $regex;
      my $re;
      if ($config{general}{match_as} eq 'perl') {
	my $is_ok = eval '$re = qr/$regex/i';
	Error("Oops!  \"$regex\" is not a valid regular expression"), return unless $is_ok;
      } else {
	$regex = glob_to_regex($given);
      };
      if ($how eq 'regex') {
	map { $groups{$_}->freeze if ($groups{$_}->{label} =~ /$regex/); freeze_chores($_)} keys %marked;
      } else {
	map { $groups{$_}->unfreeze if ($groups{$_}->{label} =~ /$regex/); freeze_chores($_)} keys %marked;
      };
      push @regex_history, $given;
      $what = ($how eq 'regex') ? 'Froze' : 'Unfroze';
      $message = "$what all groups matching /$given/";
      last SWITCH;
    };
  };
  set_properties(1, $current, 0);
  project_state(0);
  Echo($message);
};

## this is always called *after* the group is (un)frozen
sub freeze_chores {
  my $which = $_[0];
  my @normal = (-fill => $config{colors}{foreground},
		-font => $config{fonts}{med});
  my @frozen = (-fill => $config{colors}{foreground},
		-font => $config{fonts}{medit});
  my $tag = $groups{$which}->{bindtag};
  ## toggle the font for a group list entry for freezing/unfreezing
  if ($groups{$which}->{frozen}) { # make the text the frozen color
    $list -> itemconfigure($groups{$which}->{text}, @frozen);
    $list -> bind($tag, '<Any-Leave>'=>sub{my $this = shift; $this->itemconfigure('current', @frozen); Leave($this)});
  } else {			   # make the text the normal color
    $list -> itemconfigure($groups{$which}->{text}, @normal);
    $list -> bind($tag, '<Any-Leave>'=>sub{my $this = shift; $this->itemconfigure('current', @normal); Leave($this)});
  };
  ## freeze/unfreeze the referent
  if ($groups{$which}->{reference}) {
    if ($groups{$which}->{frozen}) {
      $groups{$groups{$which}->{reference}} -> freeze;
    } else {
      $groups{$groups{$which}->{reference}} -> unfreeze;
    };
  };
};

sub about_group {
  about_marked_groups({$current=>1});
};
sub about_marked_groups {
  my $r_marked = $_[0];
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my $message = q{};
  my @list = sort {($list->bbox($groups{$a}->{text}))[1] <=>
		     ($list->bbox($groups{$b}->{text}))[1]} (keys (%$r_marked));
  foreach my $k (@list) {
    next unless ($$r_marked{$k});
    $message .= "\n\n"   . &identify_group($k);
    $message .= "\n\n" . &group_stats($k);
    $message .= "\n\n" . sprintf("epsilon_k=%.5f, epsilon_R=%.5f, recommended kmax=%.3f", $groups{$k}->chi_noise());
    $message .= "\n\n" . &show_mu_str unless $groups{$k}->{is_merge};
    $message .= "\n\n" . &nknots($k) if ($groups{$k}->{is_xmu} and not $groups{$k}->{is_xanes});
    $message .= "\n\n" . &groupIndex($k);
    $message .= "\n\n" . "This group is tied to \"" . $groups{$groups{$k}->{reference}}->{label} . "\"" if $groups{$k}->{reference};
    $message .= "\n\nThis groups is frozen.\n" if $groups{$k}->{frozen};
    $message .= "\n\n" . "-" x 60;
  };
  $message =~ s/^\n//;
  $message =~ s/-+$//;
  $message .= "\n\n";
  my $dialog =
    $top -> DialogBox(-title          => 'Athena: About groups',
		      -buttons        => [qw/OK/],
		      -default_button => 'OK');
  my $txt = $dialog -> Scrolled("ROText",
				-width=>60,
				-height=>12,
				-wrap=>'word',
				-scrollbars=>'oe',
			       ) -> pack(-fill=>'y', -expand=>1);
  $txt -> Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
  $txt -> tagConfigure("text", -font=>$config{fonts}{fixedsm});
  $txt -> insert('end', $message, 'text');
  disable_mouse3($txt);
  my $response = $dialog->Show();
};



sub identify_group {
  Echo("No data"), return unless ($current);
  my $this = $_[0] || $current;
  my $message;
  my $group = $groups{$this}->{group};
  my $label = "\"" . $groups{$this}->{label} . "\"";
  SWITCH: {
      my $what = "";
      ($groups{$this}->{is_merge}) and ($what  = " merged");
      ($groups{$this}->{is_diff})  and ($what .= " difference");
      ($groups{$this}->{is_pixel}) and ($what .= " pixel");

      ($groups{$this}->{not_data}) and do {
	$message = "$label is a detector or peak fit record.  It can be plotted only in energy.";
	last SWITCH;
      };
      ($groups{$this}->{is_xanes}) and do {
	$message = "$label is a$what xanes record.  It can be plotted only in energy.";
	last SWITCH;
      };
      ($groups{$this}->{is_nor}) and do {
	$message = "$label is a$what normalized mu(E) record.  It can be plotted in any space.";
	last SWITCH;
      };
      ($groups{$this}->{is_bkg}) and do {
	$message = "$label is a$what background record.  It can be plotted in any space.";
	last SWITCH;
      };
      ($groups{$this}->{is_xmu}) and do {
	$message = "$label is a$what mu(E) record.  It can be plotted in any space.";
	last SWITCH;
      };
      ($groups{$this}->{is_chi}) and do {
	$message = "$label is a$what chi(k) record.  It can be plotted in k-, R-, or q-space.";
	last SWITCH;
      };
      ($groups{$this}->{is_rsp}) and do {
	$message = "$label is a$what chi(R) record.  It can be plotted in R- or q-space.";
	last SWITCH;
      };
      ($groups{$this}->{is_qsp}) and do {
	$message = "$label is a$what chi(q) record.  It can be plotted only in q-space.";
	last SWITCH;
      };
    };
  ##Echo($message . "  It's group name is \"" . $group . "\"");
  return $message . "  It's group name is \"" . $group . "\"";
};

sub group_stats {
  Echo("No data"), return unless ($current);
  my $this = $_[0] || $current;
  my $message;
  my $group = $groups{$this}->{group};
  SWITCH: {
      ($groups{$this}->{not_data}) and do {
	my @x = Ifeffit::get_array($group.".energy");
	$message = sprintf "This detector or peak fit record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_xanes}) and do {
	my @x = Ifeffit::get_array($group.".energy");
	$message = sprintf "This xanes record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_nor}) and do {
	my @x = Ifeffit::get_array($group.".energy");
	$message = sprintf "This normalized mu(E) record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_bkg}) and do {
	my @x = Ifeffit::get_array($group.".energy");
	$message = sprintf "This background record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_xmu}) and do {
	my @x = Ifeffit::get_array($group.".energy");
	$message = sprintf "This mu(E) record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_chi}) and do {
	my @x = Ifeffit::get_array($group.".k");
	$message = sprintf "This chi(k) record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_rsp}) and do {
	my @x = Ifeffit::get_array($group.".r");
	$message = sprintf "This chi(R) record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
      ($groups{$this}->{is_qsp}) and do {
	my @x = Ifeffit::get_array($group.".q");
	$message = sprintf "This chi(q) record has %d points from %.3f to %.3f",
	  $#x+1, $x[0], $x[$#x];
	last SWITCH;
      };
    };
  ##Echo($message);
  return $message;
};

sub show_mu_str {
  my $mu_str = $groups{$current}->{mu_str};
  $mu_str =~ s/$current\.//g;
  $mu_str =~ s/\(/( /g;
  $mu_str =~ s/\)/ )/g;
  ##Echo($groups{$current}->{label} . ": mu(E) was constructed from columns as: $mu_str");
  return "mu(E) was constructed from columns as: $mu_str";
};


sub nknots {
  my $this = $_[0] || $current;
  my $kmin   = $groups{$this}->{bkg_spl1};
  my $kmax   = $groups{$this}->{bkg_spl2};
  my $deltak = $kmax - $kmin;
  my $nidp   = int( 2 * $deltak * $groups{$this}->{bkg_rbkg} / PI ) + 1;
  my $label  = $groups{$this}->{label};
  return "\"$label\" uses $nidp spline knots (evenly spaced in k between $kmin and $kmax, inclusive)";
  ##Echo("\"$label\" uses $nidp spline knots (evenly spaced in k between $kmin and $kmax, inclusive)");
};

sub groupIndex {
  my $i = 1;
  foreach my $g (&sorted_group_list) {
    return "\"$groups{$g}->{label}\" is item number $i in the groups list." if ($g eq $_[0]);
    ++$i;
  };
}


sub sorted_group_list {
  my @list = sort {($list->bbox($groups{$a}->{text}))[1] <=>
		     ($list->bbox($groups{$b}->{text}))[1]} (keys (%marked));
  return @list;
};

## END OF GROUP OPERATIONS SUBSECTION
##########################################################################################
