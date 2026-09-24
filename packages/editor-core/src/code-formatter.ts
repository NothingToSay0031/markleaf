export type CodeFormatResult =
  | { status: 'formatted'; code: string }
  | { status: 'unchanged' }
  | { status: 'unsupported' }
  | { status: 'failed'; message: string }

type PrettierPlugin = import('prettier').Plugin

const supportedParsers = {
  babel: 'babel',
  typescript: 'typescript',
  json: 'json',
  json5: 'json5',
  css: 'css',
  scss: 'scss',
  less: 'less',
  html: 'html',
  vue: 'vue',
  yaml: 'yaml',
  markdown: 'markdown',
} as const

const languageParsers: Record<string, keyof typeof supportedParsers> = {
  cjs: 'babel',
  css: 'css',
  html: 'html',
  javascript: 'babel',
  js: 'babel',
  json: 'json',
  jsonc: 'json5',
  json5: 'json5',
  jsx: 'babel',
  less: 'less',
  markdown: 'markdown',
  md: 'markdown',
  mjs: 'babel',
  scss: 'scss',
  ts: 'typescript',
  tsx: 'typescript',
  typescript: 'typescript',
  vue: 'vue',
  yaml: 'yaml',
  yml: 'yaml',
}

export function isCodeFormatterLanguage(language: string | null | undefined): boolean {
  const key = language?.trim().toLowerCase() ?? ''
  return key.length > 0 && key !== 'mermaid' && key in languageParsers
}

export type ExternalCodeFormatter = {
  languages: string[]
  supportsSelectionLineRanges?: boolean
  selectionLineRangeLanguages?: string[]
  format: (
    code: string,
    language: string,
    selection?: CodeFormatSelectionRange,
  ) => Promise<CodeFormatResult>
}

export type CodeFormatSelectionRange = {
  startLine: number
  endLine: number
}

let externalFormatter: ExternalCodeFormatter | null = null
let externalLanguages = new Set<string>()

export function setExternalCodeFormatter(formatter: ExternalCodeFormatter | null): void {
  externalFormatter = formatter
  externalLanguages = new Set((formatter?.languages ?? []).map(language => language.trim().toLowerCase()))
}

export function isExternalFormatterLanguage(language: string | null | undefined): boolean {
  const key = language?.trim().toLowerCase() ?? ''
  return key.length > 0 && externalLanguages.has(key)
}

export function isFormatterSupportedLanguage(language: string | null | undefined): boolean {
  return isCodeFormatterLanguage(language) || isExternalFormatterLanguage(language)
}

export function supportsExternalFormatterSelectionLineRanges(
  language: string | null | undefined,
): boolean {
  const formatter = externalFormatter
  if (formatter?.supportsSelectionLineRanges !== true) return false
  const supportedLanguages = formatter.selectionLineRangeLanguages
  if (!supportedLanguages) return true
  const key = language?.trim().toLowerCase() ?? ''
  return key.length > 0 && supportedLanguages.includes(key)
}

export function normalizeInlineCodeWhitespace(code: string): string {
  return code.trim().replace(/[ \t]{2,}/g, ' ')
}

async function loadPrettier(): Promise<{
  format: typeof import('prettier/standalone')['format']
  plugins: PrettierPlugin[]
}> {
  const [{ format }, babel, estree, typescript, postcss, html, yaml, markdown] = await Promise.all([
    import('prettier/standalone'),
    import('prettier/plugins/babel'),
    import('prettier/plugins/estree'),
    import('prettier/plugins/typescript'),
    import('prettier/plugins/postcss'),
    import('prettier/plugins/html'),
    import('prettier/plugins/yaml'),
    import('prettier/plugins/markdown'),
  ])
  return {
    format,
    plugins: [babel, estree.default, typescript, postcss, html, yaml, markdown] as unknown as PrettierPlugin[],
  }
}

let prettierLoader: Promise<Awaited<ReturnType<typeof loadPrettier>>> | null = null

function loadFormatter(): Promise<Awaited<ReturnType<typeof loadPrettier>>> {
  prettierLoader ??= loadPrettier()
  return prettierLoader
}

export async function formatCode(
  code: string,
  language: string,
  selection?: CodeFormatSelectionRange,
): Promise<CodeFormatResult> {
  const languageKey = language.trim().toLowerCase()
  const parser = languageParsers[languageKey]
  if (!parser) {
    if (isExternalFormatterLanguage(languageKey) && externalFormatter) {
      return selection === undefined
        ? externalFormatter.format(code, languageKey)
        : externalFormatter.format(code, languageKey, selection)
    }
    return { status: 'unsupported' }
  }

  try {
    const prettier = await loadFormatter()
    const formatted = await prettier.format(code, {
      parser: supportedParsers[parser],
      plugins: prettier.plugins,
      tabWidth: 2,
      printWidth: 80,
      semi: true,
      singleQuote: false,
      endOfLine: 'lf',
    })
    return formatted === code ? { status: 'unchanged' } : { status: 'formatted', code: formatted }
  } catch (error) {
    return {
      status: 'failed',
      message: error instanceof Error ? error.message : String(error),
    }
  }
}
