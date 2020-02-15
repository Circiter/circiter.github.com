FROM xucheng/texlive-full:latest

#FROM ruby:2.6.5
#FROM jekyll/jekyll
#FROM rekka/tectonic
#FROM WtfJoke/tectonic-docker

#ENV RUBYGEMS_VERSION=2.7.0

#FROM phpirates/texlive-latexbuild:small-2018
#packages=xkeyval, amsmath, amscls, mathtools, xcolor, pgf, marvosym, amsfonts, opensans, framed, collection-fontsrecommended, collection-langeuropean, graphics

LABEL "com.github.actions.name"="Build a Jekyll site/blog"
LABEL "com.github.actions.description"="Builds a Jekyll site or a blog"
LABEL "repository"="https://github.com/Circiter/circiter.github.io"
ADD build.sh /build.sh
ENTRYPOINT ["/bin/sh", "/build.sh"]
