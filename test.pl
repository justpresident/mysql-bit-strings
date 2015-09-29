#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use List::Util qw(min max);

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

# str_and_aggr check
$dbh->do("update A set a = str_set_bit(a,5)");
for my $i (0..17) {
	my ($res) = $dbh->selectrow_array("
		select str_get_bit(str_and_aggr(a),$i) from A
	");
	my $expected = {5 => 1};

	is($res, $expected->{$i} ? 1 : 0, "bit $i in str_and_aggr is ". ($expected->{$i} || 0));
}


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

	diag sprintf("perl string for num $i:  %s", unpack("b*", $str));
	diag sprintf("mysql string for num $i: %s", unpack("b*", $res4));
}


{
	my $is = sub {
		my $what = shift;
		my $expected = shift;
		my $msg = shift;
		my $data = shift;

		$dbh->do('drop table if exists A');
		$dbh->do('create table A (a binary(16))');

		my $res = undef;
		my $expected_res = undef;

		if ($data) {
			for my $val (@$data) {
				$dbh->do("insert into A set a = $val");
			}

			($res) = $dbh->selectrow_array("select $what from A limit 1");
			($expected_res) = $dbh->selectrow_array("select $expected from A limit 1");
		} else {
			($res) = $dbh->selectrow_array("select $what");
			($expected_res) = $dbh->selectrow_array("select $expected");
		}

		unless (defined $res) {
			fail("$what is undef ($msg)");
			return 1;
		}

		unless (defined $expected_res) {
			fail("$expected is undef ($msg)");
			return 1;
		}

		my $not_equal = scalar grep { vec($res, $_, 1) != vec($expected_res, $_, 1) } (0 .. (max(length($res), length($expected_res)) + 1) * 8);
		if ($not_equal) {
			fail("'$what' is not '$expected' ($msg)");
			diag sprintf("Got:      %s", unpack("b*", $res));
			diag sprintf("Expected: %s", unpack("b*", $expected_res));
		} else {
			pass("'$what' is '$expected' ($msg)");
			# diag sprintf("Got:      %s", unpack("b*", $res));
			# diag sprintf("Expected: %s", unpack("b*", $expected_res));
		}

		return 1;
	};

	# NULL equals to empty string: basic functions
	{
		$is->(
			'str_or(str_set_bit("", 100), str_set_bit("", 50))',
			'str_or(str_set_bit("", 50), str_set_bit("", 100))',
			"sanity check (basic)"
		);

		$is->('str_set_bit(NULL, 100)', 'str_set_bit("", 100)', "str_set_bit() treats NULL as ''");
		$is->('str_get_bit(NULL, 100)', 0, "str_get_bit() treats NULL as ''");

		throws_ok(sub { $dbh->selectrow_array('select str_set_bit("100", NULL)') }, qr/does not accept NULL/, "str_set_bit() returns error for NULL bit" );
		throws_ok(sub { $dbh->selectrow_array('select str_get_bit("100", NULL)') }, qr/does not accept NULL/, "str_get_bit() returns error for NULL bit" );

		$is->('str_or(NULL, str_set_bit("", 100))', 'str_set_bit("", 100)', "str_or treats left NULL as ''");
		$is->('str_or(str_set_bit("", 100), NULL)', 'str_set_bit("", 100)', "str_or treats right NULL as ''");
		$is->('str_or(NULL, NULL)', '""', "str_or treats both NULLs as ''");

		$is->('str_and(NULL, str_set_bit("", 100))', '""', "str_and treats left NULL as ''");
		$is->('str_and(str_set_bit("", 100), NULL)', '""', "str_and treats right NULL as ''");
		$is->('str_and(NULL, NULL)', '""', "str_or treats both NULLs as ''");
	}

	# NULL equals to empty string: aggregate functions
	{
		$is->(
			'str_or_aggr(a)',
			'str_or(str_or(str_set_bit("", 10), str_set_bit("", 20)), str_set_bit("", 30))',
			'str_or_aggr - sanity check',
			[ 'str_set_bit("", 10)', 'str_set_bit("", 20)', 'str_set_bit("", 30)' ]
		);

		$is->(
			'str_or_aggr(a)',
			'str_or(str_set_bit("", 10), str_set_bit("", 30))',
			'str_or_aggr treats NULL as ""',
			[ 'NULL', 'str_set_bit("", 10)', 'NULL', 'NULL', 'str_set_bit("", 30)', 'NULL' ]
		);

		$is->(
			'str_or_aggr(a)',
			'""',
			'str_or_aggr does not fail on all NULLs',
			[ 'NULL', 'NULL', 'NULL', 'NULL' ]
		);

		# $is->(
		# 	'str_or_aggr(a)',
		# 	'""',
		# 	'str_or_aggr does not fail on empty input',
		# 	[ ]
		# );

		$is->(
			'str_and_aggr(a)',
			'str_set_bit("", 10)',
			'str_and_aggr - sanity check',
			[ 'str_set_bit("", 10)', 'str_or(str_set_bit("", 10), str_set_bit("", 20))' ]
		);

		$is->(
			'str_and_aggr(a)',
			'str_set_bit("", 10)',
			'str_and_aggr treats NULL as ""',
			[ 'str_set_bit("", 10)', 'str_or(str_set_bit("", 10), str_set_bit("", 20))' ]
		);

		$is->(
			'str_and_aggr(a)',
			'""',
			'str_and_aggr does not fail on all NULLs',
			[ 'NULL', 'NULL', 'NULL', 'NULL' ]
		);

		# $is->(
		# 	'str_and_aggr(a)',
		# 	'""',
		# 	'str_and_aggr does not fail on empty input',
		# 	[ ]
		# );
	}


	# check bugfix: str_set_bit does not shorten a long string when you set an early bit

	$is->('str_set_bit("Cheerilee is the best pony!", 5)', 'str_or(str_set_bit("", 5), "Cheerilee is the best pony!")', "str_set_bit does not eat strings");


	# check bugfix: str_and, str_and_aggr should treat non-existant bits as 0
	{
		my $one10 = ''; vec($one10, $_, 1) = 1 for (1..10); $one10 = $dbh->quote($one10);
		my $one20 = ''; vec($one20, $_, 1) = 1 for (1..20); $one20 = $dbh->quote($one20);

		$is->("str_and($one10, $one20)", "$one10", "str_and treats unset bits as zeroes (all, left)");
		$is->("str_and($one20, $one10)", "$one10", "str_and treats unset bits as zeroes (all, right)");

		$is->('str_and(str_set_bit("", 50), "")', '""', "str_and treats unset bits as zeroes (one, left)");
		$is->('str_and("", str_set_bit("", 50))', '""', "str_and treats unset bits as zeroes (one, right)");

		$is->('str_and_aggr(a)', "$one10", "str_and_aggr treats unset bits as zeroes (all, left)", ["$one10", "$one20"]);
		$is->('str_and_aggr(a)', "$one10", "str_and_aggr treats unset bits as zeroes (all, right)", ["$one20", "$one10"]);

		$is->('str_and_aggr(a)', '""', "str_and_aggr treats unset bits as zeroes (one, left)", ['str_set_bit("", 50)', '""']);
		$is->('str_and_aggr(a)', '""', "str_and_aggr treats unset bits as zeroes (one, right)", ['""', 'str_set_bit("", 50)']);
	}
}


done_testing();
