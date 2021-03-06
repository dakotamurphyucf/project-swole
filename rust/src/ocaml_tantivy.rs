use std::path::Path;
use tantivy::collector::TopDocs;
use tantivy::directory::MmapDirectory;
use tantivy::query::QueryParser;
use tantivy::schema::*;
use tantivy::{doc, Index, ReloadPolicy};

// Note we do not need schema in here because we have index,schema() at all times
struct TantivyIndex {
    schema: Schema,
    reader: tantivy::IndexReader,
    index: Index,
}

// https://github.com/zshipko/ocaml-rs/blob/master/test/src/custom.rs
unsafe extern "C" fn tantivy_index_finalizer(v: ocaml::Raw) {
    let ptr = v.as_pointer::<TantivyIndex>();
    ptr.drop_in_place()
}

ocaml::custom_finalize!(TantivyIndex, tantivy_index_finalizer);

#[ocaml::func]
pub fn new_tantivy_index() -> ocaml::Pointer<TantivyIndex> {
    let mut schema_builder = Schema::builder();

    schema_builder.add_text_field("title", TEXT | STORED);
    schema_builder.add_text_field("body", TEXT);

    let schema = schema_builder.build();
    let index_path = Path::new("/home/dakota/project-swole/tantivity/");
    let dir = MmapDirectory::open(&index_path).unwrap();
    let index = Index::open_or_create(dir, schema.clone()).unwrap();
    let reader = index
        .reader_builder()
        .reload_policy(ReloadPolicy::OnCommit)
        .try_into()
        .unwrap();
    ocaml::Pointer::alloc_custom(TantivyIndex {
        schema,
        reader,
        index,
    })
    // ocaml::Pointer::alloc_final(gc, MyType, finalizer, None) can also be used
    // if you don't intend to implement `Custom`
}

#[ocaml::func]
pub fn query_tantivy(
    t: ocaml::Pointer<TantivyIndex>,
    query: String,
) -> Result<ocaml::List<'static, String>, ocaml::Error> {
    let tindex = t.as_ref();
    let reader = &tindex.reader;
    let index = &tindex.index;
    let schema = &tindex.schema;
    let searcher = reader.searcher();

    let title = schema.get_field("title").unwrap();
    let body = schema.get_field("body").unwrap();
    // ### Query

    // The query parser can interpret human queries.
    // Here, if the user does not specify which
    // field they want to search, tantivy will search
    // in both title and body.
    let query_parser = QueryParser::for_index(&index, vec![title, body]);

    let query = query_parser.parse_query(&query.as_str())?;

    let top_docs = searcher.search(&query, &TopDocs::with_limit(10))?;

    let mut list = ocaml::List::empty();
    for (_score, doc_address) in top_docs {
        let retrieved_doc = searcher.doc(doc_address)?;
        unsafe { list = list.add(gc, schema.to_json(&retrieved_doc)) }
    }
    Ok(list)
}

pub fn tantiviy(query: &str) -> tantivy::Result<Vec<String>> {
    // Let's create a temporary directory for the
    // sake of this example
    let index_path = Path::new("/home/dakota/project-swole/tantivity/");

    // # Defining the schema
    //
    // The Tantivy index requires a very strict schema.
    // The schema declares which fields are in the index,
    // and for each field, its type and "the way it should
    // be indexed".

    // First we need to define a schema ...
    let mut schema_builder = Schema::builder();

    schema_builder.add_text_field("title", TEXT | STORED);
    schema_builder.add_text_field("body", TEXT);

    let schema = schema_builder.build();

    // # Indexing documents
    //
    // Let's create a brand new index.
    //
    // This will actually just save a meta.json
    // with our schema in the directory.
    // let index = Index::create_in_dir(&index_path, schema.clone())?;
    let dir = MmapDirectory::open(&index_path)?;
    let index = Index::open_or_create(dir, schema.clone())?;
    let mut index_writer = index.writer(50_000_000)?;

    // Let's index our documents!
    // We first need a handle on the title and the body field.

    // ### Adding documents
    //
    // We can create a document manually, by setting the fields
    // one by one in a Document object.
    let title = schema.get_field("title").unwrap();
    let body = schema.get_field("body").unwrap();

    let mut old_man_doc = Document::default();
    old_man_doc.add_text(title, "The Old Man and the Sea");
    old_man_doc.add_text(
        body,
        "He was an old man who fished alone in a skiff in the Gulf Stream and \
         he had gone eighty-four days now without taking a fish.",
    );

    // ... and add it to the `IndexWriter`.
    index_writer.add_document(old_man_doc);

    // For convenience, tantivy also comes with a macro to
    // reduce the boilerplate above.
    index_writer.add_document(doc!(
    title => "Of Mice and Men",
    body => "A few miles south of Soledad, the Salinas River drops in close to the hillside \
            bank and runs deep and green. The water is warm too, for it has slipped twinkling \
            over the yellow sands in the sunlight before reaching the narrow pool. On one \
            side of the river the golden foothill slopes curve up to the strong and rocky \
            Gabilan Mountains, but on the valley side the water is lined with trees???willows \
            fresh and green with every spring, carrying in their lower leaf junctures the \
            debris of the winter???s flooding; and sycamores with mottled, white, recumbent \
            limbs and branches that arch over the pool"
    ));

    // Multivalued field just need to be repeated.
    index_writer.add_document(doc!(
    title => "Frankenstein",
    title => "The Modern Prometheus",
    body => "You will rejoice to hear that no disaster has accompanied the commencement of an \
             enterprise which you have regarded with such evil forebodings.  I arrived here \
             yesterday, and my first task is to assure my dear sister of my welfare and \
             increasing confidence in the success of my undertaking."
    ));

    // This is an example, so we will only index 3 documents
    // here. You can check out tantivy's tutorial to index
    // the English wikipedia. Tantivy's indexing is rather fast.
    // Indexing 5 million articles of the English wikipedia takes
    // around 3 minutes on my computer!

    // ### Committing
    //
    // At this point our documents are not searchable.
    //
    //
    // We need to call `.commit()` explicitly to force the
    // `index_writer` to finish processing the documents in the queue,
    // flush the current index to the disk, and advertise
    // the existence of new documents.
    //
    // This call is blocking.
    index_writer.commit()?;

    // If `.commit()` returns correctly, then all of the
    // documents that have been added are guaranteed to be
    // persistently indexed.
    //
    // In the scenario of a crash or a power failure,
    // tantivy behaves as if it has rolled back to its last
    // commit.

    // # Searching
    //
    // ### Searcher
    //
    // A reader is required first in order to search an index.
    // It acts as a `Searcher` pool that reloads itself,
    // depending on a `ReloadPolicy`.
    //
    // For a search server you will typically create one reader for the entire lifetime of your
    // program, and acquire a new searcher for every single request.
    //
    // In the code below, we rely on the 'ON_COMMIT' policy: the reader
    // will reload the index automatically after each commit.
    let reader = index
        .reader_builder()
        .reload_policy(ReloadPolicy::OnCommit)
        .try_into()?;

    // We now need to acquire a searcher.
    //
    // A searcher points to a snapshotted, immutable version of the index.
    //
    // Some search experience might require more than
    // one query. Using the same searcher ensures that all of these queries will run on the
    // same version of the index.
    //
    // Acquiring a `searcher` is very cheap.
    //
    // You should acquire a searcher every time you start processing a request and
    // and release it right after your query is finished.
    let searcher = reader.searcher();

    // ### Query

    // The query parser can interpret human queries.
    // Here, if the user does not specify which
    // field they want to search, tantivy will search
    // in both title and body.
    let query_parser = QueryParser::for_index(&index, vec![title, body]);

    // `QueryParser` may fail if the query is not in the right
    // format. For user facing applications, this can be a problem.
    // A ticket has been opened regarding this problem.
    let query = query_parser.parse_query(query)?;

    // A query defines a set of documents, as
    // well as the way they should be scored.
    //
    // A query created by the query parser is scored according
    // to a metric called Tf-Idf, and will consider
    // any document matching at least one of our terms.

    // ### Collectors
    //
    // We are not interested in all of the documents but
    // only in the top 10. Keeping track of our top 10 best documents
    // is the role of the `TopDocs` collector.

    // We can now perform our query.
    let top_docs = searcher.search(&query, &TopDocs::with_limit(10))?;

    // The actual documents still need to be
    // retrieved from Tantivy's store.
    //
    // Since the body field was not configured as stored,
    // the document returned will only contain
    // a title.
    let mut vec: Vec<String> = Vec::new();
    for (_score, doc_address) in top_docs {
        let retrieved_doc = searcher.doc(doc_address)?;
        vec.push(schema.to_json(&retrieved_doc));
    }

    Ok(vec)
}
