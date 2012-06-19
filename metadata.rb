maintainer        "Grid Dynamics"
maintainer_email  "clou4dev@griddynamics.com"
description       "Installs and configures tomcat6"
version           "0.1"

%w{redhat centos debian ubuntu}.each do |os|
  supports os
end

depends "java"
