meteor-mongo-extensions
=======================

MapReduce is fixed and working as described below.

Very simple implementation of some of mongodb aggregation framework functions for Meteor. Extends Collection on
both Server and Client with 3 methods so far so that you can do:

```coffeescript
    col = new Meteor.Collection "name"

    if Meteor.isClient
        col.distinct "Field Name", (error, result)->
            console.dir result

        col.aggregate pipeline, (error, result)->
            console.dir result

        # just an example - map and reduce need to be defined as strings
        map = "function() {emit(this.Region, this.Amount);}"
        reduce = "function(reg, am) { return Array.sum(am);};"

        col.mapReduce map, reduce, {out: "out_collection_name", verbose: true}, (err,res)->
            console.dir res.stats # statistics object for running mapReduce
            col = new Meteor.Collection res.collectionName
            Meteor.subscribe res.collectionName, ->
                data = col.find().fetch() # resulting collection
                console.dir data


    if Meteor.isServer
        result = col.distinct "Field Name"
        console.dir result

        result = col.aggregate pipeline
        console.dir result
```

If called on the client, it simply passes the call to the server collection - so that's mostly a convenience wrapper.
No visibility permissions are checked, so be careful with what data you may want to expose.

mapReduce call is slightly more advanced: as results of running mapReduce are put into a separate collection,
it is automatically published on the server so you can subscribe on the client, (theoretically) providing
reactivity for subsequent calls.

This package is MIT Licensed. Do whatever you like with it but any responsibility for doing so is your own.
