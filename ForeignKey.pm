=head1 NAME

DbFramework::ForeignKey - Foreign Key class

=head1 SYNOPSIS

  use DbFramework::ForeignKey;
  my $fk = new DbFramework::ForeignKey($name,\@attributes,$primary);
  $fk->references($primary);
  $sql = $fk->as_sql;

=head1 DESCRIPTION

The B<DbFramework::ForeignKey> class implements foreign keys for a
table.

=head1 SUPERCLASSES

B<DbFramework::Key>

=cut

package DbFramework::ForeignKey;
use strict;
use base qw(DbFramework::Key);
use Alias;
use vars qw( $NAME $BELONGS_TO @INCORPORATES_L $BGCOLOR );

# CLASS DATA

my %fields = (
	      # ForeignKey 0:N References 1:1 PrimaryKey
	      REFERENCES => undef,
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,\@attributes,$primary)

Returns a new B<DbFramework::ForeignKey> object.

I<$name> is the name of the foreign key.  I<@attributes> is a list of
B<DbFramework::Attribute> objects from a single B<DbFramework::Table>
object which make up the key.  I<$primary> is the
B<DbFramework::Primary> object which the foreign key references.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift,shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->references(shift);
  $self->bgcolor('#777777');
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 references($primary)

I<$primary> should be a B<DbFramework::PrimaryKey> object.  If
supplied, it sets the primary key referenced by this foreign key.
Returns the B<DbFramework::PrimaryKey> object referenced by this
foreign key.

=cut

#-----------------------------------------------------------------------------

sub _input_template {
  my $self   = attr shift;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  return qq{<TR>
<TD BGCOLOR='$BGCOLOR'><STRONG>$NAME</STRONG></TD>
<TD><DbFKey ${t_name}.$NAME></TD>
</TR>
};
}

#-----------------------------------------------------------------------------

# yikes! how do I do this?

sub _output_template {
  my $self   = attr shift;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $out;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    $out .= qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${t_name}.${a_name}></TD>};
  }
  $out;
}

1;

=head1 SEE ALSO

L<DbFramework::Key>, L<DbFramework::PrimaryKey>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
