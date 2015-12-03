FROM       fedora:22

# install the required dependencies to compile native extensions
# and needed by the website to fetch resources
RUN        dnf -y install gcc-c++ make ruby-devel libxml2-devel libxslt-devel findutils git ruby wget

RUN        groupadd -r dev && useradd  -g dev -u 1000 dev && mkdir -p /home/dev && chown dev:dev /home/dev

# From here we run everything as dev user
USER       dev

# Setup all the env variables needed for ruby
ENV        HOME /home/dev
ENV        GEM_HOME $HOME/.gems
ENV        GEM_PATH $HOME/.gems
ENV        PATH $PATH:$GEM_HOME/bin
ENV        LC_ALL en_US.UTF-8
ENV        LANG en_US.UTF-8
# Rakefile takes BIND into account
# used to bind awestruct to 0.0.0.0 instead of localhost
# otherwise the port is not exposed out of docker
ENV        BIND "-b 0.0.0.0"
RUN        mkdir $HOME/.gems

# Install Rake and Bundler for driving the Awestruct build & site
RUN        gem install -N rake bundler

# Clone infinispan.github.io in order to run the setup task
RUN        git clone https://github.com/infinispan/infinispan.github.io.git $HOME/infinispan.github.io
RUN        cd $HOME/infinispan.github.io && git checkout develop && rake setup

# We need to patch awestruct to make auto generation work. On mounted volumes file
# change montoring will only work with polling
RUN        gem contents awestruct | grep auto.rb | xargs sed -i "s/^\(.*force_polling =\).*/\1 true/"

EXPOSE     4242
VOLUME     $HOME/infinispan.github.io
WORKDIR    $HOME/infinispan.github.io

CMD [ "/bin/bash" ]

