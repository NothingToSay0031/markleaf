import { describe, expect, it } from 'vitest'
import { isHostCommandAllowed } from '../src/host-command-policy'

describe('host command policy', () => {
  it('allows the host to change read-only mode while read-only', () => {
    expect(isHostCommandAllowed('setReadOnly', {
      readOnly: true,
      documentType: 'markdown',
    })).toBe(true)
  })
})
