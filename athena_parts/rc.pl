## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2005 Bruce Ravel
##
##  This section of the code initializes all configuration values.
##  This file was generated from the athena.config file.


sub default_rc {
  $_[0]{general}{query_save} = 1;
  $_[0]{general}{query_constrain} = 0;
  $_[0]{general}{listside} = "right";
  $_[0]{general}{mru_limit} = 16;
  $_[0]{general}{mru_display} = "full";
  $_[0]{general}{compress_prj} = 1;
  $_[0]{general}{remember_cwd} = 0;
  $_[0]{general}{purge_stash} = 1;
  $_[0]{general}{user_key} = "comma";
  $_[0]{general}{mac_eol} = "fix";
  $_[0]{general}{interp} = "quad";
  $_[0]{general}{minpts} = 10;
  $_[0]{general}{rel2tmk} = 1;
  $_[0]{general}{autoplot} = 1;
  $_[0]{general}{autoreplot} = 0;
  $_[0]{general}{groupreplot} = "none";
  $_[0]{general}{match_as} = "perl";
  $_[0]{general}{i0_regex} = 'i(0$|o)';
  $_[0]{general}{transmission_regex} = '^i($|1$|t)';
  $_[0]{general}{fluorescence_regex} = 'i[fy]';
  $_[0]{general}{print_spooler} = ($is_windows) ? "" : "lpr";
  $_[0]{general}{ps_device} = "/cps";


  $_[0]{doc}{prefer} = "html";
  $_[0]{doc}{browser} = "firefox";
  $_[0]{doc}{zoom} = ($is_windows) ? 2 : 0;


  $_[0]{list}{x1} = 0.8;
  $_[0]{list}{x2} = 0.85;
  $_[0]{list}{y} = ($is_windows) ? 0.7 : 0.86;


  $_[0]{plot}{k_w} = "1";
  $_[0]{plot}{charsize} = 1.2;
  $_[0]{plot}{charfont} = 1;
  $_[0]{plot}{key_x} = 0.8;
  $_[0]{plot}{key_y} = 0.9;
  $_[0]{plot}{key_dy} = 0.075;
  $_[0]{plot}{bg} = "white";
  $_[0]{plot}{fg} = "black";
  $_[0]{plot}{showgrid} = 1;
  $_[0]{plot}{grid} = "grey82";
  $_[0]{plot}{c0} = "blue";
  $_[0]{plot}{c1} = "red";
  $_[0]{plot}{c2} = "green4";
  $_[0]{plot}{c3} = "darkviolet";
  $_[0]{plot}{c4} = "darkorange";
  $_[0]{plot}{c5} = "brown";
  $_[0]{plot}{c6} = "deeppink";
  $_[0]{plot}{c7} = "gold";
  $_[0]{plot}{c8} = "cyan3";
  $_[0]{plot}{c9} = "yellowgreen";
  $_[0]{plot}{linetypes} = 0;
  $_[0]{plot}{showmarkers} = 1;
  $_[0]{plot}{marker} = 9;
  $_[0]{plot}{markersize} = 2;
  $_[0]{plot}{markercolor} = "orange2";
  $_[0]{plot}{nindicators} = 8;
  $_[0]{plot}{indicatorcolor} = "violetred";
  $_[0]{plot}{indicatorline} = "solid";
  $_[0]{plot}{pointfinder} = 8;
  $_[0]{plot}{pointfindersize} = 2;
  $_[0]{plot}{pointfindercolor} = "darkseagreen4";
  $_[0]{plot}{bordercolor} = "wheat4";
  $_[0]{plot}{borderline} = "solid";
  $_[0]{plot}{emin} = -200;
  $_[0]{plot}{emax} = 800;
  $_[0]{plot}{kmin} = 0;
  $_[0]{plot}{kmax} = 15;
  $_[0]{plot}{rmin} = 0;
  $_[0]{plot}{rmax} = 6;
  $_[0]{plot}{qmin} = 0;
  $_[0]{plot}{qmax} = 15;
  $_[0]{plot}{smoothderiv} = 3;
  $_[0]{plot}{e_mu} = "m";
  $_[0]{plot}{e_mu0} = "z";
  $_[0]{plot}{e_pre} = 0;
  $_[0]{plot}{e_post} = 0;
  $_[0]{plot}{e_norm} = 0;
  $_[0]{plot}{e_der} = 0;
  $_[0]{plot}{e_marked} = "n";
  $_[0]{plot}{k_win} = 0;
  $_[0]{plot}{k_marked} = "1";
  $_[0]{plot}{r_mag} = "m";
  $_[0]{plot}{r_env} = 0;
  $_[0]{plot}{r_re} = 0;
  $_[0]{plot}{r_im} = 0;
  $_[0]{plot}{r_pha} = 0;
  $_[0]{plot}{r_win} = 0;
  $_[0]{plot}{r_marked} = "rm";
  $_[0]{plot}{q_mag} = 0;
  $_[0]{plot}{q_env} = 0;
  $_[0]{plot}{q_re} = "r";
  $_[0]{plot}{q_im} = 0;
  $_[0]{plot}{q_pha} = 0;
  $_[0]{plot}{q_win} = 0;
  $_[0]{plot}{q_marked} = "qr";


  $_[0]{bkg}{e0} = "derivative";
  $_[0]{bkg}{fraction} = 0.5;
  $_[0]{bkg}{ledgepeak} = "0";
  $_[0]{bkg}{kw} = 2;
  $_[0]{bkg}{rbkg} = 1.0;
  $_[0]{bkg}{pre1} = -150;
  $_[0]{bkg}{pre2} = -30;
  $_[0]{bkg}{nor1} = 150;
  $_[0]{bkg}{nor2} = -100;
  $_[0]{bkg}{nnorm} = "3";
  $_[0]{bkg}{step_increment} = 0.01;
  $_[0]{bkg}{flatten} = 1;
  $_[0]{bkg}{spl1} = 0.0;
  $_[0]{bkg}{spl2} = 0;
  $_[0]{bkg}{nclamp} = 5;
  $_[0]{bkg}{clamp1} = "None";
  $_[0]{bkg}{clamp2} = "Strong";


  $_[0]{clamp}{slight} = 3;
  $_[0]{clamp}{weak} = 6;
  $_[0]{clamp}{medium} = 12;
  $_[0]{clamp}{strong} = 24;
  $_[0]{clamp}{rigid} = 96;


  $_[0]{fft}{pluck_replot} = 0;
  $_[0]{fft}{arbkw} = 0.5;
  $_[0]{fft}{dk} = 1;
  $_[0]{fft}{win} = "hanning";
  $_[0]{fft}{kmin} = 2;
  $_[0]{fft}{kmax} = -2;
  $_[0]{fft}{pc} = "no";
  $_[0]{fft}{rmax_out} = 10;


  $_[0]{bft}{dr} = 0.0;
  $_[0]{bft}{win} = "hanning";
  $_[0]{bft}{rmin} = 1;
  $_[0]{bft}{rmax} = 3;


  $_[0]{xanes}{nor1} = 15;
  $_[0]{xanes}{nor2} = 0;
  $_[0]{xanes}{cutoff} = 100;


  $_[0]{calibrate}{calibrate_default} = "d";
  $_[0]{calibrate}{emin} = -20;
  $_[0]{calibrate}{emax} = 40;


  $_[0]{rebin}{emin} = -30;
  $_[0]{rebin}{emax} = 50;
  $_[0]{rebin}{pre} = 10;
  $_[0]{rebin}{xanes} = 0.5;
  $_[0]{rebin}{exafs} = 0.05;


  $_[0]{deglitch}{chie_emin} = 10;
  $_[0]{deglitch}{emax} = 10;
  $_[0]{deglitch}{margin} = 0.1;


  $_[0]{sa}{algorithm} = "fluo";
  $_[0]{sa}{emin} = -30;
  $_[0]{sa}{emax} = 100;
  $_[0]{sa}{thickness} = 10;
  $_[0]{sa}{angle_in} = 45;
  $_[0]{sa}{angle_out} = 45;


  $_[0]{mee}{enable} = 0;
  $_[0]{mee}{plot} = "k";
  $_[0]{mee}{shift} = 100;
  $_[0]{mee}{width} = 1;
  $_[0]{mee}{amp} = 0.01;


  $_[0]{align}{align_default} = "d";
  $_[0]{align}{fit} = "d";
  $_[0]{align}{emin} = -30;
  $_[0]{align}{emax} = 100;


  $_[0]{pixel}{do_pixel_check} = 0;
  $_[0]{pixel}{emin} = -100;
  $_[0]{pixel}{emax} = 600;
  $_[0]{pixel}{resolution} = 0.5;


  $_[0]{merge}{merge_weight} = "u";
  $_[0]{merge}{plot} = "stddev";


  $_[0]{smooth}{iterations} = 10;
  $_[0]{smooth}{rmax} = 6.0;


  $_[0]{diff}{emin} = -10;
  $_[0]{diff}{emax} = 40;
  $_[0]{diff}{kmin} = 2;
  $_[0]{diff}{kmax} = 12;
  $_[0]{diff}{rmin} = 1;
  $_[0]{diff}{rmax} = 3;


  $_[0]{peakfit}{maxpeaks} = 6;
  $_[0]{peakfit}{fitmin} = -20;
  $_[0]{peakfit}{fitmax} = 20;
  $_[0]{peakfit}{emin} = -40;
  $_[0]{peakfit}{emax} = 70;
  $_[0]{peakfit}{components} = 0;
  $_[0]{peakfit}{difference} = 0;
  $_[0]{peakfit}{centroids} = 0;
  $_[0]{peakfit}{peakamp} = 0.4;
  $_[0]{peakfit}{peakwidth} = 1.0;


  $_[0]{linearcombo}{marked_query} = "set";
  $_[0]{linearcombo}{fitspace} = "e";
  $_[0]{linearcombo}{maxspectra} = 8;
  $_[0]{linearcombo}{energy} = "data";
  $_[0]{linearcombo}{grid} = 1;
  $_[0]{linearcombo}{fitmin} = -20;
  $_[0]{linearcombo}{fitmax} = 30;
  $_[0]{linearcombo}{fitmin_k} = 3;
  $_[0]{linearcombo}{fitmax_k} = 12;
  $_[0]{linearcombo}{emin} = -40;
  $_[0]{linearcombo}{emax} = 70;
  $_[0]{linearcombo}{fite0} = 0;
  $_[0]{linearcombo}{components} = 0;


  $_[0]{colors}{single} = ($is_windows) ? "red2" : "red4";
  $_[0]{colors}{marked} = ($is_windows) ? "mediumorchid" : "darkviolet";
  $_[0]{colors}{foreground} = "black";
  $_[0]{colors}{background} = "cornsilk3";
  $_[0]{colors}{inactivebackground} = "antiquewhite3";
  $_[0]{colors}{activebackground} = "cornsilk2";
  $_[0]{colors}{darkbackground} = "cornsilk3";
  $_[0]{colors}{background2} = "bisque3";
  $_[0]{colors}{activebackground2} = "bisque2";
  $_[0]{colors}{disabledforeground} = "grey50";
  $_[0]{colors}{highlightcolor} = "blue2";
  $_[0]{colors}{activehighlightcolor} = "blue3";
  $_[0]{colors}{requiresupdate} = "steelblue4";
  $_[0]{colors}{button} = "red4";
  $_[0]{colors}{activebutton} = "brown3";
  $_[0]{colors}{mbutton} = "darkviolet";
  $_[0]{colors}{activembutton} = "mediumpurple";
  $_[0]{colors}{current} = "indianred1";
  $_[0]{colors}{frozencurrent} = "palegreen2";
  $_[0]{colors}{hlist} = "white";


  $_[0]{fonts}{small} = ($is_windows) ? "Helvetica 9 normal" : "Helvetica 10 normal";
  $_[0]{fonts}{smbold} = ($is_windows) ? "Helvetica 9 bold" : "Helvetica 10 bold";
  $_[0]{fonts}{tiny} = "Helvetica 8 normal";
  $_[0]{fonts}{med} = ($is_windows) ? "Helvetica 10 normal" : "Helvetica 12 normal";
  $_[0]{fonts}{medit} = ($is_windows) ? "Helvetica 10 italic" : "Helvetica 12 italic";
  $_[0]{fonts}{bold} = ($is_windows) ? "Helvetica 10 bold" : "Helvetica 12 bold";
  $_[0]{fonts}{boldit} = ($is_windows) ? "Helvetica 10 bold italic" : "Helvetica 12 bold italic";
  $_[0]{fonts}{large} = "Helvetica 14 normal";
  $_[0]{fonts}{fixed} = ($is_windows) ? "Courier 10" : "Courier 12";
  $_[0]{fonts}{entry} = ($is_windows) ? "Courier 9" : "Courier 10";
  $_[0]{fonts}{entrybold} = ($is_windows) ? "Courier 9 bold" : "Courier 10 bold";


  return 1;
};


## END OF RC FILE SUBSECTION
##########################################################################################
