#FROM ruby:2.6.5
FROM xucheng/texlive-full:latest
#FROM jekyll/jekyll
#FROM rekka/tectonic
#FROM WtfJoke/tectonic-docker

#ENV RUBYGEMS_VERSION=2.7.0

#ADD b.sh /b.sh
#ENTRYPOINT ["/bin/sh", "/b.sh"]

#RUN bundle install
#RUN bundle exec jekyll build --trace

#FROM phpirates/texlive-latexbuild:small-2018
#packages=xkeyval, amsmath, amscls, mathtools, xcolor, pgf, marvosym, amsfonts, opensans, framed, collection-fontsrecommended, collection-langeuropean, graphics

ENV JEKYLL_ENV=development
RUN apk --update add zlib-dev build-base libxml2-dev libxslt-dev readline-dev libffi-dev ruby-dev yaml-dev zlib libxml2 build-base ruby-io-console readline libxslt ruby yaml libffi nodejs ruby-irb ruby-json ruby-rake ruby-rdoc git bash curl ttf-freefont fontconfig
RUN gem clean && gem install --no-ri --no-rdoc bundler json nokogiri jekyll
RUN rm -rf /usr/lib/ruby/gems/*/cache/*.gem

LABEL "com.github.actions.name"="Build a Jekyll site/blog"
LABEL "com.github.actions.description"="Builds a Jekyll site or a blog"
LABEL "repository"="https://github.com/Circiter/circiter.github.io"
ADD build.sh /build.sh
ENTRYPOINT ["/bin/sh", "/build.sh"]
