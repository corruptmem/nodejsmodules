require('js-yaml')
mongoose = require('mongoose')
NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongodb = mongoose.connect(config.mongodb)

NpmPackage.aggregate(
  [
    { "$match":  {"github.url": {"$exists": true, "$ne": null }}},
    { "$project": {"github.url": 1, "id": 1} },
    { "$group": {"_id": "$github.url", "count": {"$sum": 1}, "docs": {"$push": "$id"}}},
    { "$match": {"count": {"$gt": 1 }}}
  ],
  (error, docs) ->
    if error?
      console.error(error)
      process.exit()
    
    console.log(docs)
)
