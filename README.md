tomcat6
=======

Simplified Apache Tomcat 6 recipe for Chef

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
            ":proxy_port": 8080,
            "https_enabled": true,
            "https_forward": false
    },
    "run_list": [
        "java6",
        "tomcat6"
    ]
}
