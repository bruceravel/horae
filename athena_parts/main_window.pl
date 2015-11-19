## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains the subroutine for dealing with
##  the Group list in the skinny frame


sub fill_skinny {

  my ($list, $item, $is_file, $dont_set) = @_;
  my $list_canvas = ($list->children())[0];
  #my ($group, $label) = group_name($item);
  my ($group, $label) = ($groups{$item}->{group}, $groups{$item}->{label});
  my $vio = $config{colors}{marked};

  ## begin drawing widgets on the skinny canvas

  ## the values for widget placement were determined by trial and error
  my $step = $config{list}{real_y}; # see delete_group in group_ops.pl
  my ($cx, $cy, $tx, $ty) = ($config{list}{real_x1}.'c',
			     sprintf("%4.2fc",1.1+$step*$line_count),
			     $config{list}{real_x2}.'c',,
			     sprintf("%4.2fc",1.1+$step*$line_count));

  ($is_file) and ($marked{$group} = 0);
  ++$group_count;
  my $tag = sprintf("line_%d", $group_count); # checkbutton for marking groups
  $groups{$item}->make(bindtag=>$tag);
  my $checkbutton;
  if ($is_file) {
    $checkbutton = $list -> Checkbutton(-selectcolor=>$vio, -variable => \$marked{$group},);
  } else {
    $checkbutton = $list -> Frame(qw/-width 18p -height 10p -borderwidth 0/);
  };
  my $check = $list -> createWindow($cx, $cy, -anchor=>'e', -window => $checkbutton);
  ## change text size/color unless passing over the current group
  ## (this works because the text has only one tag associated with it,
  ## which is the first item in the list returned by the itemcget method.
  ## Take care not to undo the orange group.  The rectangle is below the text.
  my @bold     = (-fill => $config{colors}{activehighlightcolor}, );
  my @normal   = (-fill => $config{colors}{foreground}, );
  my @rect_in  = (-fill => $config{colors}{activebackground}, -outline=>$config{colors}{activebackground});
  my @rect_out = (-fill => $config{colors}{background},       -outline=>$config{colors}{background});
  $list -> bind($tag, '<Any-Enter>'=>sub{my $this = shift;
					 return if not exists($groups{$current}->{bindtag});
					 $this->configure(-cursor => $mouse_over_cursor);
					 if ($this->itemcget('current', '-tags')->[0] ne $groups{$current}->{bindtag}) {
					   #$this->itemconfigure('current', @bold  );
					   my $x = $this->find(below=>'current');
					   $this->itemconfigure($x, @rect_in,);
					 }
				       });
  $list -> bind($tag, '<Any-Leave>'=>\&Leave);
## 		sub{my $this = shift;
## 					 return if not exists($groups{$current}->{bindtag});
## 					 if ($this->itemcget('current', '-tags')->[0] ne $groups{$current}->{bindtag}) {
## 					   my $x = $this->find(below=>'current');
## 					   $this->itemconfigure($x, @rect_out,);
## 					 };
## 				       }
  ## this rectangle is colored to indicate the selected group
  ## write the name of the group over the rectangle
  my $text = $list -> createText($tx, $ty, -anchor=>'w', -text=>$label, -tags=>$tag,
				 -font => $config{fonts}{med});
  ## see set_properties for how this rectangle is managed
  my $rect = $list -> createRectangle($list->bbox($text), #$tx1, $ty1, $tx2, $ty2,
				      -width=>5,
				      -fill=>$config{colors}{background},
				      -outline=>$config{colors}{background});
  $list_canvas->raise($text, $rect);

  ## set a few features of the data object that Athena uses to display
  ## the data
  $groups{$group} -> make(check=>$check, rect=>$rect, text=>$text, checkbutton=>$checkbutton);
  ## deal with the element and edge symbols
  if (not $reading_project) {
    if ($groups{$group}->{is_pixel}) {
      $groups{$group} -> make(bkg_z=>'H', fft_edge=>'K',);
    } elsif ($groups{$group}->{not_data}) {
      1;
    } elsif (lc($groups{$group}->{bkg_z}) eq 'h') {
      my ($sym, $edg) = find_edge($groups{$group}->{bkg_e0});
      $groups{$group} -> make(bkg_z=>$sym, fft_edge=>$edg,);
    };
    ## adjust e0 if configured for half-step, zero crossing, or atomic
    if ($config{bkg}{e0} eq 'fraction') {
      $groups{$group} -> dispatch_bkg($dmode);
      set_edge($group, 'fraction');
    } elsif ($config{bkg}{e0} eq 'zero') {
      $groups{$group} -> dispatch_bkg($dmode);
      set_edge($group, 'zero');
    } elsif ($config{bkg}{e0} eq 'atomic') {
      Echo("Cannot fetch atomic e0 values."), return unless $absorption_exists;
      $groups{$group} -> dispatch_bkg($dmode);
      set_edge($group, 'atomic');
    };
    set_edge_peak($group) if (    $config{bkg}{ledgepeak}
			      and get_Z($config{bkg}{ledgepeak})
			      and (get_Z($groups{$group}->{bkg_z}) > get_Z($config{bkg}{ledgepeak}))
			      and ($groups{$group}->{fft_edge} =~ m{l[23]}i)
			     );
  };
  $groups{$group} -> make(bkg_eshift=>0) unless ($groups{$group}->{bkg_eshift} =~ /-?(\d+\.?\d*|\.\d+)/);
  $groups{$group} -> make(bkg_nclamp	=> $config{bkg}{nclamp},
			  bkg_tie_e0	=> 0,
			  bkg_former_e0	=> $groups{$group}->{bkg_e0});

  ## adjust view so this one is showing
  push @skinny_list, $check, $rect, $text;
  my $h = ($list->bbox(@skinny_list))[3] + 5;
  if ($h > 200) {
    $list -> configure(-scrollregion=>['0', '0', '200', $h]);
    $list -> yview('moveto', 1);
  };

  ## mouse bindings in the groups list
  #$list -> bind($tag, '<Double-Button-1>' => sub{set_properties($group, 0); &get_new_name;});
  $list -> bind($tag, '<Double-Button-1>' => sub{set_properties(1, $group, 0); $list_canvas->focus; &get_new_name;});
  $list -> bind($tag, '<1>' => [\&set_properties, $group, 0]);
  $list -> bind($tag, '<2>' => sub{$marked{$group} = !$marked{$group}});
  ($is_file) and
    $list -> bind($tag, '<3>' => [\&GroupsPopupMenu, $group, Ev('X'), Ev('Y')]);

  ## finally, fill parameters into the fat canvas
  set_properties(1, $group, 0) unless $dont_set;
  project_state(0);
};


## END OF GROUP LIST SUBSECTION
##########################################################################################
