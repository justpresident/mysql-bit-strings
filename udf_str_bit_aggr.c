#include <mysql.h>
#include <string.h>
#include <stdlib.h>

#define MAX_LENGTH 255

struct udf_string {
	unsigned long length;
	char str[MAX_LENGTH];
};

my_bool init_aggr(UDF_INIT *initid, UDF_ARGS *args, char *message) {
	struct udf_string *state;

	if (args->arg_count != 1) {
 		strcpy(message, "function requires 1 argument");
		return 1;
	}

	args->arg_type[0] = STRING_RESULT;

	state = malloc(sizeof(struct udf_string));

	if (state == NULL) {
		strcpy(message, "Can't allocate buffer in str_*_aggr");
		return 1;
	}

	initid->ptr = (char *)state;

	return 0;
}

void clear_aggr(UDF_INIT *initid) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;

	memset(state->str, 0, MAX_LENGTH); // we zero-fill all memory
	state->length = 1;                 // but return only one zero-byte as a result for no input
}

void deinit_aggr(UDF_INIT *initid) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;
	free(state);
}

char *aggr_result(UDF_INIT *initid, char *result, unsigned long *length) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;

	*length = state->length;
	memcpy(result, state->str, *length);

	return result;
}


// Definition for automatic 'create function' and 'drop function' generation
// Format: // MYSQL_UDF: <function_name> {string|integer|real|decimal} [aggregate]

// MYSQL_UDF: str_or_aggr string aggregate
my_bool str_or_aggr_init(UDF_INIT *initid, UDF_ARGS *args, char *message) {
	return init_aggr(initid, args, message);
}

void str_or_aggr_deinit(UDF_INIT *initid) {
	deinit_aggr(initid);
}

void str_or_aggr_clear(UDF_INIT *initid, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	clear_aggr(initid);
}

void str_or_aggr_add(UDF_INIT *initid, UDF_ARGS *args, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;

	char *str = args->args[0];
	unsigned int i;
	if (str) {
		for (i = 0; i < args->lengths[0]; ++i) {
			state->str[i] |= str[i];
		}
	}
	if (args->lengths[0] > state->length) {
		state->length = args->lengths[0];
	}
}

char * str_or_aggr(UDF_INIT *initid, UDF_ARGS *args __attribute__((unused)), char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	return aggr_result(initid, result, length);
}


// MYSQL_UDF: str_and_aggr string aggregate
my_bool str_and_aggr_init(UDF_INIT *initid, UDF_ARGS *args, char *message) {
	return init_aggr(initid, args, message);
}

void str_and_aggr_deinit(UDF_INIT *initid) {
	deinit_aggr(initid);
}

void str_and_aggr_clear(UDF_INIT *initid, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	clear_aggr(initid);


	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;
	state->length = MAX_LENGTH + 2; // indicates that we did not process any rows yet
}

void str_and_aggr_add(UDF_INIT *initid, UDF_ARGS *args, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;

	char *str = args->args[0];
	unsigned long cur_length = args->lengths[0];

	if (!str) {
		str = "";
		cur_length = 0;
	}

	unsigned int i;
	if (state->length > MAX_LENGTH) {
		// just copy first row
		memcpy(state->str, str, cur_length);
		state->length = cur_length;
	} else {
		for (i = 0; i < cur_length; ++i) {
			state->str[i] &= str[i];
		}

		if (cur_length >= state->length) {
			state->length = cur_length;
		}
	}
}

char *str_and_aggr(UDF_INIT *initid, UDF_ARGS *args __attribute__((unused)), char *result, unsigned long *length, char *is_null __attribute__((unused)), char *error __attribute__((unused))) {
	struct udf_string *state;
	state = (struct udf_string *)initid->ptr;

	// fix length first (return zero string of 1 byte in case of empty input)
	if (state->length > MAX_LENGTH)
		state->length = 1;

	return aggr_result(initid, result, length);
}
