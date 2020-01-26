FROM ruby:2.6.5
ENV RUBYGEMS_VERSION=2.7.0
#ENV LC_ALL C.UTF-8
#ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US.UTF-8
LABEL "com.github.actions.name"="Build a Jekyll site/blog"
LABEL "com.github.actions.description"="Builds a Jekyll site or a blog"
LABEL "repository"="https://github.com/Circiter/circiter.github.io"
ADD build.sh /build.sh
ENTRYPOINT ["/bin/sh", "/build.sh"]
