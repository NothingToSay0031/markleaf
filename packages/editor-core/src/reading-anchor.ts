export type ReadingAnchorKind = 'visual' | 'source'

export type ReadingAnchorInput = {
  kind: ReadingAnchorKind
  ordinal: number
  total: number
  token: string
  fraction: number
}

export type ReadingAnchor = ReadingAnchorInput

export function isReadingAnchorInput(value: unknown): value is ReadingAnchorInput {
  if (!value || typeof value !== 'object') return false
  const record = value as Record<string, unknown>
  return (record.kind === 'visual' || record.kind === 'source')
    && typeof record.ordinal === 'number'
    && Number.isFinite(record.ordinal)
    && typeof record.total === 'number'
    && Number.isFinite(record.total)
    && typeof record.token === 'string'
    && typeof record.fraction === 'number'
    && Number.isFinite(record.fraction)
}

export type TopLevelReadingBlock = {
  ordinal: number
  position: number
  text: string
}

type TopLevelReadingDocument = {
  forEach(
    callback: (
      node: { readonly textContent: string },
      position: number,
      index: number,
    ) => void,
  ): void
}

export function collectTopLevelReadingBlocks(
  document: TopLevelReadingDocument,
): TopLevelReadingBlock[] {
  const blocks: TopLevelReadingBlock[] = []
  document.forEach((node, position, ordinal) => {
    blocks.push({
      ordinal,
      position,
      text: node.textContent,
    })
  })
  return blocks
}

export function normalizeReadingAnchor(input: ReadingAnchorInput): ReadingAnchor {
  const total = Math.max(1, Math.floor(Number.isFinite(input.total) ? input.total : 1))
  const ordinal = Math.min(
    total - 1,
    Math.max(0, Math.floor(Number.isFinite(input.ordinal) ? input.ordinal : 0)),
  )
  const fraction = Math.min(
    1,
    Math.max(0, Number.isFinite(input.fraction) ? input.fraction : 0),
  )

  return {
    kind: input.kind,
    ordinal,
    total,
    token: createReadingAnchorFingerprint(input.token),
    fraction,
  }
}

export function createReadingAnchorFingerprint(text: string): string {
  return text
    .normalize('NFKC')
    .replace(/\s+/gu, ' ')
    .trim()
    .toLocaleLowerCase()
    .slice(0, 96)
}

export function resolveReadingAnchorOrdinal(
  anchor: ReadingAnchorInput,
  texts: readonly string[],
): number {
  const normalized = normalizeReadingAnchor(anchor)
  const normalizedTexts = texts.map(createReadingAnchorFingerprint)
  let bestOrdinal = normalized.ordinal
  let bestScore = Number.POSITIVE_INFINITY

  for (const [index, text] of normalizedTexts.entries()) {
    if (!text) continue
    let matchScore = Number.POSITIVE_INFINITY
    if (text === normalized.token) matchScore = 0
    else if (text.startsWith(normalized.token)) matchScore = 1
    else if (text.includes(normalized.token)) matchScore = 2
    if (matchScore === Number.POSITIVE_INFINITY) continue

    const distance = Math.abs(index - normalized.ordinal)
    const score = matchScore * 1000 + distance
    if (score < bestScore) {
      bestScore = score
      bestOrdinal = index
    }
  }

  return Math.min(
    Math.max(0, normalizedTexts.length - 1),
    bestOrdinal,
  )
}
