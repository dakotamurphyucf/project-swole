use ocaml_interop::{
    ocaml_export, ocaml_unpack_polymorphic_variant, ocaml_unpack_variant, OCaml, OCamlBytes,
    OCamlFloat, OCamlInt, OCamlInt32, OCamlInt64, OCamlList, OCamlRef, ToOCaml,
};
use std::{thread, time};
use tantivy::collector::TopDocs;
use tantivy::query::QueryParser;
use tantivy::schema::*;
use tantivy::{doc, Index, ReloadPolicy};
use std::path::Path;
use tantivy::directory::MmapDirectory;

enum Movement {
    Step { count: i32 },
    RotateLeft,
    RotateRight,
}

enum PolymorphicMovement {
    Step { count: i32 },
    RotateLeft,
    RotateRight,
}
fn tantiviy(query: &str) -> tantivy::Result<Vec<String>> { 
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

    // Our first field is title.
    // We want full-text search for it, and we also want
    // to be able to retrieve the document after the search.
    //
    // `TEXT | STORED` is some syntactic sugar to describe
    // that.
    //
    // `TEXT` means the field should be tokenized and indexed,
    // along with its term frequency and term positions.
    //
    // `STORED` means that the field will also be saved
    // in a compressed, row-oriented key-value store.
    // This store is useful for reconstructing the
    // documents that were selected during the search phase.
    schema_builder.add_text_field("title", TEXT | STORED);

    // Our second field is body.
    // We want full-text search for it, but we do not
    // need to be able to be able to retrieve it
    // for our application.
    //
    // We can make our index lighter by omitting the `STORED` flag.
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
     let index =  Index::open_or_create(dir, schema.clone())?;
     
     
    // To insert a document we will need an index writer.
    // There must be only one writer at a time.
    // This single `IndexWriter` is already
    // multithreaded.
    //
    // Here we give tantivy a budget of `50MB`.
    // Using a bigger heap for the indexer may increase
    // throughput, but 50 MB is already plenty.
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
            Gabilan Mountains, but on the valley side the water is lined with trees—willows \
            fresh and green with every spring, carrying in their lower leaf junctures the \
            debris of the winter’s flooding; and sycamores with mottled, white, recumbent \
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
ocaml_export! {
    fn rust_twice(cr, num: OCamlRef<OCamlInt>) -> OCaml<OCamlInt> {
        let num: i64 = num.to_rust(cr);
        unsafe { OCaml::of_i64_unchecked(num * 2) }
    }

    fn run_tantiviy(cr, num: OCamlRef<String>) -> OCaml<OCamlList<String>>{
        let query: String = num.to_rust(cr);
        let list = tantiviy(&query.as_str()).unwrap();
        list.to_ocaml(cr)
    }

    fn rust_twice_boxed_i64(cr, num: OCamlRef<OCamlInt64>) -> OCaml<OCamlInt64> {
        let num: i64 = num.to_rust(cr);
        let result = num * 2;
        result.to_ocaml(cr)
    }

    fn rust_twice_boxed_i32(cr, num: OCamlRef<OCamlInt32>) -> OCaml<OCamlInt32> {
        let num: i32 = num.to_rust(cr);
        let result = num * 2;
        result.to_ocaml(cr)
    }

    fn rust_add_unboxed_floats_noalloc(_cr, num: f64, num2: f64) -> f64 {
        num * num2
    }

    fn rust_twice_boxed_float(cr, num: OCamlRef<OCamlFloat>) -> OCaml<OCamlFloat> {
        let num: f64 = num.to_rust(cr);
        let result = num * 2.0;
        result.to_ocaml(cr)
    }

    fn rust_twice_unboxed_float(_cr, num: f64) -> f64 {
        num * 2.0
    }

    fn rust_increment_bytes(cr, bytes: OCamlRef<OCamlBytes>, first_n: OCamlRef<OCamlInt>) -> OCaml<OCamlBytes> {
        let first_n: i64 = first_n.to_rust(cr);
        let first_n = first_n as usize;
        let mut vec: Vec<u8> = bytes.to_rust(cr);

        for i in 0..first_n {
            vec[i] += 1;
        }

        vec.to_ocaml(cr)
    }

    fn rust_increment_ints_list(cr, ints: OCamlRef<OCamlList<OCamlInt>>) -> OCaml<OCamlList<OCamlInt>> {
        let mut vec: Vec<i64> = ints.to_rust(cr);

        for i in 0..vec.len() {
            vec[i] += 1;
        }

        vec.to_ocaml(cr)
    }

    fn rust_make_tuple(cr, fst: OCamlRef<String>, snd: OCamlRef<OCamlInt>) -> OCaml<(String, OCamlInt)> {
        let fst: String = fst.to_rust(cr);
        let snd: i64 = snd.to_rust(cr);
        let tuple = (fst, snd);
        tuple.to_ocaml(cr)
    }

    fn rust_make_some(cr, value: OCamlRef<String>) -> OCaml<Option<String>> {
        let value: String = value.to_rust(cr);
        let some_value = Some(value);
        some_value.to_ocaml(cr)
    }

    fn rust_make_ok(cr, value: OCamlRef<OCamlInt>) -> OCaml<Result<OCamlInt, String>> {
        let value: i64 = value.to_rust(cr);
        let ok_value: Result<i64, String> = Ok(value);
        ok_value.to_ocaml(cr)
    }

    fn rust_make_error(cr, value: OCamlRef<String>) -> OCaml<Result<OCamlInt, String>> {
        let value: String = value.to_rust(cr);
        let error_value: Result<i64, String> = Err(value);
        error_value.to_ocaml(cr)
    }

    fn rust_sleep_releasing(cr, millis: OCamlRef<OCamlInt>) {
        let millis: i64 = millis.to_rust(cr);
        cr.releasing_runtime(|| thread::sleep(time::Duration::from_millis(millis as u64)));
        OCaml::unit()
    }

    fn rust_sleep(cr, millis: OCamlRef<OCamlInt>) {
        let millis: i64 = millis.to_rust(cr);
        thread::sleep(time::Duration::from_millis(millis as u64));
        OCaml::unit()
    }

    fn rust_string_of_movement(cr, movement: OCamlRef<PolymorphicMovement>) -> OCaml<String> {
        let movement = cr.get(movement);
        let pm = ocaml_unpack_variant! {
            movement => {
                Step(count: OCamlInt) => { Movement::Step {count} },
                RotateLeft => Movement::RotateLeft,
                RotateRight => Movement::RotateRight,
            }
        };
        let s = match pm {
            Err(_) => "Error unpacking".to_owned(),
            Ok(Movement::Step {count}) => format!("Step({})", count),
            Ok(Movement::RotateLeft) => "RotateLeft".to_owned(),
            Ok(Movement::RotateRight) => "RotateRight".to_owned(),
        };
        s.to_ocaml(cr)
    }

    fn rust_string_of_polymorphic_movement(cr, polymorphic_movement: OCamlRef<PolymorphicMovement>) -> OCaml<String> {
        let polymorphic_movement = cr.get(polymorphic_movement);
        let pm = ocaml_unpack_polymorphic_variant! {
            polymorphic_movement => {
                Step(count: OCamlInt) => { PolymorphicMovement::Step {count} },
                RotateLeft => PolymorphicMovement::RotateLeft,
                RotateRight => PolymorphicMovement::RotateRight,
            }
        };
        let s = match pm {
            Err(_) => "Error unpacking".to_owned(),
            Ok(PolymorphicMovement::Step {count}) => format!("`Step({})", count),
            Ok(PolymorphicMovement::RotateLeft) => "`RotateLeft".to_owned(),
            Ok(PolymorphicMovement::RotateRight) => "`RotateRight".to_owned(),
        };
        s.to_ocaml(cr)
    }
}