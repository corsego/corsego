const { generateWebpackConfig, merge } = require('shakapacker')
const webpack = require('webpack')

const options = {
  resolve: {
    extensions: ['.css', '.scss', '.sass']
  }
}

const customConfig = {
  plugins: [
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default']
    })
  ],
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          'style-loader',
          'css-loader',
          'sass-loader'
        ]
      }
    ]
  }
}

module.exports = merge({}, generateWebpackConfig(options), customConfig)
