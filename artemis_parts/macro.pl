## -*- cperl -*-
##
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  ifeffit macros



sub write_macros {
  my $string = "
macro startup
  \"Artemis startup message, used to set character size and font\"
  startup.x = range(0.1,1,0.1)
  startup.y = zeros(10)
  newplot(startup.x, startup.y, nogrid, ymin=0, ymax=1, color=black, charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})
  plot_text(0.4, 0.5, text=\"Welcome to Artemis\")
  erase \@group startup
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

macro eins
  \"Fit Einstein temperature and offset for a MASS1, MASS2 given data in group eins\"
  unguess
  set(eins_hbarc   = 1973.270533,
      eins_boltz   = 8.61738e-5,
      eins_amu2ev  = 9.3149432e8)
  set eins_prefac  = eins_hbarc*eins_hbarc/(2*eins_boltz*eins_amu2ev)
  set eins_rmass   = 1/(1/\$1+1/\$2)
  guess(eins_theta = 300, eins_offset=0.001)
  def eins.vec    = eins_theta/(2*eins.1)
  def eins.thvec  = tanh(eins.vec)
  def eins.y      = eins_prefac/(eins.thvec*eins_rmass*eins_theta) + eins_offset
  def eins.resid  = eins.y-eins.2
  #minimize(eins.resid, uncertainty=eins.3)
  minimize(eins.resid)
  def eins.xx     = indarr(ceil(eins.1) + 50)
  def eins.ovec   = eins_theta/(2*eins.xx)
  def eins.thovec = tanh(eins.ovec)
  def eins.yy     = eins_prefac/(eins.thovec*eins_rmass*eins_theta) + eins_offset
end macro


## end of Artemis' macros
##
##
";
  return $string;
};

## END OF MACROS SUBSECTION
##########################################################################################
