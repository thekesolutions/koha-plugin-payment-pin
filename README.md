# Koha Payment+PIN plugin

This plugin provides a simple way to validate patron's PIN (as an extended attribute) and to add credits through an API key.

## Downloading

From the [release page](https://github.com/thekesolutions/koha-plugin-payment-pin/releases) you can download the relevant *.kpz file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

You need to tweak your _Apache_ vhost configuration for the intranet. If you are using the packages
install method (you should!) given the instance name **instance** you need to edit the
_/etc/apache2/sites-available/**instance**.conf_ file. Look for the intranet vhost and add this:

```
ScriptAlias /pin_validator.pl "/var/lib/koha/instance/plugins/Koha/Plugin/Com/Theke/PaymentPIN/pin_validator.pl"
ScriptAlias /payment.pl "/var/lib/koha/instance/plugins/Koha/Plugin/Com/Theke/PaymentPIN/payment.pl"
Alias /plugin "/var/lib/koha/instance/plugins"
<Directory /var/lib/koha/instance/plugins>
      Options Indexes FollowSymLinks
      AllowOverride None
      Require all granted
</Directory>
```

Then restart _apache_:
```
$ sudo systemctl restart apache2.service

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.
