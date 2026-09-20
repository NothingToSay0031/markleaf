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
