import path from 'path'
import TerserPlugin from 'terser-webpack-plugin'
import webpack from 'webpack'

const output = {
  filename: '[name].js',
  path: path.resolve('./dist'),
}
export default () => {
  return <webpack.Configuration>{
    entry: { index: path.resolve('./app.js'), PRGAThreadCom: path.resolve('./src/utils/PRGAThreadCom.js') },
    output,
    module: {
      rules: [
        {
          test: /\.[tj]s$/i,
          use: [
            {
              loader: 'ts-loader',
              options: {
                transpileOnly: true, // 只做语言转换，而不做类型检查
              },
            },
          ],
          exclude: /node_modules/,
        },
      ],
    },
    resolve: {
      extensions: ['.ts', '.js'],
      alias: {
        '@': path.resolve('./src'),
      },
    },
    plugins: [],
    target: 'node',
    mode: 'production',
    optimization: {
      minimize: true,
      minimizer: [
        new TerserPlugin({
          // 是否启用多线程
          parallel: true,
          // 是否将注释剥离到单独的文件中
          extractComments: false,
          terserOptions: {
            // 是否压缩代码
            compress: true,
            // 是否压缩标识符
            mangle: true,
            // 是否保留函数名
            keep_fnames: true,
            // 是否保留类名
            keep_classnames: true,
            // format: {
            //   // 输出格式化
            //   beautify: true,
            //   // 保留注释
            //   comments: true,
            // },
          },
        }),
      ],
    },
  }
}
