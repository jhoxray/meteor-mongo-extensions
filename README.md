meteor-mongo-extensions
=======================

Very simple implementation of some of mongodb aggregation framework functions for Meteor. Extends Collection on
both Server and Client with 2 methods so far so that you can do:

    col = new Meteor.Collection "name"

    if Meteor.isClient
        col.distinct "Field Name", (error, result)->
            console.dir result

        col.aggregate pipeline, (error, result)->
            console.dir result


    if Meteor.isServer
        result = col.distinct "Field Name"
        console.dir result

        result = col.aggregate pipeline
        console.dir result


If called on the client, it simply passes the call to the server collection - so that's mostly a convenience wrapper.
No visibility permissions are checked, so be careful with what data you may want to expose.

This package is MIT Licensed. Do whatever you like with it but any responsibility for doing so is your own.
