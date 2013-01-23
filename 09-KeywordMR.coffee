require('js-yaml')
mongoose = require('mongoose')

NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongoose.connect(config.mongodb)

mr = {}

mr.map = () ->
  return unless this.keywords? and this.keywords.length? > 0

  re = /^[a-zA-Z0-9\-]+$/

  for keyword in this.keywords
    if re.test(keyword) and this.metrics.popularScore > 0
      emit(keyword, { score: this.metrics.popularScore })

mr.reduce = (key, values) ->
  object = { score: 0 }
  for v in values
    object.score += v.score

  return object

mr.out = { merge: "tags" }

NpmPackage.mapReduce mr, (err) =>
    console.error(err) if err?
    mongoose.connection.db.ensureIndex "tags", {"value.score": 1}, (err) =>
      console.error(err) if err?
      console.log("Done")
      process.exit()
