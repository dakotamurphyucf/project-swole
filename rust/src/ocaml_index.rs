use crate::ocaml_schema;
use std::path::Path;
use tantivy::directory::MmapDirectory;
use tantivy::schema::Schema;
use tantivy::{Index, ReloadPolicy};

pub struct TantivyIndex {
    pub schema: Schema,
    pub reader: tantivy::IndexReader,
    pub index: Index,
}

// https://github.com/zshipko/ocaml-rs/blob/master/test/src/custom.rs
unsafe extern "C" fn tantivy_index_finalizer(v: ocaml::Raw) {
    let ptr = v.as_pointer::<TantivyIndex>();
    ptr.drop_in_place()
}

ocaml::custom_finalize!(TantivyIndex, tantivy_index_finalizer);

#[ocaml::func]
pub fn tantivy_index(
    t: ocaml::Pointer<ocaml_schema::SchemaWrap>,
    path: String,
) -> ocaml::Pointer<'static, TantivyIndex> {
    let tindex = t.as_ref();
    let schema = &tindex.schema;
    let index_path = Path::new(&path);
    let dir = MmapDirectory::open(&index_path).unwrap();
    let index = Index::open_or_create(dir, schema.clone()).unwrap();
    let reader = index
        .reader_builder()
        .reload_policy(ReloadPolicy::OnCommit)
        .try_into()
        .unwrap();
    ocaml::Pointer::alloc_custom(TantivyIndex {
        schema: schema.clone(),
        reader,
        index,
    })
}
