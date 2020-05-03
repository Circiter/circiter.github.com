---
layout: default
title: Дневник Circiter'а.
---

[в процессе наполнения] {% icon fa-spinner fa-spin %}

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
{% tag_cloud font-size: 0.80 - 2.80em %}

<hr>

- [000064 Минирепозитории gists](https://gist.github.com/Circiter/)
- [0000C8 Учётная запись на <img src="/public/images/github-mark.png" />GitHub](https://github.com/Circiter)
- [00012C Электронная почта](mailto:xcirciter@gmail.com)
