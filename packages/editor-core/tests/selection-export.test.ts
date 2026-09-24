import { describe, expect, it } from 'vitest'
import { createEditor, exportEditorSelection } from '../src/editor'
import { CellSelection } from '@tiptap/pm/tables'

describe('selection export semantics', () => {
  it('keeps inline and display formula delimiters in plain text copy', () => {
    const mount = document.createElement('main')
    document.body.append(mount)
    const editor = createEditor(mount, 'before $x+1$ after\n\n$$\ny = mx + b\n$$')

    try {
      editor.commands.selectAll()
      const exported = exportEditorSelection(editor)
      expect(exported.text).toContain('before $x+1$ after')
      expect(exported.text).toContain('$$\ny = mx + b\n$$')
      expect(exported.markdown).toContain('$x+1$')
    } finally {
      editor.destroy()
      mount.remove()
    }
  })

  it('exports selected tables as tab-separated rows for spreadsheet paste', () => {
    const mount = document.createElement('main')
    document.body.append(mount)
    const editor = createEditor(mount, '| Name | Count |\n| --- | ---: |\n| Apples | 3 |\n| Pears | 2 |')

    try {
      editor.commands.selectAll()
      const exported = exportEditorSelection(editor)
      expect(exported.text).toContain('Name\tCount')
      expect(exported.text).toContain('Apples\t3')
      expect(exported.text).toContain('Pears\t2')
    } finally {
      editor.destroy()
      mount.remove()
    }
  })

  it('exports every selected cell in a CellSelection', () => {
    const mount = document.createElement('main')
    document.body.append(mount)
    const markdown = '| a | b | c |\n| --- | --- | --- |\n| 1 | 2 | 3 |'
    const editor = createEditor(mount, markdown)
    try {
      const cellPositions: number[] = []
      editor.state.doc.descendants((node, pos) => {
        if (node.type.name !== 'tableCell' && node.type.name !== 'tableHeader') return true
        cellPositions.push(pos)
        return false
      })
      expect(cellPositions.length).toBe(6)

      editor.view.dispatch(editor.state.tr.setSelection(
        CellSelection.create(editor.state.doc, cellPositions[0]!, cellPositions[2]!),
      ))
      const exported = exportEditorSelection(editor)
      expect(exported.text).toBe('a\tb\tc')
      expect(exported.markdown).toContain('| a   |')
      expect(exported.markdown).toContain('| b   |')
      expect(exported.markdown).toContain('| c   |')
    } finally {
      editor.destroy()
      mount.remove()
    }
  })

  it('preserves task state, footnote references, and definitions in plain text', () => {
    const mount = document.createElement('main')
    document.body.append(mount)
    const editor = createEditor(
      mount,
      '- [x] done\n- [ ] todo\n\nSee note[^note].\n\n[^note]: the body',
    )

    try {
      editor.commands.selectAll()
      const exported = exportEditorSelection(editor)
      expect(exported.text).toContain('[x] done')
      expect(exported.text).toContain('[ ] todo')
      expect(exported.text).toContain('See note[note].')
      expect(exported.text).toContain('[note]: the body')
      expect(exported.markdown).toContain('- [x] done')
      expect(exported.markdown).toContain('See note[^note].')
    } finally {
      editor.destroy()
      mount.remove()
    }
  })
})
