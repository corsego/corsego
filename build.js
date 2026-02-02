#!/usr/bin/env bun
// Bun build script for Corsego
// Bundles JavaScript with Bun, CSS with PostCSS
// Usage: bun run build.js [--watch]

import { spawn } from 'child_process';

const isWatch = process.argv.includes('--watch');
const isProd = process.env.NODE_ENV === 'production';

async function buildJS() {
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
    console.error('JavaScript build failed:');
    for (const log of result.logs) {
      console.error(log);
    }
    return false;
  }

  console.log('JavaScript build complete!');
  for (const output of result.outputs) {
    console.log(`  ${output.path}`);
  }
  return true;
}

function buildCSS() {
  return new Promise((resolve) => {
    console.log(`Building CSS (${isProd ? 'production' : 'development'})...`);

    const args = [
      './app/javascript/application.css',
      '-o', './app/assets/builds/application.css'
    ];

    if (isProd) {
      args.push('--no-map');
    }

    const proc = spawn('bun', ['run', 'postcss', ...args], {
      stdio: 'inherit',
      shell: true
    });

    proc.on('close', (code) => {
      if (code === 0) {
        console.log('CSS build complete!');
        console.log('  ./app/assets/builds/application.css');
        resolve(true);
      } else {
        console.error('CSS build failed');
        resolve(false);
      }
    });

    proc.on('error', (err) => {
      console.error('CSS build error:', err);
      resolve(false);
    });
  });
}

async function build() {
  const [jsSuccess, cssSuccess] = await Promise.all([buildJS(), buildCSS()]);
  return jsSuccess && cssSuccess;
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

  // Watch JavaScript files
  watch('./app/javascript', { recursive: true }, async (eventType, filename) => {
    if (filename && filename.endsWith('.js')) {
      console.log(`\nJS file changed: ${filename}`);
      await buildJS();
    }
    if (filename && filename.endsWith('.css')) {
      console.log(`\nCSS file changed: ${filename}`);
      await buildCSS();
    }
  });

  // Keep process alive
  await new Promise(() => {});
}
