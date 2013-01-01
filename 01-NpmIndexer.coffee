require('js-yaml')
mongoose = require('mongoose')
NpmIndexer = require('./indexer/NpmIndexer')

config = require('./config')

mongoose.connect(config.mongodb)

indexer = new NpmIndexer()
#indexer.indexAll((error) =>
indexer.indexPackage('uglify-js', (error) =>
  if error?
    console.error(error)
  mongoose.connection.close()
  process.exit()
)
