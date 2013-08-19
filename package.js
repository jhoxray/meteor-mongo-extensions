Package.describe({
    summary: "Straightforward implementation of mongodb aggregation framework"
});

Npm.depends({mongodb: "1.3.17"});

Package.on_use(function (api, where) {
    api.use('coffeescript', ['client', 'server']);
    api.use('underscore', ['client', 'server']);

    api.add_files('client.coffee', 'client');
    api.add_files('server.coffee', 'server');

});
