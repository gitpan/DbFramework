sub drop_create {
  my($db,$table,$c,$sql,$dbh) = @_;
  my $rv = $dbh->do("DROP TABLE $table");

  ## init catalog
  if ( defined $c ) {
    my $c_sql = qq{
      DELETE FROM c_key
      WHERE db_name      = '$db'
      AND   ( table_name = '$table' )
    };
    my $sth = do_sql($c->dbh,$c_sql); $sth->finish;
    $c_sql = qq{
      DELETE FROM c_relationship
      WHERE db_name    = '$db'
      AND   ( fk_table = '$table' )
    };
    $sth = do_sql($c->dbh,$c_sql); $sth->finish;
  }

  return $dbh->do($sql) || die $dbh->errstr;
}

sub do_sql {
  my($dbh,$sql) = @_;
  #print STDERR "$sql\n";
  my $sth = $dbh->prepare($sql) || die($dbh->errstr);
  my $rv  = $sth->execute       || die($sth->errstr);
  return $sth;
}  

1;
