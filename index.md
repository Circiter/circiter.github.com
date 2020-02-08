---
layout: default
title: Home
---

# circiter.tk || circiter.github.io

[ nothing to see yet :( ]

{% comment %}
{% assign pages_list = site.pages %}
{% for node in pages_list %}[-]({{ node.url }}).{% endfor %}
{% endcomment %}

Some posts:
{% assign posts_list = site.blog_posts %}
{% for post in posts_list %}
    {% if post.title != null %}
        {% if post.layout == "post" %}
* [{{ post.title }}]({{ post.url }})
        {% endif %}
        {% if post.layout == "draft" %}
* [[draft] {{ post.title }}]({{ post.url }})
        {% endif %}
    {% endif %}
{% endfor %}

----------

- [000000 Home](http://circiter.tk)
- [000064 Gists](https://gist.github.com/Circiter/)
- [0000C8 Empty <img src="/assets/images/blacktocat.png" />GitHub repository](https://github.com/Circiter)
- [00012C Mail me](mailto:xcirciter@gmail.com)
