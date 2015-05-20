#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

# FIXME: fix it to connect to your DB
############################################
use DBI;
my $con_params = {
	db => "example", # FIXME
	socket => "/var/lib/mysql/mysql.sock", #FIXME
	user => "root",
	pass => "",
};
my $dbh = DBI->connect(
	"DBI:mysql:database=$con_params->{db};mysql_socket=$con_params->{socket}",
	$con_params->{user},
	$con_params->{pass},
	{RaiseError => 1}
);
############################################

my $STRICT_SIZE_CHECK = 0;

my $nullstr = $dbh->quote($STRICT_SIZE_CHECK ? "\0" : "");

# str_or check
for my $i (0..10) {
	my ($res) = $dbh->selectrow_array("
		select
			str_get_bit(
				str_or(
					str_set_bit($nullstr,1),
					str_set_bit($nullstr,2)
				),
				$i
			)
	");

	my $expected = {1 => 1, 2 => 1};
	is($res, $expected->{$i} ? 1 : 0, "bit $i in str_or is ". ($expected->{$i} || 0));
}

# str_and check
for my $i (0..8) {
	my ($res) = $dbh->selectrow_array("
		select
			str_get_bit(
				str_and(
					str_or(
						str_set_bit($nullstr,1),
						str_set_bit($nullstr,2)
					),
					str_set_bit($nullstr,2)
				),
				$i
			)
	");

	my $expected = {2 => 1};
	is($res, $expected->{$i} ? 1 : 0, "bit $i in str_and is ". ($expected->{$i} || 0));
}

$dbh->do("drop table if exists A");
$dbh->do("create table A (a binary(1))");

$dbh->do("
	insert into A values
	(str_set_bit($nullstr,1)),
	(str_set_bit($nullstr,7)),
	(str_set_bit($nullstr,9))
");

# str_or_aggr check
for my $i (0..17) {
	my ($res) = $dbh->selectrow_array("
		select str_get_bit(str_or_aggr(a),$i) from A
	");
	my $expected = {1 => 1, 7 => 1};
	
	is($res, $expected->{$i} ? 1 : 0, "bit $i in str_or_aggr is ". ($expected->{$i} || 0));
}

#str_and_aggr check
$dbh->do("update A set a = str_set_bit(a,5)");
for my $i (0..17) {
	my ($res) = $dbh->selectrow_array("
		select str_get_bit(str_and_aggr(a),$i) from A
	");
	my $expected = {5 => 1};
	
	is($res, $expected->{$i} ? 1 : 0, "bit $i in str_and_aggr is ". ($expected->{$i} || 0));
}


######################################
# compatibility with perl vec function
my $null16 = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
for my $i (0..127 ) {

	my $str = $null16;
	vec($str, $i, 1) = 1;

	my $another_str = $null16;
	vec($another_str, $i+1, 1) = 1;

	my ($res2) = $dbh->selectrow_array("select str_get_bit(" . $dbh->quote($str) .  ", $i)");
	ok($res2, "str_get_bit gets a bit set by vec(str, num) = 1 for num = $i");

	my ($res3) = $dbh->selectrow_array("select str_get_bit(" . $dbh->quote($another_str) .  ", $i)");
	ok(!$res3, "str_get_bit does not get bit num when num+1 is set by vec() for num = $i");

	my ($res4) = $dbh->selectrow_array("select str_set_bit(" . $dbh->quote($null16) . ", $i)");
	ok(vec($res4, $i, 1), "str_set_bit sets a bit which is accessible by  vec(str, num) for num = $i");

	diag sprintf("str1 for num $i: %s", unpack("b*", $str));
	diag sprintf("res4 for num $i: %s", unpack("b*", $res4));
}


done_testing();

