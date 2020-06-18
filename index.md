---
layout: default
title: Дневник Circiter'а.
---

# circiter.tk || circiter.github.io

Простой публичный дневник (блог).

Сообщения-статьи:
{% assign posts_list = site.blog_posts %}
{% for post in posts_list %}
    {% if post.test == null %}
        {% if post.title != null %}
            {% if post.layout == "post" %}
* [{{ post.title }}]({{ post.url }})
            {% endif %}
        {% endif %}
    {% endif %}
{% endfor %}

<hr>
Облако меток: {% tag_cloud font-size: 0.80 - 1.15em %}

<hr>

- [000064 Минирепозитории gists](https://gist.github.com/Circiter/)
- [0000C8 Учётная запись на ![](/public/images/github-mark.png){:.inline}GitHub](https://github.com/Circiter)
- [00012C Электронная почта](mailto:xcirciter@gmail.com)
