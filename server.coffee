#hacky advanced mongo definitions based on https://github.com/meteor/meteor/pull/644
if Meteor.isServer

  path = __meteor_bootstrap__.require("path")
  MongoDB = __meteor_bootstrap__.require("mongodb")
  Future = __meteor_bootstrap__.require(path.join("fibers", "future"))

  _dummyCollection_ = new Meteor.Collection '__dummy__'

  # Wrapper of the call to the db into a Future
  _futureWrapper = (collection, commandName, args)->
    col = if (typeof collection) == "string" then  _dummyCollection_ else collection
    collectionName = if (typeof collection) == "string" then  collection else collection._name

    #tl?.debug "future Wrapper called for collection " + collectionName + " command: " + commandName + " args: " + args
    future = new Future
    col.find()._mongo.db.createCollection(collectionName,(err,collection)=>
      future.throw err if err
      collection[commandName](args, (err,result)=>
        future.throw(err) if err
        future.ret([true,result])
      )
    )
    result = future.wait()
    #console.dir "Result from the Future Wrapper is: " + result
    throw result[1] if !result[0]
    result[1]

  # exposing the methods to the client
  Meteor.methods
    _callAdvancedDBMethod: _futureWrapper

  # Extending Collection on the server
  _.extend Meteor.Collection::,

    distinct: (key) ->
      #_collectionDistinct @_name, key, query, options
      _futureWrapper @_name, "distinct", key

    aggregate: (pipeline) ->
      _futureWrapper @_name, "aggregate", pipeline


