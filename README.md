Introduction
============
This is the source code for the [Infinispan.org](http://www.infinispan.org) website.  This is based on templates created by the JBoss Community using [Awestruct](http://awestruct.org) and [Bootstrap](http://twitter.github.com/bootstrap).

System Requirements
===================
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

1. Build the website
--------------------
Run Awestruct in development mode from the top-level directory to build the website and host it using a local web server:

`bin/run_dev.sh`

**Note:** The first time the site is built common JavaScript, font and image files will be downloaded from [http://static.jboss.org](http://static.jboss.org) and cached into a local *cache/* directory using wget. This then allows you to run the site locally rather than relying on a network connection. Since the cache download takes a considerable amount of time by default the `wget` command will run only once a day to prevent unrequired delays in build times. The time interval and other settings of this process can be configured in site.yml.

**Tip:** Use the `--directory-prefix` option of the `wget: urls:` property in *_config/site.yml* if you wish to use a different directory name. A *.gitignore* file is automatically created in this directory containing a * to prevent you adding cached files to GIT by mistake. 

2. View the website
-------------------
Use a web browser to visit [http://localhost:4242](http://localhost:4242) where you can see the site.

3. Add/edit web pages and layouts
---------------------------------
Use a text editor to create/edit web pages and/or layouts. Use the `bootstrap_css_url` and `bootstrap_js_url` variables to ensure you refer to the locally built versions of the files in the development profile and the hosted versions in the staging and production profiles.

**Note:** Currently the template uses images from an example project. If you wish to use your own project images then you must upload them to http://static.jboss.org/images/[project], edit `project` and `project_images_url` variables and edit the `http://static.jboss.org/images/example/` line in the `wget: urls:` property, all three settings can be found in *_config/site.yml*.

4. Customize the theme
----------------------
To use the theme simply reference the hosted *bootstrap-community.css* and *bootstrap-community.js* files on [http://static.jboss.org](http://static.jboss.org). However if you wish to make project-specific changes then test them locally using the development profile and host the compiled css and js files in your project-specific staging/production domains. Update the `bootstrap_css_url` and `bootstrap_js_url` variables in the staging/production profiles to refer to them.
 
5. Stage the website
--------------------
Once you're happy with your website in development mode update the `profiles: staging: base_url:` property in *_config/site.yml* to point to your staging domain and run the `bundle exec awestruct -P staging` command to generate a version that can be uploaded for others to review.

6. Publish the website
----------------------
If everyone is happy with staging then update the `profiles: production: base_url:` property in *_config/site.yml* to point to your production domain and run the `bin/publish_production.sh` command to produce a version that will be published to `http://infinispan.github.io` and `http://www.infinispan.org`. 
