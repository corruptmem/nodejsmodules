require 'js-yaml'
express = require 'express'
mongoose = require 'mongoose'
expressParams = require 'express-params'

config = require './config'

mongoose.connect(config.mongodb)

app = express()
app.set 'views', __dirname + '/app/views'
app.set 'view engine', 'jade'

app.locals(require './helpers/links')

expressParams.extend(app)

app.configure =>
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use(require('connect-assets')())
  app.use express.static __dirname + "/public"

app.configure 'development', =>
  app.use express.errorHandler {
    dumpExceptions: true
    showStack: true
  }

app.configure 'production', =>
  app.use express.errorHandler()

for controller in ["home"]
  require("./app/controllers/#{controller}").setup(app)

app.listen config.web.port
