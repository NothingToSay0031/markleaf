import { describe, expect, it } from 'vitest'
import { collectTopLevelReadingBlocks } from '../src/renderer-entry'

describe('renderer entry exports', () => {
  it('exports reading-anchor helpers used by the webview bundle', () => {
    expect(typeof collectTopLevelReadingBlocks).toBe('function')
  })
})
