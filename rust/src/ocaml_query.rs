use crate::ocaml_index;
use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;

// https://github.com/zshipko/ocaml-rs/blob/master/test/src/custom.rs
pub struct QueryParserWrap {
    pub parser: QueryParser,
}

unsafe extern "C" fn tantivy_query_parser_finalizer(v: ocaml::Raw) {
    let ptr = v.as_pointer::<QueryParserWrap>();
    ptr.drop_in_place()
}

ocaml::custom_finalize!(QueryParserWrap, tantivy_query_parser_finalizer);

#[ocaml::func]
pub unsafe fn create_query_parser(
    t: ocaml::Pointer<'static, ocaml_index::TantivyIndex>,
    default_fields: ocaml::Array<String>,
) -> Result<ocaml::Pointer<'static, QueryParserWrap>, ocaml::Error> {
    let tindex = t.as_ref();
    let index = &tindex.index;
    let schema = index.schema();
    let mut vec: Vec<tantivy::schema::Field> = Vec::new();
    for i in 0..default_fields.len() {
        let field_str = default_fields.get_unchecked(i);
        let field = schema.get_field(&field_str).unwrap();
        vec.push(field);
    }
    let parser = QueryParser::for_index(&index, vec);
    Ok(ocaml::Pointer::alloc_custom(QueryParserWrap { parser }))
}

#[ocaml::func]
pub fn query(
    t: ocaml::Pointer<'static, ocaml_index::TantivyIndex>,
    qt: ocaml::Pointer<'static, QueryParserWrap>,
    query: String,
    limit: usize,
) -> Result<ocaml::List<'static, String>, ocaml::Error> {
    let tindex = t.as_ref();
    let index = &tindex.index;
    let schema = index.schema();
    let reader = &tindex.reader;
    let qtparser = qt.as_ref();
    let query_parser = &qtparser.parser;
    let searcher = reader.searcher();
    let query = query_parser.parse_query(&query)?;
    let top_docs = searcher.search(&query, &TopDocs::with_limit(limit))?;
    let mut list = ocaml::List::empty();
    for (_score, doc_address) in top_docs {
        let retrieved_doc = searcher.doc(doc_address)?;
        unsafe { list = list.add(gc, schema.to_json(&retrieved_doc)) }
    }
    Ok(list)
}
