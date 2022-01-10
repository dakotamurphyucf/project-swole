use tantivy::schema::Schema;
use tantivy::schema::*;

#[derive(ocaml::IntoValue, ocaml::FromValue)]
enum TextFieldOptions {
    Text,
    TextAndStored,
    String,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
enum U64FieldOptions {
    Indexed,
    IndexedAndStored,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
enum F64FieldOptions {
    Indexed,
    IndexedAndStored,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
enum FacetFieldOptions {
    Default,
}

#[derive(ocaml::IntoValue, ocaml::FromValue)]
enum AddField {
    Text(TextFieldOptions),
    U64(U64FieldOptions),
    Facet(FacetFieldOptions),
    F64(F64FieldOptions),
}

// https://github.com/zshipko/ocaml-rs/blob/master/test/src/custom.rs
pub struct SchemaWrap {
    pub schema: Schema,
}

unsafe extern "C" fn tantivy_schema_finalizer(v: ocaml::Raw) {
    let ptr = v.as_pointer::<SchemaWrap>();
    ptr.drop_in_place()
}

ocaml::custom_finalize!(SchemaWrap, tantivy_schema_finalizer);

#[ocaml::func]
pub unsafe fn new_tantivy_schema(
    arr: ocaml::Array<(String, AddField)>,
) -> ocaml::Pointer<'static, SchemaWrap> {
    let mut schema_builder = Schema::builder();
    for i in 0..arr.len() {
        match arr.get_unchecked(i) {
            (name, AddField::Text(opt)) => match opt {
                TextFieldOptions::Text => {
                    schema_builder.add_text_field(&name.as_str(), TEXT);
                }
                TextFieldOptions::TextAndStored => {
                    schema_builder.add_text_field(&name.as_str(), TEXT | STORED);
                }
                TextFieldOptions::String => {
                    schema_builder.add_text_field(&name.as_str(), STRING);
                }
            },
            (name, AddField::U64(opt)) => match opt {
                U64FieldOptions::Indexed => {
                    schema_builder.add_u64_field(&name.as_str(), INDEXED);
                }
                U64FieldOptions::IndexedAndStored => {
                    schema_builder.add_u64_field(&name.as_str(), INDEXED | STORED);
                }
            },
            (name, AddField::F64(opt)) => match opt {
                F64FieldOptions::Indexed => {
                    schema_builder.add_f64_field(&name.as_str(), INDEXED);
                }
                F64FieldOptions::IndexedAndStored => {
                    schema_builder.add_f64_field(&name.as_str(), INDEXED | STORED);
                }
            },
            (name, AddField::Facet(opt)) => match opt {
                FacetFieldOptions::Default => {
                    schema_builder.add_facet_field(&name.as_str(), FacetOptions::default());
                }
            },
        }
    }
    let schema: Schema = schema_builder.build();
    ocaml::Pointer::alloc_custom(SchemaWrap { schema })
}
