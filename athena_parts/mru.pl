## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This implements the most-recently-used (MRU) file functionality


## handle the MRU stack.  Also deal with the global variables that
## keep track of the current working directory and the current project
## file name.
sub push_mru {
  my ($file, $push_file, $project, $complete) = @_;
  my ($name, $path, $suffix) = fileparse($file);

  ## set some global variables
  $current_data_dir = $path;
  ## if this is a project, then set the global project name
  ## variable. however, if the global variable is already set, then
  ## set the global variable to a single space.  the idea here is that
  ## the project name should be explicitly set upon saving in the case
  ## where projects are merged
  if ($project and $complete) {
    ##$project_name = ($project_name !~ /^\s*$/) ? " " : $file;
    $project_name = $file;
    $plot_features{project} = $project_name;
  };
  return unless ($push_file);

  ## check to see if this file is already in the sack
  my $im = $config{general}{mru_limit};
  my $ifound = 0;
  foreach my $i (1 .. $im-1) {
    next unless exists($mru{mru}{$i});
    ($ifound = $i), last if ($file eq $mru{mru}{$i});
  };
  ## if it is on the stack already, remove it and move all lower ones
  ## up
  if ($ifound) {
    foreach my $i ($ifound+1 .. $im) {
      my $j = $i - 1;
      $mru{mru}{$j} = $mru{mru}{$i};
    };
  };

  ## push each entry down in the stack
  foreach my $i (reverse(1 .. $im-1)) {
    my $j = $i + 1;
    $mru{mru}{$j} = $mru{mru}{$i};
  };
  ## push this file to the top of the stack
  $mru{mru}{1} = $file;

  ## update the mru menu
  &set_recent_menu;

  ## save the mru file
  tied(%mru) -> WriteConfig($mrufile);
};


sub set_recent_menu {
  my $menu = $file_menu -> cget('-menu') -> entrycget('Recent files', '-menu');
  $menu -> delete(0,'end');
  foreach my $i (1 .. $config{general}{mru_limit}) {
    last unless ($mru{mru}{$i});
    my $label = $mru{mru}{$i};
    ($label = basename($label)) if ($config{general}{mru_display} eq "name");
    $menu -> add('command', -label=>$label, @menu_args,
		 -command=>sub{&read_file(0, $mru{mru}{$i})});
  };
};



## END OF MRU SUBSECTION
##########################################################################################
