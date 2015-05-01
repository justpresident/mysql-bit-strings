#!/usr/bin/perl

use warnings;
use strict;

use Yabs::CollectBase;
use Yabs::Logger;

use Test::More;

my $dbh = connect_local({raise_error => 1});

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

done_testing();

