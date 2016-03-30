var webpack = require('webpack');
// var sourcemap = require('karma-sourcemap-loader');




module.exports = function (config) {
	config.set({
		browsers: [ 'Chrome' ], //run in chrome
		singleRun: true, //run only once by default
		frameworks: [ 'mocha' ], //use mocha
		files: [ 'test/test.jsx' ], //load this file
		preprocessors: {
			'test/test.jsx': [ 'webpack', 'sourcemap' ]
			 // use webpack for preprocess
		},
		reporters: [ 'dots' ], //report results in dots format
		webpack: { // similar to webpack.config
			devtool: 'inline-source-map',
			module: {
				loaders: [
					{
						test: /\.jsx$/, 
						exclude: /node_modules/,
						loader: 'babel-loader',
						query: {
							presets: ['es2015', 'react']
						}
					},
					{ 
						test:  /\.json$/, 
						loader: 'json-loader' 
					},
				],
			},
		},
		webpackMiddleware: { 
			noInfo: true 
		},
		// webpackServer: {
		// 	noInfo: true //dont write to console while running in karma
		// },
		plugins:[
			require('karma-webpack'),
			require('karma-mocha'),
			require('karma-chrome-launcher'),
			require('karma-sourcemap-loader')
		]
	})
}