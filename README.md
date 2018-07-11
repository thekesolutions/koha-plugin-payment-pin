# Koha Payment+PIN plugin

This plugin provides a simple way to validate patron's PIN (as an extended attribute) and to add credits through an API key.

## Downloading

From the [release page](https://github.com/thekesolutions/koha-plugin-payment-pin/releases) you can download the relevant _*.kpz_ file


## Installing

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
```

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.

## Usage

In order to use the provided scripts as an API, you need to generate (and save) an API key on the _configuration_ page for the plugin.
After that you can test the endpoints using the key like this:

```
POST http://host_port/pin_validator.pl?api_key=THEAPIKEY
{
	"pin": 1234,
	"cardnumber": "thecardnumber"
}
```

If there's a problem with the API key, plugin configuration or the data is not correct, this are the possible results:

Data errors:
```
500 Internal Server Error
{ "authorized": false, "error": "An explanation" }
```

Invalid key:
```
401 Unauthorized
{ "error": "Invalid API key" }
```

Missing key:
```
401 Unauthorized
{ "error": "API key missing" }
```

### PIN validation

```
POST http://host_port/pin_validator.pl?api_key=THEAPIKEY
{
    "pin": 1234,
    "cardnumber": "thecardnumber"
}
```

Results:

PIN and cardnumber combination valid:
```
200 OK
{ "authorized": true }
```

PIN and cardnumber combination invalid:
```
200 OK
{ "authorized": false }
```

### Payment

```
POST http://host_port/payment.pl?api_key=THEAPIKEY
{
    "amount": 35,
    "cardnumber": "thecardnumber"
}
```

Results:

Everything ok:
```
200 OK
{ "success": true}
```

Cardnumber doesn't exist:
```
500 Internal Server Error
{ authorized => JSON::false, error => "Invalid cardnumber" }
```
