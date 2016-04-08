static VALUE wrap_get_phi(VALUE self) {
    if (!model_loaded)
        return Qnil;

    VALUE arr = rb_ary_new2(last_corpus->num_docs);
    int i = 0, j = 0, k = 0;

    //int max_length = max_corpus_length(last_corpus);
    short error = 0;

    for (i = 0; i < last_corpus->num_docs; i++) {
        VALUE arr1 = rb_ary_new2(last_corpus->docs[i].length);

        lda_inference(&(last_corpus->docs[i]), last_model, last_gamma[i], last_phi, &error);

        for (j = 0; j < last_corpus->docs[i].length; j++) {
            VALUE arr2 = rb_ary_new2(last_model->num_topics);

            for (k = 0; k < last_model->num_topics; k++) {
                rb_ary_store(arr2, k, rb_float_new(last_phi[j][k]));
            }

            rb_ary_store(arr1, j, arr2);
        }

        rb_ary_store(arr, i, arr1);
    }

    return arr;
}
