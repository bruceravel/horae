#!/usr/bin/perl -w
######################################################################
## Space Group Browser for TkAtoms using Atoms version 3.0beta9
##                                     copyright (c) 1999 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##	    http://feff.phys.washington.edu/~ravel/software/atoms/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it under the same terms as Perl
##     itself.
##
##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     Artistic License for more details.
## -------------------------------------------------------------------
######################################################################
## $Id: SGB.pm,v 1.3 1999/05/19 22:23:25 bruce Exp $
######################################################################
##
## This is a perl module supplying the space group browser widget.
## This was developed for use with TkAtoms.
##
## To use the space group browser, insert this in the appropriate
## place in the main program:
##           use Xray::Tk::SGB;
## 	     $browser =  $top -> SGB(-SpaceWidget=>\$space_field);
##           $browser -> configure(@sgb_args);
##           $browser -> Show;
##
## $top is the top level widget.  \$space_field is a reference to the
## widget into which the browser should insert a space group symbol.
## Typically this is an Entry widget.
##
######################################################################
##
## To do:
##
######################################################################
## Code:

=head1 NAME

Xray::Tk::SGB - A widget for browsing space group symbols

=head1 DESCRIPTION

This widget is composite of a Text field, and Entry field, and two
Buttons which supply as simple textual browsing mechanism for
exploring space group symbols.  In a typical use, it is hooked up to
an Entry widget in a perl/Tk application so that a space group symbol
can be specified in the application with the click of a mouse.

=head1 SYNOPSIS

     use Tk;
     use Xray::Xtal;
     use Xray::Tk::SGB;
     $browser =  $top -> SGB(-SpaceWidget=>\$space_field);
     $browser -> configure(@sgb_args);
     $browser -> Show;

Configuration parameters are described below.

=head1 METHODS

The only non-standard method is C<Show>, which is used to actually
display the browser on your screen.  C<Show> always returns 0;

=head1 CONFIGURATION OPTIONS

=over 4

=item -SpaceWidget

This is a reference to a widget, typically an Entry widget, into which
the browser will insert space group symbols.  If this is undefined or
not a reference to a widget, then the Mouse-1 action of the browser is
disabled.

=item -sgbActive

The color of active text in the browser.

=item -sgbGroup

The color used for particular emphasis of active text.

=item -button

Background color of the button.

=item -buttonActive

Active color of the buttons.  Also the color of the text in the statusbar.

=item -buttonLabel

Color of the text on the buttons.

=item -buttonFont

The font to use on the button.

=item -sgbFont

The font to use in the text and status areas of the browser.  This
looks best if it is a fixed width font.

=back

Other properties, such as C<-foreground> are inherited and may be
configured.


=head1 INTERNATIONALIZATION

All of the text displayed in the SGB widget can be customized using
configure.  The primary purpose of this is to allow the use of other
languages in the SGB widget.  The following list shows the configure
switch and its default value.  You should play around with SGB before
translating or otherwise changing them so you can see what each string
is used for.

=over 4

=item -dismiss

  Dismiss

=item -back

  Back

=item -restore

  Restore

=item -Triclinic

  Triclinic

=item -Monoclinic

  Monoclinic

=item -Orthorhombic

  Orthorhombic

=item -Tetragonal

  Tetragonal

=item -Trigonal

  Trigonal

=item -Hexagonal

  Hexagonal

=item -Cubic

  Cubic

=item -MouseLInsert

  Mouse-1 to insert this symbol.

=item -MouseLDisplay

  Mouse-1 to display space group

=item -MouseADisplay

  Any mouse button for groups of this class.

=item -RestoreMsg

  Restore the initial symbol:

=item -DismissMsg

  Dismiss the space group browser.

=item -Groups

  groups

=item -MouseLR

  Mouse-1=insert  Mouse-3=describe

=item -BackScreen

  Return to the previous screen.

=item -Number

  Number

=item -NumberDesc

  Space group index from ITC

=item -Schoenflies

  Schoenflies

=item -SchoenfliesDesc

  Schoenflies notation

=item -Full

  Full symbol

=item -FullDesc

  Symbol denoting complete symmetries

=item -NewSymbol

  New symbol

=item -NewSymbolDesc

  Symbol using \"e\" for the glide plane

=item -Thirtyfive

  1935 symbol

=item -ThirtyfiveDesc

  Symbol from the 1935 edition of ITXC

=item -Shorthand

  Shorthand

=item -ShorthandDesc

  Special strings recognized by Atoms

=item -Settings

  Settings

=item -SettingsDesc

  Symbols for alternate settings

=item -Short

  Short symbols

=item -ShortDesc

  Short symbols for alternate settings

=item -TopTop

  Select a crystal class to display all space groups
  within that class.

=item -ViewCurrent

  View current group:

=item -ClassTop

  Space group listing:

=item -GroupTop

  Various symbols which may be used to describe space group:

=item -Note

  Note:

=item -SettingsMon

  The first three settings are for the b axis and beta
  angle unique.  The next three are for the c axis and
  gamma angle unique.  The final three are for the a
  axis and alpha angle unique.  Within each group, the
  three choices are the possible choices of axes. Atoms
  has no a priori way of knowing the correct setting
  for your data.

=item -SettingsOrt

  The five additional settings correspond to the five
  additional ways of setting a coordinate system in
  3-space.  They correspond to permutations of ba-c,
  cab, -cba, bca, and a-cb away from the standard
  setting, abc.  Atoms has no a priori way of knowing
  the correct setting for your data.

=item -SettingsTet

  C and F centered tetragonal cells are related to the
  standard cells by a 45 degree rotation in ab plane
  and a doubling of the cell volume.  Atoms has no a
  priori way of knowing the correct setting for your
  data.

=item -SettingsRho

  You may use the rhombohedral parameters, in which
  case you must specify a and alpha.  You may also use
  the trigonal parameters in which case you must
  specify a and c.  The trigonal representation has
  three times the volume of the rhombohedral
  representation.  Atoms has no a priori way of knowing
  the correct setting for your data.



=back


=head1 USING THE SPACE GROUP BROWSER

Use of the browser is pretty straight forward because the status bar
at the bottom of the widget always informs the user about what actions
are available.

The opening panel displays the seven crystal classes.  The names of
the crystal classes are active text.  Clicking any mouse button on a
crystal class will display a list of all space groups in that class.
If the widget specified by C<-SpaceWidget> is displaying a valid group
symbol, then that symbol will be displayed as active text.  Clicking
Mouse-1 one on that symbol will jump to the panel describing that
symbol.

The second panel displays lists of space groups divided by crystal
class.  The index of the group (as indexed in the International Tables
of Crystallography) and the canonical (Hermann-Maguin) space group
symbol are shown.  The space group symbols are active text.  Clicking
Mouse-1 will insert that symbol into the widget given by
C<-SpaceWidget>. Clicking Mouse-3 will display information about that
group.

The last panel is the space group description.  It shows all symbols
recognized as describing that group by the database in C<Xray::Xtal>,
which is use-ed by C<Xray::Tk::SGB>. Clicking Mouse-1 on any active
text will insert that symbol into the widget given by C<-SpaceWidget>.

At the bottom of the widget are three buttons.  The C<back> button
causes the previous panel to be displayed.  The C<restore> is only
active if the widget given by C<-SpaceWidget> contains a symbol.  If so,
pressing it will restore that widget to its initial value.  The
C<dismiss> button destroys the SGB widget.


=head1 TO DO

=over 4

=item *

The interaction of SGB(), configure(), and Show() is not as smooth as
it should be.

=back

=head1 Author

  Bruce Ravel <ravel@phys.washington.edu> (c) 1999
  http://feff.phys.washington.edu/~ravel/software/
  http://feff.phys.washington.edu/~ravel/software/atoms/

This code is distributed with Atoms and may be redistributed under the
same terms as Atoms, which are the same terms as Perl itself.

=cut



package Xray::Tk::SGB;

require 5.002;
use Tk;
use Tk::Balloon;
use Carp;
use strict;
use Xray::Xtal;

@Xray::Tk::SGB::ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('SGB');

$Xray::Tk::SGB::VERSION = '0.03';


my ($sg_back_button, $sg_dismiss_button, $sg_restore_button, $sg_t, $sg_status,
    $sg_balloon, $sg_space_widget, $sg_cache);
my %sgb_top_hints;

# SGB object constructor.  Uses `new' method from base class
# to create object container then creates the dialog toplevel.
sub Populate {
  my($sgb, @args) = @_;
  $sgb -> SUPER::Populate(@args);
  ##print $sgb->class, $/;
  $sgb -> resizable(0,0);
  $sgb -> title("Space Group Browser");
  $sgb -> iconname("Space Group Browser");
  $sgb -> bind('<Control-q>' => sub{$sgb->withdraw});
  $sgb -> bind('<Control-d>' => sub{$sgb->withdraw});
  $sgb -> protocol(WM_DELETE_WINDOW => sub{$sgb->withdraw});

  ## fill it up with widgets
  $sg_t = $sgb->Scrolled(qw/Text -setgrid true -width  50 -height 30
			 -wrap word -scrollbars e/)
    -> pack();
  $sg_t -> Subwidget("yscrollbar")
    -> configure(-background=>$sg_t->cget('-background'));
  $sg_t->tag(qw/configure bold -font/, $sgb->cget('-sgbFont') );
  &disable_mouse3($sg_t->Subwidget('text'));
  $sg_t->tag(qw/configure margins -lmargin1 6m -lmargin2 6m -rmargin 10m/);
  $sg_t->tag('bind', 'unhint', '<Any-Leave>' =>
	     sub {$sg_status -> delete(qw/0 end/)} );


  $sg_status = $sgb->Entry(qw/-width  50 -borderwidth 1 -relief sunken/)
    -> pack();
  $sg_balloon = $sgb -> Balloon(-borderwidth=>0, -initwait=>0,
				-state=>'status', -statusbar=>$sg_status,
			       );

  $sg_restore_button = $sgb -> Button(-command => \&sg_restore_symbol)
    -> pack(-side=>'left', -padx=>4,);
  $sg_restore_button -> configure(-state=>'disabled');
  $sg_back_button = $sgb -> Button() -> pack(-side=>'left', -padx=>4,);
  $sg_dismiss_button = $sgb -> Button(-command => sub{$sgb->withdraw})
    -> pack(-side=>'right', -padx=>4,);

  $sgb->Advertise(text_area      => $sg_t);
  $sgb->Advertise(status_area    => $sg_status);
  $sgb->Advertise(dimiss_button  => $sg_dismiss_button);
  $sgb->Advertise(back_button    => $sg_back_button);
  $sgb->Advertise(restore_button => $sg_restore_button);


  $sgb ->
    ConfigSpecs(
		-sgbActive    => ['PASSIVE', undef, undef, '#0000ff'], # blue
		-sgbGroup     => ['PASSIVE', undef, undef, '#9400d3'], # darkviolet
		-button       => ['PASSIVE', undef, undef,
				  $sg_back_button->cget('-background')],
		-buttonActive => ['PASSIVE', undef, undef,
				  $sg_back_button->cget('-activebackground')],
		-buttonLabel  => ['PASSIVE', undef, undef,
				  $sg_back_button->cget('-activeforeground')],
		-buttonFont   => ['PASSIVE', undef, undef,
		                  $sg_back_button->cget('-font')],
		-sgbFont      => ['PASSIVE', undef, undef, $sg_t->cget('-font')],
		-dismiss      => ['PASSIVE', undef, undef, 'Dismiss'],
		-back         => ['PASSIVE', undef, undef, 'Back'],
		-restore      => ['PASSIVE', undef, undef, 'Restore'],
		-SpaceWidget  => ['PASSIVE', undef, undef, undef],
		-Triclinic    => ['PASSIVE', undef, undef, 'Triclinic'],
		-Monoclinic   => ['PASSIVE', undef, undef, 'Monoclinic'],
		-Orthorhombic => ['PASSIVE', undef, undef, 'Orthorhombic'],
		-Tetragonal   => ['PASSIVE', undef, undef, 'Tetragonal'],
		-Trigonal     => ['PASSIVE', undef, undef, 'Trigonal'],
		-Hexagonal    => ['PASSIVE', undef, undef, 'Hexagonal'],
		-Cubic        => ['PASSIVE', undef, undef, 'Cubic'],
		-MouseLInsert => ['PASSIVE', undef, undef,
				  'Mouse-1 to insert this symbol.'],
		-MouseLDisplay => ['PASSIVE', undef, undef,
				   'Mouse-1 to display space group'],
		-MouseADisplay => ['PASSIVE', undef, undef,
				   'Any mouse button for groups of this class.'],
		-RestoreMsg   => ['PASSIVE', undef, undef,
				  'Restore the initial symbol: '],
		-DismissMsg   => ['PASSIVE', undef, undef,
				  'Dismiss the space group browser.'],
		-Groups       => ['PASSIVE', undef, undef, 'groups'],
		-MouseLR      => ['PASSIVE', undef, undef,
				  'Mouse-1=insert  Mouse-3=describe'],
		-BackScreen   => ['PASSIVE', undef, undef,
				  'Return to the previous screen.'],
		-Number       => ['PASSIVE', undef, undef, 'Number'],
		-NumberDesc   => ['PASSIVE', undef, undef,
				  'Space group index from ITC'],
		-Schoenflies      => ['PASSIVE', undef, undef, 'Schoenflies'],
		-SchoenfliesDesc  => ['PASSIVE', undef, undef,
				  'Schoenflies notation'],
		-Full	      => ['PASSIVE', undef, undef,
				  'Symbol denoting complete symmetries'],
		-FullDesc     => ['PASSIVE', undef, undef, 'Full symbol'],
		-NewSymbol     => ['PASSIVE', undef, undef, 'New symbol'],
		-NewSymbolDesc => ['PASSIVE', undef, undef,
				   'Symbol using \"e\" for the glide plane'],
		-Thirtyfive     => ['PASSIVE', undef, undef, '1935 symbol'],
		-ThirtyfiveDesc => ['PASSIVE', undef, undef,
				    'Symbol from the 1935 edition of ITXC'],
		-Shorthand      => ['PASSIVE', undef, undef, 'Shorthand'],
		-ShorthandDesc  => ['PASSIVE', undef, undef,
				    'Special strings recognized by Atoms'],
		-Settings      => ['PASSIVE', undef, undef, 'Settings'],
		-SettingsDesc  => ['PASSIVE', undef, undef,
				    'Symbols for alternate settings'],
		-Short      => ['PASSIVE', undef, undef, 'Short symbols'],
		-ShortDesc  => ['PASSIVE', undef, undef,
				'Short symbols for alternate settings'],

		'-TopTop' => ['PASSIVE', undef, undef,
			      'Select a crystal class to display all space groups within that class.'],
		'-ViewCurrent' => ['PASSIVE', undef, undef, 'View current group:'],
		'-ClassTop' => ['PASSIVE', undef, undef, 'Space group listing:'],
		'-GroupTop' => ['PASSIVE', undef, undef,
				'Various symbols which may be used to describe space group:'],
		'-Note' => ['PASSIVE', undef, undef, 'Note:'],

		'-SettingsMon' => ['PASSIVE', undef, undef,
				   'The first three settings are for the b axis and beta angle unique.  The next three are for the c axis and gamma angle unique.  The final three are for the a axis and alpha angle unique.  Within each group, the three choices are the possible choices of axes. Atoms has no a priori way of knowing the correct setting for your data.'],

		'-SettingsOrt' => ['PASSIVE', undef, undef,
				   'The five additional settings correspond to the five additional ways of setting a coordinate system in 3-space.  They correspond to permutations of ba-c, cab, -cba, bca, and a-cb away from the standard setting, abc.  Atoms has no a priori way of knowing the correct setting for your data.'],

		'-SettingsTet' => ['PASSIVE', undef, undef,
				   'C and F centered tetragonal cells are related to the standard cells by a 45 degree rotation in ab plane and a doubling of the cell volume.  Atoms has no a priori way of knowing the correct setting for your data.'],

		'-SettingsRho' => ['PASSIVE', undef, undef,
				   'You may use the rhombohedral parameters, in which case you must specify a and alpha.  You may also use the trigonal parameters in which case you must specify a and c.  The trigonal representation has three times the volume of the rhombohedral representation.  Atoms has no a priori way of knowing the correct setting for your data.'],

		#-foreground   => ['ADVERTISED','foreground','Foreground','black'],
		#-background   => ['DESCENDANTS','background','Background',undef],
		DEFAULT       => ['text_area',undef,undef,undef]
	       );
  $sgb->Delegates('Construct' => $sg_t);

} # end Dialog constructor


# SGB object public method - finish configuring and display the browser.
sub Show {
  my $sgb = $_[0];

  %sgb_top_hints = ("Tri" => [$sgb->cget('-Triclinic'),     1,   2],
		    "Mon" => [$sgb->cget('-Monoclinic'),    3,  15],
		    "Ort" => [$sgb->cget('-Orthorhombic'), 16,  74],
		    "Tet" => [$sgb->cget('-Tetragonal'),   75, 142],
		    "Trg" => [$sgb->cget('-Trigonal'),    143, 167],
		    "Hex" => [$sgb->cget('-Hexagonal'),   168, 194],
		    "Cub" => [$sgb->cget('-Cubic'),       195, 230]);


  $sg_t -> configure(-font => $sgb->cget('-sgbFont'));
  $sg_t -> tag(qw/configure color1 -foreground/, $sgb->cget('-foreground') );
  $sg_t -> tag(qw/configure color2 -foreground/, $sgb->cget('-sgbActive') );
  $sg_t -> tag(qw/configure color3 -foreground/, $sgb->cget('-sgbGroup') );
  $sg_t->tag('bind', 'hint_insert', '<Any-Enter>' =>
	     [\&hint, $sgb->cget('-MouseLInsert')]);

  $sg_status -> configure(-foreground => $sgb->cget('-buttonActive'),
			  -font       => $sgb->cget('-sgbFont'));
  $sg_dismiss_button ->
    configure(
	      -text		=> $sgb->cget('-dismiss'),
	      -foreground	=> $sgb->cget('-buttonLabel'),
	      -background	=> $sgb->cget('-button'),
	      -activeforeground	=> $sgb->cget('-buttonLabel'),
	      -activebackground => $sgb->cget('-buttonActive'),
	      -font		=> $sgb->cget('-buttonFont'),);
  $sg_balloon -> attach($sg_dismiss_button,
			-statusmsg=>$sgb->cget('-DismissMsg'));
  $sg_back_button ->
    configure(
	      -text		=> $sgb->cget('-back'),
	      -foreground	=> $sgb->cget('-buttonLabel'),
	      -background	=> $sgb->cget('-button'),
	      -activeforeground	=> $sgb->cget('-buttonLabel'),
 	      -activebackground => $sgb->cget('-buttonActive'),
	      -font		=> $sgb->cget('-buttonFont'),
	      -command		=> sub{1});
  $sg_restore_button ->
    configure(
	      -text		=> $sgb->cget('-restore'),
	      -foreground	=> $sgb->cget('-buttonLabel'),
	      -background	=> $sgb->cget('-button'),
	      -activeforeground	=> $sgb->cget('-buttonLabel'),
 	      -activebackground => $sgb->cget('-buttonActive'),
	      -font		=> $sgb->cget('-buttonFont'),);

  if (Exists($ {$sgb->cget('-SpaceWidget')})) {
    $sg_space_widget = $sgb->cget('-SpaceWidget');
    unless ($$sg_space_widget -> get() =~ /^\s*$/) {
      $sg_restore_button -> configure(-state=>'normal');
      $sg_cache ||= $$sg_space_widget -> get();
      my $str = join(" ", $sgb->cget('-RestoreMsg'), $sg_cache);
      $sg_balloon -> attach($sg_restore_button, -statusmsg=>$str);
    };
  };

  &space_group_browser_top($sgb);
  return 0;
};




### private subroutines

sub space_group_browser_top {
  my $sgb = $_[0];
  my $str = "";
  $sg_back_button -> configure(-state=>'disabled');
  $sg_balloon -> detach($sg_back_button);
  $sg_t -> configure(-state=>'normal');
  $sg_t -> delete(qw/1.0 end/);
  inswt($sg_t, "\n\n");
  inswt($sg_t, $sgb->cget('-TopTop'), 'margins');
  inswt($sg_t, "\n\n");
  foreach my $class ("Tri", "Mon", "Ort", "Tet", "Trg", "Hex", "Cub") {
    $sg_t->tag('bind', 'hint'.$class, '<Any-Enter>' =>
	       [\&hint, $sgb->cget('-MouseADisplay')]);
    $sg_t->tag('bind', 'm1'.$class, '<1>' =>
	   [\&space_group_browser_class, $sgb, $class]);
    $sg_t->tag('bind', 'm2'.$class, '<2>' =>
	   [\&space_group_browser_class, $sgb, $class]);
    $sg_t->tag('bind', 'm3'.$class, '<3>' =>
	   [\&space_group_browser_class, $sgb, $class]);

    inswt($sg_t, "     $sgb_top_hints{$class}->[0]",
	  'color2', 'hint'.$class, 'unhint', 'm1'.$class, ,
	  'm2'.$class, 'm3'.$class);
    inswt($sg_t, " " x (15 - length($sgb_top_hints{$class}->[0])));
    inswt($sg_t, "(" . $sgb->cget('-Groups') . " $sgb_top_hints{$class}->[1]-" .
	  "$sgb_top_hints{$class}->[2])\n\n");
  };

  my $current_group;
  Exists($$sg_space_widget) and
    $current_group = $$sg_space_widget -> get();
  if ($current_group) {

    my ($group, $foo) = Xray::Xtal::Cell::canonicalize_symbol($current_group);
    my $class;
    my $this  = Xray::Xtal::Cell::describe_group($group);
    (exists $$this{number}) && do {
      my $index = $$this{number};
    CLASS: {
	$class = "",    last CLASS if ($index <=  0);
	$class = "Tri", last CLASS if ($index <=  2);
	$class = "Mon", last CLASS if ($index <=  15);
	$class = "Ort", last CLASS if ($index <=  74);
	$class = "Tet", last CLASS if ($index <= 142);
	$class = "Trg", last CLASS if ($index <= 167);
	$class = "Hex", last CLASS if ($index <= 194);
	$class = "Cub", last CLASS if ($index <= 230);
	$class = ""
      };
      $sg_t->tag('bind', 'm1_current', '<1>' =>
		 [\&space_group_browser_group, $sgb, $group, $class]);
      $str = $sgb->cget('-MouseLDisplay') . " " . $current_group;
      $sg_t->tag('bind', 'hint_current', '<Any-Enter>' => [\&hint, $str]);
      inswt($sg_t, $sgb->cget('-ViewCurrent') . " ",
	    qw/margins m1_current hint_current unhint/);
      inswt($sg_t, "$current_group",
	    qw/margins color3 m1_current hint_current unhint/);
    };
  };
  $sg_t -> configure(-state=>'disabled');
};

sub space_group_browser_class {
  my $sgb = $_[1];
  my $token = $_[2];
  ##print "sgb ref: ", $sgb, $/, "token: ", $token, $/;
  my ($class, $first, $last) = @{$sgb_top_hints{$token}};
  my @sg_list = &generate_sg_list;
  $sg_back_button -> configure(-state=>'normal',
			       -command=>[\&space_group_browser_top, $sgb],
			      );
  $sg_balloon -> attach($sg_back_button,
			-statusmsg=>$sgb->cget('-BackScreen'));
  $sg_t -> configure(-state=>'normal');
  $sg_t -> delete(qw/1.0 end/);
  inswt($sg_t, "\n  " . $sgb->cget('-ClassTop') . " " . $class . "\n\n");

  foreach my $i ($first .. $last) {
    my $this = $i-1;
    $sg_t->tag('bind', 'hintGroup'.$i, '<Any-Enter>' =>
	       [\&hint, sprintf("%-10s: ", $sg_list[$this]) .
		$sgb->cget('-MouseLR')]);
    $sg_t->tag('bind', 'm1_'.$i, '<1>' =>
	       [\&sg_browser_dispose, $sg_list[$this]]);
    $sg_t->tag('bind', 'm3_'.$i, '<3>' =>
	   [\&space_group_browser_group, $sgb, $sg_list[$this], $token]);

    inswt($sg_t, sprintf("    %3s: ", $i));
    inswt($sg_t, sprintf("%-10s", $sg_list[$this]),
	  qw/color2 unhint/, 'hintGroup'.$i, 'm1_'.$i, 'm3_'.$i);
    inswt($sg_t, "\n");
  };
  $sg_t -> configure(-state=>'disabled');
};


sub space_group_browser_group {
  my ($sgb, $group, $class) = ($_[1], $_[2], $_[3]);
  $sg_back_button -> configure(-state=>'normal',
			       -command=>[\&space_group_browser_class,
					  " ", $sgb, $class],
			      );
  $sg_balloon -> attach($sg_back_button,
			-statusmsg=>$sgb->cget('-BackScreen'));
  $sg_t -> configure(-state=>'normal');
  $sg_t -> delete(qw/1.0 end/);
  inswt($sg_t, "\n");
  inswt($sg_t, $sgb->cget('-GroupTop'));
  inswt($sg_t, " ");
  $sg_t->tag('bind', 'm1_canonical', '<1>' => [\&sg_browser_dispose, $group]);
  inswt($sg_t, $group, qw/color3 m1_canonical hint_insert unhint/);
  inswt($sg_t, "\n\n");
  ## inswt($sg_t, "  Atoms will usually interpret correctly symbols " .
  ##       "entered without white space.\n\n");

  my $this = Xray::Xtal::Cell::describe_group($group);

  ## insert fields from space groups hash which are scalar valued
  my %labels = ("number"       =>
		[$sgb->cget("-Number"),      $sgb->cget("-NumberDesc")],
		"schoenflies"  =>
		[$sgb->cget("-Schoenflies"), $sgb->cget("-SchoenfliesDesc")],
		"full"	       =>
		[$sgb->cget("-Full"),        $sgb->cget("-FullDesc")],
		"new_symbol"   =>
		[$sgb->cget("-NewSymbol"),   $sgb->cget("-NewSymbolDesc")],
		"thirtyfive"   =>
		[$sgb->cget("-Thirtyfive"),  $sgb->cget("-ThirtyfiveDesc")],
	       );
  foreach my $field (qw/number schoenflies full new_symbol thirtyfive/) {
    next unless exists $$this{$field};

    $sg_t->tag('bind', 'hint_'.$field, '<Any-Enter>' =>
	    [\&hint, $labels{$field}->[1]]);
    inswt($sg_t, sprintf("  %13s: ", $labels{$field}->[0]),
	  'hint_'.$field, 'unhint');

    my $sym = $$this{$field};
    $sg_t->tag('bind', 'm1_'.$field, '<1>' => [\&sg_browser_dispose, $sym]);
    inswt($sg_t, $sym, 'color2', 'm1_'.$field, 'hint_insert', 'unhint');

    inswt($sg_t, "\n\n");
  };

  ## insert shorthand notation
  if (exists $$this{'shorthand'}) {

    $sg_t->tag('bind', 'hint_shorthand', '<Any-Enter>' =>
	    [\&hint, $sgb->cget('-ShorthandDesc')]);
    inswt($sg_t, sprintf("  %13s: ", $sgb->cget('-Shorthand')),
	  'hint_shorthand', 'unhint');

    my $counter = 0;
    foreach my $sh (@{$$this{'shorthand'}}) {
      $counter and inswt($sg_t, " " x 17);
      ++$counter;
      $sg_t->tag('bind', 'm1_'.$sh, '<1>' => [\&sg_browser_dispose, $sh]);
      inswt($sg_t, $sh, 'color2', 'm1_'.$sh, 'hint_insert', 'unhint');
      inswt($sg_t, "\n");
    };
    inswt($sg_t, "\n");
  };

  ## symbols for alternate settings
  if (exists $$this{'settings'}) {

    $sg_t->tag('bind', 'hint_settings', '<Any-Enter>' =>
	    [\&hint, $sgb->cget('-SettingsDesc')]);
    inswt($sg_t, sprintf("  %13s: ", $sgb->cget('-Settings')),
	  'hint_settings', 'unhint');

    my $counter = 0;
    foreach my $sh (@{$$this{'settings'}}) {
      $counter and inswt($sg_t, " " x 17);
      ++$counter;
      $sg_t->tag('bind', 'm1_'.$counter, '<1>' => [\&sg_browser_dispose, $sh]);
      inswt($sg_t, $sh, 'color2', 'm1_'.$counter, 'hint_insert', 'unhint');
      inswt($sg_t, "\n");
    };
    inswt($sg_t, "\n");
  };

  ## short symbols for alternate settings (monoclinic)
  if (exists $$this{'short'}) {

    $sg_t->tag('bind', 'hint_short', '<Any-Enter>' =>
	    [\&hint, $sgb->cget('-ShortDesc')]);
    inswt($sg_t, sprintf("  %13s: ", $sgb->cget('-Short')),
	  'hint_short', 'unhint');

    my $counter = 0;
    foreach my $sh (@{$$this{'short'}}) {
      $counter and inswt($sg_t, " " x 17);
      ++$counter;
      $sg_t->tag('bind', 'm1_short_'.$counter, '<1>' =>
	      [\&sg_browser_dispose, $sh]);
      inswt($sg_t, $sh, 'color2', 'm1_short_'.$counter,
	    'hint_insert', 'unhint');
      inswt($sg_t, "\n");
    };
    inswt($sg_t, "\n");
  };

  my %settings_explain =
    ("Mon" => $sgb->cget(-'SettingsMon'),
     "Ort" => $sgb->cget(-'SettingsOrt'),
     "Tet" => $sgb->cget(-'SettingsTet'),
     );

  if (exists $$this{'settings'}) {
    inswt($sg_t, $sgb->cget('-Note')."\n", qw/bold/);
    inswt($sg_t, $settings_explain{$class}, qw/margins/);
  };

  if ($group =~ /^r/i) {
    inswt($sg_t, $sgb->cget('-Note')."\n", qw/bold/);
    inswt($sg_t, $sgb->cget(-'SettingsRho'), qw/margins/);
  };
  $sg_t -> configure(-state=>'disabled');
};


sub disable_mouse3 {
  my $text = $_[0];
  my @swap_bindtags = $text->bindtags;
  $text -> bindtags([@swap_bindtags[1,0,2,3]]);
  $text -> bind('<Button-3>' => sub{$_[0]->break});
};


sub hint {
  $sg_status -> delete(qw/0 end/);
  $sg_status -> insert(0, $_[1]);
};


sub inswt {
  # insert_with_tags
  #
  # The procedure below inserts text into a given text widget and applies
  # one or more tags to that text.  The arguments are:
  #
  # w		Window in which to insert
  # text	Text to insert (it's inserted at the "insert" mark)
  # args	One or more tags to apply to text.  If this is empty then all
  #           tags are removed from the text.
  # swiped from widget demo
  my($w, $text, @args) = @_;
  my $start = $w->index('insert');
  $w->insert('insert', $text);
  foreach my $tag ($w->tagNames($start)) {
    $w->tagRemove($tag, $start, 'insert');
  };
  foreach my $i (@args) {
    $w->tagAdd($i, $start, 'insert');
  };
};				# end inswt


sub sg_restore_symbol {
  $$sg_space_widget -> delete(qw/0 end/);
  $$sg_space_widget -> insert(0, $sg_cache);
};

sub sg_browser_dispose {
  ## local $| = 1;
  ## print $_[1], $/;
  ## print $$sg_space_widget, $/;
  if (Exists($$sg_space_widget))  {
    $$sg_space_widget -> delete(qw/0 end/);
    $$sg_space_widget -> insert(0, $_[1]);
  };
};

sub generate_sg_list {
  return ('p 1',
	  'p -1',
	  'p 2',
	  'p 21',
	  'c 2',
	  'p m',
	  'p c',
	  'c m',
	  'c c',
	  'p 2/m',
	  'p 21/m',
	  'c 2/m',
	  'p 2/c',
	  'p 21/c',
	  'c 2/c',
	  'p 2 2 2',
	  'p 2 2 21',
	  'p 21 21 2',
	  'p 21 21 21',
	  'c 2 2 21',
	  'c 2 2 2',
	  'f 2 2 2',
	  'i 2 2 2',
	  'i 21 21 21',
	  'p m m 2',
	  'p m c 21',
	  'p c c 2',
	  'p m a 2',
	  'p c a 21',
	  'p n c 2',
	  'p m n 21',
	  'p b a 2',
	  'p n a 21',
	  'p n n 2',
	  'c m m 2',
	  'c m c 21',
	  'c c c 2',
	  'a m m 2',
	  'a b m 2',
	  'a m a 2',
	  'a b a 2',
	  'f m m 2',
	  'f d d 2',
	  'i m m 2',
	  'i b a 2',
	  'i m a 2',
	  'p m m m',
	  'p n n n',
	  'p c c m',
	  'p b a n',
	  'p m m a',
	  'p n n a',
	  'p m n a',
	  'p c c a',
	  'p b a m',
	  'p c c n',
	  'p b c m',
	  'p n n m',
	  'p m m n',
	  'p b c n',
	  'p b c a',
	  'p n m a',
	  'c m c m',
	  'c m c a',
	  'c m m m',
	  'c c c m',
	  'c m m a',
	  'c c c a',
	  'f m m m',
	  'f d d d',
	  'i m m m',
	  'i b a m',
	  'i b c a',
	  'i m m a',
	  'p 4',
	  'p 41',
	  'p 42',
	  'p 43',
	  'i 4',
	  'i 41',
	  'p -4',
	  'i -4',
	  'p 4/m',
	  'p 42/m',
	  'p 4/n',
	  'p 42/n',
	  'i 4/m',
	  'i 41/a',
	  'p 4 2 2',
	  'p 4 21 2',
	  'p 41 2 2',
	  'p 41 21 2',
	  'p 42 2 2',
	  'p 42 21 2',
	  'p 43 2 2',
	  'p 43 21 2',
	  'i 4 2 2',
	  'i 41 2 2',
	  'p 4 m m',
	  'p 4 b m',
	  'p 42 c m',
	  'p 42 n m',
	  'p 4 c c',
	  'p 4 n c',
	  'p 42 m c',
	  'p 42 b c',
	  'i 4 m m',
	  'i 4 c m',
	  'i 41 m d',
	  'i 41 c d',
	  'p -4 2 m',
	  'p -4 2 c',
	  'p -4 21 m',
	  'p -4 21 c',
	  'p -4 m 2',
	  'p -4 c 2',
	  'p -4 b 2',
	  'p -4 n 2',
	  'i -4 m 2',
	  'i -4 c 2',
	  'i -4 2 m',
	  'i -4 2 d',
	  'p 4/m m m',
	  'p 4/m c c',
	  'p 4/n b m',
	  'p 4/n n c',
	  'p 4/m b m',
	  'p 4/m n c',
	  'p 4/n m m',
	  'p 4/n c c',
	  'p 42/m m c',
	  'p 42/m c m',
	  'p 42/n b c',
	  'p 42/n n m',
	  'p 42/m b c',
	  'p 42/m n m',
	  'p 42/n m c',
	  'p 42/n c m',
	  'i 4/m m m',
	  'i 4/m c m',
	  'i 41/a m d',
	  'i 41/a c d',
	  'p 3',
	  'p 31',
	  'p 32',
	  'r 3',
	  'p -3',
	  'r -3',
	  'p 3 1 2',
	  'p 3 2 1',
	  'p 31 1 2',
	  'p 31 2 1',
	  'p 32 1 2',
	  'p 32 2 1',
	  'r 3 2',
	  'p 3 m 1',
	  'p 3 1 m',
	  'p 3 c 1',
	  'p 3 1 c',
	  'r 3 m',
	  'r 3 c',
	  'p -3 1 m',
	  'p -3 1 c',
	  'p -3 m 1',
	  'p -3 c 1',
	  'r -3 m',
	  'r -3 c',
	  'p 6',
	  'p 61',
	  'p 65',
	  'p 62',
	  'p 64',
	  'p 63',
	  'p -6',
	  'p 6/m',
	  'p 63/m',
	  'p 6 2 2',
	  'p 61 2 2',
	  'p 65 2 2',
	  'p 62 2 2',
	  'p 64 2 2',
	  'p 63 2 2',
	  'p 6 m m',
	  'p 6 c c',
	  'p 63 c m',
	  'p 63 m c',
	  'p -6 m 2',
	  'p -6 c 2',
	  'p -6 2 m',
	  'p -6 2 c',
	  'p 6/m m m',
	  'p 6/m c c',
	  'p 63/m c m',
	  'p 63/m m c',
	  'p 2 3',
	  'f 2 3',
	  'i 2 3',
	  'p 21 3',
	  'i 21 3',
	  'p m -3',
	  'p n -3',
	  'f m -3',
	  'f d -3',
	  'i m -3',
	  'p a -3',
	  'i a -3',
	  'p 4 3 2',
	  'p 42 3 2',
	  'f 4 3 2',
	  'f 41 3 2',
	  'i 4 3 2',
	  'p 43 3 2',
	  'p 41 3 2',
	  'i 41 3 2',
	  'p -4 3 m',
	  'f -4 3 m',
	  'i -4 3 m',
	  'p -4 3 n',
	  'f -4 3 c',
	  'i -4 3 d',
	  'p m -3 m',
	  'p n -3 n',
	  'p m -3 n',
	  'p n -3 m',
	  'f m -3 m',
	  'f m -3 c',
	  'f d -3 m',
	  'f d -3 c',
	  'i m -3 m',
	  'i a -3 d'
	 );

};

1;
