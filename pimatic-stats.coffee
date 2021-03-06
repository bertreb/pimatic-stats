module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  types = env.require('decl-api').types
  _ = require('lodash')

  class StatsPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>

      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass('StatsDevice', {
        configDef: deviceConfigDef.StatsDevice,
        createCallback: (config, lastState) => new StatsDevice(config, lastState, @framework, deviceConfigDef)
      })

  plugin = new StatsPlugin

  class StatsDevice extends env.devices.Device

    constructor: (@config, lastState, @framework, deviceConfig) ->

      @id = @config.id
      @name = @config.name
      @test = @config.test
      @stats = @config.statistics ? null
      @attributes = {}
      @attributeValues = {}

      @show = @hide = false
      if not @config.show? or @config.show is "all"
        @show = false
        @hide = true
      else
        @show = true
        @hide = false

      @attrList = deviceConfig.StatsDevice.properties.statistics.items.enum
      for _attr in @attrList
        do (_attr) =>
          @attributes[_attr] =
            description: _attr
            type: types.number
            label: _attr
            acronym: _attr
            hidden: @show
            displaySparkline: false
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )
      if @attributes?.pimaticOutdated?
        @attributes?.pimaticOutdated.type = types.string
      if @attributes?.nodeVersion?
        @attributes.nodeVersion.type = types.string
      if @attributes?.database?
        @attributes.database.type = types.string
      if @attributes?.npmVersion?
        @attributes.npmVersion.type = types.string
      if @attributes?.pimaticVersion?
        @attributes.pimaticVersion.type = types.string

      for _attr in @stats
        do (_attr) =>
          @attributes[_attr].hidden = @hide

      @attributeValues.devices = lastState?.devices?.value or 0
      @attributeValues.rules = lastState?.rules?.value or 0
      @attributeValues.variables = lastState?.variables?.value or 0
      @attributeValues.pages = lastState?.pages?.value or 0
      @attributeValues.groups = lastState?.groups?.value or 0
      @attributeValues.index = lastState?.index?.value or 0
      @attributeValues.plugins = lastState?.plugins?.value or 0
      @attributeValues.pluginsOutdated = lastState?.pluginsOutdated?.value or 0
      @attributeValues.database = lastState?.database?.value or ""
      @attributeValues.pimaticOutdated = lastState?.pimaticOutdated?.value or ""
      @attributeValues.pimaticVersion = lastState?.pimaticVersion?.value or ""
      @attributeValues.npmVersion = lastState?.npmVersion?.value or ""
      @attributeValues.nodeVersion = lastState?.nodeVersion?.value or ""


      events = [
        "deviceAdded", "ruleAdded", "ruleRemoved", "variableAdded",
        "deviceRemoved", "variableRemoved",
        "pageAdded", "pageRemoved", "groupAdded", "groupRemoved"
      ]

      for _event in events
        @framework.on _event, () =>
          @refreshData()
          @checkDB()

      @framework.pluginManager.getInstalledPluginsWithInfo()
        .then((data) =>
          @attributeValues.plugins = data.length
          @emit 'plugins', @attributeValues.plugins
        )
        .catch((err) ->
          env.logger.error "error getting plugin info: " + err.message
        )

      @framework.on 'after init' , () =>
        @refreshData()

      scheduleCheckOutdated = () =>
        @framework.pluginManager.getOutdatedPlugins()
          .then((data) =>
            for outdated in data
              env.logger.info "Outdated plugin: '" + outdated.plugin + "'"
            @attributeValues.pluginsOutdated = data.length
            @emit 'pluginsOutdated', @attributeValues.pluginsOutdated
          )
          .catch((err) ->
            env.logger.error "error checking outdatedPlugins: " + err.message
          )

        @framework.pluginManager.isPimaticOutdated()
          .then((data) =>
            @attributeValues.pimaticOutdated = if data then "yes" else "no"
            @emit 'pimaticOutdated', @attributeValues.pimaticOutdated
          )
          .catch((err) ->
            env.logger.error "error checking isPimaticOutdated: " +  err.message
          )

        @packageJson = @framework.pluginManager.getInstalledPackageInfo('pimatic')
        @attributeValues.pimaticVersion = String @packageJson.version
        @emit 'pimaticVersion', @attributeValues.pimaticVersion

        @framework.pluginManager.checkNpmVersion()
          .then((data) =>
            @attributeValues.npmVersion = String data
            @emit 'npmVersion', @attributeValues.npmVersion
          )
          .catch((err) ->
            env.logger.error "error checking checkNpmVersion: " + err.message
          )

        @framework.database.checkDatabase()
          .then((problems) =>
            _size = _.size(problems)
            if _size is 0
              @attributeValues.database = "ok"
            else
              @attributeValues.database = (String _size) + " problem" + (if _size > 1 then "s")
            @emit 'database', @attributeValues.database
          )
          .catch((err) ->
            env.logger.error "error checking database: " + err.message
          )

        @_scheduleOutdatedTimer = setTimeout(scheduleCheckOutdated, @_getTimeTillNextUpdate())

      scheduleCheckOutdated()

      @attributeValues.nodeVersion = String process.versions.node
      @emit 'nodeVersion', @attributeValues.nodeVersion

      super()

    checkDB: () =>
      @framework.database.checkDatabase()
        .then((problems) =>
          _size = _.size(problems)
          if _size is 0
            @attributeValues.database = "ok"
          else
            @attributeValues.database = (String _size) + " problems"
          @emit 'database', @attributeValues.database
        )
        .catch((err) ->
          env.logger.error err.message
        )

    refreshData: () =>
      @attributeValues.devices = Number (@framework.deviceManager.getDevices()).length
      @emit 'devices', @attributeValues.devices

      @attributeValues.rules = Number (@framework.ruleManager.getRules()).length
      @emit 'rules', @attributeValues.rules

      @attributeValues.variables = Number (@framework.variableManager.getVariables()).length
      @emit 'variables', @attributeValues.variables

      @attributeValues.groups = Number (@framework.groupManager.getGroups()).length
      @emit 'groups', @attributeValues.groups

      @_pages = @framework.pageManager.getPages()
      @attributeValues.pages = Number (@_pages).length
      @emit 'pages', @attributeValues.pages

      @attributeValues.index =
        @attributeValues.devices *
        @attributeValues.rules
      @emit 'index', @attributeValues.index

    _getTimeTillNextUpdate: ->
      #22 hours + 4 hours random
      interval = 79200000 + Math.round(14400 * Math.random())
      return interval

    destroy: ->
      clearTimeout @_scheduleOutdatedTimer
      super()

  return plugin
