import { describe, expect, it } from 'vitest'
import { SourceEditor } from '../src/source-editor'

describe('SourceEditor runtime mode', () => {
  it('blocks edits after switching to read-only and allows edits again', () => {
    document.body.innerHTML = '<main id="source"></main>'
    const mount = document.querySelector<HTMLElement>('#source')!
    const editor = new SourceEditor(mount, 'before', () => {})
    editor.setSelection(6)

    expect(editor.replaceSelection('!')).toBe(true)
    expect(editor.view.state.doc.toString()).toBe('before!')

    editor.setReadOnly(true)
    expect(editor.replaceSelection('?')).toBe(false)
    expect(editor.view.state.doc.toString()).toBe('before!')

    editor.setReadOnly(false)
    expect(editor.replaceSelection('?')).toBe(true)
    expect(editor.view.state.doc.toString()).toBe('before!?')

    editor.destroy()
  })

  it('keeps document statistics stable across selection moves and refreshes after edits', () => {
    document.body.innerHTML = '<main id="source"></main>'
    const mount = document.querySelector<HTMLElement>('#source')!
    const editor = new SourceEditor(mount, 'one two\nthree', () => {})

    const initial = editor.getStatus()
    editor.setSelection(0, 3)
    expect(editor.getStatus()).toMatchObject({
      totalCharacterCount: initial.totalCharacterCount,
      nonWhitespaceCharacterCount: initial.nonWhitespaceCharacterCount,
      paragraphCount: initial.paragraphCount,
      selectedCharacterCount: 3,
    })

    editor.replaceSelection('a much longer line')
    expect(editor.getStatus().totalCharacterCount).toBeGreaterThan(initial.totalCharacterCount)
    editor.destroy()
  })
})

describe('SourceEditor long-document chapters', () => {
  it('detects source chapters and jumps between them', () => {
    document.body.innerHTML = '<main id="source"></main>'
    const mount = document.querySelector<HTMLElement>('#source')!
    const editor = new SourceEditor(
      mount,
      '# Intro\nbody\n\n## Data\ntext\n\n第三章 结论\nfinal text',
      () => {},
    )

    expect(editor.getSourceChapters()).toEqual([
      { level: 1, text: 'Intro', position: 0 },
      { level: 2, text: 'Data', position: 14 },
      { level: 1, text: '第三章 结论', position: 28 },
    ])

    editor.gotoSourceChapter(editor.getSourceChapters()[2]!)
    expect(editor.view.state.selection.main.from).toBe(28)
    expect(editor.getActiveSourceChapterPosition()).toBe(28)
    editor.destroy()
  })
})
