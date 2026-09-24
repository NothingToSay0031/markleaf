import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  createEditor,
  formatCode,
  formatCurrentCodeBlock,
  formatSelectedCodeBlock,
  getMarkdown,
  normalizeInlineCodeWhitespace,
  executeEditorCommand,
} from '../src/index'

function setup(markdown: string) {
  document.body.innerHTML = '<main id="editor"></main>'
  const editor = createEditor(
    document.querySelector<HTMLElement>('#editor')!,
    markdown,
    false,
    { externalHistory: false },
  )
  return { editor }
}

afterEach(() => {
  document.body.innerHTML = ''
  vi.restoreAllMocks()
})

describe('phase 1 code formatting', () => {
  it('formats TypeScript through the built-in formatter registry', async () => {
    const result = await formatCode('const value={answer:42}', 'ts')
    expect(result).toEqual({
      status: 'formatted',
      code: 'const value = { answer: 42 };\n',
    })
  })

  it('recognizes common language aliases and rejects unsupported languages', async () => {
    await expect(formatCode('a:  1\nb: "x"', 'yml')).resolves.toEqual({
      status: 'formatted',
      code: 'a: 1\nb: "x"\n',
    })
    await expect(formatCode('const value = 1', 'brainfuck')).resolves.toEqual({
      status: 'unsupported',
    })
  })

  it('only cleans inline code without applying a language formatter', () => {
    expect(normalizeInlineCodeWhitespace('  const   value = 1  ')).toBe('const value = 1')

    const { editor } = setup('before `  const   value = 1  ` after')
    let inlineStart = 0
    let inlineEnd = 0
    editor.state.doc.descendants((node, position) => {
      const index = node.text?.indexOf('const   value = 1') ?? -1
      if (index < 0) return true
      inlineStart = position + index
      inlineEnd = position + (node.text?.length ?? 0) - 1
      return false
    })
    editor.commands.setTextSelection({ from: inlineStart, to: inlineEnd })
    expect(executeEditorCommand(editor, 'normalizeInlineCode')).toBe(true)
    expect(editor.state.doc.textContent).toContain('before  const value = 1  after')
  })

  it('formats the current code block while preserving its language and undo history', async () => {
    const { editor } = setup('```ts\nconst value={answer:42}\n```')
    editor.commands.setTextSelection({ from: 3, to: 3 })

    await expect(formatCurrentCodeBlock(editor)).resolves.toBe(true)
    expect(getMarkdown(editor)).toContain('```ts\nconst value = { answer: 42 };\n```')
    expect(editor.getAttributes('codeBlock').language).toBe('ts')

    executeEditorCommand(editor, 'undo')
    expect(getMarkdown(editor)).toContain('```ts\nconst value={answer:42}\n```')
  })

  it('formats the current code block with the shift-option-f shortcut', async () => {
    const { editor } = setup('```ts\nconst value={answer:42}\n```')
    editor.commands.setTextSelection({ from: 3, to: 3 })

    const handled = editor.commands.keyboardShortcut('Shift-Alt-f')
    expect(handled).toBe(true)
    await new Promise(resolve => setTimeout(resolve, 50))

    expect(getMarkdown(editor)).toContain('```ts\nconst value = { answer: 42 };\n```')
  })

  it('does not mutate unsupported or read-only code blocks', async () => {
    const unsupported = setup('```brainfuck\n++++++++\n```')
    unsupported.editor.commands.setTextSelection({ from: 3, to: 3 })
    await expect(formatCurrentCodeBlock(unsupported.editor)).resolves.toBe(false)
    expect(getMarkdown(unsupported.editor)).toContain('++++++++')
    unsupported.editor.destroy()

    const readOnly = setup('```ts\nconst value={answer:42}\n```')
    readOnly.editor.setEditable(false, false)
    readOnly.editor.commands.setTextSelection({ from: 3, to: 3 })
    await expect(formatCurrentCodeBlock(readOnly.editor)).resolves.toBe(false)
    expect(getMarkdown(readOnly.editor)).toContain('const value={answer:42}')
  })
})

describe('phase 2 selected code formatting', () => {
  it('formats only the complete lines covered by the selection', async () => {
    const { editor } = setup([
      '```ts',
      'function demo() {',
      '  const value={answer:42}',
      '  if(value){console.log(value)}',
      '}',
      '```',
    ].join('\n'))
    const codeBlock = editor.state.doc.firstChild!
    const codeStart = codeBlock.content.size > 0 ? 1 : 1
    const text = codeBlock.textContent
    const from = codeStart + text.indexOf('  const value=')
    const to = codeStart + text.indexOf('\n}', from)

    editor.commands.setTextSelection({ from, to })
    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(true)
    expect(getMarkdown(editor)).toBe([
      '```ts',
      'function demo() {',
      '  const value = { answer: 42 };',
      '  if (value) {',
      '    console.log(value);',
      '  }',
      '}',
      '```',
    ].join('\n'))

    executeEditorCommand(editor, 'undo')
    expect(getMarkdown(editor)).toContain('  const value={answer:42}')
  })

  it('expands a partial line selection to whole lines instead of breaking the statement', async () => {
    const { editor } = setup([
      '```ts',
      'function demo() {',
      '  const value={answer:42}',
      '}',
      '```',
    ].join('\n'))
    const codeBlock = editor.state.doc.firstChild!
    const text = codeBlock.textContent
    const from = 1 + text.indexOf('{answer:42}')
    const to = from + '{answer:42}'.length

    editor.commands.setTextSelection({ from, to })
    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(true)
    expect(getMarkdown(editor)).toBe([
      '```ts',
      'function demo() {',
      '  const value = { answer: 42 };',
      '}',
      '```',
    ].join('\n'))
  })

  it('does not mutate unsupported selected code', async () => {
    const { editor } = setup('```brainfuck\n++++++++\n++++++++\n```')
    editor.commands.setTextSelection({ from: 3, to: 10 })
    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(false)
    expect(getMarkdown(editor)).toContain('++++++++')
  })
})
