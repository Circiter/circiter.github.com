---
layout: post
title: "Проверочное сообщение"
test: true
---

Inline formula: $\frac{d}{dx}x^2=2x$.

Block formula: $$y(t)=\int_{-\infty}^\infty x(\xi-t)h(\xi)d\xi.$$

Another block formula: {% latex %}\begin{displaymath}y(t)=\int_{-\infty}^\infty x(\tau-t)h(\tau)d\tau.\end{displaymath}{% endlatex %}

Block of latex code:
{% latex %}
\begin{tikzpicture}
    \draw (0,0) -- (2,1) arc (90:-90:.5) -- cycle;
\end{tikzpicture}
{% endlatex %}

Another block:
{% latex %}
\LaTeX
{% endlatex %}
