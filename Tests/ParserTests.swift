//
//  ParserTests.swift
//  Tests
//
//  Created by Mikhail Korzh on 15.09.2026.
//  Copyright © 2026 Mikhail Korzh.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Testing
@testable import Mark

struct ParserTests {
    
    let parser = Parser()
    
    @Test
    func parsesSingleSegment() {
        let result = parser.parse("INT: Hello")
        
        #expect(result.segments.count == 1)
        #expect(result.segments[0].speaker == "INT")
        #expect(result.segments[0].speakerRange == TextRange(location: 0, length: 3))
        #expect(result.segments[0].textRange == TextRange(location: 5, length: 5))
    }
    
    @Test
    func parsesMultipleSegments() {
        let result = parser.parse("""
        INT: Hello
        P1: Hi
        INT: How are you?
        """)
        
        #expect(result.segments.count == 3)
        #expect(result.segments.map(\.speaker) == ["INT", "P1", "INT"])
    }
    
    @Test
    func continuesAcrossParagraphs() {
        let result = parser.parse("""
        INT: Hello
        This is another paragraph.
        And another one.
        P1: Yes.
        """)
        
        #expect(result.segments.count == 2)
        #expect(result.segments[0].speaker == "INT")
        #expect(result.segments[1].speaker == "P1")
    }
    
    @Test
    func supportsSpeakerWithSpaces() {
        let result = parser.parse("Interviewer One: Hello")
        
        #expect(result.segments.count == 1)
        #expect(result.segments[0].speaker == "Interviewer One")
    }
    
    @Test
    func ignoresIndentedSpeakerMarker() {
        let result = parser.parse("  INT: Hello")
        
        #expect(result.segments.isEmpty)
    }
    
    @Test
    func findsUniqueSpeakers() {
        let result = parser.parse("""
        INT: Hello
        P1: Hi
        INT: How are you?
        P1: Fine.
        """)
        
        #expect(result.speakers == ["INT", "P1"])
    }
    
    @Test
    func handlesEmptyDocument() {
        let result = parser.parse("")
        
        #expect(result.segments.isEmpty)
    }
    
    @Test
    func incrementalParserMatchesFullParserAfterEdit() {
        let oldText = "INT: Hello"
        let newText = "INT: Hello!"
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 10, length: 0),
            newRange: TextRange(location: 10, length: 1)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserMatchesFullParserAfterDeletion() {
        let oldText = "INT: Hello!"
        let newText = "INT: Hello"
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 10, length: 1),
            newRange: TextRange(location: 10, length: 0)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserShiftsFollowingSegmentsAfterEdit() {
        let oldText = """
        INT: Hello
        P1: Hi
        """
        
        let newText = """
        INT: Hello!
        P1: Hi
        """
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 10, length: 0),
            newRange: TextRange(location: 10, length: 1)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserShiftsFollowingSegmentsAfterDeletion() {
        let oldText = """
    INT: Hello!
    P1: Hi
    """
        
        let newText = """
    INT: Hello
    P1: Hi
    """
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 10, length: 1),
            newRange: TextRange(location: 10, length: 0)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserUpdatesSpeakerMarker() {
        let oldText = "INT: Hello"
        let newText = "P1: Hello"
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 0, length: 3),
            newRange: TextRange(location: 0, length: 2)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserCreatesNewSegment() {
        let oldText = """
        INT: Hello

        This is a paragraph.
        """
        
        let newText = """
        INT: Hello
        
        P1: This is a paragraph.
        """
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 12, length: 0),
            newRange: TextRange(location: 12, length: 4)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func incrementalParserMergesSegments() {
        let oldText = """
    INT: Hello
    
    P1: How are you?
    """
        
        let newText = """
    INT: Hello
    
    How are you?
    """
        
        let parser = Parser()
        let incrementalParser = IncrementalParser()
        
        let initial = parser.parse(oldText)
        let expected = parser.parse(newText)
        
        let change = TextChange(
            oldRange: TextRange(location: 12, length: 4),
            newRange: TextRange(location: 12, length: 0)
        )
        
        let incremental = incrementalParser.update(
            text: newText,
            document: initial,
            change: change
        )
        
        #expect(incremental == expected)
    }
    
    @Test
    func parsedDocumentStoreUpdatesAfterEdit() {
        let oldText = "INT: Hello"
        let newText = "INT: Hello!"
        
        var store = ParsedDocumentStore(text: oldText)
        
        store.update(
            text: newText,
            change: TextChange(
                oldRange: TextRange(location: 10, length: 0),
                newRange: TextRange(location: 10, length: 1)
            )
        )
        
        #expect(store.parsedDocument == Parser().parse(newText))
    }
    
    /// Deleting text across multiple segments reparses the whole affected range.
    @Test
    func testDeletionAcrossMultipleSegments() {
        let oldText = """
    DAVID: Hello
    ANNA: How are you?
    JOHN: Fine.
    """
        
        let document = Parser().parse(oldText)
        
        let oldStart = oldText.utf16.firstIndex(of: 0) // placeholder
    }
}
