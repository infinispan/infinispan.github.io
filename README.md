= Introduction

This is the source code for the [Infinispan.org](http://www.infinispan.org) website.  This is based on templates created by the JBoss Community using [Awestruct](http://awestruct.org) and [Bootstrap](http://twitter.github.com/bootstrap).

= System Requirements
* Ruby 1.9.2 or above
* RubyGems - 1.3.6 or above
* Bundler - 1.3.5
   * Try `sudo gem install bundler`
* GNU WGet 1.14

**Note:** If you are using Mac OS X, you need to have the following setup:
   1. [XCode](https://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12). After installing XCode, you should go to `XCode -> Preferences -> Download` and install the command line (CLI) tools.
   1. [MacPorts](http://www.macports.org/)
   1. You can install WGet using MacPorts: `sudo port install wget`
   1. You need `libxml2` and `libxslt`: `sudo port install libxml2 libxslt`
   1. You will need Ruby >= 1.9.2.  Mac OS _Mountain Lion_ comes with 1.8.x.  Using [RVM](https://rvm.io/) and [JewelryBox](http://jewelrybox.unfiniti.com/) is probably the best way to manage and install several different versions of Ruby on OS X.

== 1. Build the website
Run Awestruct in development mode from the top-level directory to build the website and host it using a local web server:

`bin/run_dev.sh`

**Note:** The first time the site is built common JavaScript, font and image files will be downloaded from [http://static.jboss.org](http://static.jboss.org) and cached into a local *cache/* directory using wget. This then allows you to run the site locally rather than relying on a network connection. Since the cache download takes a considerable amount of time by default the `wget` command will run only once a day to prevent unrequired delays in build times. The time interval and other settings of this process can be configured in site.yml.

**Tip:** Use the `--directory-prefix` option of the `wget: urls:` property in *_config/site.yml* if you wish to use a different directory name. A *.gitignore* file is automatically created in this directory containing a * to prevent you adding cached files to GIT by mistake. 

== 2. View the website locally
Use a web browser to visit [http://localhost:4242](http://localhost:4242) where you can see the site.

== 3. Stage the website
Staging is published on OpenShift.  To do this, you *must* have SSH access to Infinispan's OpenShift account.  After that, you must:

`$ bin/publish_staging.sh` and then browse to `http://stg-ispn.rhcloud.com` to test.

== 4. Publish the website
If everyone is happy with staging then update the `profiles: production: base_url:` property in *_config/site.yml* to point to your production domain and run the `bin/publish_production.sh` command to produce a version that will be published to `http://infinispan.github.io` and `http://www.infinispan.org`. 

= Contribute to issues on Infinispan.org
Feel like contributing?  Great!  Read [this page](https://github.com/infinispan/infinispan.github.io/blob/develop/CONTRIBUTING.md) on how to contribute.