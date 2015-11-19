# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### histogram import subsystem
###===================================================================

sub histogram {

  my $path = $_[0];
  my %histo_params = (this_path => $path,
		      this_feff => $current,
		      label => $config{histogram}{template},
		      position_column => $config{histogram}{position_column},
		      height_column => $config{histogram}{height_column},
		     );

  map {$_ -> configure(-state=>'disabled')}
    ($gsd_menu, $feff_menu, $paths_menu, $data_menu, $sum_menu, $fit_menu); #, $settings_menu);
 SWITCH: {
    $opparams->packForget(), last SWITCH if ($current_canvas eq 'op');
    $gsd     ->packForget(), last SWITCH if ($current_canvas eq 'gsd');
    $feff    ->packForget(), last SWITCH if ($current_canvas eq 'feff');
    $path    ->packForget(), last SWITCH if ($current_canvas eq 'path');
  };
  $current_canvas = 'histogram';
  my $histo = $fat -> Canvas(-relief=>'flat',
			       -borderwidth=>0,
			       @window_size,
			       -highlightcolor=>$config{colors}{background})
    -> pack();

  $histo -> packPropagate(0);



  $histo -> Label(-text=>"Histogram tool", @title2)
    -> pack(-side=>'top', -anchor=>'w', -padx=>6);

  $histo -> Button(-text=>'Return to the main window',  @button_list,
		     #-background=>$config{colors}{background},
		     #-activebackground=>$config{colors}{activebackground},
		     -command=>sub{
		       $histo->packForget;
		       $current_canvas = "";
		       &display_properties;
		       set_fit_button('fit');
		       Echo("Restored normal view");
		     })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>2);


  my $labframe = $histo -> LabFrame(-label=>$paths{$current}->get('lab') . ": $path",
				    -foreground=>$config{colors}{activehighlightcolor},
				    -labelside=>'acrosstop')
    -> pack(-side=>'top');

  $widgets{histo_header} = $labframe -> ROText(-width=>49, -height=>10, relief=>'flat',
					       -wrap=>'none', -font=>$config{fonts}{fixed})
    -> pack(-side=>'top', -anchor=>'c');
  &disable_mouse3($widgets{histo_header});
  $widgets{histo_header} -> tagConfigure('absorber', -foreground=>$config{colors}{button});

  $widgets{histo_header} -> delete(qw(1.0 end));
  my $i = 0;
  open P, File::Spec->catfile($project_folder, $paths{$current}->get('id'), $path);
  my $switch = 0;
  while (<P>) {
    $switch = 1, next if ($_ =~ /^\s+-------/);
    next unless $switch;
    last if ($_ =~ /\@\#$/);
    $_ =~ s/\s+absorbing/ absorbing/;
    ($_ =~ / 0 /) ?
      $widgets{histo_header} -> insert('end', $_ , 'absorber') :
	$widgets{histo_header} -> insert('end', $_);
    ++$i;
  };
  close P;
  $widgets{histo_header} -> configure(-height=>$i);

  my $frame = $histo -> Frame()
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Button(-text=>"Path list entry:",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   -font=>$config{fonts}{med},
		   -relief=>'flat', -borderwidth=>0,
		   -command=>[\&Echo, $click_help{'Path list entry'}]
		  )
    -> pack(-side=>'left', -padx=>6);
  $frame -> Entry(-width=>25, -textvariable=>\$histo_params{label},
		  -font=>$config{fonts}{fixed})
    -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $histo -> Label(-text=>'(%p=path file name, %r=bin distance, %n=bin height, %i=index)',
		  -foreground=>$config{colors}{foreground},
		  -font=>$config{fonts}{small}
		  )
    -> pack(-side=>'top');

  $frame = $histo -> Frame()
    -> pack(-side=>'top');
  $frame -> Button(-text=>'Position column:',
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   -font=>$config{fonts}{med},
		   -relief=>'flat', -borderwidth=>0,
		   -command=>[\&Echo, $click_help{'Position column'}]
		  )
    -> pack(-side=>'left', -padx=>0);
  $frame -> NumEntry(-width=>4,
		     -orient=>'horizontal',
		     -foreground=>$config{colors}{foreground},
		     -textvariable=>\$histo_params{position_column},
		     -minvalue=>1,
		    )
    -> pack(-side=>'left', -padx=>4);
  $frame -> Label(-width=>4)
    -> pack(-side=>'left', -padx=>0);
  $frame -> Button(-text=>'Height column:',
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   -font=>$config{fonts}{med},
		   -relief=>'flat', -borderwidth=>0,
		   -command=>[\&Echo, $click_help{'Height column'}]
		  )
    -> pack(-side=>'left', -padx=>0);
  $frame -> NumEntry(-width=>4,
		     -orient=>'horizontal',
		     -foreground=>$config{colors}{foreground},
		     -textvariable=>\$histo_params{height_column},
		     -minvalue=>1,
		    )
    -> pack(-side=>'left', -padx=>4);

  $widgets{histo_fileframe} = $histo
    -> LabFrame(-label=>'Histogram file',
		-foreground=>$config{colors}{activehighlightcolor},
		-labelside=>'acrosstop')
      -> pack(-side=>'top', -expand=>1, -fill=>'both');


  $widgets{histo_text} = $widgets{histo_fileframe}
    -> Scrolled('Text', -scrollbars=>'osoe', -width=>10, -height=>10,
		-font=>$config{fonts}{fixed})
      -> pack(-side=>'top', -expand=>1, -fill=>'both');
  $widgets{histo_text} -> Subwidget("xscrollbar")
  ->configure(-background=>$config{colors}{background},
	      ($is_windows) ? () : (-width=>8));
  $widgets{histo_text} -> Subwidget("yscrollbar")
  ->configure(-background=>$config{colors}{background},
	      ($is_windows) ? () : (-width=>8));
  BindMouseWheel($widgets{histo_text});

  $frame = $histo -> Frame()
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Button(-text => 'Make histogram', @button2_list,
		   -command =>
		   sub { histogram_build(\%histo_params) },
		  )
    -> pack(-side=>'left', -padx=>4, -fill=>'x', -expand=>1);
  $frame -> Button(-text => 'Browse', @button2_list,
		   -command =>
		   sub {
		     my $path = $current_data_dir || cwd;
		     my $types = [['All files',        '*'],];
		     my $file = $top -> getOpenFile(-filetypes=>$types,
						   ##(not $is_windows) ?
						   ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
						   -initialdir=>$path,
						   -title => "Artemis: Open a histogram file");
		     return unless ($file);
		     $current_data_dir = dirname($file);
		     $widgets{histo_fileframe} -> configure(-label=>$file);
		     $widgets{histo_text} -> delete('1.0', 'end');
		     local $/ = undef;
		     open F, $file;
		     $widgets{histo_text} -> insert('end', <F>);
		     close F;
		   })
    -> pack(-side=>'left', -padx=>4);



  set_fit_button('disabled');
  Echo("Showing histogram tool");
  $top -> update;
};


sub histogram_build {
  my $rhash = $_[0];
  my $feff  = $$rhash{this_feff};
  my $path  = $$rhash{this_path};
  my $label = $$rhash{label};

  ## intrpline is the same for each of these histogram bins
##   my $start = $widgets{feff_intrp} -> search(-exact=>substr($path,4,4), "1.0") || 0;
##   my $end = (split(/\./, $start))[0] . ".end";
##   my $intrpline = ($start) ? $widgets{feff_intrp}->get($start, $end) : "";
  my $intrpline = "";

  my $text  = $widgets{histo_text} -> get('1.0', 'end');
  my $index = 0;
  foreach my $line (split(/\n/, $text)) {
    ++$index;
    my @line = split(" ", $line);
    my $r = $line[$$rhash{position_column}-1] || 0;
    my $n = $line[$$rhash{height_column}-1]   || 0;
    my %sub = (r=>$r, n=>$n, p=>$path, i=>sprintf("%3.3d", $index));
    (my $this_label = $label) =~ s/\%([inpr])/$sub{$1}/g;

    my $this = $list -> addchild($feff);
    $paths{$this} = Ifeffit::Path -> new(id	   => $this,
					 type      => 'path',
					 file      => $path,
					 include   => 1,
					 plotpath  => 0,
					 parent    => $feff,
					 do_k      => 1,
					 data      => $paths{$current}->data,
					 intrpline => $intrpline,
					 family    => \%paths);
    my @autoparams = @{$paths{$feff}{autoparams}};
    foreach my $p (qw(s02 e0 delr sigma^2 ei 3rd 4th)) {
      my $ap = shift @autoparams;
      $paths{$this} -> make($p=>$ap);
    };
    $paths{$this} -> make(header=> nnnn_header($this,File::Spec->catfile($project_folder, $paths{$current}->get('id'), $path)));
    $paths{$this} -> make(lab   => $this_label,
			  deg   => $n,
			  label => "bin of $n at $r using $path",
			  delr  => "($r-reff)*delta");
    $list -> entryconfigure($this, -style=>$list_styles{enabled}, -text=>$this_label);
    $paths{$this} -> pathgroup(\%paths);
##     $list->anchorSet($this);
##     $list->selectionClear;
##     $list->selectionSet($this);
  };


};
