import type { MarkdownLexerConfiguration, MarkdownToken } from '@tiptap/core'
import { ORDERED_LIST_MARKER_PATTERN, OrderedList } from '@tiptap/extension-list'
import TaskList from '@tiptap/extension-task-list'
import { Table } from '@tiptap/extension-table'

// marked probes every registered block tokenizer with the whole remaining
// document at every block boundary, and a tokenizer's `start` is only a
// paragraph-truncation hint: returning -1 does not stop marked from calling
// `tokenize`. The stock list and table tokenizers split that whole remainder
// before they can tell the block is not theirs, so parsing costs
// O(blocks x document length). Each guard here reads only the lines the stock
// implementation needs to reject a non-match, then delegates to it.

type OrderedListTokenizer = NonNullable<typeof OrderedList.config.markdownTokenizer>
type TaskListTokenizer = NonNullable<typeof TaskList.config.markdownTokenizer>
type TableTokenizer = NonNullable<typeof Table.config.markdownTokenizer>

function firstLines(src: string, count: number): string[] {
  const lines: string[] = []
  let start = 0
  while (lines.length < count) {
    const end = src.indexOf('\n', start)
    if (end < 0) {
      lines.push(src.slice(start))
      break
    }
    lines.push(src.slice(start, end))
    start = end + 1
  }
  return lines
}

// parseIndentedBlocks skips leading blank lines before it can reject a block,
// so the task list guard has to skip them too.
function firstNonBlankLine(src: string): string {
  let start = 0
  for (;;) {
    const end = src.indexOf('\n', start)
    const line = end < 0 ? src.slice(start) : src.slice(start, end)
    if (line.trim() !== '') return line
    if (end < 0) return ''
    start = end + 1
  }
}

// Mirrors ORDERED_LIST_ITEM_REGEX / the task list item pattern restricted to a
// single line, which is all either stock tokenizer needs to accept a block.
const ORDERED_ITEM_PREFIX = new RegExp(`^\\s*(?:${ORDERED_LIST_MARKER_PATTERN})[.)]\\s`)
const TASK_ITEM_PREFIX = /^\s*[-+*]\s+\[[ xX]\]\s/

const orderedListTokenizer = OrderedList.config.markdownTokenizer as OrderedListTokenizer
const taskListTokenizer = TaskList.config.markdownTokenizer as TaskListTokenizer
const tableTokenizer = Table.config.markdownTokenizer as TableTokenizer

export const OrderedListMarkdown = OrderedList.extend({
  markdownTokenizer: {
    ...orderedListTokenizer,
    tokenize(src: string, tokens: MarkdownToken[], helpers: MarkdownLexerConfiguration) {
      return ORDERED_ITEM_PREFIX.test(firstLines(src, 1)[0] ?? '')
        ? orderedListTokenizer.tokenize(src, tokens, helpers)
        : undefined
    },
  } satisfies OrderedListTokenizer,
})

export const TaskListMarkdown = TaskList.extend({
  markdownTokenizer: {
    ...taskListTokenizer,
    tokenize(src: string, tokens: MarkdownToken[], helpers: MarkdownLexerConfiguration) {
      return TASK_ITEM_PREFIX.test(firstNonBlankLine(src))
        ? taskListTokenizer.tokenize(src, tokens, helpers)
        : undefined
    },
  } satisfies TaskListTokenizer,
})

// The stock table start() only inspects the first two lines, but splits the
// entire remaining document to get them.
export const tableMarkdownTokenizer: TableTokenizer = {
  ...tableTokenizer,
  start(src: string): number {
    const [header, delimiter] = firstLines(src, 2)
    if (delimiter === undefined) return -1
    if (!/^[ \t|:]*-[ \t|:-]*$/.test(delimiter) || !delimiter.includes('|')) return -1
    return header?.includes('|') ? 0 : -1
  },
}
