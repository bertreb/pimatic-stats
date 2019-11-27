pimatic-stats
===================

Getting statistics from a Pimatic home automation system.
This plugin provides information on the configuration of your Pimatic system. This information is normally only available via the api.
The number of devices, rules, variables, pages and groups can be selected and will be available as a variable and visible via the GUI. For comparison the 'size' of Pimatic is added. The size shows how big the configuration is. The higher the size the more devices and rules are used.

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
When the plugin is installed (including restart) a Stats device can be added. Below the settings, with the items that are available.

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

The following variables are available to you in Pimatic for the StatsDevice. All variables are initially visible. In the device config you can remove/add them.

* ${stats device id}.devices          - number of devices
* ${stats device id}.rules            - number of rules
* ${stats device id}.variables        - number of variables. Devices specific and custom
* ${stats device id}.pages            - number of pages
* ${stats device id}.groups           - number of groups
* ${stats device id}.size      	      - the size of the Pimatic system,  based on total number of devices, rules, variables, pages and groups
* ${stats device id}.pluginsOutdated  - number of outdated Plugins. This is checked every day at midnight.
* ${stats device id}.pimaticOutdated  - whether Pimatic is outdated. This is checked every day at midnight.
* ${stats device id}.nodeVersion      - actual Node version Pimatic is using


In the GUI an attribute becomes visible when added in the device config.

---------

The plugin is Node v10 compatible and in development. You could backup Pimatic before you are using this plugin!
