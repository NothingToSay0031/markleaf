import { describe, expect, it } from 'vitest'
import {
  collectTopLevelReadingBlocks,
  createReadingAnchorFingerprint,
  isReadingAnchorInput,
  normalizeReadingAnchor,
  resolveReadingAnchorOrdinal,
  type ReadingAnchor,
} from '../src/reading-anchor'
import { createEditor } from '../src/editor'

describe('reading anchors', () => {
  it('rejects malformed host payloads before normalization', () => {
    expect(isReadingAnchorInput(null)).toBe(false)
    expect(isReadingAnchorInput({ kind: 'visual', ordinal: 0, total: 1, token: 'ok' })).toBe(false)
    expect(isReadingAnchorInput({ kind: 'visual', ordinal: 0, total: 1, token: 'ok', fraction: 0 })).toBe(true)
  })

  it('keeps ProseMirror positions separate from top-level block ordinals', () => {
    const editor = createEditor(
      document.createElement('div'),
      'one\n\ntwo longer\n\nthree',
    )

    try {
      expect(collectTopLevelReadingBlocks(editor.state.doc)).toEqual([
        { ordinal: 0, position: 0, text: 'one' },
        { ordinal: 1, position: 5, text: 'two longer' },
        { ordinal: 2, position: 17, text: 'three' },
      ])
    } finally {
      editor.destroy()
    }
  })

  it('normalizes malformed anchors into a safe range', () => {
    const anchor = normalizeReadingAnchor({
      kind: 'visual',
      ordinal: 99,
      total: 3,
      token: '  Second paragraph  ',
      fraction: 2,
    })

    expect(anchor).toEqual({
      kind: 'visual',
      ordinal: 2,
      total: 3,
      token: 'second paragraph',
      fraction: 1,
    })
  })

  it('keeps an ordinal whose text still matches', () => {
    const anchor: ReadingAnchor = {
      kind: 'visual',
      ordinal: 1,
      total: 4,
      token: 'second',
      fraction: 0.25,
    }
    const texts = ['first', 'second edited', 'third', 'fourth']

    expect(resolveReadingAnchorOrdinal(anchor, texts)).toBe(1)
  })

  it('finds the nearest text match after paragraphs are inserted or removed', () => {
    const anchor: ReadingAnchor = {
      kind: 'visual',
      ordinal: 2,
      total: 4,
      token: 'target paragraph',
      fraction: 0.5,
    }
    const texts = ['first', 'inserted', 'target paragraph edited', 'old', 'last']

    expect(resolveReadingAnchorOrdinal(anchor, texts)).toBe(2)
  })

  it('falls back to the clamped ordinal when the text cannot be found', () => {
    const anchor: ReadingAnchor = {
      kind: 'source',
      ordinal: 8,
      total: 3,
      token: createReadingAnchorFingerprint('missing'),
      fraction: 0,
    }

    expect(resolveReadingAnchorOrdinal(anchor, ['one', 'two', 'three'])).toBe(2)
  })
})
