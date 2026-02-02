#!/usr/bin/env bun
// Bun build script for Corsego
// Usage: bun run build.js [--watch]

const isWatch = process.argv.includes('--watch');
const isProd = process.env.NODE_ENV === 'production';

async function build() {
  console.log(`Building JavaScript (${isProd ? 'production' : 'development'})...`);

  const result = await Bun.build({
    entrypoints: ['./app/javascript/application.js'],
    outdir: './app/assets/builds',
    naming: '[name].js',
    minify: isProd,
    sourcemap: isProd ? 'none' : 'external',
    target: 'browser',
    external: ['jquery'],
    define: {
      'process.env.NODE_ENV': JSON.stringify(isProd ? 'production' : 'development'),
    },
  });

  if (!result.success) {
    console.error('Build failed:');
    for (const log of result.logs) {
      console.error(log);
    }
    return false;
  }

  console.log('Build complete!');
  for (const output of result.outputs) {
    console.log(`  ${output.path}`);
  }
  return true;
}

// Initial build
const success = await build();
if (!success && !isWatch) {
  process.exit(1);
}

// Watch mode
if (isWatch) {
  console.log('\nWatching for changes...');
  const { watch } = await import('fs');

  watch('./app/javascript', { recursive: true }, async (eventType, filename) => {
    if (filename && filename.endsWith('.js')) {
      console.log(`\nFile changed: ${filename}`);
      await build();
    }
  });

  // Keep process alive
  await new Promise(() => {});
}
