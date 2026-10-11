#  Document Format

Mark uses plain-text files with the `.mark` extension. At the end of each file, following the main interview text, there is an optional metadata block where the app stores additional information. This approach ensures your files can be opened and edited on any device using any text editor.

## Document Text

The document text is the main content of the `.mark` file. It is passed directly to the editor's text view and can be edited freely.

Similar to other lightweight markup languages, Mark uses a simple syntax to identify speakers:

```
Sarah: You know... I'm not sure I really understood what I was doing back then. I knew a lot of people at the time, but I guess I didn't have any real friends. It was a cold, damp, depressing September. I had rent to pay. My boyfriend at the time and I thought we'd found a way out, even if it wasn't exactly the "right" one.
Elena: So, you started working in the autumn of that year?
Sarah: Yes, that's right. I was really struggling with it at the time, and I definitely couldn't look at myself the same way afterwards.
```

The text at the beginning of a line, up to the first colon, becomes the speaker marker. All subsequent text is treated as the speaker's dialogue. Additional colons within the same paragraph are treated as part of the speech and do not create new speaker markers. If you need to start a line with a colon without creating a speaker marker, simply escape it as `\:`.

The Parser splits the text into segments containing the ranges for the speaker marker, the speech, and the complete segment. It works with the UTF-16 representation of the string and operates incrementally. When the text changes, Mark reparses only the affected area and adjusts subsequent ranges automatically.

## Metadata

The hidden data layer contains information associated with the document that does not appear directly in the text view. Mark stores this metadata at the very end of the file as a JSON block, followed only by optional whitespace or newlines. Mark locates this block by finding the final end marker and searching backward for the start marker:

```
Sarah: In a single evening, I could make more than I would have earned in a month working at the shop. Of course, there were plenty of problems, too...

/* MARK SECTION START

Whoops! You've stumbled into the secret depths of Mark's internal data layer. Unless you're a wizard who knows exactly what they're doing, it's best to leave this part untouched!

{
  "key" : value
}

MARK SECTION END */
```
