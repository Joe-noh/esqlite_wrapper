#ifndef UTILS_H
#define UTILS_H

ERL_NIF_TERM make_atom(ErlNifEnv*, const char*);
ERL_NIF_TERM ok_tuple(ErlNifEnv*, ERL_NIF_TERM);
ERL_NIF_TERM ok_triple(ErlNifEnv*, ERL_NIF_TERM, ERL_NIF_TERM);
ERL_NIF_TERM error_tuple(ErlNifEnv *env, ERL_NIF_TERM);
ERL_NIF_TERM error_message_tuple(ErlNifEnv*, const char*);
ERL_NIF_TERM ok_or_error_tuple(ErlNifEnv*, int);

unsigned int get_list_length(ErlNifEnv*, ERL_NIF_TERM);
char* get_string_from_char_list(ErlNifEnv*, ERL_NIF_TERM);

#endif
