# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;

BEGIN { plan tests => 1}

package Foo;
use strict;
use base qw(DbFramework::Util);

my %fields = (
	      NAME       => undef,
	      CONTAINS_H => undef,
	     );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->contains_h(shift);
  return $self;
}

package main;
my $foo = new Foo('foo',['foo','oof','bar','rab','baz','zab']);
my @names = $foo->contains_h_byname('foo','bar');
ok("@names",'oof rab');

#my @quux = $foo->contains_h_byname('quux');
#print "\$#quux = $#quux, \$quux[0] = $quux[0]\n";
#my %foo = ( foo => 'oof', bar => 'rab' );
#print @{foo}{'foo','bar'},"\n";
#@quux = @{foo}{'baz','foobar','quux'};
#print "\$#quux = $#quux, \$quux[0] = $quux[0]\n";
#@quux = ();
#print "\$#quux = $#quux, \$quux[0] = $quux[0]\n";
