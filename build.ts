import esbuild from 'esbuild';

await esbuild.build({
  logLevel: 'info',
  entryPoints: ['./src/index.ts'],
  outdir: './dist',
  minify: true,
  bundle: true,
  sourcemap: true,
  platform: 'node',
  format: 'esm',
  banner: { // commonjs用ライブラリをESMプロジェクトでbundleする際に生じることのある問題への対策
    js: 'import { createRequire as topLevelCreateRequire } from "module"; import url from "url"; const require = topLevelCreateRequire(import.meta.url); const __filename = url.fileURLToPath(import.meta.url); const __dirname = url.fileURLToPath(new URL(".", import.meta.url));',
  },
})