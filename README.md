# mysql-bit-strings
Mysql UDFs to work with bits in string

Provided functions allows you to use strings as long bit arrays. If your application requires to handle more than 64 bits in mysql columns, this library is for you. You can create column up to 255 bytes long as binary(255) and therefore you will have 255*8 available bits to store flags.

# Installation
### DEB-file
Install package build dependencies
```sudo apt-get install devscripts debhelper libmysqlclient-dev g++ gawk```

Build package ```debuild```

Install package ```sudo dpkg -i ../mysql-bit-strings-udf_0.01_all.deb```

### Manual
Install package build dependencies
```sudo apt-get install devscripts debhelper libmysqlclient-dev g++ gawk```

Compile library ```make```

Install it
```
sudo cp libmysql_bit_strings_udf.so /usr/lib
sudo cp libmysql_bit_strings_udf.so /usr/lib/mysql/plugin/
mysql < create_funcs.sql
```
### Usage

Suppose you have a table
```
create table Tbl (
  field1 binary(16);
)
```
### Simple functions

* str_set_bit(STR, BIT_NUM) - allows you to set bit in a string STR at position BIT_NUM
```
insert into Tbl values
  (str_set_bit("",99));
  
update Tbl set field1 = str_set_bit(field1, 800);
```

* str_get_bit(STR, BIT_NUM) - returns you a bit from string STR at position BIT_NUM
```
select str_get_bit(field1, 85) from Tbl
```

* str_or(STR1, STR2) - returns string with bitwise OR of corresponding bytes in strings STR1 and STR2
```
select str_or(field1, str_set_bit("",23)) from Tbl
```

* str_and(STR1, STR2) - returns string with bitwise AND of corresponding bytes in strings STR1 and STR2

### Aggregate functions

* str_or_aggr(STR) - bitwise OR of all aggregated fields
```
select str_or_aggr(field1) from Tbl
```

* str_and_aggr(STR) - bitwise AND of all aggregated fields
```
select str_and_aggr(field1) from Tbl
```
