import type { Editor } from '@tiptap/core'

export type OutlineHeading = { level: number; text: string; position: number }

export function getDocumentOutline(editor: Editor): OutlineHeading[] {
  const headings: OutlineHeading[] = []
  editor.state.doc.descendants((node, position) => {
    if (node.type.name === 'heading') headings.push({ level: node.attrs.level, text: node.textContent, position })
  })
  return headings
}

function normalizeOutlineText(value: string): string {
  return value.replace(/\s+/g, ' ').trim()
}

/// Resolve a heading after mode switches or document edits. Positions can go
/// stale even though the visible heading text is still authoritative; the old
/// position remains a tie-breaker for duplicate headings.
export function resolveOutlineHeading(editor: Editor, position: number, headingText?: string): HTMLElement | null {
  const headings = getDocumentOutline(editor)
  const normalizedText = headingText === undefined ? undefined : normalizeOutlineText(headingText)
  const candidates = normalizedText === undefined
    ? headings
    : headings.filter(heading => normalizeOutlineText(heading.text) === normalizedText)
  const heading = candidates.reduce<OutlineHeading | null>((nearest, candidate) => {
    if (!nearest) return candidate
    return Math.abs(candidate.position - position) < Math.abs(nearest.position - position)
      ? candidate
      : nearest
  }, null)

  const node = editor.view.nodeDOM(heading?.position ?? position)
  return node instanceof HTMLElement && /^H[1-6]$/.test(node.tagName) ? node : null
}

export function getActiveOutlinePosition(editor: Editor, source: 'cursor' | 'scroll', topInset = 0): number | null {
  const headings = getDocumentOutline(editor)
  let active: number | null = source === 'scroll' ? headings[0]?.position ?? null : null
  const threshold = topInset + Math.max(80, (window.innerHeight - topInset) * .2)
  for (const heading of headings) {
    const node = editor.view.nodeDOM(heading.position)
    if (source === 'cursor' ? heading.position <= editor.state.selection.from
      : node instanceof HTMLElement && node.getBoundingClientRect().top <= threshold) active = heading.position
  }
  return active
}

export function scrollToOutlineHeading(editor: Editor, position: number, topInset = 0, headingText?: string): boolean {
  const heading = resolveOutlineHeading(editor, position, headingText)
  if (!heading) return false
  const scrollingElement = document.scrollingElement as HTMLElement ?? document.documentElement

  // Outline commands must drive whichever element actually owns scrolling.
  // The editor is normally window-scrolled, but host containers and future
  // layout modes can introduce an intermediate scroll box.
  let scrollContainer: HTMLElement = scrollingElement
  for (let node: HTMLElement | null = heading.parentElement; node; node = node.parentElement) {
    const overflowY = window.getComputedStyle(node).overflowY
    if ((overflowY === 'auto' || overflowY === 'scroll' || overflowY === 'overlay')
      && node.scrollHeight > node.clientHeight) {
      scrollContainer = node
      break
    }
  }

  const apply = () => {
    const lineHeight = Number.parseFloat(window.getComputedStyle(heading).lineHeight)
    const containerRect = scrollContainer.getBoundingClientRect()
    const viewportTop = scrollContainer === scrollingElement ? 0 : containerRect.top
    const top = Math.max(0, scrollContainer.scrollTop + heading.getBoundingClientRect().top - viewportTop - topInset
      - (Number.isFinite(lineHeight) ? lineHeight / 2 : 12))

    // WKWebView may ignore window.scrollTo for very tall documents, while the same
    // scrolling element accepts direct offset writes (the path used by session restore).
    scrollContainer.scrollTop = top
    if (scrollContainer === scrollingElement) {
      document.documentElement.scrollTop = top
      document.body.scrollTop = top
    }
  }

  apply()
  // Images, fonts, and ProseMirror decorations can settle after the command has
  // returned. Re-read the heading rect after layout so the final position is
  // anchored to the heading that was clicked, rather than a stale pre-layout row.
  window.requestAnimationFrame(() => {
    apply()
    window.requestAnimationFrame(apply)
  })
  return true
}

export function assignHeadingAnchors(root: ParentNode): void {
  const used = new Set<string>()
  for (const heading of root.querySelectorAll('h1,h2,h3,h4,h5,h6')) {
    const slug = (heading.textContent ?? '').toLowerCase().replace(/[^\p{L}\p{N}_\-\s]/gu, '').replace(/\s/g, '-') || 'heading'
    let id = slug
    for (let suffix = 1; used.has(id); suffix++) id = `${slug}-${suffix}`
    used.add(id)
    heading.id = id
  }
}

export function scrollToHeadingAnchor(editor: Editor, fragment: string, topInset = 0): boolean {
  let slug = fragment.replace(/^#/, '')
  try { slug = decodeURIComponent(slug) } catch { /* Match a literal percent in the fragment. */ }
  assignHeadingAnchors(editor.view.dom)
  const heading = getDocumentOutline(editor).find(item => {
    const node = editor.view.nodeDOM(item.position)
    return node instanceof HTMLElement && node.id === slug
  })
  return heading ? scrollToOutlineHeading(editor, heading.position, topInset) : false
}
