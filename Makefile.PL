use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# select drivers to test
my @drivers = qw/mysql mSQL/;
print "Enter (space seperated) DBI drivers to test: [@drivers] ";
my $drivers = <STDIN>;
chop $drivers;
@drivers = split /\s/,$drivers if $drivers ne '';

my %catalog_db;
for ( @drivers ) {
  my $answer = '';
  while ( 1 ) {
    print "Create catalog database for $_ (y/N)?: ";
    $answer = <STDIN>;
    last if $answer =~ /^\n$/;
    chop $answer;
    $answer = uc($answer);
    last if $answer =~ /^(Y|N)$/
  }
  $catalog_db{$_} = ($answer eq 'Y') ? 1 : 0;
}

my $config = 't/Config.pm';
open(CONFIG,">$config") || die "Couldn't open config file: $config: $!";
print STDERR "Writing config file: $config\n";
print CONFIG qq{package t::Config;

\@drivers    = qw/@drivers/;
\%catalog_db = (};
		
while ( my($k,$v) = each %catalog_db ) {
  print CONFIG " $k => $v,";
}
print CONFIG qq{);
1;
};

close CONFIG;

WriteMakefile(
    'NAME'	   => 'DbFramework::Persistent',
    'DISTNAME'     => 'DbFramework',
    'VERSION_FROM' => 'Persistent.pm',
    'PREREQ_PM'    => { 'Alias' => 0, 'Pod::Usage' => 0, 'DBI' => 1.06 },
    'PMLIBDIRS'    => [ 'DataType' ],
    'clean'        => { FILES => "t/Config.pm TAGS" },
    'linkext'      => { LINKTYPE=>'' },
    'dist'         => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz'}
);
