=head1 NAME

DbFramework::DataType - Data type class

=head1 SYNOPSIS

  use DbFramework::DataType;
  my $dt = new DbFramework::DataType($name,$length,$extra);
  $dt->name($name);
  $dt->length($length);
  $dt->extra($extra);

=head1 DESCRIPTION

A B<DbFramework::DataType> object represents a data type associated
with a B<DbFramework::Attribute> object.

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

=cut

package DbFramework::DataType;
use strict;
use base qw(DbFramework::DefinitionObject);
use Alias;
use vars qw();

## CLASS DATA

my %fields = (
              LENGTH => undef,
	      EXTRA  => undef,
	     );
my @types  = qw/CHAR DATE DATETIME INT INTEGER TEXT TIMESTAMP VARCHAR
                DOUBLE LONGBLOB FLOAT/;

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,$length,$extra)

Create a new B<DbFramework::DataType> object.  I<$name> is the name of
the data type.  I<$length> is the length of the data type.  I<$extra>
is any extra information which applies to the data type
e.g. I<AUTO_INCREMENT> in they case of a Mysql I<INTEGER> data type.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $type  = uc(shift);
  grep(/^$type$/,@types) || 
    die "Invalid datatype '$type'\nValid types are (@types)";
  my $self  = bless($class->SUPER::new($type),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->length(shift);
  $self->extra(uc(shift));
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head2 name($name)

If I<$name> is supplied, sets the name of the data type.  Valid data
types are I<CHAR DATE DATETIME INT INTEGER TEXT TIMESTAMP VARCHAR>.
Returns the name of the data type.

=head2 length($length)

If I<$length> is supplied, sets the length of the data type.  Returns
the length of the data type.

=head2 extra($extra)

If I<$extra> is supplied, sets any extra information which applies to
the data type e.g. I<AUTO_INCREMENT> in they case of a Mysql
I<INTEGER> data type.  Returns the extra information which applies to
the data type.

=cut

1;

=head1 SEE ALSO

L<DbFramework::DefinitionObject>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
