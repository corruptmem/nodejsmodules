NpmPackage = require('../../model/NpmPackage')

module.exports = (type, keyword, callback) =>
    sort = {}
    sort["metrics." + type + "Score"] = -1
    filter = if keyword? and keyword.length > 0 and keyword != 'all' then {"keywords": keyword} else {}
    
    select =
      id: 1
      owner: 1
      url: 1
      keywords: 1
      metrics: 1
      description: 1
    
    NpmPackage.find(filter, select).sort(sort).limit(15).lean().exec callback
