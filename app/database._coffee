mysql = require 'mysql'

module.exports = (config) ->
  connection = mysql.createConnection
    host: config.db.host
    port: config.db.port
    user: config.db.user
    password: config.db.password
    database: config.db.database
  return connection
