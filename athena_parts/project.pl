## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  writing project files


sub save_project {
  Echo('No data!'), return unless ($current);
  my $save = lc($_[0]);
  if ($save eq 'marked') {
    my $m = 0;
    map {$m += $_} values %marked;
    Error("Saving marked groups aborted.  There are no marked groups."), return 1 unless ($m);
  };
  my $file;
  my $curr = $current;
  my $how  = 2;
  if (($save ne 'all quick') or ($project_name =~ /^\s*$/)) {
    my $path = $current_data_dir || Cwd::cwd;
    my $init = 'athena.prj';
    if ($project_name !~ /^\s*$/) {
      my $suff;
      ($init, $path, $suff) = fileparse($project_name);
    };
    local $Tk::FBox::a;
    local $Tk::FBox::b;
    my $types = [['Athena project files', '.prj'],
		 ['All Files', '*'],];
    $file = $top -> getSaveFile(-defaultextension=>'.prj',
				-filetypes=>$types,
				#(not $is_windows) ?
				#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-initialfile=>$init,
				-title => "Athena: Save project");
    return unless $file;
    #my ($name, $pth, $suffix) = fileparse($file);
    #$current_data_dir = $pth;
    if ($save eq 'marked') {
      &push_mru($file, 1, 0);
    } else {
      &push_mru($file, 1, 1, 1);
    };
  } else {
    $file = $project_name;
  };
  ##open REC, '>'.$file or die $!;
  open REC, '>'.$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  $top -> Busy(-recurse=>1,);
  local $| = 1;
  print REC "# Athena project file -- Athena version $VERSION\n";
  print REC $groups{$current} -> project_header;
  close REC;
  my $save_groupreplot = $config{general}{groupreplot};
  $config{general}{groupreplot} = 'none';
  my @keys = &sorted_group_list;
  foreach (@keys) {
    next if ($_ eq "Default Parameters");
    next if (($save eq 'marked') and (not $marked{$_}));
    set_properties(0, $_, 1);
    save_record($file, $how++, 0, $save);
  };
  open REC, '>>'.$file or die $!;
  my $journal = $notes{journal} -> get(qw(1.0 end));
  my $eol = $/;
  my $colon = ":";
  my $end = "End";
  my $lv = ucfirst("local ");
  my @journal = split(/$eol/, $journal);
  print REC Data::Dumper->Dump([\@journal], [qw/*journal/]), "\n\n";
  print REC Data::Dumper->Dump([\%plot_features], [qw/*plot_features/]), "\n\n";
  my @indic = (0);
  foreach (1 .. $#indicator) {
    push @indic, ["", $indicator[$_]->[1], $indicator[$_]->[2]]
  };
  print REC Data::Dumper->Dump([\@indic], [qw/*indicator/]), "\n\n";
  print REC Data::Dumper->Dump([\%lcf_data], [qw/*lcf_data/]), "\n\n";
  $lv .= "Var" . "iables";
  print REC "\n1;\n\n# $lv$colon\n# truncate-lines$colon t\n# End$colon\n";
  close REC;
  if ($config{general}{compress_prj}) {
    Echo("Compressing $file");
    my $stash = File::Spec->catfile($stash_dir, basename($file));
    move($file, $stash);
    my $gz    = gzopen($stash, 'rb');
    my $gzout = gzopen($file, 'wb9');
    my $buffer;
    $gzout->gzwrite($buffer) while $gz->gzread($buffer) > 0 ;
    $gz->gzclose;
    $gzout->gzclose;
    unlink $stash;
  };
  set_properties(1, $curr, 1);
  $config{general}{groupreplot} = $save_groupreplot;
  project_state(1) unless ($save eq 'marked');
  ($save =~ /all/)    and Echo("Saved entire project to $file", 0);
  ($save eq 'marked') and Echo("Saved all marked groups to $file", 0);
  $top->Unbusy;
};

sub read_record {
  my ($plot, $file, $old_group, $ra, $rx, $ry, $rstddev, $ri0) = @_;
  my $gp = "";
  my @args = @$ra; my @x = @$rx; my @y = @$ry; my @stddev = @$rstddev; my @i0 = @$ri0;

  ## deal with backward compatibility issues in the parameters
  ##
  ## need to accommodate the change to (groupname != listentry) in
  ## 0.8.009 without breaking old project files.  search ahead in
  ## @args for the label string and use it, if found.  otherwise use
  ## the old group name as the argument to group_name
  ##
  ## there is a chance that a project file comes from a version of
  ## athena between when I introduced peak fitting and when I made the
  ## main window modal.  I need to check that values of "fit
  ## amplitude" and "set amplitude" (from peak fitting) are changed to
  ## "fit amp."  and "set amp."
  ##
  ## then in 0.8.028 I change "arctangent" to "atan" and so on.
  my $old_label = $old_group;
  my $is_frozen = 0;
  foreach (0 .. $#args) {
    next unless defined $args[$_]; # undef is a possible value in @args
    if ($args[$_] eq 'label') {
      $old_label = $args[$_+1];
      next;
    } elsif ($args[$_] =~ /(fit|set) amplitude(.*)/) {
      $args[$_] = $1 . " amp." . $2;
    } elsif ($args[$_] =~ /peak_step/) { # this is to accommodate a
      $args[$_] =~ s/step/function/;     # small change to peakfitting
    				         # for 0.8.018
    } elsif (lc($args[$_]) =~ /arctangent/) {
      $args[$_] = 'atan';
    } elsif (lc($args[$_]) =~ /error/) {
      $args[$_] = 'erf';
    } elsif (lc($args[$_]) =~ /gauss/) {
      $args[$_] = 'gauss';
    } elsif (lc($args[$_]) =~ /loren/) {
      $args[$_] = 'loren';
    } elsif ($args[$_] eq 'frozen') { # need to turn off frozen-ness until the
      $is_frozen = $args[$_+1];       # record is imported
      $args[$_+1] = 0;
    };
  };

  my ($group, $label) = group_name($old_label);
  $label =~ s{[\"\']}{}g;
  ++$line_count;
  $groups{$group} = Ifeffit::Group -> new(file=>$file, group=>$group, label=>$label);
  $groups{$group} -> make(@args);
  $groups{$group} -> make(line=>$line_count, old_group=>$old_group);
  $groups{$group} -> make(is_rec=>1, is_raw=>0, update_bkg=>1, is_proj=>1);
  $groups{$group} -> make(i0 => "$group.i0") if (@i0);
  $groups{$group} -> put_titles;
  my ($x, $y, $z) = (0, 0, 0);
 SWITCH: {
    ($x,$y)    = ('.energy', '.det'),            last SWITCH if $groups{$group}->{not_data};
    ($x,$y)    = ('.energy', '.xmu'),            last SWITCH if $groups{$group}->{is_xmu};
    ($x,$y)    = ('.k',      '.chi'),            last SWITCH if $groups{$group}->{is_chi};
    ($x,$y,$z) = ('.r', '.chir_re', '.chir_im'), last SWITCH if $groups{$group}->{is_rsp};
    ($x,$y,$z) = ('.q', '.chiq_re', '.chiq_im'), last SWITCH if $groups{$group}->{is_qsp};
  };
  Ifeffit::put_array($group.$x, \@x);
  Ifeffit::put_array($group.$y, \@y);
  Ifeffit::put_array("$group.stddev", \@stddev) if (@stddev);
  Ifeffit::put_array("$group.i0",     \@i0)     if (@i0);
  ##($z) and Ifeffit::put_array($group.$z, \@z);

  ## fill_skinny unsets this parameter and it needs to be dealt with
  ## after the entire project is read
  my $save_stan = $groups{$group}->{bkg_stan};
  fill_skinny($list, $group, 1);
  $groups{$group}->make(bkg_stan=>$save_stan);
  if ($is_frozen) { # turn frozen-ness back on
    $groups{$group}->freeze;
    freeze_chores($group);
  };
  ($gp) or ($gp = $group);
  return $group unless $plot;
				# what about reading r or q records?
 SWITCH: {
    ($groups{$gp}->{is_xmu}) and do {
      $groups{$gp} -> plotE('emz',$dmode,\%plot_features, \@indicator);
      $last_plot = 'e';
      $last_plot_params = [$gp, 'group', 'e', 'emz'];
      last SWITCH;
    };
    ($groups{$gp}->{is_chi}) and do {
      #my $str = sprintf('k%1d', $groups{$gp}->{fft_kw});
      my $str = sprintf('k%1d', $plot_features{kw});
      $groups{$gp} -> plotk($str,$dmode,\%plot_features, \@indicator);
      $last_plot = 'k';
      $last_plot_params = [$gp, 'group', 'k', $str];
      last SWITCH;
    };
  };
  return $group;
};


## the call to save_record takes three arguments:
##  1st: filename or nil to prompt for filename
##  2nd: 0=open file to overwite, 1=open file to append
##  3rd: 0=save record as record type, 1=force saving as chi(k)

## save a record as a Data::Dumper file.  This contains four lvalues,
## 1) the group name from this session, 2) an array of parameters, 3)
## an x-array, 4) a y-array.  The x- and y-arrays are appropriate to
## the initial state of the data (i.e. the intial state of raw data is
## energy/xmu and the initial state of merged chi(k) data is k/chi).
sub save_record {
  Echo('No data!'), return unless ($current);
  Echo("Saving records is unsupported for R- and q-space data", 0), return
    if (($groups{$current}->{is_rsp}) or ($groups{$current}->{is_qsp}));
  Echonow("Saving record for group \"$groups{$current}->{label}\"", 0);
  my ($file, $how, $force_chik, $save) = @_;
  #my $how = ((defined $_[1]) and $_[1]) ? $_[1] : 0;
  #if (defined $_[0] and  $_[0]) {
  #  $file = $_[0]; # File::Spec->catfile($current_data_dir, $_[0].".rec");
  #} else {
  unless ($file) {
    local $Tk::FBox::a;
    local $Tk::FBox::b;
    my $path = $current_data_dir || Cwd::cwd;
    my $fname = ($force_chik) ? $current . "_chik.rec" : "$current.rec";
    my $types = [['Athena record files', '.rec'],
		 ['All Files', '*'],];
    $file = $top -> getSaveFile(-defaultextension=>'rec',
				-filetypes=>$types,
				#(not $is_windows) ?
				#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-initialfile=>$fname,
				-title => "Athena: Save record");
    Echonow("Saving record for group \"$groups{$current}->{label}\" ... canceled", 0), return
      unless $file;
    my ($name, $pth, $suffix) = fileparse($file);
    $current_data_dir = $pth;
    ##&push_mru($file, 1);
  };
  refresh_titles($groups{$current}); # make sure titles are up-to-date
  my @args = ();
  foreach (sort keys(%{$groups{$current}})) {
    next if ($_ =~ /\b([ex]col|check(button)?|group|id|rect|text)\b/);
    next if ($_ eq 'made_pixel');
    next if ($_ =~ /^update/);
    next if ($_ eq "project_marked");
    ##next if ($_ =~ /^title/);
    if (($save eq 'marked') and ($_ eq 'reference') and ($groups{$current}->{reference})) {
      my $ref = $groups{$current}->{reference};
      next unless $marked{$ref};
    };
    push @args, $_, $groups{$current}->{$_};
  };
  push @args, "project_marked", $marked{$current};
  ## need to update from titles palette
  ## my @titles = @{$groups{$current}->{titles}};
  my (@x, @y, @z, @stddev, @i0);
 SWITCH: {
    ($force_chik) and do {
      $groups{$current}->dispatch_bkg($dmode) if $groups{$current}->{update_bkg};
      @x = Ifeffit::get_array($current.".k");
      @y = Ifeffit::get_array($current.".chi");
      ## need to flag this as a chi record -- appending new values to
      ## the end of @args is cheesy, but it works
      push @args, qw(is_chi 1 is_bkg 0 is_xmu 0 is_nor 0 is_merge 0);
      last SWITCH;
    };
    ($groups{$current}->{not_data}) and do {
      @x = Ifeffit::get_array($current.".energy");
      ## @x = map {$_ + $groups{$current}->{bkg_eshift}} @x;
      @y = Ifeffit::get_array($current.".det");
      last SWITCH;
    };
    ($groups{$current}->{is_xmu}) and do {
      @x = Ifeffit::get_array($current.".energy");
      ## @x = map {$_ + $groups{$current}->{bkg_eshift}} @x;
      @y = Ifeffit::get_array($current.".xmu");
      @i0 = Ifeffit::get_array($groups{$current}->{i0}) if ($groups{$current}->{i0});
      last SWITCH;
    };
    ($groups{$current}->{is_chi}) and do {
      @x = Ifeffit::get_array($current.".k");
      @y = Ifeffit::get_array($current.".chi");
      last SWITCH;
    };
    ($groups{$current}->{is_rsp}) and do {
      @x = Ifeffit::get_array($current.".r");
      @y = Ifeffit::get_array($current.".chir_re");
      @z = Ifeffit::get_array($current.".chir_im");
      last SWITCH;
    };
    ($groups{$current}->{is_qsp}) and do {
      @x = Ifeffit::get_array($current.".q");
      @y = Ifeffit::get_array($current.".chiq_re");
      @z = Ifeffit::get_array($current.".chiq_im");
      last SWITCH;
    };
  };
  ## what about chi(k) records with stddev???
  if ((not $force_chik) and $groups{$current}->{is_merge}) {
    @stddev = Ifeffit::get_array($current.".stddev");
  };
  my $open = ($how > 1) ? '>>' : '>';
  my $arg = (($how == 0) or ($how == 2)) ? 1 : 0;
  open REC, $open.$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  ($how) or print REC "# Athena record file -- Athena version $VERSION\n";
  ($how) or print REC $groups{$current} -> project_header();
  print REC
    Data::Dumper->Dump([$current], [qw/old_group/]), "\n",
    Data::Dumper->Dump([\@args],   [qw/*args/]),     "\n",
    Data::Dumper->Dump([\@x],      [qw/*x/]),        "\n",
    Data::Dumper->Dump([\@y],      [qw/*y/]),        "\n";
  print REC Data::Dumper->Dump([\@stddev],[qw/*stddev/]), "\n" if @stddev;
  print REC Data::Dumper->Dump([\@i0],    [qw/*i0/]),     "\n" if $groups{$current}->{i0};
  print REC "[record]   # create object and set arrays in ifeffit\n\n";
  unless ($how) {

    my $colon = ":";
    my $end = "End";
    my $lv = ucfirst("local ");
    $lv .= "Var" . "iables";
    print REC "\n1;\n\n# $lv$colon\n# truncate-lines$colon t\n# End$colon\n";
  };
  close REC;
  Echonow("Wrote record to $file", 0);
};


sub close_project {
  reset_window($which_showing, $fat_showing, 0) unless ($fat_showing eq 'normal');
  delete_many($list, $dmode, 0);
  project_state(1);
  $plot_features{project} = q{};
};

sub clear_project_name {
  $plot_features{project} = q{};
  $project_name = q{};
  project_state(0);
};

## state=0 -> project needs to be saved  state=1 -> project has been saved
sub project_state {
  return unless $current;
  ##$_[0] || print join(" ", caller), $/;
  $project_saved = $_[0];
  $lab -> configure(-text   => ($_[0]) ? "" : "modified",);
  return if ($current eq "Default Parameters");
  autoreplot() if $config{general}{autoreplot};
  section_indicators();
};


sub examine_project {
  my ($prjfile, $r_hash, $r_cancel, $r_project_no_prompt) = @_;
  my @athena_index  = ();
  my @athena_groups = ();
  my $titles;

  my $prj = $top->Toplevel(-class=>'horae');
  $prj -> withdraw;
  $prj -> title("Athena: import from project file");
  $prj -> protocol(WM_DELETE_WINDOW => sub{$$r_cancel = 1; $prj->destroy; return});
  $prj -> packPropagate(1);
  $prj -> bind('<Control-q>' => sub{$$r_cancel = 1; $prj->destroy; return});
  $prj -> bind('<Control-d>' => sub{$$r_cancel = 1; $prj->destroy; return});

  $prj -> Label(-text       => $prjfile,
		-foreground => $config{colors}{activehighlightcolor},
		-font       => $config{fonts}{bold},
		-borderwidth=> 2,
		-relief     => 'ridge',
	       )
    -> pack(-side=>'top', -fill=>'x', -padx=>0, -pady=>0);

  my $labframe = $prj -> LabFrame(-label=>'Project groups',
				  -labelside=>'acrosstop',
				  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left', -expand=>1, -fill=>'both', -anchor=>'w');

  my $hlist;
  $hlist = $labframe -> Scrolled('HList',
				 -scrollbars	   => 'osoe',
				 -columns	   => 1,
				 -header	   => 0,
				 -selectmode	   => 'extended',
				 -width		   => 25,
				 -height	   => 30,
				 -background	   => $config{colors}{hlist},
				 #-highlightcolor => $config{colors}{hlist},
				 -selectbackground => $config{colors}{current},
				 -browsecmd	   =>
				 sub {
				   ## only plot if this selection is
				   ## also the anchor
				   return if $hlist->info('anchor') ne $_[0];
				   project_plot($hlist, $titles, $prjfile);
				 },
				)
    -> pack(-expand=>1, -fill=>'both');
  $hlist->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					     ($is_windows) ? () : (-width=>8));
  $hlist->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					     ($is_windows) ? () : (-width=>8));
  BindMouseWheel($hlist);

  my $fr = $prj -> Frame()
    -> pack(-side=>'right', -expand=>1, -fill=>'both', -anchor=>'n');
  $labframe = $fr -> LabFrame(-label=>'Journal',
			      -labelside=>'acrosstop',
			      -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'both', -padx=>0, -pady=>0);
  my $journal =  $labframe -> Scrolled('ROText',
				       -scrollbars => 'osoe',
				       -wrap       => 'none',
				       -height     => 12,)
    -> pack(-expand=>1, -fill=>'both');
  $journal->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					       ($is_windows) ? () : (-width=>8));
  $journal->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
					       ($is_windows) ? () : (-width=>8));
  $journal -> tagConfigure("text", -font=>$config{fonts}{fixedsm});
  BindMouseWheel($journal);
  disable_mouse3($journal->Subwidget("rotext"));

  ## selection buttons
  my $button_frame = $fr -> LabFrame(-label=>'Select groups',
				     -labelside=>'acrosstop',
				     -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -expand=>1, -fill=>'x', -padx=>0, -pady=>0);
  $button_frame -> Button(-text	       => "All",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     => sub{ $hlist->selectionSet(@athena_index[0,-1]) },
			 )
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);
  $button_frame -> Button(-text	       => "None",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     => sub{{$hlist->selectionClear();
					       $hlist->anchorClear();} },
			 )
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);
  $button_frame -> Button(-text	       => "Invert",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     =>
			  sub{
			    foreach my $i (@athena_index) {
			      ($hlist->selectionIncludes($i)) ?
				$hlist->selectionClear($i) :
				  $hlist->selectionSet($i);
			    };
			  },
			 )
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);

  $labframe = $fr -> LabFrame(-label	  => 'Selected group titles',
			      -labelside  => 'acrosstop',
			      -foreground => $config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -expand=>1, -fill=>'both', -padx=>0, -pady=>0);
  $titles =  $labframe -> Scrolled('ROText',
				   -scrollbars => 'osoe',
				   -wrap       => 'none',
				   -height     => 12,)
    -> pack(-expand=>1, -fill=>'both');
  $titles -> Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
						($is_windows) ? () : (-width=>8));
  $titles -> Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
						($is_windows) ? () : (-width=>8));
  $titles -> tagConfigure("text",    -font=>$config{fonts}{fixedsm});
  $titles -> tagConfigure("explain", -font=>$config{fonts}{fixedsm}, -foreground=>$config{colors}{button});
  BindMouseWheel($titles);
  disable_mouse3($titles->Subwidget("rotext"));


  ## ok/cancel buttons
  $button_frame = $fr -> Frame()
    -> pack(-side=>'bottom', -fill=>'x', -padx=>0, -pady=>0);
  $button_frame -> Button(-text	       => "Import",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     =>
			  sub {
			    my $n_selected = 0;
			    ## import bkg removal standards as well
			    foreach my $i (@athena_index) {
			      next if not $hlist->selectionIncludes($i);
			      my %args = project_get_array($prjfile, $i, "args");
			      next if ($args{bkg_stan} eq 'None');
			      my $j = 0;
			      foreach my $og (@athena_groups) {
				if ($og eq $args{bkg_stan}) {
				  $hlist->selectionSet($athena_index[$j]);
				  last;
				};
				++$j;
			      };
			    };
			    foreach my $i (@athena_index) {
			      ++$n_selected if $hlist->selectionIncludes($i);
			    };
			    $hlist->selectionSet(@athena_index[0,-1]) if not $n_selected;
			    if (($n_selected == 0) or ($n_selected == $#athena_index+1)) {
			      $$r_project_no_prompt = 1;
			    };
			    my $c = 0;
			    foreach my $i (@athena_index) {
			      $$r_hash{$athena_groups[$c]} = ($hlist->selectionIncludes($i)) ? 1 : 0;
			      ++$c;
			    };
			    $$r_cancel = 0;
			    $prj->destroy;
			    return(());
			  },
			 )
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>4, -pady=>4)
      -> focus;
  $button_frame -> Button(-text	       => "Quick help",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     => sub{project_quick_help($titles)},
		)
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);
  $button_frame -> Button(-text	       => "Cancel",
			  @button_list,
			  -width       => 8,
			  -borderwidth => 1,
			  -command     => sub{$$r_cancel = 1; $prj->destroy; return(())},
			 )
    -> pack(-side=>'right', -expand=>1, -fill=>'x', -padx=>4, -pady=>4);


  my $athena_fh = gzopen($prjfile, "rb") or die "could not open $prjfile as an Athena project\n";

  my $nline = 0;
  my $line = q{};
  ##while (<ORIG>) {
  my $cpt = new Safe;
  my $bytesread;
 PRJ: while (($bytesread = $athena_fh->gzreadline($line)) > 0) {
    my $error = $athena_fh->gzerror;
    ++$nline;
    if ($line =~ /^\@journal/) {
      @ {$cpt->varglob('journal')} = $cpt->reval( $line );
      my @journal = @ {$cpt->varglob('journal')};
      map { $journal -> insert('end', $_."\n", 'text') } @journal;
    };
    ##print $bytesread, " ", $error, $/;
    if ( (($bytesread < 0) or $error) and ($gzerrno != Z_STREAM_END) ) {
      pop @athena_groups;
      pop @athena_index;
      project_error($titles, $error);
      Error("An error was found while reading \"$prjfile\".");
      last PRJ;
    };
    next unless ($line =~ /^\$old_group/);
    push @athena_index, $nline;
    $ {$cpt->varglob('old_group')} = $cpt->reval($line);
    my $old_group = $ {$cpt->varglob('old_group')};
    push @athena_groups, $old_group;
    $$r_hash{$old_group} = 0;
  };
  $athena_fh->gzclose();
  undef $cpt;

  foreach my $i (@athena_index) {
    my %args = project_get_array($prjfile, $i, "args");
    $args{label} =~ s{[\"\']}{}g;
    $hlist -> add($i, -data=>$i);
    $hlist -> itemCreate($i, 0, -text=>$args{label});
  };

  if ($$r_project_no_prompt) {
    $hlist->selectionSet(@athena_index[0,-1]);
    my $c = 0;
    foreach my $i (@athena_index) {
      $$r_hash{$athena_groups[$c]} = ($hlist->selectionIncludes($i)) ? 1 : 0;
      ++$c;
    };
    $$r_cancel = 0;
    $prj->destroy;
    return 0;
  } else {
    $prj->deiconify;
    $prj->raise;
  };
  return $prj;

};


sub project_error {
  my ($titles, $error) = @_;
  $titles->delete(qw(1.0 end));
  $titles->insert('end', "  !!! WARNING !!!\n", 'explain');
  my $message = "
An error has been encountered reading this project file.  It is
likely that the file has been corrupted in some way.  All data
after the point of failure has been excluded from the groups list.

The error returned by zlib is:
  $error
";
  $titles->insert('end', $message, 'explain');
};


sub project_get_array {
  my ($prjfile, $index, $which) = @_;
  my $cpt = new Safe;
  my @array;
  my $prj = gzopen($prjfile, "rb") or die "could not open $prjfile as an Athena project\n";
  ##open A, $prjfile;
  my $count = 0;
  my $found = 0;
  my $re = '@' . $which;
  my $line = q{};
  ##foreach my $line (<A>) {
  while ($prj->gzreadline($line) > 0) {
    ++$count;
    $found = 1 if ($count == $index);
    next unless $found;
    last if ($line =~ /^\[record\]/);
    if ($line =~ /^$re/) {
      @ {$cpt->varglob('array')} = $cpt->reval( $line );
      @array = @ {$cpt->varglob('array')};
      last;
    };
  };
  $prj->gzclose();
  ##close A;
  return @array;
};

sub project_plot {
  my ($hlist, $titles, $prjfile) = @_;
  $top -> Busy;
  my $n = $hlist->info('anchor');
  my $i = $hlist->info('data', $n);
  my ($xlabel, $ylabel) = ("Energy (eV)", "x\\gm(E)");

  ## get the args hash
  my %args = project_get_array($prjfile, $i, "args");
  if ($args{is_chi}) {
    ($xlabel, $ylabel) = ("wavenumber (\\A\\u-1\\d)", "\\gx(k)*k\\u2\\d" );
  } elsif ($args{not_data}) {
    ($xlabel, $ylabel) = ("Energy (eV)",              "data"             );
  } elsif ($args{is_bkg}) {
    ($xlabel, $ylabel) = ("Energy (eV)",              "background(E)"    );
  } elsif ($args{is_pixel}) {
    ($xlabel, $ylabel) = ("pixel",                    "x\\gm(E)"         );
  };

  ## fill titles
  $titles->configure(-foreground=>$config{colors}{foreground});
  $titles->delete(qw(1.0 end));
  foreach my $t (@{ $args{titles} }) {
    $titles->insert('end', $t."\n", 'text');
  };

  ## get the x- and y-axis arrays
  my @x = project_get_array($prjfile, $i, "x");
  @x = map {$_ + $args{bkg_eshift}} @x if not $args{is_chi};
  my @y = project_get_array($prjfile, $i, "y");
  Ifeffit::put_array("p___rj.x", \@x);
  Ifeffit::put_array("p___rj.y", \@y);
  my $plot = ($args{is_chi})	# plot k^2 weighted chi(k)
    ? "newplot(p___rj.x, \"p___rj.y*p___rj.x**2\","
     : "newplot(p___rj.x, p___rj.y,";
  $plot .= "        title=\"$args{label}\", color=blue,";
  $plot .= "        xlabel=\"$xlabel\", ylabel=\"$ylabel\")\n";

  Echo("Plotting group from project \"$args{label}\"");
  $groups{"Default Parameters"}->dispose($plot, $dmode);

  Echo("Plotting groups from project \"$args{label}\" ... done!");
  $top -> Unbusy;
}

sub project_quick_help {
  my ($titles) = @_;
  my @hints = ("Click on a group to select and plot.",
	       "Control-click to add a group to the selection.",
	       "Shift-click or click-drag to select multiple groups.",
	       "All groups will be imported if none are selected.",);

  $titles->delete(qw(1.0 end));
  $titles->insert('end', "\n", 'explain');
  foreach my $h (@hints) {
    $titles->insert('end', $h."\n\n", 'explain');
  };
};

sub section_indicators {
  return unless $current;
  return unless (exists $groups{$current});
  my ($blue, $cyan, $grey) = ($config{colors}{activehighlightcolor},
			      $config{colors}{requiresupdate},
			      $config{colors}{disabledforeground});
  #($blue, $cyan) = ($config{colors}{frozen}, $config{colors}{frozenrequiresupdate}) if $groups{$current}->{frozen};

 SWITCH:{
    ($groups{$current}->{is_xanes}) and do {
      $header{bkg} -> configure(-foreground=>($groups{$current}->{update_bkg}) ? $cyan : $blue);
      $header{bkg_secondary} -> configure(-foreground=>($groups{$current}->{update_bkg}) ? $cyan : $blue);
      $header{fft} -> configure(-foreground=>$grey);
      $header{bft} -> configure(-foreground=>$grey);
      last SWITCH;
    };
    ($groups{$current}->{is_xmu}) and do {
      $header{bkg} -> configure(-foreground=>($groups{$current}->{update_bkg}) ? $cyan : $blue);
      $header{bkg_secondary} -> configure(-foreground=>($groups{$current}->{update_bkg}) ? $cyan : $blue);
      $header{fft} -> configure(-foreground=>($groups{$current}->{update_fft}) ? $cyan : $blue);
      $header{bft} -> configure(-foreground=>($groups{$current}->{update_bft}) ? $cyan : $blue);
      last SWITCH;
    };
    ($groups{$current}->{is_chi}) and do {
      $header{bkg} -> configure(-foreground=>$grey);
      $header{bkg_secondary} -> configure(-foreground=>$grey);
      $header{fft} -> configure(-foreground=>($groups{$current}->{update_fft}) ? $cyan : $blue);
      $header{bft} -> configure(-foreground=>($groups{$current}->{update_bft}) ? $cyan : $blue);
      last SWITCH;
    };
    ($groups{$current}->{is_rsp}) and do {
      $header{bkg} -> configure(-foreground=>$grey);
      $header{bkg_secondary} -> configure(-foreground=>$grey);
      $header{fft} -> configure(-foreground=>$grey);
      $header{bft} -> configure(-foreground=>($groups{$current}->{update_bft}) ? $cyan : $blue);
      last SWITCH;
    };
    ($groups{$current}->{is_qsp}) and do {
      $header{bkg} -> configure(-foreground=>$grey);
      $header{bkg_secondary} -> configure(-foreground=>$grey);
      $header{fft} -> configure(-foreground=>$grey);
      $header{bft} -> configure(-foreground=>$grey);
      last SWITCH;
    };
    ($groups{$current}->{not_data}) and do {
      $header{bkg} -> configure(-foreground=>$grey);
      $header{bkg_secondary} -> configure(-foreground=>$grey);
      $header{fft} -> configure(-foreground=>$grey);
      $header{bft} -> configure(-foreground=>$grey);
      last SWITCH;
    };
  };

};

## END OF PROJECT FILE SUBSECTION
##########################################################################################
