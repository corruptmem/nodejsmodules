tagList = require '../query/tag_list'

class TagController
  index: (req, res, next) =>
    query = req.param "q"
    tagList query, (err, result) =>
      next(err) if err?
      res.format { json: () -> res.send(result) }

  @setup: (app) =>
    my = new TagController()
    app.get "/tags.json", my.index

module.exports = TagController
