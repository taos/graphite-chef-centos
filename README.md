graphite-chef-centos
====================

Chef cookbook for installing Graphite on Centos and AmazonLinux.
It is currently really hard to even try out graphite on Centos. This cookbook should help get you started, but is currently a proof-of-concept, only used for initial install. Not designed for production servers. 

Known Issues:
 * Currently recipe must be run twice. manage.py syncdb call fails the first time.
