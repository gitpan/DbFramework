=head1 NAME

DbFramework::Attribute - Attribute class

=head1 SYNOPSIS

  use DbFramework::Attribute;
  my $a = new DbFramework::Attribute($name,$default_value,$is_optional,$data_type);
  $a->name($name);
  $a->default_value($value);
  $a->is_optional($boolean);
  $a->references($data_type);
  $sql  = $a->as_sql;
  $s    = $a->as_string;
  $html = $a->as_html_form_field($value,$type);

=head1 DESCRIPTION

A B<DbFramework::Attribute> object represents an attribute (column) in
a table (entity).

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Attribute;
use strict;
use base qw(DbFramework::Util);
use vars qw( $NAME $DEFAULT_VALUE $IS_OPTIONAL $REFERENCES $BGCOLOR);
use Alias;

## CLASS DATA

my %fields = (
	      NAME          => undef,
	      DEFAULT_VALUE => undef,
	      IS_OPTIONAL   => undef,
	      # Attribute 0:N References 0:1 DefinitionObject (DataType)
	      REFERENCES    => undef,
	      BGCOLOR       => '#007777',
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,$default_value,$is_optional,$data_type)

Create a new B<DbFramework::Attribute> object.  I<$name> is the name
of the attribute.  I<$default_value> is the default value for the
attribute.  I<$is_optional> should be set to true if the attribute is
optional or false.  I<$data_type> is a B<DbFramework::DataType>
object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->default_value(shift);
  $self->is_optional(shift);
  $self->references(shift);
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head2 name($name)

If I<$name> is supplied, sets the attribute name.  Returns the
attribute name.

=head2 default_value($value)

If I<$value> is supplied, sets the default value for the attribute.
Returns the default value for the attribute.

=head2 is_optional($boolean)

If I<$boolean> is supplied, sets the optionality of the attribute.
I<$boolean> should evaluate to true or false.  Returns the optionality
of the attribute.

=head2 references($data_type)

If I<$data_type> is supplied, sets the data type of the attribute.
I<$data_type> is a B<DbFramework::DataType> object.  Returns a
B<DbFramework::DataType> object.

=head2 bgcolor($bgcolor)

If I<$color> is supplied, sets the background colour for HTML table
cells.  Returns the current background colour.

=head2 as_sql($dbh)

Returns a string which can be used to create a column in an SQL
'CREATE TABLE' statement.  I<$dbh> is a B<DBI> handle.

=cut

sub as_sql {
  my($self,$dbh) = (attr shift,shift);
  my $sql  = "$NAME ";
  $sql    .= $REFERENCES->name;
  $sql    .= '(' . $REFERENCES->length . ')'           if $REFERENCES->length;
  $sql    .= " NOT NULL"                               unless $IS_OPTIONAL;
  $sql    .= " DEFAULT " . $dbh->quote($DEFAULT_VALUE) if $DEFAULT_VALUE;
  $sql    .= ' ' . $REFERENCES->extra                  if $REFERENCES->extra;
  return $sql;
}

##-----------------------------------------------------------------------------

=head2 as_html_form_field($value,$type)

Returns an HTML form field representation of the attribute.  The HTML
field type produced depends on the name of the associated
B<DbFramework::DataType> object.  This can be overidden by setting
I<$type>.  I<$value> is the default value to be entered in the
generated field.

=cut

sub as_html_form_field {
  my $self   = attr shift;
  my $value  = defined($_[0]) ? $_[0] : '';
  my $type   = defined($_[1]) ? $_[1] : $REFERENCES->name;
  my $length = $REFERENCES->length;
  my $html;

# we'll worry about foreign keys another day

# set the flag to add a 'NULL' FK entry 
# based on 'NOT NULL' constraint

#  if ( $this_column->ForeignKey ) {
#    my($fk_pk_values,$fk_pk_labels) =
#      $self->{SCHEMA}->get_fk_pk_labels($this_column,1);

    # null query string as we just want this object 
    # for its methods
#    my $cgi = new CGI('');
#    if ( $this_column->ManyToMany ) {
#      $html = $cgi->scrolling_list(-name=>$this_column->name, 
#				   -values=>$fk_pk_values,
#				   -labels=>$fk_pk_labels,
#				   -multiple=>'true');
#    } else {
#      $html = $cgi->popup_menu(-name=>$this_column->Name,
#			       -values=>$fk_pk_values,
#			       -labels=>$fk_pk_labels);
#    }
#  }

    SWITCH: {
      $type =~ /INT/ &&
	do { 
	  $html = qq{<INPUT NAME="$NAME" VALUE="$value" SIZE=10 TYPE="text">};
	  last SWITCH;
	};
      $type =~ /CHAR$/ &&
	do {
	  $html = qq{<INPUT NAME="$NAME" VALUE="$value" SIZE=30 TYPE="text" MAXLENGTH=$length>};
	  last SWITCH;
	};
      $type eq 'TEXT' &&
	do {
	  $value =~ s/'//g;	# remove quotes
	  $html  = qq{<TEXTAREA COLS=60 NAME="$NAME" ROWS=4>$value</TEXTAREA>};
	  last SWITCH;
	};
      $type eq 'BOOLEAN' &&
	do {
	  my $y = qq{Yes <INPUT TYPE="RADIO" NAME="$NAME" VALUE=1};
	  my $n = qq{No <INPUT TYPE="RADIO" NAME="$NAME" VALUE=0};
	  $html = $value ? qq{$y CHECKED>\n$n>\n} : qq{$y>\n$n CHECKED>\n};
	  last SWITCH;
	};
      # default
      my $size = ($length < 30) ? $length : 30;
      $html    = qq{<INPUT MAXLENGTH=$size NAME="$NAME" VALUE="$value" SIZE=$size TYPE="text">};
    }
  return $html;
}

##-----------------------------------------------------------------------------

=head2 as_string()

Return attribute details as a text string.

=cut

sub as_string {
  my $self = attr shift;
  my $s = "$NAME(" . $REFERENCES->name;
  $s   .= ' ('. $REFERENCES->length . ')' if $REFERENCES->length;
  $s   .= " '$DEFAULT_VALUE'"             if $DEFAULT_VALUE;
  $s   .= ' NOT NULL'                     unless $IS_OPTIONAL;
  $s   .= ' ' . $REFERENCES->extra        if $REFERENCES->extra;
  #print " $FUNCTION" if $FUNCTION;
  return "$s)\n";
}

##----------------------------------------------------------------------------

sub _input_template {
  my($self,$t_name) = (attr shift,shift);
  return qq{<TR>
<TD BGCOLOR='$BGCOLOR'><STRONG>$NAME</STRONG></TD>
<TD><DbField ${t_name}.$NAME></TD>
</TR>
};
}

##----------------------------------------------------------------------------

sub _output_template {
  my($self,$t_name) = (attr shift,shift);
  return qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${t_name}.$NAME></TD>};
}

1;

=head1 SEE ALSO

L<DbFramework::DataType>

=head1 AUTHOR

Paul Sharpe

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
