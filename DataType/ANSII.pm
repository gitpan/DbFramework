=head1 NAME

DbFramework::DataType::ANSII - ANSII data type class

=head1 SYNOPSIS

  use DbFramework::DataType::ANSII;
  $dt     = new DbFramework::DataType::ANSII($dbh,$type,$length);
  $name   = $dt->name($name);
  $type   = $type($type);
  $length = $dt->length($length);
  $extra  = $dt->extra($extra);

=head1 DESCRIPTION

A B<DbFramework::DataType::ANSII> object represents an ANSII data type.

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

=cut

package DbFramework::DataType::ANSII;
use strict;
use base qw(DbFramework::DefinitionObject);
use Alias;
use vars qw();

## CLASS DATA

my %fields = (
              LENGTH  => undef,
	      EXTRA   => undef,
	      TYPES_L => undef,
	      TYPE    => undef,
	     );

# arbitrary number to add to SQL type numbers as they can be negative
# and we want to store them in an array
my $_sql_type_adjust = 1000;

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($dbh,$type,$length)

Create a new B<DbFramework::DataType> object.  I<$dbh> is a B<DBI>
database handle.  I<$type> is a numeric ANSII type e.g. a type
containd in the array reference returned by $sth->{TYPE}.  This method
will die() unless I<$type> is a member of the set of ANSII types
returned by I<$dbh>.  I<$length> is the length of the data type.

=cut

sub new {
  my $_debug = 0;
  my $proto     = shift;
  my $class     = ref($proto) || $proto;
  my $dbh       = shift;
  my $realtype  = shift;
  my $type      = $realtype + $_sql_type_adjust;

  my(@types,@type_names);
  for my $t ( $dbh->type_info($DBI::SQL_ALL_TYPES) ) {
    # first DATA_TYPE returned should be the ANSII type
    unless ( $types[$t->{DATA_TYPE} + $_sql_type_adjust] ) {
      $types[$t->{DATA_TYPE} + $_sql_type_adjust] = $t;
      $type_names[$t->{DATA_TYPE} + $_sql_type_adjust] = uc($t->{TYPE_NAME});
      print STDERR $t->{DATA_TYPE} + $_sql_type_adjust," $type_names[$t->{DATA_TYPE} + $_sql_type_adjust]\n" if $_debug
    }
  }
  $types[$type] || die "Invalid ANSII data type: $type";
  print STDERR "\ntype = $type ($type_names[$type])\n\n" if $_debug;

  my $self = bless($class->SUPER::new($type_names[$type]),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;

  $self->type($realtype);
  $self->types_l(\@types);
  $self->length(shift);
  $self->extra('AUTO_INCREMENT')
    if $self->types_l->[$type]->{AUTO_INCREMENT};

  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head2 name($name)

If I<$name> is supplied, sets the name of the ANSII data type.
Returns the name of the data type.

=head2 type($type)

If I<$type> is supplied, sets the number of the ANSII data type.
Returns the numeric data type.

=head2 length($length)

If I<$length> is supplied, sets the length of the data type.  Returns
the length of the data type.

=head2 extra($extra)

If I<$extra> is supplied, sets any extra information which applies to
the data type e.g. I<AUTO_INCREMENT>.  Returns the extra information
which applies to the data type.

=cut

1;

=head1 SEE ALSO

L<DbFramework::DefinitionObject>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
