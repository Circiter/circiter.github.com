---
layout: post
title: "Проверочное сообщение"
test: true
tags: тестирование meta
---

1. list item 1
2. list item 2

   text
3. list item 3

-----------

1. list item 1
   
   text
2. list item 2
   
   text 2
3. list item 3

--------------

<<Кавычки>>

* <<кавычки>>

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

Заготовка сверхрегенеративного приемника на основе генератора Хартли:

{% tex block %}
\def\CalcC(#1){\coordinate (base) at (#1.base);
\coordinate (collector) at (#1.collector);
\coordinate (emitter) at (#1.emitter);
\draw (barycentric cs:base=0.32,collector=0.5,emitter=0.5) circle [radius=14pt];
}
\begin{circuitikz}[bigL/.style={L,bipoles/length=2cm}]
    \draw (0,0) node[inner sep=0](B2){} to[bigL] (0,2) node[inner sep=0](B1){};
    \draw (B2|-,|-B2) ++(-0.1,0.6) to[short] ++(-0.5,0) -- ++(0,-0.5) node[ground]{};
    \draw (B2) -- (1,|-B2) to[vC,*-*] (1,|-B1) -- (B1);
    \draw (1,|-B1) to[C] ++(0,1) node[antenna] {};
    \draw (2,|-B1) node[pnp,yscale=-1,anchor=C,rotate=-90] (VT1) {} (VT1.collector);
    \CalcC(VT1);
    \draw (1,|-B1) -- (2,|-B1) -- (VT1.C);
    \draw (1,|-B2) -- (VT1.B|-B2) -- (VT1.B);
    \draw (VT1.E) -- (4,|-VT1.E) to[C,*-] ++(0,-1) node[ground](){};
    \draw (4,|-VT1.E) to[R,-o] (6,|-VT1.E);
    \draw (4,|-VT1.E) to[C,-o] ++(0,1);
\end{circuitikz}
{% endtex %}

Соответствующий код:

{% highlight latex %}
{% raw %}
\def\CalcC(#1){%
\coordinate (base) at (#1.base);
\coordinate (collector) at (#1.collector);
\coordinate (emitter) at (#1.emitter);
\draw (barycentric cs:base=0.32,collector=0.5,emitter=0.5) circle [radius=14pt];
}
\begin{circuitikz}[bigL/.style={L,bipoles/length=2cm}]
    \draw (0,0) node[inner sep=0](B2){} to[bigL] (0,2) node[inner sep=0](B1){};
    \draw (B2|-,|-B2) ++(-0.1,0.6) to[short] ++(-0.5,0) -- ++(0,-0.5) node[ground]{};
    \draw (B2) -- (1,|-B2) to[vC,*-*] (1,|-B1) -- (B1);
    \draw (1,|-B1) to[C] ++(0,1) node[antenna] {};
    \draw (2,|-B1) node[pnp,yscale=-1,anchor=C,rotate=-90] (VT1) {} (VT1.collector);
    \CalcC(VT1);
    \draw (1,|-B1) -- (2,|-B1) -- (VT1.C);
    \draw (1,|-B2) -- (VT1.B|-B2) -- (VT1.B);
    \draw (VT1.E) -- (4,|-VT1.E) to[C,*-] ++(0,-1) node[ground](){};
    \draw (4,|-VT1.E) to[R,-o] (6,|-VT1.E);
    \draw (4,|-VT1.E) to[C,-o] ++(0,1);
\end{circuitikz}
{% endraw %}
{% endhighlight %}

{% tex block %}
{% raw %}
\LaTeX
{% endraw %}
{% endtex %}
