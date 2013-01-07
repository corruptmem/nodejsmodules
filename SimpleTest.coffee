require('js-yaml')
mongoose = require('mongoose')
NpmPackage = require('./model/NpmPackage')
config = require('./config')
express = require('express')
gravatar = require('gravatar')

mongoose.connect(config.mongodb)

app = express()

app.get("/", (req, res) =>
  res.setHeader("Content-Type", 'text/html')

  type = req.param("q", "popular")
  keyword = req.param("k")

  sort = {}
  sort["metrics." + type + "Score"] = -1
  filter = if keyword? and keyword.length > 0 then {"keywords": keyword} else {}
  console.log(filter, sort)
  select = {"id": 1, "owner": 1, "url": 1, "keywords": 1, "metrics": 1, "description": 1}


  NpmPackage.find(filter, select).sort(sort).limit(15).exec((err, docs) =>
    return res.end(err) if err?


    body = "<style>body { font-family: sans-serif; } div { padding: 3px 0 }</style>"
    for doc in docs
      g = gravatar.url(doc.owner, {s: 15}) if doc.owner?
      body += "<div><b>#{doc.id}</b> by <img src='#{g}'> #{doc.owner}: <span style='color: #aaa'>#{doc.description}</span>"
      body += " - <a href='#{doc.url}'>Link</a>" if doc.url?


    res.end(body)
  )

)

app.listen(3000)


NpmPackage.find().sort({"metric.newScore": -1}).limit(15).exec((err, doc) =>
  console.log(doc.length)
)
