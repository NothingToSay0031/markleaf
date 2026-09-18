import { defineConfig } from 'vite'
import { katexSelfContainedCss, katexWoff2Only } from './build/index'

export default defineConfig({
  plugins: [katexWoff2Only(), katexSelfContainedCss()],
  build: {
    target: 'es2022',
    outDir: 'dist/renderer',
    lib: {
      entry: {
        'editor-core': 'src/renderer-entry.ts',
        'export-html': 'src/export-entry.ts',
      },
      formats: ['es'],
      cssFileName: 'editor-core',
    },
    sourcemap: false,
  },
})
