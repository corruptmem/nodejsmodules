NpmPackage = require('../../model/NpmPackage')

module.exports = (callback) =>
  NpmPackage.aggregate(
    [
      $match:
        "keywords.0":
          $exists: true
    ,
      $project:
        keywords: 1
        "metrics.popularScore": 1
    ,
      $unwind: "$keywords"
    ,
      $group:
        _id: "$keywords"
        score:
          $sum: "$metrics.popularScore"
    ,
      $sort:
        score: -1
    ,
      $limit: 100
    ], callback)
