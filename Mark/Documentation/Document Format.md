#  Document Format

## About `.mark` files

Mark files are plain text files with a `.mark` extension. Mark stores its document data directly in the file, so the document and its associated data can be moved between devices as a single file.

The document itself is still plain text and can be opened in any text editor. Editors that don't support Mark will simply see the data block at the end of the file.

## Metadata

Mark's internal data is stored in a special block at the end of the file:

```
/* MARK SECTION START
You probably weren't supposed to see this. This section belongs to Mark's internal data layer. Please don't edit it unless you know exactly what you're doing.
{ JSON data }
MARK SECTION END */
```

The start and end markers are defined by `MetaBlockFormat`, which is the single source of truth for the format. The data between them is a JSON representation of the document's `Meta` object. When opening a file, Mark reads and decodes this block. When saving, it writes the `Meta` object back to the file.

The block must be at the end of the file, followed only by whitespace or newlines. Mark looks for the final end marker and then searches backwards for the matching start marker. A `.mark` file without a data block is valid. Mark treats the entire file as document text and uses an empty `Meta` object. The `Serializer` is responsible for reading and writing this representation.
