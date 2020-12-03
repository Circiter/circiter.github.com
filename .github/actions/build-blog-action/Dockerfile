# Working solution:
#FROM xucheng/texlive-full:latest
# FIXME: Try to use xucheng/texlive-small:latest instead.

#FROM ruby:2.6.5
#FROM jekyll/jekyll
#FROM rekka/tectonic
#FROM WtfJoke/tectonic-docker

#ENV RUBYGEMS_VERSION=2.7.0

#FROM ivanpondal/alpine-latex:1.1.0

FROM phpirates/texlive-latexbuild:small-2018
#packages=xkeyval, amsmath, amscls, mathtools, xcolor, pgf, marvosym, amsfonts, opensans, framed, collection-fontsrecommended, collection-langeuropean, graphics, collection-fontsextra, xypic, collection-latexextra, collection-langcyrillic

LABEL "com.github.actions.name"="Build a Jekyll site/blog"
LABEL "com.github.actions.description"="Builds a Jekyll site or a blog"
LABEL "repository"="https://github.com/Circiter/circiter.github.io"
ADD build.sh /build.sh
ENTRYPOINT ["/bin/sh", "/build.sh"]
