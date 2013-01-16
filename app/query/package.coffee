NpmPackage = require('../../model/NpmPackage')

module.exports = (id, callback) =>
    filter =
      id: id
    
    select =
      reverseDependencies: 0
    
    NpmPackage.find(filter, select).limit(1).lean().exec callback
