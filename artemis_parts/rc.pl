## -*- cperl -*-
##
##  This file is part of Artemis, copyright (c) 2001-2005 Bruce Ravel
##
##  This section of the code initializes all configuration values.
##  This file was generated from the artemis.config file.


sub default_rc {
  my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));


  $_[0]{general}{'query_save'} = 1;
  $_[0]{general}{'autosave_policy'} = "autosave";
  $_[0]{general}{'fit_query'} = 1;
  $_[0]{general}{'sort_sets'} = 1;
  $_[0]{general}{'mru_limit'} = 8;
  $_[0]{general}{'mru_display'} = "full";
  $_[0]{general}{'doc_zoom'} = 4;
  $_[0]{general}{'remember_cwd'} = 0;
  $_[0]{general}{'mac_eol'} = "fix";
  $_[0]{general}{'layout'} = "mlp";
  $_[0]{general}{'projectbar'} = "file";
  $_[0]{general}{'print_spooler'} = ($is_windows) ? "" : "lpr";
  $_[0]{general}{'ps_device'} = "/cps";
  $_[0]{general}{'import_feffit'} = 0;


  $_[0]{geometry}{'window_multiplier'} = ($is_windows) ? 1.0 : 1.07;
  $_[0]{geometry}{'main_width'} = ($is_windows) ? 13.5 : 14;
  $_[0]{geometry}{'main_height'} = ($is_windows) ? 15.5 : 16.5;


  $_[0]{plot}{'charsize'} = 1.2;
  $_[0]{plot}{'charfont'} = 1;
  $_[0]{plot}{'key_x'} = 0.8;
  $_[0]{plot}{'key_y'} = 0.9;
  $_[0]{plot}{'key_dy'} = 0.075;
  $_[0]{plot}{'plot_phase'} = 0;
  $_[0]{plot}{'window_multiplier'} = 1.05;
  $_[0]{plot}{'bg'} = "white";
  $_[0]{plot}{'fg'} = "black";
  $_[0]{plot}{'showgrid'} = 1;
  $_[0]{plot}{'grid'} = "grey82";
  $_[0]{plot}{'c0'} = "blue";
  $_[0]{plot}{'c1'} = "red";
  $_[0]{plot}{'c2'} = "green4";
  $_[0]{plot}{'c3'} = "darkviolet";
  $_[0]{plot}{'c4'} = "darkorange";
  $_[0]{plot}{'c5'} = "brown";
  $_[0]{plot}{'c6'} = "deeppink";
  $_[0]{plot}{'c7'} = "gold";
  $_[0]{plot}{'c8'} = "cyan3";
  $_[0]{plot}{'c9'} = "yellowgreen";
  $_[0]{plot}{'datastyle'} = "solid";
  $_[0]{plot}{'fitstyle'} = "solid";
  $_[0]{plot}{'partsstyle'} = "solid";
  $_[0]{plot}{'kmin'} = 0;
  $_[0]{plot}{'kmax'} = 15;
  $_[0]{plot}{'rmin'} = 0;
  $_[0]{plot}{'rmax'} = 6;
  $_[0]{plot}{'qmin'} = 0;
  $_[0]{plot}{'qmax'} = 15;
  $_[0]{plot}{'kweight'} = "2";
  $_[0]{plot}{'plot_win'} = 0;
  $_[0]{plot}{'r_pl'} = "m";
  $_[0]{plot}{'q_pl'} = "r";
  $_[0]{plot}{'nindicators'} = 8;
  $_[0]{plot}{'indicatorcolor'} = "violetred";
  $_[0]{plot}{'indicatorline'} = "solid";


  $_[0]{data}{'fit_space'} = "R";
  $_[0]{data}{'fit_bkg'} = 0;
  $_[0]{data}{'kmin'} = 2;
  $_[0]{data}{'kmax'} = -2;
  $_[0]{data}{'dk'} = 1;
  $_[0]{data}{'kweight'} = 1;
  $_[0]{data}{'rmin'} = 1;
  $_[0]{data}{'rmax'} = 3;
  $_[0]{data}{'dr'} = 0.0;
  $_[0]{data}{'kwindow'} = "hanning";
  $_[0]{data}{'rwindow'} = "hanning";
  $_[0]{data}{'cormin'} = 0.25;
  $_[0]{data}{'bkg_corr'} = "no";
  $_[0]{data}{'rmax_out'} = 10;
  $_[0]{data}{'bkgsub_window'} = 1;


  $_[0]{log}{'style'} = "raw";


  $_[0]{gds}{'start_hidden'} = 0;
  $_[0]{gds}{'guess_color'} = "darkviolet";
  $_[0]{gds}{'def_color'} = "green4";
  $_[0]{gds}{'set_color'} = "black";
  $_[0]{gds}{'skip_color'} = "grey50";
  $_[0]{gds}{'restrain_color'} = "#a300a3";
  $_[0]{gds}{'after_color'} = "skyblue4";
  $_[0]{gds}{'merge_color'} = "red";
  $_[0]{gds}{'merge_background'} = "white";
  $_[0]{gds}{'highlight'} = "darkseagreen1";


  $_[0]{athena}{'parameters'} = "project";


  $_[0]{atoms}{'feff_version'} = "6";
  $_[0]{atoms}{'template'} = "feff";
  $_[0]{atoms}{'absorption_tables'} = "elam";
  $_[0]{atoms}{'elem'} = "entry";


  $_[0]{feff}{'feff_executable'} = ($is_windows) ? "feff6l" : "feff6";


  $_[0]{autoparams}{'do_autoparams'} = 1;
  $_[0]{autoparams}{'data_increment'} = "numbers";
  $_[0]{autoparams}{'s02'} = "amp";
  $_[0]{autoparams}{'s02_type'} = "guess";
  $_[0]{autoparams}{'e0'} = "enot";
  $_[0]{autoparams}{'e0_type'} = "guess";
  $_[0]{autoparams}{'delr'} = "delr";
  $_[0]{autoparams}{'delr_type'} = "guess";
  $_[0]{autoparams}{'sigma2'} = "ss";
  $_[0]{autoparams}{'sigma2_type'} = "guess";
  $_[0]{autoparams}{'ei'} = "";
  $_[0]{autoparams}{'ei_type'} = "def";
  $_[0]{autoparams}{'third'} = "";
  $_[0]{autoparams}{'third_type'} = "def";
  $_[0]{autoparams}{'fourth'} = "";
  $_[0]{autoparams}{'fourth_type'} = "def";


  $_[0]{intrp}{'betamax'} = 20;
  $_[0]{intrp}{'core_token'} = "[+]";
  $_[0]{intrp}{'ss'} = "navajowhite3";
  $_[0]{intrp}{'focus'} = "slategray3";
  $_[0]{intrp}{'excluded'} = "sienna";
  $_[0]{intrp}{'absent'} = "grey50";
  $_[0]{intrp}{'font'} = "Courier 10 bold";
  $_[0]{intrp}{'unimported'} = "Courier 10 italic";


  $_[0]{paths}{'extpp'} = 0;
  $_[0]{paths}{'firstn'} = 10;
  $_[0]{paths}{'label'} = "Path %i: [%p]";


  $_[0]{warnings}{'reff_margin'} = 1.1;
  $_[0]{warnings}{'s02_max'} = 0;
  $_[0]{warnings}{'s02_neg'} = 1;
  $_[0]{warnings}{'e0_max'} = 10;
  $_[0]{warnings}{'dr_max'} = 0.5;
  $_[0]{warnings}{'ss2_max'} = 0;
  $_[0]{warnings}{'ss2_neg'} = 1;
  $_[0]{warnings}{'3rd_max'} = 0;
  $_[0]{warnings}{'4th_max'} = 0;
  $_[0]{warnings}{'ei_max'} = 0;
  $_[0]{warnings}{'dphase_max'} = 0;


  $_[0]{logview}{'prefer'} = "rfactor";
  $_[0]{logview}{'eins_temp_max'} = 1500;
  $_[0]{logview}{'eins_sigma_max'} = 0.03;


  $_[0]{histogram}{'use'} = 0;
  $_[0]{histogram}{'position_column'} = 2;
  $_[0]{histogram}{'height_column'} = 3;
  $_[0]{histogram}{'template'} = "%i: %p (%r)";


  $_[0]{colors}{'check'} = ($is_windows) ? "red2" : "red4";
  $_[0]{colors}{'foreground'} = "black";
  $_[0]{colors}{'background'} = "antiquewhite3";
  $_[0]{colors}{'background2'} = "bisque3";
  $_[0]{colors}{'inactivebackground'} = "antiquewhite3";
  $_[0]{colors}{'activebackground'} = "antiquewhite2";
  $_[0]{colors}{'activebackground2'} = "bisque2";
  $_[0]{colors}{'disabledforeground'} = "grey50";
  $_[0]{colors}{'highlightcolor'} = "blue2";
  $_[0]{colors}{'activehighlightcolor'} = "blue3";
  $_[0]{colors}{'mbutton'} = "darkviolet";
  $_[0]{colors}{'button'} = "red4";
  $_[0]{colors}{'activebutton'} = "brown3";
  $_[0]{colors}{'fitbutton'} = "green4";
  $_[0]{colors}{'activefitbutton'} = "green3";
  $_[0]{colors}{'current'} = "orange2";
  $_[0]{colors}{'selected'} = "lightgoldenrod1";
  $_[0]{colors}{'exclude'} = "sienna";
  $_[0]{colors}{'hidden'} = "darkviolet";
  $_[0]{colors}{'warning_bg'} = "red";
  $_[0]{colors}{'warning_fg'} = "white";


  $_[0]{fonts}{'small'} = ($is_windows) ? "Helvetica 8 normal" : "Helvetica 10 normal";
  $_[0]{fonts}{'smbold'} = ($is_windows) ? "Helvetica 8 bold" : "Helvetica 10 bold";
  $_[0]{fonts}{'med'} = ($is_windows) ? "Helvetica 8 normal" : "Helvetica 12 normal";
  $_[0]{fonts}{'bold'} = ($is_windows) ? "Helvetica 8 bold" : "Helvetica 12 bold";
  $_[0]{fonts}{'bignbold'} = ($is_windows) ? "Helvetica 12 bold" : "Helvetica 14 bold";
  $_[0]{fonts}{'large'} = ($is_windows) ? "Helvetica 12 normal" : "Helvetica 14 normal";
  $_[0]{fonts}{'fixedsm'} = "Courier 10";
  $_[0]{fonts}{'fixed'} = ($is_windows) ? "Courier 10" : "Courier 12";
  $_[0]{fonts}{'fixedit'} = ($is_windows) ? "Courier 10 italic" : "Courier 12 italic";
  $_[0]{fonts}{'fixedbold'} = ($is_windows) ? "Courier 10 bold" : "Courier 12 bold";
  $_[0]{fonts}{'noplot'} = ($is_windows) ? "Helvetica 8 bold italic" : "Helvetica 10 bold italic";


  return 1;
};


## END OF RC FILE SUBSECTION
##########################################################################################
