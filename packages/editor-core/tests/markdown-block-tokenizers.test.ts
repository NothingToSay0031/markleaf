import { describe, expect, it, vi } from 'vitest'
import { OrderedList } from '@tiptap/extension-list'
import TaskList from '@tiptap/extension-task-list'
import { Table } from '@tiptap/extension-table'
import type { MarkdownLexerConfiguration, MarkdownToken } from '@tiptap/core'
import { OrderedListMarkdown, TaskListMarkdown, tableMarkdownTokenizer } from '../src/markdown-block-tokenizers'

type Tokenizer = NonNullable<typeof OrderedList.config.markdownTokenizer>

const stockOrderedTokenizer = OrderedList.config.markdownTokenizer as Tokenizer
const stockTaskTokenizer = TaskList.config.markdownTokenizer as Tokenizer
const stockTableTokenizer = Table.config.markdownTokenizer as Tokenizer
const stockTableStart = stockTableTokenizer.start as ((src: string) => number) | undefined
const wrappedTableStart = tableMarkdownTokenizer.start as ((src: string) => number) | undefined

const wrappedOrderedTokenizer = OrderedListMarkdown.config.markdownTokenizer as Tokenizer
const wrappedTaskTokenizer = TaskListMarkdown.config.markdownTokenizer as Tokenizer

const lexer: MarkdownLexerConfiguration = {
  inlineTokens(src) {
    return [{ type: 'text', raw: src, text: src }]
  },
  blockTokens(src) {
    return [{ type: 'paragraph', raw: src, text: src, tokens: [{ type: 'text', raw: src, text: src }] }]
  },
}

describe('guarded Markdown block tokenizers', () => {
  it('returns exactly the stock ordered-list token when the first line is an ordered list', () => {
    const sources = [
      '1. First\n2. Second\n3. Third',
      '  3) Indented\n      continuation',
      'xviii. Roman numeral\nnext line',
      'a. Alpha item\nb. Alpha item',
    ]

    for (const source of sources) {
      const tokens: MarkdownToken[] = []
      expect(wrappedOrderedTokenizer.tokenize(source, tokens, lexer)).toEqual(
        stockOrderedTokenizer.tokenize(source, tokens, lexer),
      )
    }
  })

  it('rejects ordered-list look-alikes without invoking the full-document stock tokenizer', () => {
    const longTail = `${'Plain prose that must not be scanned repeatedly. '.repeat(20_000)}\n\n1. Too far below`
    const splitSpy = vi.spyOn(String.prototype, 'split')

    try {
      for (const source of [
        'This paragraph is not an ordered list.',
        '- This is an unordered list.',
        '1.No space after the marker.',
        '(216) 555-1234 is a phone number.',
        longTail,
      ]) {
        const tokens: MarkdownToken[] = []
        expect(wrappedOrderedTokenizer.tokenize(source, tokens, lexer)).toBeUndefined()
      }

      const splitCalls = splitSpy.mock.calls.filter(([separator]) => String(separator) === '\n')
      expect(splitCalls).toHaveLength(0)
    } finally {
      splitSpy.mockRestore()
    }
  })

  it('returns exactly the stock task-list token, including blank lines and nesting', () => {
    const sources = [
      '- [x] Done\n- [ ] Todo',
      '  + [X] Checked and indented\n    continuation',
      '\n\n- [ ] First after blank lines',
      '- [ ] Parent\n  - [x] Nested child',
    ]

    for (const source of sources) {
      const tokens: MarkdownToken[] = []
      expect(wrappedTaskTokenizer.tokenize(source, tokens, lexer)).toEqual(
        stockTaskTokenizer.tokenize(source, tokens, lexer),
      )
    }
  })

  it('rejects task-list look-alikes without invoking the full-document stock tokenizer', () => {
    const longTail = `${'Ordinary text follows many blank lines. '.repeat(20_000)}\n\n- [ ] Too far below`
    const splitSpy = vi.spyOn(String.prototype, 'split')

    try {
      for (const source of [
        'This paragraph is not a task list.',
        '- A regular bullet',
        '- [n] An invalid checkbox',
        '- [ ]Missing whitespace',
        longTail,
      ]) {
        const tokens: MarkdownToken[] = []
        expect(wrappedTaskTokenizer.tokenize(source, tokens, lexer)).toBeUndefined()
      }

      const splitCalls = splitSpy.mock.calls.filter(([separator]) => String(separator) === '\n')
      expect(splitCalls).toHaveLength(0)
    } finally {
      splitSpy.mockRestore()
    }
  })

  it('keeps table start detection identical to the stock tokenizer', () => {
    const sources = [
      '| Name | Count |\n| --- | ---: |\n| Apples | 3 |',
      'a | b\n--- | ---\n1 | 2',
      '| Left | Right |\n| :--- | ---: |\n| 1 | 2 |',
      'Leading prose\n| a | b |\n| - | - |',
      '| a | b |',
      'a | b\n---',
      'Heading\n---',
    ]

    for (const source of sources) {
      expect(wrappedTableStart?.(source)).toBe(stockTableStart?.(source))
    }

    expect(wrappedTableStart?.('| a | b |\n| --- | ---: |\n| 1 | 2 |')).toBe(0)
    expect(wrappedTableStart?.('\n\n| a | b |\n| --- | ---: |')).toBe(-1)
    expect(wrappedTableStart?.('| a | b |\n---')).toBe(-1)
  })
})
