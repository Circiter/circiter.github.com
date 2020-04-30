---
layout: default
title: Дневник Circiter'а.
---

# circiter.tk || circiter.github.io

Простой публичный дневник (блог).

Сообщения-статьи:
{% assign posts_list = site.blog_posts %}
{% for post in posts_list %}
    {% if post.title != null %}
        {% if post.layout == "post" %}
* [{{ post.title }}]({{ post.url }})
        {% endif %}
        {% if post.layout == "draft" %}
* [[черновик] {{ post.title }}]({{ post.url }})
        {% endif %}
    {% endif %}
{% endfor %}

<hr>
Метки:
{% capture tags %}
    {% for tag in site.tags %}
        {{ tag[0] }}
    {% endfor %}
{% endcapture %}
{% assign sortedtags = tags | split:' ' | sort_natural %}

<hr>
список тэгов:
{% for tag in sortedtags %}
    <h3 id="{{tag}}">{{tag}}</h3>
    <ul>
    {% for post in site.tags[tag] %}
        <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
    </ul>
{% endfor %}
<hr>

иконка:
{% icon fa-spinner fa-spin %}

<hr>
облако тэгов:
{% tag_cloud font-size: 50 - 150% %}

<hr>

- [000064 Минирепозитории gists](https://gist.github.com/Circiter/)
- [0000C8 Учётная запись на <img src="/public/images/github-mark.png" />GitHub](https://github.com/Circiter)
- [00012C Электронная почта](mailto:xcirciter@gmail.com)
