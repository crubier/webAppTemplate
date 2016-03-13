# coffeelint: disable=max_line_length
gulp        = require 'gulp'
serve       = require 'gulp-serve'
gutil       = require "gulp-util"
stylus      = require 'gulp-stylus'
changed     = require 'gulp-changed'
execSync    = require 'exec-sync'
clean       = require 'gulp-clean'
livereload  = require 'gulp-livereload'
notify      = require 'gulp-notify'
jade        = require 'gulp-jade'
coffee      = require 'gulp-coffee'
sourcemaps  = require 'gulp-sourcemaps'
fs          = require 'fs'
os          = require 'os'
webpack     = require "webpack"
notifier    = new (require('node-notifier'))()

databaseUser = 'dynamo'

gulp.task 'default', ['build']

gulp.task 'clean',  ['clean-out']

gulp.task 'clean-all',  ['clean-out','clean-database','clean-logs']

gulp.task 'setup', ['setup-database']

gulp.task 'build', ['backend','frontend','watch']

gulp.task 'build-prod', ['backend','frontend-prod','watch']

gulp.task 'clean-logs',  () ->
  gulp.src('./*.log', {read: false}).pipe(clean())

gulp.task 'clean-out',  () ->
  gulp.src('./out/', {read: false}).pipe(clean())

gulp.task 'serve', serve('.out/frontend')

gulp.task "backend", ()->
  gulp.src('./src/backend/**/*.*').pipe(changed('./out/backend/')).pipe(sourcemaps.init()).pipe(coffee().on('error', gutil.log)).pipe(sourcemaps.write()).pipe(gulp.dest('./out/backend/')).pipe(notify("Backend built"))

gulp.task "frontend", ()->
  gulp.src('./src/frontend/**/*.svg').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("SVG built"))
  gulp.src('./src/frontend/**/*.html').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("HTML built"))
  gulp.src('./src/frontend/**/*.css').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("CSS built"))
  gulp.src('./src/frontend/**/*.jade').pipe(changed('./out/frontend/', {extension: '.jade'})).pipe(jade({locals:{}})).pipe(gulp.dest('./out/frontend/')).pipe(notify("Jade built"))
  gulp.src('./src/frontend/**/*.styl').pipe(changed('./out/frontend/', {extension: '.css'})).pipe(stylus()).pipe(gulp.dest('./out/frontend/')).pipe(notify("Stylus built"))
  gulp.start "webpack"
  return

gulp.task "frontend-prod", ()->
  gulp.src('./src/frontend/**/*.svg').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("SVG built"))
  gulp.src('./src/frontend/**/*.html').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("HTML built"))
  gulp.src('./src/frontend/**/*.css').pipe(changed('./out/frontend/')).pipe(gulp.dest('./out/frontend/')).pipe(notify("CSS built"))
  gulp.src('./src/frontend/**/*.jade').pipe(changed('./out/frontend/', {extension: '.jade'})).pipe(jade({locals:{}})).pipe(gulp.dest('./out/frontend/')).pipe(notify("Jade built"))
  gulp.src('./src/frontend/**/*.styl').pipe(changed('./out/frontend/', {extension: '.css'})).pipe(stylus()).pipe(gulp.dest('./out/frontend/')).pipe(notify("Stylus built"))
  gulp.start "webpack-prod"
  return

gulp.task("webpack", (callback)->
  webpack({
    entry: "./src/frontend/script/main.coffee",
    output:
      filename: "./out/frontend/script/bundle.js"
    resolve:
      modulesDirectories:["./node_modules","./src"]
    stats:
      colors: true
      modules: true
      reasons: true
    failOnError: true
    module:
      loaders: [
        {test: /\.jsx$/, loader: "jsx-loader" },
        {test: /\.coffee$/, loader: "coffee-loader" },
        {test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate" }
      ]
    devtool:'inline-source-map'
      },
      (err, stats) ->
        if(err) then throw new gutil.PluginError("webpack", err)
        gutil.log("[webpack]", stats.toString({
            # // output options
        }))
        callback()
    )
  notifier.notify(message:"JS built")
  return
  )


gulp.task("webpack-prod", (callback)->
  webpack({
    entry: "./src/frontend/script/main.coffee",
    output:
      filename: "./out/frontend/script/bundle.js"
    resolve:
      modulesDirectories:["./node_modules","./src"]
    stats:
      colors: true
      modules: true
      reasons: true
    failOnError: true
    module:
      loaders: [
        {test: /\.jsx$/, loader: "jsx-loader" },
        {test: /\.coffee$/, loader: "coffee-loader" },
        {test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate" }
      ]
    # devtool:'inline-source-map'
    plugins: [
        new webpack.optimize.DedupePlugin()
        new webpack.optimize.AggressiveMergingPlugin()
        new webpack.optimize.UglifyJsPlugin()
      ]
    },
    (err, stats) ->
      if(err) then throw new gutil.PluginError("webpack", err)
      gutil.log("[webpack]", stats.toString({
          # // output options
      }))
      callback()
    )
  notifier.notify(message:"JS built")
  return
  )

gulp.task 'setup-database',(callback)->
  # gutil.log os.platform() = darwin linux win32 sunos
  try
    if fs.existsSync('./db') then throw new Error "A 'db' folder already exists, you need to 'cult clean-database' before starting a new database"
    if not (execSync 'which initdb')
      if (execSync 'which brew')
        gutil.log "You have homebrew, so we use it to install postgresql. You can 'brew uninstall postgresql' if you want to uninstall it afterwards"
        execSync 'brew install postgresql'
      else
        throw new Error 'You need to install postgresql manually'
    execSync 'initdb ./db -A trust'
    gulp.start 'start-database'
    gutil.log "We created a new role called \'#{databaseUser}\'. You will be asked the password you want to set for it."
    execSync "createuser -d -P #{databaseUser}"
    gutil.log "Success. Database is running. A user called #{databaseUser} exists. You can 'cult stop-database' and 'cult start-database'"
  catch e
    gutil.log   e.message
  return

gulp.task 'start-database',  () ->
  try
    execSync 'pg_ctl -D ./db start'
  catch e
    gutil.log e.message
  return

gulp.task 'stop-database',()->
  try
    if not ((execSync 'pg_ctl -D ./db status') is 'pg_ctl: no server running')
      execSync 'pg_ctl -D ./db stop'
  catch e
    gutil.log e.message
  return

gulp.task 'clean-database',  () ->
  gulp.start 'stop-database'
  gulp.src('./db/', {read: false}).pipe(clean())
  return

gulp.task 'watch', () ->
  server = livereload()
  gulp.watch("./src/**/*.*",['frontend']).on('change', (file) -> gutil.log(file.path))
  gulp.watch("./out/**/*.*").on('change', (file) -> (server.changed(file.path)))
  return
  # gulp.watch("./out/frontend/**/*").on('change', (file) -> server.changed(file.path))

# coffeelint: enable=max_line_length
