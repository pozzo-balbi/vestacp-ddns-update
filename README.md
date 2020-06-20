# vestacp-ddns-update
enables easy ddns setup within vestacp

Ryan Brownell, https://github.com/ryanbrownell, published under https://github.com/ryanbrownell/vesta a (now old) version 
of VestaCP with some extra features that provide DDNS besides the DNS support. Since then some security vulnerabilities 
were found in VestaCP, so it is not adviced to use his version any longer in a production environment.

Comparing his VestaCP version with an standard VestaCP, I found that only a few files needed to be modified or added. So
the script creates or updates existing files of a standard VestaCP installation to provide DDNS functionality.

While it should work with version 0.9.8-24, nothing can be said about future versions.

Please also take a look at https://github.com/ryanbrownell/DDNS-for-Vesta-CP if that is useful for you.
