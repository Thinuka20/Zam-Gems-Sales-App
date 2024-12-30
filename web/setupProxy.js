const corsProxy = {
  target: 'http://124.43.70.220:7072',
  changeOrigin: true,
  secure: false,
  pathRewrite: {
    '^/api': '/Reports'
  }
};

module.exports = corsProxy;