import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  createEditor,
  executeEditorCommand,
  formatCode,
  formatSelectedCodeBlock,
  resolveEditorActions,
  isFormatterSupportedLanguage,
  setExternalCodeFormatter,
  formatCurrentCodeBlock,
  supportsCodeHighlighting,
} from '../src/index'

function setup(markdown: string) {
  const editor = createEditor(document.createElement('div'), markdown, false)
  return { editor }
}

afterEach(() => {
  setExternalCodeFormatter(null)
  vi.restoreAllMocks()
})

describe('external code formatter contract', () => {
  it('provides highlighting for every declared and formatter language', () => {
    const languages = [
      'swift', 'c', 'cpp', 'objective-c', 'java', 'kotlin', 'python',
      'javascript', 'typescript', 'jsx', 'tsx', 'html', 'css', 'json',
      'yaml', 'xml', 'shell', 'powershell', 'sql', 'markdown', 'verilog',
      'latex', 'go', 'rust', 'php', 'ruby', 'r', 'toml', 'ini', 'diff',
      'mermaid', 'py', 'c++', 'cc', 'cxx', 'hpp', 'sv', 'systemverilog',
      'rs', 'sh', 'bash', 'objc', 'm', 'mm',
    ]
    for (const language of languages) {
      expect(supportsCodeHighlighting(language), language).toBe(true)
    }
  })

  it('routes unsupported optional languages to the host formatter', async () => {
    const formatter = vi.fn().mockResolvedValue({ status: 'formatted', code: 'value = 1\n' })
    setExternalCodeFormatter({ languages: ['py', 'python'], format: formatter })

    expect(isFormatterSupportedLanguage('python')).toBe(true)
    await expect(formatCode('value=1', 'py')).resolves.toEqual({
      status: 'formatted',
      code: 'value = 1\n',
    })
    expect(formatter).toHaveBeenCalledWith('value=1', 'py')
  })

  it('keeps built-in languages local and reports unavailable optional languages', async () => {
    const formatter = vi.fn()
    setExternalCodeFormatter({ languages: ['py'], format: formatter })

    await expect(formatCode('const value={answer:42}', 'ts')).resolves.toEqual({
      status: 'formatted',
      code: 'const value = { answer: 42 };\n',
    })
    expect(formatter).not.toHaveBeenCalled()
    expect(isFormatterSupportedLanguage('java')).toBe(false)
  })

  it('keeps code block commands editable only while an optional formatter is configured', async () => {
    const { editor } = setup('```python\nvalue=1\n```')
    editor.commands.setTextSelection({ from: 3, to: 3 })
    expect(executeEditorCommand(editor, 'formatCodeBlock')).toBe(false)

    setExternalCodeFormatter({
      languages: ['python', 'py'],
      format: async () => ({ status: 'formatted', code: 'value = 1\n' }),
    })
    expect(executeEditorCommand(editor, 'formatCodeBlock')).toBe(true)
  })

  it('reports optional Java formatters as available for native menus', () => {
    setExternalCodeFormatter({
      languages: ['java'],
      format: async () => ({ status: 'formatted', code: 'class A {}\n' }),
    })
    expect(isFormatterSupportedLanguage('java')).toBe(true)
    expect(resolveEditorActions(
      { codeBlock: true, codeBlockLanguage: 'java' },
      { readOnly: false },
    ).formatCodeBlock).toEqual({ enabled: true, checked: false })
  })

  it('formats Java selections by sending the complete code block with a line range', async () => {
    const { editor } = setup([
      '```java',
      'private int count ;',
      'private String name="x";',
      '```',
    ].join('\n'))
    const codeBlock = (() => {
      let found: { pos: number; node: { textContent: string } } | null = null
      editor.state.doc.descendants((node, pos) => {
        if (node.type.name !== 'codeBlock') return true
        found = { pos, node }
        return false
      })
      return found!
    })()
    const contentStart = codeBlock!.pos + 1
    const lines = codeBlock!.node.textContent.split('\n')
    const secondLineStart = contentStart + (lines[0]?.length ?? 0) + 1
    editor.commands.setTextSelection({
      from: secondLineStart + 7,
      to: secondLineStart + 12,
    })

    const formatter = vi.fn().mockImplementation(async (code: string, language: string, selection: unknown) => {
      expect(selection).toEqual({ startLine: 3, endLine: 3 })
      const lines = code.split('\n')
      expect(lines[1]).toContain('__MARKLEAF_FORMAT_BEGIN_')
      expect(lines[3]).toContain('__MARKLEAF_FORMAT_END_')
      lines[2] = 'private int count = 1;'
      return { status: 'formatted' as const, code: lines.join('\n') }
    })
    setExternalCodeFormatter({
      languages: ['java'],
      supportsSelectionLineRanges: true,
      format: formatter,
    })

    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(true)
    expect(formatter).toHaveBeenCalledWith(
      expect.stringContaining('__MARKLEAF_FORMAT_BEGIN_'),
      'java',
      { startLine: 3, endLine: 3 },
    )
    expect(editor.state.doc.textContent).toBe(
      'private int count ;\nprivate int count = 1;',
    )
    const selectionText = editor.state.doc.textBetween(
      editor.state.selection.from,
      editor.state.selection.to,
      '\n',
    )
    expect(selectionText).toBe('private int count = 1;')
  })

  it('replaces an expanded Java line range exactly once', async () => {
    const originalLines = [
      'public class FormatterDemo{',
      'private final String name;',
      'private int count;',
      'public FormatterDemo(String name,int count){this.name=name;this.count=count;}',
      'public String label(){return name+": "+count;}',
      '}',
    ]
    const { editor } = setup('```java\n' + originalLines.join('\n') + '\n```')
    const codeBlock = (() => {
      let found: { pos: number; node: { textContent: string } } | null = null
      editor.state.doc.descendants((node, pos) => {
        if (node.type.name !== 'codeBlock') return true
        found = { pos, node }
        return false
      })
      return found!
    })()
    const contentStart = codeBlock!.pos + 1
    const lineStarts = [0]
    for (const line of originalLines.slice(0, -1)) {
      lineStarts.push(lineStarts.at(-1)! + line.length + 1)
    }
    editor.commands.setTextSelection({
      from: contentStart + lineStarts[3]! + 7,
      to: contentStart + lineStarts[3]! + 20,
    })

    const formattedConstructorLines = [
      '',
      '  public FormatterDemo(String name, int count) {',
      '    this.name = name;',
      '    this.count = count;',
      '  }',
    ]
    const formatter = vi.fn().mockImplementation(async (code: string) => {
      const lines = code.split('\n')
      const beginIndex = lines.findIndex(line => line.includes('__MARKLEAF_FORMAT_BEGIN_'))
      const endIndex = lines.findIndex(line => line.includes('__MARKLEAF_FORMAT_END_'))
      const output = [
        ...lines.slice(0, beginIndex + 1),
        ...formattedConstructorLines,
        ...lines.slice(endIndex),
      ]
      return { status: 'formatted' as const, code: output.join('\n') }
    })
    setExternalCodeFormatter({
      languages: ['java'],
      supportsSelectionLineRanges: true,
      selectionLineRangeLanguages: ['java'],
      format: formatter,
    })

    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(true)
    expect(formatter).toHaveBeenCalledWith(
      expect.stringContaining('__MARKLEAF_FORMAT_BEGIN_'),
      'java',
      { startLine: 5, endLine: 5 },
    )
    expect(editor.state.doc.textContent).toBe([
      originalLines[0]!,
      originalLines[1]!,
      originalLines[2]!,
      ...formattedConstructorLines,
      originalLines[4]!,
      originalLines[5]!,
    ].join('\n'))
  })

  it('keeps legacy fragment formatting for external formatters without line-range support', async () => {
    const { editor } = setup('```python\nvalue=1\nvalue2=2\n```')
    editor.commands.setTextSelection({ from: 3, to: 7 })
    const formatter = vi.fn().mockResolvedValue({ status: 'formatted', code: 'value = 1' })
    setExternalCodeFormatter({
      languages: ['python'],
      supportsSelectionLineRanges: true,
      selectionLineRangeLanguages: ['java'],
      format: formatter,
    })

    await expect(formatSelectedCodeBlock(editor)).resolves.toBe(true)
    expect(formatter).toHaveBeenCalledWith('value=1', 'python')
  })

  it('keeps the caret collapsed after JavaScript whole-block formatting', async () => {
    const { editor } = setup('```js\nconst value={a:1,b:2}\n```')
    const contentStart = (() => {
      let start = 0
      editor.state.doc.descendants((node, pos) => {
        if (node.type.name === 'codeBlock') {
          start = pos + 1
          return false
        }
        return true
      })
      return start
    })()
    editor.commands.setTextSelection(contentStart + 12)

    await expect(formatCurrentCodeBlock(editor)).resolves.toBe(true)
    expect(editor.state.doc.textContent).toBe('const value = { a: 1, b: 2 };')
    expect(editor.state.selection.empty).toBe(true)
  })

  it.each([
    ['javascript', 'const value={a:1,b:2}'],
    ['js', 'const value={a:1,b:2}'],
    ['cjs', 'const value={a:1,b:2}'],
    ['mjs', 'const value={a:1,b:2}'],
    ['jsx', 'const value=(<div title="demo"></div>)'],
    ['typescript', 'const value:{a:number}={a:1}'],
    ['ts', 'const value:{a:number}={a:1}'],
    ['tsx', 'const value=(<div title="demo"></div>)'],
    ['json', '{"a":1}'],
    ['css', '.demo{color:red}'],
    ['scss', '$color:red;.demo{color:$color}'],
    ['less', '@color:red;.demo{color:@color}'],
    ['html', '<div>\n\n<p>demo</p></div>'],
    ['vue', '<template>\n\n<div title="demo"></div></template>'],
    ['yaml', 'name:    demo'],
    ['yml', 'name:    demo'],
    ['markdown', '#    Demo'],
  ])('keeps the caret collapsed after whole-block %s formatting', async (language, code) => {
    const { editor } = setup('```' + language + '\n' + code + '\n```')
    const contentStart = (() => {
      let start = 0
      editor.state.doc.descendants((node, pos) => {
        if (node.type.name === 'codeBlock') {
          start = pos + 1
          return false
        }
        return true
      })
      return start
    })()
    editor.commands.setTextSelection(contentStart + Math.floor(code.length / 2))

    await expect(formatCurrentCodeBlock(editor)).resolves.toBe(true)
    expect(editor.state.selection.empty).toBe(true)
  })
})
