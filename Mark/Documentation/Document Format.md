#  Document Format

Mark works with plain text files with the `.mark` extension. At the end of each file, following the main interview text, there is an optional metadata block where the app stores additional information about the document. This approach allows the file to be opened and edited on any device and in any text editor.
##  Document text

The document text is the main content of the `.mark` file. It is passed directly to the editor's text view and can be edited by the user.

Similar to other simple markup syntax systems, Mark uses interview markup to identify speakers:

```markup
Speaker: text
```

The text at the beginning of a line, up to the colon, becomes the speaker marker, while all subsequent text is treated as the interview participant's speech. Additional colons within a paragraph do not create additional speaker markers and are treated by the parser as part of the speech. If you need to add a colon to the text without creating a speaker marker, escape the colon as `\:`.

The `Parser` splits the text into segments containing the ranges of the speaker markers, speech, and the complete segment. It works with the UTF-16 representation of the string. The parser is incremental. When the text changes, Mark reparses only the affected area and adjusts subsequent ranges.
## Metadata

The hidden data layer contains information associated with the document but does not appear directly in the text view. Mark stores this metadata at the very end of the file as a JSON block, after which only whitespace or newlines may appear. Mark locates this block by finding the final end marker and searching backward for the start marker:

```markup
Speaker: text

/* MARK SECTION START

Whoops! You've stumbled into the secret depths of Mark's internal data layer. Unless you're a wizard who knows exactly what they're doing, it's best to leave this part untouched!

{ JSON data }

MARK SECTION END */
```
