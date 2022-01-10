use crate::ocaml_index;

#[ocaml::func]
pub unsafe fn add_docs_json(
    t: ocaml::Pointer<'static, ocaml_index::TantivyIndex>,
    arr: ocaml::Array<String>,
) -> Result<u64, ocaml::Error> {
    let tindex = t.as_ref();
    let index = &tindex.index;
    let schema = &tindex.schema;
    let reader = &tindex.reader;
    let mut index_writer = index.writer(50_000_000)?;
    for i in 0..arr.len() {
        let json = arr.get_unchecked(i);
        let doc = schema.parse_document(&json.as_str())?;
        index_writer.add_document(doc);
    }
    let stamp = index_writer.commit()?;
    reader.reload()?;
    Ok(stamp)
}
