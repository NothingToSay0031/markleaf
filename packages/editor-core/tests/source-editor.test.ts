import { describe, expect, it } from 'vitest'
import { SourceEditor } from '../src/source-editor'

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
