const { readFileSync } = require('fs')
const { build } = require('esbuild')

const excludeVendorFromSourceMapPlugin = ({ filter }) => ({
  name: 'excludeVendorFromSourceMap',
  setup (build) {
    build.onLoad({ filter }, args => {
      if (args.path.endsWith('.js')) {
        return {
          contents:
            readFileSync(args.path, 'utf8') +
            '\n//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIiJdLCJtYXBwaW5ncyI6IkEifQ==',
          loader: 'default'
        }
      }
    })
  }
})

const excludeNodeModules = excludeVendorFromSourceMapPlugin({
  filter: /node_modules/
})

const buildConfig = {
  sourcemap: 'inline',
  bundle: true,
  minify: true,
  allowOverwrite: true,
  logLevel: 'info',
  plugins: [excludeNodeModules]
}

const buildTutorial = Object.assign(
  {
    entryPoints: [
      'inst/lib/tutorial/tutorial.js',
      'inst/lib/tutorial/tutorial-autocompletion.js',
      'inst/lib/tutorial/tutorial-diagnostics.js'
    ],
    outdir: 'inst/lib/tutorial'
  },
  buildConfig
)

const buildTutorialFormat = Object.assign(
  {
    entryPoints: [
      'inst/rmarkdown/templates/tutorial/resources/tutorial-format.js'
    ],
    outfile: 'inst/rmarkdown/templates/tutorial/resources/tutorial-format.js'
  },
  buildConfig
)

const buildI18N = Object.assign(
  {
    entryPoints: ['inst/lib/i18n/tutorial-i18n-init.js'],
    outfile: 'inst/lib/i18n/tutorial-i18n-init.js'
  },
  buildConfig
)

build(buildTutorial).catch(() => process.exit(1))
build(buildTutorialFormat).catch(() => process.exit(1))
build(buildI18N).catch(() => process.exit(1))
