pimatic-stats
===================

Creating statistics from a Pimatic home automation system.
This plugin provides information on the usage of Pimatic, normaly only available via the api.
The number of devices, rules, variables, pages and groups can be selected and will be available as a variable and visible via the Gui. For comparison a pimatic-index is added. The index shows how 'heavy' the configuration is.

Installation
------------
To enable the Stats plugin add this to the plugins section via the GUI or add it in the config.json file.

```
...
{
  "plugin": "Stats"
}
...
```

Stats device
-----------------
When the plugin is installed (including restart) a Stats device can be added. Below the settings with the default values.

```
{
  "id": "<stats-device-id>",
  "class": "StatsDevice",
  "statistics":
  	 "items": [
       "devices", "rules", "variables", "pages", "groups", "plugins", "pluginsOutdated", "pimaticOutdated",
       "nodeVersion"
     ]
}
```
### Usage

The following variables are available to you in Pimatic for the StatsDevice (after selection in de config!).

* ${stats device id}.devices          - number of devices
* ${stats device id}.rules            - number of rules
* ${stats device id}.variables        - number of variables. Devices specific and custom
* ${stats device id}.pages            - number of pages
* ${stats device id}.groups           - number of groups
* ${stats device id}.index      	  - the index based on total number of devices, rules, variables, pages and groups
* ${stats device id}.pluginsOutdated  - number of outdated Plugins
* ${stats device id}.pimaticOutdated  - weather Pimatic is outdated
* ${stats device id}.nodeVersion      - actual Node version Pimatic is using


In the gui an attribute becomes visible when added in the device config.

---------

The plugin is Node v10 compatible and in development. You could backup Pimatic before you are using this plugin!
