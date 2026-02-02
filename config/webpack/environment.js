const { generateWebpackConfig } = require('shakapacker')
const webpack = require('webpack')

const config = generateWebpackConfig()

config.plugins.push(
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default']
  })
)

module.exports = config
