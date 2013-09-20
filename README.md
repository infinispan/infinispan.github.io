# Introduction

This is the source code for the [Infinispan.org](http://www.infinispan.org) website.  This is based on templates created by the JBoss Community using [Awestruct](http://awestruct.org) and [Bootstrap](http://twitter.github.com/bootstrap).

# System Requirements
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

## 1. Build the website
Run Awestruct in development mode from the top-level directory to build the website and host it using a local web server:

`$ bin/run_dev.sh`

## 2. View the website locally
Use a web browser to visit [http://localhost:4242](http://localhost:4242) where you can see the site.

## 3. Stage the website
Staging is published on OpenShift.  To do this, you *must* have SSH access to Infinispan's OpenShift account.  After that, you must:

* Run `$ bin/publish_staging.sh`
* Browse to `http://stg-ispn.rhcloud.com` to test

### Permissions.
To be able to publish to staging, you must:
* Have the following in your `~/.ssh/config`:

```
    Host *.rhcloud.com
        IdentityFile ~/.ssh/libra_id_rsa
        VerifyHostKeyDNS yes
        StrictHostKeyChecking no
        UserKnownHostsFile ~/.ssh/libra_known_hosts
```

* Have `libra_id_rsa`, `libra_id_rsa.pub` and `libra_known_hosts` in your `~/.ssh` directory.
Contact Infinispan project leads for these files.

## 4. Publish the website
If everyone is happy with staging then:

* Run `$ bin/publish_production.sh`
* Browse to `http://www.infinispan.org`

### Permissions.
To be able to publish to production, you must have git push rights on *http://github.com/infinispan/infinispan.github.io*.
Contact Infinispan project leads for such permissions.

# Contribute to issues on Infinispan.org
Feel like contributing?  Great!  Read [this page](https://github.com/infinispan/infinispan.github.io/blob/develop/CONTRIBUTING.md) on how to contribute.