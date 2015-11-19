use ExtUtils::MakeMaker;
require Config;
$Verbose = 1;

WriteMakefile(
	NAME => 'STAR::Parser',
	VERSION_FROM => 'lib/STAR/Parser.pm'
);

package MY;

sub libscan
{
    my($self, $path) = @_;
    return '' if $path =~ m:\bRCS/:;
    return '' if $path =~ m/~$/;
    return '' if $path =~ m/Makefile\~?$/;
    $path;
}
