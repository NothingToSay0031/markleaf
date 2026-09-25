import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createEditor, getMarkdown } from '../src/editor'

type Operation = {
  kind: 'available-read' | 'style-read' | 'style-write' | 'natural-read' | 'computed-read'
  container: HTMLElement
  key?: string
}

const mathMarkdown = Array.from({ length: 5 }, (_, index) => {
  const latex = `E_{${index}} = ${index + 1}a_{${index}}x^{2} + ${index + 1}b_{${index}}x + ${index + 1}c_{${index}}`
  return `$$\n${latex}\n$$`
}).join('\n\n')

describe('block math width fitting', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    document.body.replaceChildren()
  })

  it('batches same-frame block math fits and separates layout reads from writes', () => {
    const mount = document.createElement('div')
    document.body.append(mount)

    const rafCallbacks: Array<FrameRequestCallback> = []
    const rafSpy = vi.spyOn(window, 'requestAnimationFrame').mockImplementation(callback => {
      rafCallbacks.push(callback)
      return rafCallbacks.length
    })

    const editor = createEditor(mount, mathMarkdown)
    const containers = Array.from(
      mount.querySelectorAll<HTMLElement>('.markleaf-math-block'),
    )

    expect(containers).toHaveLength(5)
    // Five node views request a fit during creation, but only one frame callback
    // is installed for the whole batch.
    expect(rafSpy).toHaveBeenCalledTimes(1)
    expect(rafCallbacks).toHaveLength(1)

    const operations: Operation[] = []
    const naturalWidths = new WeakMap<HTMLElement, number>(containers.map((container, index) => [container, index === 4 ? 80 : 400]))

    const getRect = vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
      operations.push({ kind: 'natural-read', container: this })
      const width = naturalWidths.get(this) ?? 100
      return new DOMRect(0, 0, width, 20)
    })
    const getStyle = vi.spyOn(window, 'getComputedStyle').mockImplementation(element => {
      operations.push({ kind: 'computed-read', container: element as HTMLElement })
      return { fontSize: '16px' } as CSSStyleDeclaration
    })

    for (const container of containers) {
      Object.defineProperty(container, 'clientWidth', {
        configurable: true,
        get() {
          operations.push({ kind: 'available-read', container })
          return 100
        },
      })

      for (const key of ['display', 'width', 'fontSize'] as const) {
        const style = container.style
        let value = style.getPropertyValue(key)
        Object.defineProperty(style, key, {
          configurable: true,
          get() {
            operations.push({ kind: 'style-read', container, key })
            return value
          },
          set(next: string) {
            operations.push({ kind: 'style-write', container, key })
            value = next
          },
        })
      }

      // Keep the real descriptor available for cleanup.
      Object.defineProperty(container, '__markleafStyleInstrumentation__', {
        configurable: true,
        value: { getRect, getStyle },
      })
    }

    const callbacks = rafCallbacks.splice(0, rafCallbacks.length)
    callbacks.forEach(callback => callback(performance.now()))

    const measured = new Set(operations.filter(operation => operation.kind === 'natural-read').map(operation => operation.container))
    expect(measured).toEqual(new Set(containers))

    const availableReadIndexes = operations
      .map((operation, index) => operation.kind === 'available-read' ? index : -1)
      .filter(index => index >= 0)
    const firstWriteIndex = operations.findIndex(operation => operation.kind === 'style-write')
    expect(availableReadIndexes).toHaveLength(containers.length)
    expect(firstWriteIndex).toBeGreaterThan(Math.max(...availableReadIndexes))

    // All max-content reads happen after the measurement styles are written and
    // before any result is written back.
    // The first write is the start of the measurement-style phase. Every
    // initial read (available width and existing styles) happens before it,
    // and every max-content read happens after it.
    const firstStyleWriteIndex = operations.findIndex(operation => operation.kind === 'style-write')
    const initialReadIndexes = operations
      .map((operation, index) => (operation.kind === 'available-read' || operation.kind === 'style-read') ? index : -1)
      .filter(index => index >= 0)
    expect(firstStyleWriteIndex).toBeGreaterThan(Math.max(...initialReadIndexes))
    const naturalReadIndexes = operations
      .map((operation, index) => operation.kind === 'natural-read' ? index : -1)
      .filter(index => index >= 0)
    expect(naturalReadIndexes).toHaveLength(containers.length)
    expect(Math.min(...naturalReadIndexes)).toBeGreaterThan(firstStyleWriteIndex)

    // All result writes happen after the max-content reads.
    const restoreWriteContainers = new Set(operations
      .map((operation, index) => operation.kind === 'style-write' && index > Math.max(...naturalReadIndexes) ? operation.container : null)
      .filter(container => container !== null))
    expect(restoreWriteContainers).toEqual(new Set(containers))

    expect(containers[0]!.style.fontSize).toBe('4.00px')
    expect(containers[3]!.style.fontSize).toBe('4.00px')
    expect(containers[4]!.style.fontSize).toBe('')
    expect(containers[0]!.style.display).toBe('')
    expect(containers[0]!.style.width).toBe('')

    editor.destroy()
    expect(getMarkdown(editor)).toContain('$$')
  })

  it('removes destroyed block math nodes from the pending fit batch', () => {
    const mount = document.createElement('div')
    document.body.append(mount)

    const rafCallbacks: Array<FrameRequestCallback> = []
    vi.spyOn(window, 'requestAnimationFrame').mockImplementation(callback => {
      rafCallbacks.push(callback)
      return rafCallbacks.length
    })

    const editor = createEditor(mount, '$$\nE = mc^2\n$$')
    const container = mount.querySelector<HTMLElement>('.markleaf-math-block')
    expect(container).not.toBeNull()

    editor.destroy()
    const rectSpy = vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect')
    rafCallbacks.splice(0).forEach(callback => callback(performance.now()))

    expect(rectSpy).not.toHaveBeenCalled()
  })
})
