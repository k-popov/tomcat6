tomcat6
=======

Simplified Apache Tomcat 6 cookbook for Chef.

Cookbook capabilities:

 - downloads the latest Apache Tomcat from the official site or the version specified by URL;
 - unpacks the archive, sets the appropriate permissions for folders;
 - moves webapps/logs/conf directories to some other place if requested, creates symlinks;
 - removes the example web-applications (deletion list is configurable);
 - optionally configures proxying with apache httpd;
 - adds a manager user for application deployment with 'tcdeploy' cookbook;
 - has java classpath configurable
 - uses a environmental variables file for tomcat configuration.


Sample JSON file:

{
    "tomcat6": {
        "install_java": false,
        "config_dir": "/usr/local/etc/tomcat",
        "user": "tomcat",
        "group": "tomcat",
        "apache_proxy" : true
    },
    "apache": {
        "default_proxy": {
            "read_thru_locations": {
                "logs": false,
                "conf": false
                },
            "ssl_offload": true
            },
            "port": 80,
            "port_secure": 443,
            "proxy_port": 8080,
            "https_enabled": true,
            "https_forward": false
    },
    "run_list": [
        "java6",
        "tomcat6"
    ]
}
