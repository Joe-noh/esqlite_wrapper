#include <erl_nif.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

#include "utils.h"

typedef struct {
    sqlite3* conn;
} exq_database;

typedef struct {
    sqlite3_stmt* stmt;
} exq_prepared;

static ERL_NIF_TERM fetch_column_names(ErlNifEnv*, sqlite3_stmt*, int);
static ERL_NIF_TERM fetch_row(ErlNifEnv*, sqlite3_stmt*, int);
static ERL_NIF_TERM fetch_text(ErlNifEnv*, sqlite3_stmt*, int);
static ERL_NIF_TERM fetch_blob(ErlNifEnv*, sqlite3_stmt*, int);
static ERL_NIF_TERM fetch_int(ErlNifEnv*, sqlite3_stmt*, int);
static ERL_NIF_TERM fetch_double(ErlNifEnv*, sqlite3_stmt*, int);

static ErlNifResourceType *exq_database_type = NULL;
static ErlNifResourceType *exq_prepared_type = NULL;

static void exq_database_destructor(ErlNifEnv* env, void* arg) {
}

static void exq_prepared_destructor(ErlNifEnv* env, void* arg) {
}

// open(char_list) :: {:ok, db}
static ERL_NIF_TERM exq_open(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_database* db = enif_alloc_resource(exq_database_type, sizeof(exq_database));

    char* db_path = get_string_from_char_list(env, argv[0]);

    int code = sqlite3_open(db_path, &db->conn);

    if (code == SQLITE_OK) {
        ERL_NIF_TERM db_resource = enif_make_resource(env, db);
        enif_release_resource(db);

        return ok_tuple(env, db_resource);
    }

    return error_message_tuple(env, sqlite3_errstr(code));
}

// close(db) :: :ok
static ERL_NIF_TERM exq_close(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_database* db;
    enif_get_resource(env, argv[0], exq_database_type, (void**)&db);

    int code = sqlite3_close(db->conn);
    if (code == SQLITE_OK) {
        return make_atom(env, "ok");
    }

    return enif_make_int(env, code);
}


// prepare(db, char_list) :: stmt | {:error, message}
static ERL_NIF_TERM exq_prepare(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps = enif_alloc_resource(exq_prepared_type, sizeof(exq_prepared));

    exq_database* db;
    enif_get_resource(env, argv[0], exq_database_type, (void**)&db);

    char* sql = get_string_from_char_list(env, argv[1]);
    unsigned int length = get_list_length(env, argv[1]);

    int code = sqlite3_prepare_v2(db->conn, sql, length, &(ps->stmt), NULL);

    if (code == SQLITE_OK) {
        ERL_NIF_TERM prepared = enif_make_resource(env, ps);
        enif_release_resource(ps);

        return prepared;
    }

    return error_message_tuple(env, sqlite3_errstr(code));
}


// step(stmt) :: {:ok, map} | :done | :busy
static ERL_NIF_TERM exq_step(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps;
    enif_get_resource(env, argv[0], exq_prepared_type, (void**)&ps);

    int num_columns;
    int code = sqlite3_step(ps->stmt);
    switch (code) {
    case SQLITE_ROW:
        num_columns = sqlite3_column_count(ps->stmt);
        if (num_columns == 0) {
            return make_atom(env, "ok");
        }
        return ok_triple(env, fetch_column_names(env, ps->stmt, num_columns),
                              fetch_row(env, ps->stmt, num_columns));
    case SQLITE_DONE:
        return make_atom(env, "done");
    case SQLITE_BUSY:
        return make_atom(env, "busy");
    default: // SQLITE_ERROR or SQLITE_MISUSE
        return error_message_tuple(env, sqlite3_errstr(code));
    }
}

static ERL_NIF_TERM fetch_column_names(ErlNifEnv* env, sqlite3_stmt* stmt, int num_columns) {
    if (num_columns == 0) {
        return make_atom(env, "none");
    }

    ERL_NIF_TERM* column_names = (ERL_NIF_TERM*)malloc(sizeof(ERL_NIF_TERM) * num_columns);

    for (int i=0; i < num_columns; i++) {
        const char* name = sqlite3_column_name(stmt, i);
        column_names[i] = make_atom(env, name);
    }

    ERL_NIF_TERM names_tuple = enif_make_list_from_array(env, column_names, num_columns);
    free(column_names);

    return names_tuple;
}

static ERL_NIF_TERM fetch_row(ErlNifEnv* env, sqlite3_stmt* stmt, int num_columns) {
    if (num_columns == 0) {
        return make_atom(env, "none");
    }

    ERL_NIF_TERM* row = (ERL_NIF_TERM*)malloc(sizeof(ERL_NIF_TERM) * num_columns);

    for (int i=0; i < num_columns; i++) {
        int type = sqlite3_column_type(stmt, i);
        switch (type) {
            case SQLITE_TEXT:    row[i] = fetch_text(env, stmt, i);   break;
            case SQLITE_BLOB:    row[i] = fetch_blob(env, stmt, i);   break;
            case SQLITE_INTEGER: row[i] = fetch_int(env, stmt, i);    break;
            case SQLITE_FLOAT:   row[i] = fetch_double(env, stmt, i); break;
            case SQLITE_NULL:    row[i] = make_atom(env, "nil");      break;
        }
    }

    ERL_NIF_TERM row_tuple = enif_make_list_from_array(env, row, num_columns);
    free(row);

    return row_tuple;
}

static ERL_NIF_TERM fetch_text(ErlNifEnv* env, sqlite3_stmt* stmt, int index) {
    char* text = (char*)sqlite3_column_text(stmt, index);
    return enif_make_string(env, text, ERL_NIF_LATIN1);
}

static ERL_NIF_TERM fetch_blob(ErlNifEnv* env, sqlite3_stmt* stmt, int index) {
    ERL_NIF_TERM nif_blob;
    void* blob = (void*)sqlite3_column_blob(stmt, index);
    int size = sqlite3_column_bytes(stmt, index);
    void* nif_blob_raw_data = (void*)enif_make_new_binary(env, size, &nif_blob);
    memcpy(nif_blob_raw_data, blob, size);

    return nif_blob;
}

static ERL_NIF_TERM fetch_int(ErlNifEnv* env, sqlite3_stmt* stmt, int index) {
    return enif_make_int(env, sqlite3_column_int(stmt, index));
}

static ERL_NIF_TERM fetch_double(ErlNifEnv* env, sqlite3_stmt* stmt, int index) {
    return enif_make_double(env, sqlite3_column_double(stmt, index));
}

// bind_text(stmt, index, text) :: :ok | {:error, message}
static ERL_NIF_TERM exq_bind_text(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps;
    enif_get_resource(env, argv[0], exq_prepared_type, (void**)&ps);

    char* sql = get_string_from_char_list(env, argv[1]);
    unsigned int length = get_list_length(env, argv[1]);

    int index;
    enif_get_int(env, argv[2], &index);

    int code = sqlite3_bind_text(ps->stmt, index, sql, length, SQLITE_TRANSIENT);

    return ok_or_error_tuple(env, code);
}

// bind_blob(stmt, index, blob) :: :ok | {:error, message}
static ERL_NIF_TERM exq_bind_blob(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps;
    enif_get_resource(env, argv[0], exq_prepared_type, (void**)&ps);

    ErlNifBinary blob;
    int index;

    enif_inspect_binary(env, argv[1], &blob);
    enif_get_int(env, argv[2], &index);

    int code = sqlite3_bind_blob(ps->stmt, index, (void*)(blob.data), blob.size, SQLITE_TRANSIENT);

    return ok_or_error_tuple(env, code);
}

// bind_int(stmt, index, integer) :: :ok | {:error, message}
static ERL_NIF_TERM exq_bind_int(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps;
    enif_get_resource(env, argv[0], exq_prepared_type, (void**)&ps);

    int value;
    int index;

    enif_get_int(env, argv[1], &value);
    enif_get_int(env, argv[2], &index);

    int code = sqlite3_bind_int(ps->stmt, index, value);

    return ok_or_error_tuple(env, code);
}

// bind_float(stmt, index, float) :: :ok | {:error, message}
static ERL_NIF_TERM exq_bind_float(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    exq_prepared* ps;
    enif_get_resource(env, argv[0], exq_prepared_type, (void**)&ps);

    double value;
    int index;

    enif_get_double(env, argv[1], &value);
    enif_get_int(env, argv[2], &index);

    int code = sqlite3_bind_double(ps->stmt, index, value);

    return ok_or_error_tuple(env, code);
}

static int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    exq_database_type = enif_open_resource_type(
        env, "Elixir.Exqlite.Nif", "exq_database_type",
        exq_database_destructor, ERL_NIF_RT_CREATE, NULL
    );
    exq_prepared_type = enif_open_resource_type(
        env, "Elixir.Exqlite.Nif", "exq_prepared_type",
        exq_prepared_destructor, ERL_NIF_RT_CREATE, NULL
    );

    return 0;
}

static ErlNifFunc nif_functions[] = {
    {"open",       1, exq_open},
    {"close",      1, exq_close},
    {"prepare",    2, exq_prepare},
    {"step",       1, exq_step},
    {"bind_text",  3, exq_bind_text},
    {"bind_blob",  3, exq_bind_blob},
    {"bind_int",   3, exq_bind_int},
    {"bind_float", 3, exq_bind_float}
};

ERL_NIF_INIT(Elixir.Exqlite.Nif, nif_functions, on_load, 0, 0, NULL);

