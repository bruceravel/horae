## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  report generation.

sub report_csv {
  my $how = $_[0];
  if ($how eq 'marked') {
    my $m = 0;
    map {$m += $_} values %marked;
    Error("Report aborted.  There are no marked groups."), return 1 unless ($m);
  };

  my $types = [['Comma separated value files', '.csv'], ['All Files', '*'],];
  my $path = $current_data_dir || Cwd::cwd;
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>"athena.csv",
				 -title => "Athena: Write report");
  return unless $file;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  #&push_mru($file, 0);
  Echo("Generating CSV report to \"$file\" ...");

  open CSV, ">".$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  print CSV "# Athena CSV report -- Athena version $VERSION\n";
  print CSV $groups{$current} -> project_header;
  print CSV ",,,Background Removal Parameters,,,,,,,,,,,,,,,,,Forward Fourier transform parameters,,,,,,,,Backward Fourier transform parameters,,,,Plotting parameters,\n";
  do {
    no warnings; # avoid warning about commas after File Clamp2 r-range
    print CSV join(',', qw(Group File, E0 Rbkg Standard Algorithm Element k-weight),
		   'E0 shift', 'Edge Step', 'Fixed Step', 'Functional normalization', 'Pre-edge range',
		   'Normalization range', 'Spline range', 'Nknots',
		   qw(Clamp1 Clamp2, arb-k-weight dk window k-range),
		   'Do PC', 'PC element', 'PC edge,',
		   qw(dr window r-range,),
		   'Scaling factor', 'y-offset'), "\n\n";
  };

  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    (my $str = $groups{$k}->{label}) =~ s/,/ /g;
    print CSV $str;
    ($str = $groups{$k}->{file}) =~ s/,/ /g;
    print CSV ",", $str,",";
    foreach my $p (qw(bkg_e0 bkg_rbkg bkg_stan)){
      print CSV ",", $groups{$k}->{$p};
    };
    printf CSV ($groups{$k}->{bkg_cl}) ? ",Cromer-Liberman" : ",Autobk";
    foreach my $p (qw(bkg_z bkg_kw bkg_eshift bkg_step)) {
       print CSV ",", $groups{$k}->{$p};
    };
    printf CSV ($groups{$k}->{bkg_fixstep}) ? ",yes" : ",no";
    printf CSV ($groups{$k}->{bkg_fnorm}) ? ",yes" : ",no";
    printf CSV ",[%s : %s]", $groups{$k}->{bkg_pre1}, $groups{$k}->{bkg_pre2};
    printf CSV ",[%s : %s]", $groups{$k}->{bkg_nor1}, $groups{$k}->{bkg_nor2};
    printf CSV ",[%s : %s]", $groups{$k}->{bkg_spl1}, $groups{$k}->{bkg_spl2};
    my $deltak = $groups{$current}->{bkg_spl2} - $groups{$current}->{bkg_spl1};
    print CSV ",",int( 2 * $deltak * $groups{$k}->{bkg_rbkg} / PI ) + 1;
    foreach my $p (qw(bkg_clamp1 bkg_clamp2)) {
      print CSV ",", $groups{$k}->{$p};
    };
    print CSV ",";
    ## begin fft params
    foreach my $p (qw(fft_arbkw fft_dk fft_win)) {
      print CSV ",", $groups{$k}->{$p};
    };
    printf CSV ",[%s - %s]", $groups{$k}->{fft_kmin}, $groups{$k}->{fft_kmax};
    print CSV ", ", ($groups{$k}->{fft_pc} eq 'on') ? 'yes' : 'no';
    foreach my $p (qw(bkg_z fft_edge)) {
      print CSV ",", $groups{$k}->{$p};
    };
    print CSV ",";
    ## begin bft params
    foreach my $p (qw(bft_dr bft_win)) {
      print CSV ",", $groups{$k}->{$p};
    };
    printf CSV ",[%s-%s]", $groups{$k}->{bft_rmin}, $groups{$k}->{bft_rmax};
    print CSV ",";
    ## begin plot params
    foreach my $p (qw(plot_scale plot_yoffset)) {
      print CSV ",", $groups{$k}->{$p};
    };
    print CSV "\n";
  };
  close CSV;
  Echo("Generating CSV report to \"$file\" ... done!");
};



sub report_excel {
  my $how = $_[0];
  if ($how eq 'marked') {
    my $m = 0;
    map {$m += $_} values %marked;
    Error("Report aborted.  There are no marked groups."), return 1 unless ($m);
  };

  my $types = [['Excel files', '.xls'], ['All Files', '*'],];
  my $path = $current_data_dir || Cwd::cwd;
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>"athena.xls",
				 -title => "Athena: Write report");
  return unless $file;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  #&push_mru($file, 0);
  Echo("Generating Excel report to \"$file\" ...");

  ## new workbook with one sheet
  my $workbook = Spreadsheet::WriteExcel -> new($file) or do {
    Error("You cannot write a spreadsheet to \"$file\".");
    return;
  };
  $workbook -> set_codepage(2) if (lc($^O) eq 'darwin');
  my $worksheet = $workbook -> addworksheet('Athena parameters');

  ## several formats for different kinds of cells
  my $topheader = $workbook->addformat(bold=>1, color=>'black', bg_color=>'gray',
				      align=>'left');
  my $header  = $workbook->addformat(bold=>1, bg_color=>'grey', align=>'center');
  my $number  = $workbook->addformat(align=>'center', num_format=>'0.000');
  #$number    -> set_num_format('0.000');
  my $integer = $workbook->addformat(align=>'center');
  my $string  = $workbook->addformat(align=>'center');
  my $fname   = $workbook->addformat(italic=>1);
  my $sep     = $workbook->addformat(align=>'center');
  #$sep       -> set_bg_color(22);

  my $col = 0;
  my $row = 1;

  my $comment = "# Athena Excel report -- Athena version $VERSION\n";
  $comment   .= $groups{$current} -> project_header;
  chomp $comment;
  $comment   .= " (Spreadsheet::WriteExcel version $Spreadsheet::WriteExcel::VERSION)";
  $comment   =~ s/\# //g;
  foreach (split(/\n/, $comment)) {
    $worksheet -> merge_range($row, 0, $row, 33, $_, $topheader);
    $row++;
  };
  $row++;

  ## set up the top-most header line
  $worksheet -> write_blank($row, 0);
  $worksheet -> write_blank($row, 1);
  $worksheet -> merge_range($row, 3,$row,18, 'Background removal parameters', $topheader);
  $worksheet -> merge_range($row,20,$row,26, 'Forward transform parameters',  $topheader);
  $worksheet -> merge_range($row,28,$row,30, 'Backward transform parameters', $topheader);
  $worksheet -> merge_range($row,32,$row,33, 'Plotting parameters',           $topheader);
  $row++;

  ## write the column headers
  foreach (qw(Group File)) {
    $worksheet -> write($row, $col++, $_, $header);
  };
  $worksheet -> write_blank($row-1, $col);
  $worksheet -> write_blank($row, $col++);
  ## background parameters
  foreach (qw(E0 Rbkg Standard Algorithm Element k-weight), 'E0 shift',
	   'Edge Step', 'Fixed Step', 'Functional norm.', 'Pre-edge range',
	   'Normalization range', 'Spline range', 'Nknots',
	   qw(Clamp1 Clamp2)) {
    $worksheet -> write($row, $col++, $_, $header);
  };
  $worksheet -> write_blank($row-1, $col); # lines like this fill gaps
  $worksheet -> write_blank($row, $col++);
  ## fft parameters
  foreach ('arbitrary k-weight', qw(dk window k-range), 'Do PC', 'PC element', 'PC edge') {
    $worksheet -> write($row, $col++, $_, $header);
  };
  $worksheet -> write_blank($row-1, $col);
  $worksheet -> write_blank($row, $col++);
  ## bft parameters
  foreach (qw(dR window R-range)) {
    $worksheet -> write($row, $col++, $_, $header);
  };
  $worksheet -> write_blank($row-1, $col);
  $worksheet -> write_blank($row, $col++);
  ## plot parameters
  foreach ('Scaling factor', 'y-offset') {
    $worksheet -> write($row, $col++, $_, $header);
  };
  $row++;

  ## set all the column widths to sensible values (very fiddly!)
  $worksheet->set_column(0, 0, 15); # group
  $worksheet->set_column(1, 1, 10); # file
  $worksheet->set_column(2, 2,  2); # spacer
  foreach (3  .. 12) { $worksheet->set_column($_, $_, 12) }; # bkg params
  foreach (13 .. 15) { $worksheet->set_column($_, $_, 20) }; # ranges
  $worksheet->set_column(16, 16, 7); # nknots
  foreach (17 .. 18) { $worksheet->set_column($_, $_, 12) }; # clamps
  $worksheet->set_column(19, 19, 2); # spacer
  foreach (21 .. 21) { $worksheet->set_column($_, $_, 12) }; # fft params
  $worksheet->set_column(22, 22, 16); # k window
  foreach (23 .. 25) { $worksheet->set_column($_, $_, 12) }; # k-range
  $worksheet->set_column(27, 27,  2); # spacer
  $worksheet->set_column(28, 28, 12); # dr
  $worksheet->set_column(29, 29, 16); # r-window
  $worksheet->set_column(30, 30, 12); # r-range
  $worksheet->set_column(31, 31,  2); # spacer
  foreach (32 .. 33) { $worksheet->set_column($_, $_, 18) }; # plotting params

  ## write out the parameters for each (marked) group, taking care to
  ## set formats appropriately
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    $col = 0;
    $worksheet -> write($row, $col++,  $groups{$k}->{label}, $string);
    $worksheet -> write($row, $col++,  $groups{$k}->{file}, $fname);
    $worksheet -> write_blank($row, $col++, $sep);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_e0}, $number);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_rbkg}, $number);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_stan}, $number);
    $worksheet -> write($row, $col++, ($groups{$k}->{bkg_cl}) ? "Cromer-Liberman" : "Autobk",
			$string);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_z}, $string);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_kw}, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_eshift}, $number);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_step}, $number);
    $worksheet -> write($row, $col++, ($groups{$k}->{bkg_fixstep}) ? "yes" : "no", $string);
    $worksheet -> write($row, $col++, ($groups{$k}->{bkg_fnorm}) ? "yes" : "no", $string);
    $worksheet -> write($row, $col++,
			sprintf("[%.3f : %.3f]", $groups{$k}->{bkg_pre1}, $groups{$k}->{bkg_pre2}),
			$string);
    $worksheet -> write($row, $col++,
			sprintf("[%.3f : %.3f]", $groups{$k}->{bkg_nor1}, $groups{$k}->{bkg_nor2}),
			$string);
    $worksheet -> write($row, $col++,
			sprintf("[%.3f : %.3f]", $groups{$k}->{bkg_spl1}, $groups{$k}->{bkg_spl2}),
			$string);
    my $deltak = $groups{$current}->{bkg_spl2} - $groups{$current}->{bkg_spl1};
    $worksheet -> write($row, $col++,  int( 2 * $deltak * $groups{$current}->{bkg_rbkg} / PI ) + 1, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_clamp1}, $string);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_clamp2}, $string);
    $worksheet -> write_blank($row, $col++, $sep);
    $worksheet -> write($row, $col++,  $groups{$k}->{fft_arbkw}, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{fft_dk}, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{fft_win}, $string);
    $worksheet -> write($row, $col++,
			sprintf("[%s : %s]", $groups{$k}->{fft_kmin}, $groups{$k}->{fft_kmax}),
			$string);
    $worksheet -> write($row, $col++,  $groups{$k}->{fft_pc}, $string);
    $worksheet -> write($row, $col++,  $groups{$k}->{bkg_z}, $string);
    $worksheet -> write($row, $col++,  $groups{$k}->{fft_edge}, $string);
    $worksheet -> write_blank($row, $col++, $sep);
    $worksheet -> write($row, $col++,  $groups{$k}->{bft_dr}, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{bft_win}, $string);
    $worksheet -> write($row, $col++,
			sprintf("[%s : %s]", $groups{$k}->{bft_rmin}, $groups{$k}->{bft_rmax}),
			$string);
    $worksheet -> write_blank($row, $col++, $sep);
    $worksheet -> write($row, $col++,  $groups{$k}->{plot_scale}, $integer);
    $worksheet -> write($row, $col++,  $groups{$k}->{plot_yoffset}, $number);
    ++$row;
  };

  $worksheet -> set_landscape();
  $worksheet -> set_selection(7,0); # select the first non-header cell
  $workbook -> close();		# write it out and get the hell out of dodge!
  Echo("Generating Excel report to \"$file\" ... done!");
};


sub report_ascii {
  my $how = $_[0];
  if ($how eq 'marked') {
    my $m = 0;
    map {$m += $_} values %marked;
    Error("Report aborted.  There are no marked groups."), return 1 unless ($m);
  };

  my $types = [['Text files', '.txt'], ['All Files', '*'],];
  my $path = $current_data_dir || Cwd::cwd;
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>"athena.txt",
				 -title => "Athena: Write report");
  return unless $file;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  #&push_mru($file, 0);
  Echo("Generating text report to \"$file\" ...");

  open TXT, ">".$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  print TXT "# Athena text report -- Athena version $VERSION\n",
    $groups{$current} -> project_header, "\n";

  print TXT "=" x 70, "\n",
    "Background removal parameters\n\n",
    "#  Group                  E0     Rbkg Standard        Algorithm      Elem\n",
    "# ------------------------------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    printf TXT " %-20s %9.3f %5.3f %-15.15s %-15s %-2s\n",
      $groups{$k}->{label}, $groups{$k}->{bkg_e0}, $groups{$k}->{bkg_rbkg},
	$groups{$k}->{bkg_stan},
	  ($groups{$k}->{bkg_cl}) ? "Cromer-Liberman" : "Autobk", $groups{$k}->{bkg_z};
  };
  print TXT "\n",
    "#  Group              kw E0shift Step  Fixed Fnorm Clamp1   Clamp2\n",
    "# ------------------------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    printf TXT " %-20s %1d  %7.3f %5.3f %-5s %-5s %-7s  %-7s\n",
      $groups{$k}->{label}, $groups{$k}->{bkg_kw}, $groups{$k}->{bkg_eshift},
	$groups{$k}->{bkg_step},
	  ($groups{$k}->{bkg_fixstep}) ? "yes" : "no",
	    ($groups{$k}->{bkg_fnorm}) ? "yes" : "no",
	      $groups{$k}->{bkg_clamp1}, $groups{$k}->{bkg_clamp2};
  };
  print TXT "\n",
    "#  Group                Pre-edge       Normalization   Spline       Nknots\n",
      "# ------------------------------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    my $deltak = $groups{$current}->{bkg_spl2} - $groups{$current}->{bkg_spl1};
    printf TXT " %-20s [%6.1f:%6.1f] [%6.1f:%6.1f] [%6.3f:%6.3f] %3d\n",
      $groups{$k}->{label}, $groups{$k}->{bkg_pre1}, $groups{$k}->{bkg_pre2},
	$groups{$k}->{bkg_nor1}, $groups{$k}->{bkg_nor2},
	  $groups{$k}->{bkg_spl1}, $groups{$k}->{bkg_spl2},
	    int( 2 * $deltak * $groups{$current}->{bkg_rbkg} / PI ) + 1;
  };
  print TXT "\n\n",
    "=" x 70, "\n",
    "Forward Fourier transform parameters\n\n",
    "#  Group              arbkw dk   window        k-range      Phase Correction\n",
    "# -----------------------------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    printf TXT " %-20s %1d  %3.1f %13s [%5.2f:%5.2f]   %s %-2s %-2s\n",
       $groups{$k}->{label}, $groups{$k}->{fft_arbkw}, $groups{$k}->{fft_dk},
	 $groups{$k}->{fft_win}, $groups{$k}->{fft_kmin}, $groups{$k}->{fft_kmax},
	   $groups{$k}->{fft_pc}, $groups{$k}->{bkg_z}, $groups{$k}->{fft_edge};
  };
  print TXT "\n\n",
    "=" x 70, "\n",
    "Backward Fourier transform parameters\n\n",
    "#  Group              dR     window          R-range\n",
    "# --------------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    printf TXT " %-20s %3.1f   %13s   [%5.2f:%5.2f]\n",
       $groups{$k}->{label}, $groups{$k}->{bft_dr},
	 $groups{$k}->{bft_win}, $groups{$k}->{bft_rmin}, $groups{$k}->{bft_rmax};
  };
  print TXT "\n\n",
    "=" x 70, "\n",
    "Plotting parameters\n\n",
    "#  Group              scaling factor      y-offset\n",
    "# -----------------------------------------------------\n";
  foreach my $k (&sorted_group_list) {
    next if (($how eq 'marked') and (not $marked{$k}));
    printf TXT " %-20s %-14s      %7.3f\n",
       $groups{$k}->{label}, $groups{$k}->{plot_scale}, $groups{$k}->{plot_yoffset};
  };

  close TXT;
  Echo("Generating text report to \"$file\" ... done!");
};

## END OF REPORT GENERATION SUBSECTION
##########################################################################################
