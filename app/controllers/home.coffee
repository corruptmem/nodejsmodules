Seq = require 'seq'

moduleList = require '../query/module_list'
tagList = require '../query/tag_list'

class HomeController
  index: (req, res, next) =>
    viewdata = {}
    type = req.param "sort", "popular"
    tag = req.param "tag"

    Seq()
      .par(-> moduleList type, tag, this)
      .par(-> tagList this)
      .seq((mods, tags) ->
        viewdata.currentTag = tag ? 'all'
        viewdata.currentType = type
        viewdata.modules = mods
        viewdata.tags = (t._id for t in tags)
        viewdata.tags.splice(0, 0, "all")
        res.render 'home/index', viewdata)
      .catch((err) ->
        next new Error(err))

  @setup: (app) =>
    my = new HomeController()
    app.get "/:sort?", my.index
    app.get "/:sort?/tags/:tag", my.index

module.exports = HomeController
