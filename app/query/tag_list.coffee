NpmPackage = require('../../model/NpmPackage')
mongoose = require('mongoose')

module.exports = (query, callback) =>
  mongoose.connection.db.collection "tags", (err, collection) =>
    return callback(err) if err?
    q = null
    if query?
      q = collection.find({"_id": new RegExp("^#{query}")})
    else
      q = collection.find()

    q.sort({"value.score": -1}).limit(100).toArray (err, results) =>
      return callback(err) if err?
      callback null, (r._id for r in results)
