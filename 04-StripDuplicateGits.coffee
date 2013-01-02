require('js-yaml')
mongoose = require('mongoose')

NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongoose.connect(config.mongodb)

score = (doc) =>
  return doc.downloads.total

stripDuplicates = (list, callback) =>
  console.log(list)
  NpmPackage.find({"id": {"$in": list}}).sort("id").exec((error, docs) =>
    if(error)
      process.nextTick(() => callback(error))

    max = -1
    maxDoc = null

    # find the greatest doc
    for doc in docs
      thisScore = score(doc)
      if thisScore > max
        max = thisScore
        maxDoc = doc

    waiting = docs.length - 1
    for doc in docs
      if doc != maxDoc
        doc.github.exists = false
        doc.save((error) =>
          if error?
            console.error(error)

          waiting -= 1
          if waiting == 0
            callback()
        )
  )

NpmPackage.aggregate(
  [
    { "$match":  {"github.url": {"$exists": true, "$ne": null }, "github.exists": true}},
    { "$project": {"github.url": 1, "id": 1} },
    { "$group": {"_id": "$github.url", "count": {"$sum": 1}, "docs": {"$push": "$id"}}},
    { "$match": {"count": {"$gt": 1 }}}
  ],
  (error, docs) ->
    if error?
      console.error(error)
      mongoose.connection.close()
      process.exit()


    waiting = docs.length

    if docs.length == 0
      mongoose.connection.close()

    for doc in docs
      stripDuplicates(doc.docs, (error) =>
        if error?
          console.error(error)

        waiting -= 1

        if waiting == 0
          console.log("Done")
          mongoose.connection.close()
      )
)
