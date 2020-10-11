# vestacp-ddns-update
enables easy ddns setup within vestacp

Ryan Brownell, https://github.com/ryanbrownell, published under https://github.com/ryanbrownell/vesta a (now old) version 
of VestaCP with some extra features that provide DDNS besides the DNS support. Since then some security vulnerabilities 
were found in VestaCP, so it is not adviced to use his version any longer in a production environment.

Check out https://ryanbrownell.com/project/69 to see a live demonstration of DDNS in VestaCP.

Comparing his VestaCP version with an standard VestaCP, I found that only a few files needed to be modified or added. So
the script creates or updates existing files of a standard VestaCP installation to provide DDNS functionality.

While it should work with version 0.9.8-24, nothing can be said about future versions.

Please also take a look at https://github.com/ryanbrownell/DDNS-for-Vesta-CP if that is useful for you.

Run vestacp-ddns-update.sh to install the DDNS upgrade.

If you are running the DDNS behind a http proxy, you need the following command:



sed -i '/\/\/ Refuse connections that are not running on HTTPS/,+6d' /usr/local/vesta/web/ddns/index.php

sed -i 's/$remote_addr/$http_x_forwarded_for/' /usr/local/vesta/nginx/conf/nginx.conf

sed -i 's/        ssl                  on;/        ssl                  off;/' /usr/local/vesta/nginx/conf/nginx.conf
