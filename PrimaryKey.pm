=head1 NAME

DbFramework::PrimaryKey - Primary key class

=head1 SYNOPSIS

  use DbFramework::PrimaryKey;
  $pk   = new DbFramework::Primary(\@attributes);
  $sql  = $pk->as_sql;
  $html = $pk->html_pk_select_field(\@column_names,$multiple,\@default);

=head1 DESCRIPTION

The B<DbFramework::PrimaryKey> class implements primary keys for a
table.

=head1 SUPERCLASSES

B<DbFramework::Key>

=cut

package DbFramework::PrimaryKey;
use strict;
use base qw(DbFramework::Key);
use Alias;
use vars qw( $NAME $BELONGS_TO @INCORPORATES_L $BGCOLOR $_DEBUG );
use CGI;

# CLASS DATA

my %fields = (
              # PrimaryKey 0:N Incorporates 0:N ForeignKey
              INCORPORATES => undef,
);

#-----------------------------------------------------------------------------
## CLASS METHODS
#-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new(\@attributes)

Create a new B<DbFramework::PrimaryKey> object.  I<@attributes> is a
list of B<DbFramework::Attribute> objects from a single
B<DbFramework::Table> object which make up the key.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new('PRIMARY',shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->bgcolor('#00ff00');
  return $self;
}

#-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 as_sql()

Returns a string which can be used in an SQL 'CREATE TABLE' statement
to create the primary key.

=cut

sub as_sql {
  my $self = attr shift;
  return "PRIMARY KEY (" . join(',',$self->attribute_names) . ")";
}

##----------------------------------------------------------------------------

=head2 html_select_field(\@column_names,$multiple,\@default)

Returns an HTML form field where the value consists of the values from
the columns which make up the primary key and the labels consist of
the corresponding values from I<@column_names>.  If I<$multiple> is
defined the field will allow multiple selections.  I<@default> is a
list of values which should be selected by default.

=cut

sub html_select_field {
  my $self = attr shift;

  my @labels     = $_[0] ? @{$_[0]} : $BELONGS_TO->get_attribute_names;
  my $multiple   = $_[1];
  my $default    = $_[2];
  my @pk_columns = $self->attribute_names;
  my $pk         = join(',',@pk_columns);
  my @columns    = (@pk_columns,@labels);

  # prepare arguments for CGI methods
  my $i = 0;
  my (@pk_values,%labels,@row);
  for ( $BELONGS_TO->select(\@columns,undef,join(',',@labels)) ) {
    @row   = @{$_};
    my $pk = join(',',@row[0..$#pk_columns]);                # pk fields
    $pk_values[$i++] = $pk;
    $labels{$pk}    = join(',',@row[$#pk_columns+1..$#row]); # label fields
  }

  my $html;
  my $cgi = new CGI('');  # we just want this object for its methods
  if ( $multiple ) {
    $html = $cgi->scrolling_list(-name=>$pk,
				 -values=>\@pk_values,
				 -labels=>\%labels,
				 -multiple=>'true',
				 -default=>$default,
				);
  } else {
    $html = $cgi->popup_menu(-name=>$pk,
			     -values=>\@pk_values,
			     -labels=>\%labels,
			     -default=>$default,
			    );
  }

  return $html;
}

#-----------------------------------------------------------------------------

sub _input_template {
  my($self,@fk_attributes) = @_;
  attr $self;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  print STDERR "\@fk_attributes = @fk_attributes\n" if $_DEBUG;
  my $in;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    unless ( grep(/^$a_name$/,@fk_attributes) ) { # part of foreign key
      print STDERR "Adding $a_name to input template for pk in $t_name\n" if $_DEBUG;
      $in .= qq{<TR>
<TD BGCOLOR='$BGCOLOR'><STRONG>$a_name</STRONG></TD>
<TD><DbField ${t_name}.${a_name}></TD>
</TR>
};
    }
  }
  $in;
}

#-----------------------------------------------------------------------------

sub _output_template {
  my($self,@fk_attributes) = @_;
  attr $self;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $out;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    unless ( grep(/^$a_name$/,@fk_attributes) ) { # part of foreign key
      $out .= qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${t_name}.${a_name}></TD>};
    }
  }
  $out;
}

1;

=head1 SEE ALSO

L<DbFramework::Key>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut