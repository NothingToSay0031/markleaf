import { describe, expect, it } from 'vitest'
import { createEditor, exportEditorSelection } from '../src/editor'

describe('selection export semantics', () => {
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
