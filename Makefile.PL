use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# make SchemaParser.pm

=pod

my $package = 'SchemaParser';
my $grammar = "$package.y";
my $module  = "$package.pm";
my $output  = 'y.tab.pl';

print "Generating $package\n";

die "Couldn't compile grammer in $grammar"
  if ( system("byacc -P $grammar") != 0 );

die "Error copying $output to $module"
  if ( system("tail +2 $output > $module") != 0 );

unlink $output || die "Couldn't unlink $output: $!";

=cut

WriteMakefile(
    'NAME'	   => 'DbFramework::Persistent',
    'DISTNAME'     => 'DbFramework',
    'VERSION_FROM' => 'Persistent.pm',
    'PREREQ_PM'    => { 'Alias' => 0, 'Pod::Usage' => 0, },
    'clean'        => { FILES => "y.tab.pl SchemaParser.pm TAGS" },
    'linkext'      => { LINKTYPE=>'' },
    'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz'}
);
