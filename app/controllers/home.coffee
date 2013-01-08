Seq = require 'seq'
gravatar = require 'gravatar'

moduleList = require '../query/module_list'
tagList = require '../query/tag_list'

class HomeController
  index: (req, res, next) =>
    viewdata = {}
    type = req.param "sort", "popular"
    tag = req.param "tag"
    format = req.param 'format'

    Seq()
      .par(-> moduleList type, tag, this)
      .par(-> tagList this)
      .seq((mods, tags) =>
        viewdata.currentTag = tag ? 'all'
        viewdata.currentType = type
        viewdata.modules = mods
        viewdata.tags = (t._id for t in tags)
        viewdata.tags.splice(0, 0, "all")

        @attachGravatars(mods)
        @annotateScores(mods, type)


        formats = {
          html: () -> res.render('home/index', viewdata)
          json: () -> res.send(mods)
          partial: () -> res.render('home/_modules', viewdata)
        }

        if format of formats
          formats[format]()
        else
          res.format formats

      ).catch((err) ->
        next new Error(err))

  annotateScores: (mods, scoreName) ->
    for mod in mods
      mod.score = mod.metrics[scoreName + 'Score']

  attachGravatars: (mods) ->
    for mod in mods
      mod.ownerGravatar =  gravatar.url(mod.owner ? 'nobody@example.com', { s: 120 })

  @setup: (app) =>
    my = new HomeController()
    app.get "/.:format?", my.index
    app.get "/:sort?.:format?", my.index
    app.get "/:sort?/tags/:tag.:format?", my.index

module.exports = HomeController
