require('js-yaml')
mongoose = require('mongoose')
_ = require('underscore')
NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongodb = mongoose.connect(config.mongodb)

class DepGraph
  constructor: (ids) ->
    @ids = ids
    @map = {}
    @len = ids.length
    @matrix = new Buffer(@len * @len)
    for n in [0...(@len*@len)-1]
      @matrix[n] = 0
    @calculated = {}

    for id, n in ids
      @map[id] = n

  addDependency: (fromPackage, toPackage, n = 1) =>
    from = @map[fromPackage]
    to = @map[toPackage]
    existing = @matrix[from*@len + to]
    if n < existing or existing == 0
      @matrix[from*@len + to] = n

  getDependencies: (fromPackage) =>
    deps = []
    from = @map[fromPackage]
    for to in [0..(@len - 1)]
      if @matrix[from*@len + to] == 1
        deps.push(@ids[to])

    return deps

  calculate: (id, seen = {}) =>
    if id of @calculated
      return
    
    seen = _.clone(seen)
    seen[id] = true
    @calculated[id] = true

    for rdep in @getReverseDependencies(id)
      @calculate(rdep, seen) if rdep not of seen

    for rdep in @getReverseDependencies(id)
      for drdep, val of @getAllReverseDependencies(rdep)
        #console.log("Dep from #{drdep} on #{id} with val #{val + 1} (via #{rdep})")
        @addDependency(drdep, id, val + 1)
  
  getAllReverseDependencies: (toPackage) =>
    rdeps = {}
    to = @map[toPackage]
    for from in [0..(@len - 1)]
      distance = @matrix[from*@len + to]
      if distance >= 1
        rdeps[@ids[from]] = distance

    return rdeps

  getReverseDependencies: (toPackage) =>
    rdeps = []
    to = @map[toPackage]
    for from in [0..(@len - 1)]
      if @matrix[from*@len + to] == 1
        rdeps.push(@ids[from])

    return rdeps

NpmPackage.find().exec((error, docs) =>
  if error?
    console.error(error)
    process.exit()

  packages = (doc.id for doc in docs)
  dg = new DepGraph(packages)
  for doc in docs
    for dep in doc.dependencies.concat(doc.devDependencies)
      dg.addDependency(doc.id, dep)

  #for id in packages
  console.log("Calculating")
  for pkg, i in packages
    console.log("#{i} of #{packages.length}: #{pkg}")
    dg.calculate(pkg)


  # write changes back to database
  writeOne = (error) =>
    if error?
      console.error(error)
      process.exit()

    if docs.length == 0
      mongoose.connection.close()
      console.log("Done")
      process.exit()

    doc = docs.splice(-1)[0]
    doc.allDependencies = []
    for id, distance of dg.getAllReverseDependencies(doc.id)
      doc.allDependencies.push({id: id, distance: distance})
    
    console.log("Saving #{doc.id}")
    doc.save(writeOne)

  writeOne()
)
