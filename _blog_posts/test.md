---
layout: post
title: "Проверочное сообщение"
test: true
---

Inline formula: $\frac{d}{dx}x^2=2x$.

Block formula: $$y(t)=\int\limits_{-\infty}^\infty x(\xi-t)h(\xi)\mathrm{d}\xi.$$

Another inline formula: {% tex inline %}$$y(t)=\int_{-\infty}^\infty 
x(\tau-t)h(\tau)\mathrm{d}\tau.$${% endtex %}

Block of latex code: {% tex block %}
\begin{tikzpicture}
    \draw (0,0) -- (2,1) arc (90:-90:.5) -- cycle;
\end{tikzpicture}
{% endtex %}

Another block:

{% tex block %}
\LaTeX
{% endtex %}

Circuitikz test:

{% tex block %}
\begin{circuitikz}
    \draw (0,0) node[npn] (VT1) {};
    \draw (VT1.emitter) to[R=$R1$] ++(0,-3) node[ground]{};
\end{circuitikz}
{% endtex %}
