#include <erl_nif.h>
#include <string.h>

ERL_NIF_TERM make_atom(ErlNifEnv *env, const char *name) {
    ERL_NIF_TERM atom;

    if (enif_make_existing_atom(env, name, &atom, ERL_NIF_LATIN1)) {
        return atom;
    }

    return enif_make_atom(env, name);
}

ERL_NIF_TERM ok_tuple(ErlNifEnv *env, ERL_NIF_TERM term) {
    return enif_make_tuple2(env, make_atom(env, "ok"), term);
}

ERL_NIF_TERM ok_triple(ErlNifEnv *env, ERL_NIF_TERM term1, ERL_NIF_TERM term2) {
    return enif_make_tuple3(env, make_atom(env, "ok"), term1, term2);
}

ERL_NIF_TERM error_tuple(ErlNifEnv *env, ERL_NIF_TERM term) {
    return enif_make_tuple2(env, make_atom(env, "error"), term);
}

ERL_NIF_TERM error_message_tuple(ErlNifEnv *env, const char *error) {
    return error_tuple(env, enif_make_string(env, error, ERL_NIF_LATIN1));
}

unsigned int get_list_length(ErlNifEnv* env, ERL_NIF_TERM list) {
    unsigned int length;
    enif_get_list_length(env, list, &length);

    return length;
}

char* get_string_from_char_list(ErlNifEnv* env, ERL_NIF_TERM char_list) {
    unsigned int list_length = get_list_length(env, char_list);
    list_length++;

    char* string = (char*)enif_alloc(list_length);
    enif_get_string(env, char_list, string, list_length, ERL_NIF_LATIN1);

    return string;
}
