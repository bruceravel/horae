# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##



###===================================================================
### record description subsystem
###===================================================================

sub read_record {
  my $file = $_[0];

  open PROJ, $file or die "could not open $file as a project file\n";

  my $cpt = new Safe;
  use vars qw($old_path @args @strings @journal @plot_features @parameter);
  my $from_version = 0;
  while (<PROJ>) {
    if (/^\s*\#\s*Artemis project/) {
      my @list = split(" ",$_);
      $from_version = $list[$#list];
      @list = split(/\./, $from_version);
      $from_version = $#list ? $list[0] . "." . $list[1] . $list[2] : "DR".$list[0];
      $from_version =~ s/rc//;
      next;
    };
    next if (/^\s*\#/);
    next if (/^\s*$/);

  SWITCH: {
      (/^\@parameter/) and do {
	@ {$cpt->varglob('parameter')} = $cpt->reval($_);
	@parameter = @ {$cpt->varglob('parameter')};
	push @gds, Ifeffit::Parameter->new(name	    => $parameter[0],
					   type	    => $parameter[1],
					   mathexp  => $parameter[2],
					   note	    => $parameter[3],
					   autonote => $parameter[4],
					  );
	$gds[$#gds]->make(bestfit  => $parameter[2]) if ($parameter[1] eq 'guess');
	last SWITCH;
      };
      (/^\@journal/) and do {
	## as of 0.7.004 the journal is saved in a file separate from
	## the description file.  so this block is merely to read the
	## journal from the project file from before 0.7.004
	@ {$cpt->varglob('journal')} = $cpt->reval($_);
	@journal = @ {$cpt->varglob('journal')};
	$notes{journal} -> delete(qw(1.0 end));
	foreach (@journal) {
	  $notes{journal} -> insert('end', $_."\n");
	};
	open J, ">".File::Spec->catfile($project_folder, "descriptions", "journal.artemis");
	map { print J $_, $/ } (@journal);
	print J $/;
	close J;
	last SWITCH;
      };
      (/^\%plot_features/) and do {
	% {$cpt->varglob('plot_features')} = $cpt->reval($_);
	while (my ($k, $v) = each % {$cpt->varglob('plot_features')}) {
	  $plot_features{$k} = $v;
	};
	last SWITCH;
      };
      (/^\@extra/) and do {
	@ {$cpt->varglob('extra')} = $cpt->reval($_);
	my @this = @ {$cpt->varglob('extra')};
	@extra[0..6] = @this[0..6];
	foreach (7 .. $#this) {
	  $extra[$_]->[1] = $this[$_]->[0];
	  $extra[$_]->[2] = $this[$_]->[1];
	};
	#{ no warnings;
	#  print join(" ", @extra), $/;};
	last SWITCH;
      };
      (/^\%props/) and do {
	% {$cpt->varglob('props')} = $cpt->reval($_);
	while (my ($k, $v) = each % {$cpt->varglob('props')}) {
	  next if ($k eq 'Environment');
	  next if ($k eq 'Project location');
	  next if ($k eq 'Information content');
	  $props{$k} = $v;
	};
	last SWITCH;
      };
      (/^\$old_path/) and do {
	$ {$cpt->varglob('old_path')} = $cpt->reval($_);
	$old_path = $ {$cpt->varglob('old_path')};
	@args = ();
	@strings = ();
	last SWITCH;
      };
      (/^\@args/) and do {
	@ {$cpt->varglob('args')} = $cpt->reval($_);
	@args = @ {$cpt->varglob('args')};
	last SWITCH;
      };
      (/^\@strings/) and do {
	@ {$cpt->varglob('strings')} = $cpt->reval($_);
	@strings = @ {$cpt->varglob('strings')};
	last SWITCH;
      };
      (/^\[record\]/) and do {
	last SWITCH unless @args;
	&read_path(\$old_path, \@args, \@strings);
	last SWITCH;
      };

    };

  };

  close PROJ;
  return $from_version;
};

sub read_record_on_windows {
  my $file = $_[0];

  open PROJ, $file or die "could not open $file as a project file\n";

  my $cpt = new Safe;
  use vars qw($old_path @args @strings @journal @plot_features @parameter %foo);
  my $from_version = 0;
  while (<PROJ>) {
    if (/^\s*\#\s*Artemis project/) {
      my @list = split(" ",$_);
      $from_version = $list[$#list];
      @list = split(/\./, $from_version);
      $from_version = $#list ? $list[0] . "." . $list[1] . $list[2] : "DR".$list[0];
      $from_version =~ s/rc//;
      next;
    };
    next if (/^\s*\#/);
    next if (/^\s*$/);

  SWITCH: {
      (/^\@parameter/) and do {
	eval $_;
	push @gds, Ifeffit::Parameter->new(name	    => $parameter[0],
					   type	    => $parameter[1],
					   mathexp  => $parameter[2],
					   note	    => $parameter[3],
					   autonote => $parameter[4],
					  );
	$gds[$#gds]->make(bestfit  => $parameter[2]) if ($parameter[1] eq 'guess');
	last SWITCH;
      };
      (/^\@journal/) and do {
	## as of 0.7.004 the journal is saved in a file separate from
	## the description file.  so this block is merely to read the
	## journal from the project file from before 0.7.004
	eval $_;
	$notes{journal} -> delete(qw(1.0 end));
	foreach (@journal) {
	  $notes{journal} -> insert('end', $_."\n");
	};
	open J, ">".File::Spec->catfile($project_folder, "descriptions", "journal.artemis");
	map { print J $_, $/ } (@journal);
	print J $/;
	close J;
	last SWITCH;
      };
      (/^\%plot_features/) and do {
	(my $this = $_) =~ s/^\%plot_features/\%foo/;
	eval $this;
 	foreach my $k (keys %foo) {
 	  $plot_features{$k} = $foo{$k};
 	};
	last SWITCH;
      };
      (/^\@extra/) and do {
	(my $this = $_) =~ s/^\@extra\s+=\s+//;
	my @this = eval $this;
	@extra[0..6] = @this[0..6];
	foreach (7 .. $#this) {
	  $extra[$_]->[1] = $this[$_]->[0];
	  $extra[$_]->[2] = $this[$_]->[1];
	};
	last SWITCH;
      };
      (/^\%props/) and do {
	(my $this = $_) =~ s/^\%props/\%foo/;
	eval $this;
	foreach my $k (keys %foo) {
	  ##next if ($k eq 'Last fit');
	  ($props{$k} = $foo{$k}) unless ($k eq 'Environment');
	};
	last SWITCH;
      };
      (/^\$old_path/) and do {
	eval $_;
	@args = ();
	@strings = ();
	last SWITCH;
      };
      (/^\@args/) and do {
	eval $_;
	last SWITCH;
      };
      (/^\@strings/) and do {
	eval $_;
	last SWITCH;
      };
      (/^\[record\]/) and do {
	last SWITCH unless @args;
	&read_path(\$old_path, \@args, \@strings);
	last SWITCH;
      };

    };

  };

  close PROJ;
  return $from_version;
};


sub read_athena_record {
  my ($file, $from_project, $change) = @_;
  &push_mru($file, 1, "record");
  use vars qw/$old_group @args @x @y @stddev/;
  open F, $file or die "could not open $file as an Athena record\n";
  while (<F>) {
    next if (/^\s*\#/);		# skip blank and commented lines
    next if (/^\s*$/);
    next if (/^\s*1/);
    my $cpt = new Safe;
  SWITCH: {
      (/^\$old_group/) and do {
	$ {$cpt->varglob('old_group')} = $cpt->reval($_);
	$old_group = $ {$cpt->varglob('old_group')};
	last SWITCH;
      };
      (/^\@args/) and do {
	@ {$cpt->varglob('args')} = $cpt->reval($_);
	@args = @ {$cpt->varglob('args')};
	last SWITCH;
      };
      (/^\@x/) and do {
	@ {$cpt->varglob('x')} = $cpt->reval($_);
	@x = @ {$cpt->varglob('x')};
	last SWITCH;
      };
      (/^\@y/) and do {
	@ {$cpt->varglob('y')} = $cpt->reval($_);
	@y = @ {$cpt->varglob('y')};
	last SWITCH;
      };
      (/^\@stddev/) and do {
	@ {$cpt->varglob('stddev')} = $cpt->reval($_);
	@stddev = @ {$cpt->varglob('stddev')};
	last SWITCH;
      };
      ##(/^\$old_group\s*=\s*\'([^\']*)\';$/) and do {
      ##  $old_group = $1;
      ##  last SWITCH;
      ##};
      ((/^\[record\]/) or (/^\&read_record/)) and do {
	#my $memory_ok = &memory_check(0, 1);
	#Echo ("Out of memory in Ifeffit"), last DATA if ($memory_ok == -1);
	last SWITCH;
      };
      1;
    };
  };
  close F;

  ## read the args
  my %args;
  while (@args) {
    my ($key, $val) = (shift @args, shift @args);
    $args{$key} = $val;
  };
  Echo("$file is not an Athena chi(k) record and cannot be imported."),
    return unless $args{is_chi};

  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  $name = (split(/\./, $name))[0];
  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'normal')} (keys %widgets);
  map {$grab{$_}->configure(-state=>'normal')} (keys %grab);

  ## extract the useful parts of @args
  my $group = ($change) ? $paths{$current}->data : 'data'.&next_data;
  my $fit   = $group . '.0';

  ## fill the data arrays
  Ifeffit::put_array("$group.k",   \@x);
  Ifeffit::put_array("$group.chi", \@y);
  ++$n_data;

  if (($change) or (not $current)) {
    $paths{$group} -> make(group  =>$group, file =>$file, lab=>$name,
			   is_rec =>1,);
    $list -> entryconfigure($paths{$group}->get('id'), -text=>$name);
  } else {
    $paths{$group} = Ifeffit::Path -> new(id     => $group,
					  group  => $group,
					  type   => 'data',
					  sameas => 0,
					  file   => $file,
					  lab    => $name,
					  family => \%paths,);
    $list -> add($group, -text=>$name, -style=>$list_styles{enabled});
    $list -> setmode($group, 'none');

    $list -> add($group.".0", -text=>'Fit', -style=>$list_styles{enabled},);
    $list -> setmode($group.'.0', 'close');
    $list -> hide('entry', $group.".0");
  };
  $from_project or
    $paths{$group} -> make(kmin   =>$args{fft_kmin}, kmax   =>$args{fft_kmax},
			   dk     =>$args{fft_dk},   kwindow=>$args{fft_win},
			   rmin   =>$args{bft_rmin}, rmax   =>$args{bft_rmax},
			   dr     =>$args{bft_dr},   rwindow=>$args{bft_win},
			   pcedge =>$args{fft_edge}, pcelem =>$args{bkg_z});
 SWITCH: {
    $paths{$group} -> make(k1=>1), last SWITCH if ($args{fft_kw} eq 1);
    $paths{$group} -> make(k2=>1), last SWITCH if ($args{fft_kw} eq 2);
    $paths{$group} -> make(k3=>1), last SWITCH if ($args{fft_kw} eq 3);
    $paths{$group} -> make(karb_use=>1, karb=>$args{fft_kw});
  };
  $paths{$fit}  = Ifeffit::Path -> new(id     => $group.".0",
				       type   => 'fit',
				       group  => $fit,
				       sameas => $group,
				       parent => 0,
				       family => \%paths);
  my $titles = "";
  map { $titles .= $_ . "\n" } @{$args{titles}};
  $paths{$group} -> make(titles=>$titles);
  ## pc left off by default
  ## $paths{$group} -> make(pcplot=>(lc($args{fft_pc}) eq 'on') ? 'Yes' : 'No');

  ## display data
  display_page($group);
  $file_menu->menu->entryconfigure($save_index, -state=>'normal'); # data
  &plot('r', 0) unless $from_project;
  Echo("Opened record file \`$file\'.");
  project_state(0);

};

sub read_athena_record_on_windows {
  my ($file, $from_project, $change) = @_;
  &push_mru($file, 1, "record");
  use vars qw/$old_group @args @x @y @stddev/;
  open F, $file or die "could not open $file as an Athena record\n";
  while (<F>) {
    next if (/^\s*\#/);		# skip blank and commented lines
    next if (/^\s*$/);
    next if (/^\s*1/);
  SWITCH: {
      (/^\$old_group/) and do {
	$old_group = eval $_;
	last SWITCH;
      };
      (/^\@args/) and do {
	@args = eval $_;
	last SWITCH;
      };
      (/^\@x/) and do {
	@x = eval $_;
	last SWITCH;
      };
      (/^\@y/) and do {
	@y = eval $_;
	last SWITCH;
      };
      (/^\@stddev/) and do {
	@stddev = eval $_;
	last SWITCH;
      };
      ##(/^\$old_group\s*=\s*\'([^\']*)\';$/) and do {
      ##  $old_group = $1;
      ##  last SWITCH;
      ##};
      ((/^\[record\]/) or (/^\&read_record/)) and do {
	#my $memory_ok = &memory_check(0, 1);
	#Echo ("Out of memory in Ifeffit"), last DATA if ($memory_ok == -1);
	last SWITCH;
      };
      1;
    };
  };
  close F;

  ## read the args
  my %args;
  while (@args) {
    my ($key, $val) = (shift @args, shift @args);
    $args{$key} = $val;
  };
  Echo("$file is not an Athena chi(k) record and cannot be imported."),
    return unless $args{is_chi};

  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  $name = (split(/\./, $name))[0];
  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'normal')} (keys %widgets);
  map {$grab{$_}->configure(-state=>'normal')} (keys %grab);

  ## extract the useful parts of @args
  my $group = ($change) ? $paths{$current}->data : 'data'.&next_data;
  my $fit   = $group . '.0';

  ## fill the data arrays
  Ifeffit::put_array("$group.k",   \@x);
  Ifeffit::put_array("$group.chi", \@y);
  ++$n_data;

  if (($change) or (not $current)) {
    $paths{$group} -> make(group  =>$group, file =>$file, lab=>$name,
			   is_rec =>1,);
    $list -> entryconfigure($paths{$group}->get('id'), -text=>$name);
  } else {
    $paths{$group} = Ifeffit::Path -> new(id     => $group,
					  group  => $group,
					  type   => 'data',
					  sameas => 0,
					  file   => $file,
					  lab    => $name,
					  family => \%paths,);
    $list -> add($group, -text=>$name, -style=>$list_styles{enabled});
    $list -> setmode($group, 'none');

    $list -> add($group.".0", -text=>'Fit', -style=>$list_styles{enabled},);
    $list -> setmode($group.'.0', 'close');
    $list -> hide('entry', $group.".0");
  };
  $from_project or
    $paths{$group} -> make(kmin   =>$args{fft_kmin}, kmax   =>$args{fft_kmax},
			   dk     =>$args{fft_dk},   kwindow=>$args{fft_win},
			   rmin   =>$args{bft_rmin}, rmax   =>$args{bft_rmax},
			   dr     =>$args{bft_dr},   rwindow=>$args{bft_win},
			   pcedge =>$args{fft_edge}, pcelem =>$args{bkg_z});
 SWITCH: {
    $paths{$group} -> make(k1=>1), last SWITCH if ($args{fft_kw} eq 1);
    $paths{$group} -> make(k2=>1), last SWITCH if ($args{fft_kw} eq 2);
    $paths{$group} -> make(k3=>1), last SWITCH if ($args{fft_kw} eq 3);
    $paths{$group} -> make(karb_use=>1, karb=>$args{fft_kw});
  };
  $paths{$fit}  = Ifeffit::Path -> new(id     => $group.".0",
				       type   => 'fit',
				       group  => $fit,
				       sameas => $group,
				       parent => 0,
				       family => \%paths);
  my $titles = "";
  map { $titles .= $_ . "\n" } @{$args{titles}};
  $paths{$group} -> make(titles=>$titles);
  ## pc left off by default
  ## $paths{$group} -> make(pcplot=>(lc($args{fft_pc}) eq 'on') ? 'Yes' : 'No');

  ## display data
  display_page($group);
  $file_menu->menu->entryconfigure($save_index, -state=>'normal'); # data
  &plot('r', 0) unless $from_project;
  Echo("Opened record file \`$file\'.");
  project_state(0);

};
