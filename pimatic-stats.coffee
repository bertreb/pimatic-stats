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
        createCallback: (config, lastState) => new StatsDevice(config, lastState, @framework)
      })

  plugin = new StatsPlugin

  class StatsDevice extends env.devices.Device

    constructor: (@config, lastState, @framework) ->

      @id = @config.id
      @name = @config.name
      @test = @config.test
      @stats = @config.statistics
      #@stats = if @config.statistics? then @config.statistics else null
      @attributes = {}
      @attributeValues = {}

      for _attr in @stats
        do (_attr) =>
          @attributes[_attr] =
            description: _attr
            type: types.number
            label: _attr
            acronym: _attr
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )
      if @attributes?.pimaticOutdated?
        @attributes?.pimaticOutdated.type = types.string
      if @attributes?.nodeVersion?
        @attributes.nodeVersion.type = types.string
      if @attributes?.database?
        @attributes.database.type = types.string

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
      @attributeValues.nodeVersion = lastState?.nodeVersion?.value or ""


      events = [
        "deviceAdded", "deviceRemoved", "ruleAdded",
        "ruleRemoved", "variableAdded", "variableRemoved",
        "pageAdded", "pageRemoved", "groupAdded", "groupRemoved"
      ]

      for _event in events
        @framework.on _event, () =>
          @refreshData()

      @framework.pluginManager.getInstalledPluginsWithInfo()
        .then((data) =>
          @attributeValues.plugins = data.length
          @emit 'plugins', @attributeValues.plugins
        )
        .catch((err) ->
          env.logger.error err.message
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
            env.logger.error "foutje"#err.message
          )
        @framework.pluginManager.isPimaticOutdated()
          .then((data) =>
            @attributeValues.pimaticOutdated = if data then "yes" else "no"
            @emit 'pimaticOutdated', @attributeValues.pimaticOutdated
          )
          .catch((err) ->
            env.logger.error err.message
          )
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

        @_scheduleOutdatedTimer = setTimeout(scheduleCheckOutdated, @_getTimeTillTomorrow())

      scheduleCheckOutdated()

      @attributeValues.nodeVersion = String process.versions.node
      @emit 'nodeVersion', @attributeValues.nodeVersion

      super()

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

    _getTimeTillTomorrow: ->
      midnight = new Date()
      midnight.setHours(24,0,0,0)
      interval = midnight.getTime() - Date.now()
      return interval

    destroy: ->
      clearTimeout @_scheduleOutdatedTimer
      super()

  return plugin
