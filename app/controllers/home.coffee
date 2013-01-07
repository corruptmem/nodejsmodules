class HomeController
  index: (req, res) =>
    console.log("Hello!")
    res.end("Hello World!")

  @setup: (app) =>
    my = new HomeController()
    app.get "/", my.index

module.exports = HomeController
