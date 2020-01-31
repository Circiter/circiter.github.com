#FROM ruby:2.6.5
FROM xucheng/texlive-full:latest
ENV RUBYGEMS_VERSION=2.7.0
LABEL "com.github.actions.name"="Build a Jekyll site/blog"
LABEL "com.github.actions.description"="Builds a Jekyll site or a blog"
LABEL "repository"="https://github.com/Circiter/circiter.github.io"
ADD build.sh /build.sh
ENTRYPOINT ["/bin/sh", "/build.sh"]
