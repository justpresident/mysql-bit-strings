#include <mysql.h>
#include <string.h>

// Uncomment next row if you want strict variable size checking. In this case, calling get_bit and set_bit with bit number greater than number of bits in your string will produce error.
// Also, NULL will be returned if source string is NULL
//#define STRICT_SIZE_CHECK

// Definition for automatic 'create function' and 'drop function' generation
// Format: // MYSQL_UDF: <function_name> {string|integer|real|decimal} [aggregate] 

// MYSQL_UDF: str_set_bit string
my_bool str_set_bit_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_get_bit() require 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = INT_RESULT;

	return 0;
}

void str_set_bit_deinit(UDF_INIT *initid __attribute__((unused))) {
}

#ifdef STRICT_SIZE_CHECK
char * str_set_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null, char *error) {
#else
char * str_set_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
#endif
	char *str = args->args[0];
	unsigned long long bitnum = *((long long *)args->args[1]);

#ifdef STRICT_SIZE_CHECK
	if(!str) {
		*is_null = 1;
		return NULL;
	}
#endif

	*length = bitnum / 8 + (bitnum % 8 > 0 ? 1 : 0);
	memset(result, 0, *length);
#ifdef STRICT_SIZE_CHECK
	if (args->lengths[0] < *length) {
		*error = 1;
	}
#endif

	if (str)
		memcpy(result, str, args->lengths[0]);
	// FIXME: bit ordering
	result[bitnum / 8] |= 1 << (bitnum % 8);

	return result;
}

// MYSQL_UDF: str_get_bit integer
my_bool str_get_bit_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_get_bit() require 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = INT_RESULT;

	return 0;
}

void str_get_bit_deinit(UDF_INIT *initid __attribute__((unused))) {
}

#ifdef STRICT_SIZE_CHECK
long long str_get_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *is_null, char *error) {
#else
long long str_get_bit(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
#endif
	char *str = args->args[0];
	unsigned long long bitnum = *((long long *)args->args[1]);

#ifdef STRICT_SIZE_CHECK
	if(!str) {
		*is_null = 1;
		return 0;
	}
#endif

	if (args->lengths[0] < bitnum / 8 + (bitnum % 8 > 0 ? 1 : 0)) {
#ifdef STRICT_SIZE_CHECK
		*error = 1;
#else
		return 0;
#endif
	}

	// FIXME: bit ordering
	return (str[bitnum / 8] & (1 << (bitnum % 8))) > 0 ? 1 : 0;
}



// MYSQL_UDF: str_or string
my_bool str_or_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_or() require 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = STRING_RESULT;

	return 0;
}

void str_or_deinit(UDF_INIT *initid __attribute__((unused))) {
}

char * str_or(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null, char *error __attribute__((unused)))
{
	char *str1 = args->args[0];
	char *str2 = args->args[1];
	unsigned char i;

	if(!str1 && !str2) {
		*is_null = 1;
		return NULL;
	}

	memcpy(result, str1, args->lengths[0]);
	for(i = 0; i < args->lengths[1]; ++i) {
		result[i] |= str2[i];
	}
	*length = args->lengths[0] > args->lengths[1] ? args->lengths[0] : args->lengths[1];

	return result;
}

// MYSQL_UDF: str_and string
my_bool str_and_init(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *message) {
	if (args->arg_count != 2) {
 		strcpy(message, "str_and() require 2 arguments");
		return 1;
	}
	args->arg_type[0] = STRING_RESULT;
	args->arg_type[1] = STRING_RESULT;

	return 0;
}

void str_and_deinit(UDF_INIT *initid __attribute__((unused))) {
}

char * str_and(UDF_INIT *initid __attribute__((unused)), UDF_ARGS *args, char *result, unsigned long *length, char *is_null, char *error __attribute__((unused)))
{
	char *str1 = args->args[0];
	char *str2 = args->args[1];
	unsigned char i;

	if(!str1 && !str2) {
		*is_null = 1;
		return NULL;
	}

	memcpy(result, str1, args->lengths[0]);
	for(i = 0; i < args->lengths[1]; ++i) {
		result[i] &= str2[i];
	}
	*length = args->lengths[0] > args->lengths[1] ? args->lengths[0] : args->lengths[1];

	return result;
}

