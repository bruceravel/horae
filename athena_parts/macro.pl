## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  writing and reading macros


sub setup_macro {
  my $instructions = <<EOH
To begin recording a macro, click the button below.  All subsequent
calls to ifeffit will be recorded.  When you have performed all the
ifeffit operations you wish to record, press the \"Done\" button and
you will be prompted for a filename in which to save the macro.

Data processing chores which involve altering the data, e.g.
deglitching and truncating, will not record properly as macros.
EOH
  ;

  $notes{macro} -> tagConfigure('inst', -wrap=>'word');
  $notes{macro} -> insert('end', $instructions, "text");

  my $doneline  = $notecard{macro} -> Frame(qw/-relief flat -borderwidth 2/)
    -> pack(qw/-fill x -side bottom/);
  my $startline = $notecard{macro} -> Frame(qw/-relief groove -borderwidth 2/)
    -> pack(qw/-fill x -side bottom/);

  my $rectext = $startline -> Label(-text=>"Recording macro...", -justify=>'center');
  my $start;
  $start = $startline -> Button(-text=>'Start recording',  @button_list,
				-command=>sub{$start->packForget();
					      $rectext-> pack(-expand=>1, -fill=>'x', -pady=>4);
					      ($dmode & 8) or ($dmode += 8);})
    -> pack(-expand=>1, -fill=>'x');

  my $done = $doneline
    -> Button(-text=>'Done',  @button_list,
	      -command=>sub{$rectext -> packForget();
			    $start   -> pack(-expand=>1, -fill=>'x');
			    ($dmode & 8) and ($dmode -= 8);
			    &save_macro;})
    -> pack(-expand=>1, -fill=>'x');
};

sub save_macro {
  return unless @macro_buffer;
  local $Tk::FBox::a;
  local $Tk::FBox::b;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [['Ifeffit macro files', '.ifm'],
	       ['All Files', '*'],];
  my $file = $top -> getSaveFile(-defaultextension=>'ifm',
				 -filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>'athena.ifm',
				 -title => "Athena: Save Ifeffit macro");
  if ($file) {
    my ($name, $pth, $suffix) = fileparse($file);
    $current_data_dir = $pth;
    #&push_mru($file, 0);
    open MAC, '>'.$file or do {
      Error("You cannot write macro to \"$file\"."); return
    };
    print MAC "## Ifeffit macro file recorded using Athena $VERSION\n\n";
    my $macros = write_macros();
    print MAC $macros;
    map {print MAC $_} @macro_buffer;
    close MAC;
    @macro_buffer = ();
  };
};

sub load_macro {
  local $Tk::FBox::a;
  local $Tk::FBox::b;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [['Ifeffit macro files', '.ifm'],
	       ['All Files', '*'],];
  my $file = $top -> getOpenFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -title => "Athena: Load macro");
  if ($file) {
    my ($name, $pth, $suffix) = fileparse($file);
    $current_data_dir = $pth;
    #&push_mru($file, 0);
    open MAC, $file or die "Could not open $file for reading macro\n";
    while (<MAC>) {
      next if (/^\s*\#/);
      next if (/^\s*$/);
      if ($_ =~ /^\s*read_data/) {
	my ($file, $group);
	($_ =~ /file\s*=\s*([^ \t,]*)/) and ($file = $1);
	($_ =~ /group\s*=\s*([^ \t,]*)/) and ($group = $1);
	fill_skinny($list, $file, $group);
      } else {
	$groups{$current}->dispose($_, $dmode);
      };
    };
    close MAC;
  };
};

sub write_macros {
  my $string = "
macro startup
  \"Athena startup message, used to set character size and font\"
  set(startup.x = range(0.1,1,0.1), startup.y = zeros(10))
  newplot(startup.x, startup.y, nogrid, ymin=0, ymax=1, color=black, charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})
  plot_text(0.4, 0.5, text=\"Welcome to Athena\")
  erase \@group startup
end macro

## macro for drawing markers (for e0 and the like)
macro  pmarker d.x d.y x style color yoffset
  \"plot a marker at X given D.X and D.Y and YOFFSET with STYLE, and COLOR\"
  set(p___y = interp(\$1, \$2, \$3) + \$6)
  plot_marker(\$3, p___y, \$4, color=\$5)
end macro

## making a step function
macro step x.array shift x a.step
  \"Return A.STEP function centered at X with X.ARRAY as the x-axis and a SHIFT energy shift\"
  set(t___oss.x     = \$1 + \$2,
      n___step      = nofx(t___oss.x, \$3) - 1,
      n___points    = npts(\$1) - n___step,
      t___oss.zeros = zeros(n___step),
      t___oss.ones  = ones(n___points),
      \$4 = join(t___oss.zeros, t___oss.ones) )
end macro


## log-ratio/phase difference macros:

macro do_lograt stan unknown qmin qmax npi
  \"Do log-ratio/phase-difference analysis between STAN and UNKNOWN between QMIN and QMAX\"

  ## do log-ratio fit
  guess(___c0 = 1, ___c2 = 0, ___c4 = 0);
  def(___c.ratio = ln(\$2.chiq_mag/\$1.chiq_mag),
      ___c.even = ___c0 - 2*___c2*\$1.q^2 + (2/3)*___c4*\$1.q^4,
      ___c.resev = ___c.ratio - ___c.even)
  minimize(___c.resev, x=\$1.q, xmin=\$3, xmax=\$4)
  set(___c0 = ___c0, ___c2 = ___c2, ___c4 = ___c4)

  ## do phase difference fit
  guess(___c1 = 0, ___c3 = 0)
  def(___c.diff = \$2.chiq_pha - \$1.chiq_pha,
      ___c.odd = 2*___c1*\$1.q - (4/3) * ___c3*\$1.q^3 + \$5*2*pi,
      ___c.resod = ___c.diff - ___c.odd)
  minimize(___c.resod, x=\$1.q, xmin=\$3, xmax=\$4)
  set(___c1  = ___c1, ___c3  = ___c3)
end macro

macro plot_lograt stan stan_lab unknown_lab qmax
  \"Plot log ratio and fit for STAN out to QMIN\"
  newplot(\$1.q, ___c.ratio, xmax=\$4, title=\"log-ratio between \$3 and \$2\",
          xlabel=\"k (\\A\\u-1\\d)\", ylabel=\"log-ratio\", key=data)
  plot(\$1.q, ___c.even, key=fit)
end macro

macro plot_phdiff stan stan_lab unknown_lab qmax
  \"Plot phase difference and fit for STAN out to QMIN\"
  newplot(\$1.q, ___c.diff, xmax=\$4, title=\"phase-difference between \$3 and \$2\",
          xlabel=\"k (\\A\\u-1\\d)\", ylabel=difference, key=data)
  plot(\$1.q, ___c.odd, key=fit)
end macro

macro clean_lograt
  erase ___c0 ___c1 ___c2 ___c3 ___c4
  erase \@group ___c
end macro

macro fix_chik
   \"repair chi(k) data group that is not on a uniform k grid\"
   set(fix___a.k   = range(0, ceil(\$1.k), 0.05))
   set(fix___floor = floor(\$1.k) - 0.05)
   set(fix___a.kk  = range(0, fix___floor, 0.05))
   set(fix___n     = npts(fix___a.kk))
   set(fix___a.cc  = zeros(fix___n))
   set(fix___a.x   = join(fix___a.kk, \$1.k))
   set(fix___a.y   = join(fix___a.cc, \$1.chi))
   set(fix___a.chi = rebin(fix___a.x, fix___a.y, fix___a.k))
   set(\$1.k         = fix___a.k)
   set(\$1.chi       = fix___a.chi)
   erase \@group fix___a fix___floor fix___n
end macro

## end of Athena's macros
##
##
";
  return $string;
};

##        xmin=floor(\$1),xmax=ceil(\$1),
##        ymin=floor(\$2),ymax=ceil(\$2) )

## END OF MACROS SUBSECTION
##########################################################################################
