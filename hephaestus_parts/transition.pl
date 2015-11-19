
## ===========================================================================
##  This is the transition chart portion of hephaestus

sub trans {
  $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
  switch({page=>"trans", text=>'Electronic Transitions of the Emission Lines for Any Element'});
};


sub setup_trans {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  my $transition_pic = $frame -> Photo(-file => File::Spec->catfile($hephaestus_lib, "transition.gif"));
  $frame -> Label(-image=>$transition_pic)
    -> pack(-anchor=>'center', -pady=>8);

  return $frame;
};
