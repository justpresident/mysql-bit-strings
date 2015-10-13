#include <mysql.h>
#include <string.h>

// Definition for automatic 'create function' and 'drop function' generation
// Format: // MYSQL_UDF: <function_name> {string|integer|real|decimal} [aggregate]

// MYSQL_UDF: str_set_bit string
my_bool str_set_bit_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_set_bit() requires 2 arguments");
		return 1;
	}

	if (!args->args[1]) {
		strcpy(message, "str_set_bit() does not accept NULL as bit number");
		return 1;
	}

	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = INT_RESULT;

	return 0;
}

void str_set_bit_deinit(UDF_INIT *initid __attribute__((unused))) {
}

char * str_set_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	char *str = args->args[0];
	unsigned long strlength = args->lengths[0];
	unsigned long long bitnum = *((unsigned long long *)args->args[1]);
	unsigned long bitlength = bitnum / 8 + 1;


	if (!str) {
		str = "";
		strlength = 0;
	}

	*length = strlength > bitlength ? strlength : bitlength;

	memset(result, 0, *length);
	memcpy(result, str, strlength);

	result[bitnum / 8] |= 1 << (bitnum % 8);

	return result;
}

// MYSQL_UDF: str_get_bit integer
my_bool str_get_bit_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_get_bit() requires 2 arguments");
		return 1;
	}

	if (!args->args[1]) {
		strcpy(message, "str_set_bit() does not accept NULL as bit number");
		return 1;
	}

 	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = INT_RESULT;

	return 0;
}

void str_get_bit_deinit(UDF_INIT *initid __attribute__((unused))) {
}

long long str_get_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	char *str = args->args[0];
	unsigned long long bitnum = *((long long *)args->args[1]);

	if (!str) {
		return 0;
	}

	if (args->lengths[0] < bitnum / 8 + 1) {
		return 0;
	}

	// FIXME: bit ordering
	return (str[bitnum / 8] & (1 << (bitnum % 8))) > 0 ? 1 : 0;
}



// MYSQL_UDF: str_or string
my_bool str_or_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_or() requires 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = STRING_RESULT;

	return 0;
}

void str_or_deinit(UDF_INIT *initid __attribute__((unused))) {
}

char * str_or(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused)))
{
	char *str1 = args->args[0];
	char *str2 = args->args[1];
	unsigned long length1 = args->lengths[0];
	unsigned long length2 = args->lengths[1];
	unsigned char i;

	if (!str1) {
		str1 = "";
		length1 = 0;
	}

	if (!str2) {
		str2 = "";
		length2 = 0;
	}

	*length = (length1 > length2) ? length1 : length2;
	memset(result, 0, *length);

	memcpy(result, str1, length1);
	for(i = 0; i < length2; ++i) {
		result[i] |= str2[i];
	}

	return result;
}

// MYSQL_UDF: str_and string
my_bool str_and_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_and() requires 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = STRING_RESULT;

	return 0;
}

void str_and_deinit(UDF_INIT *initid __attribute__((unused))) {
}

char * str_and(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused)))
{
	char *str1 = args->args[0];
	char *str2 = args->args[1];
	unsigned long length1 = args->lengths[0];
	unsigned long length2 = args->lengths[1];
	unsigned char i;

	if (!str1) {
		str1 = "";
		length1 = 0;
	}

	if (!str2) {
		str2 = "";
		length2 = 0;
	}

	unsigned long minlength;
	if (length1 > length2) {
		*length = length1;
		minlength = length2;
	} else {
		*length = length2;
		minlength = length1;
	}

	memset(result, 0, *length);
	memcpy(result, str1, minlength);
	for (i = 0; i < minlength; ++i) {
		result[i] &= str2[i];
	}

	return result;
}
