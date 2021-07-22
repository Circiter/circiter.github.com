---
layout: post
title: "Проверка нумерации объектов"
test: true
abstract: Аннотация с формулой: $x\neq y$.
          И абзацами.
          
          Второй абзац.
---

# Тестирование плагина `numbered-labels.rb`

**Теорема {% def theorem non-connected-pairs-in-five-graph %}.**

В планарном пятивершинном графе найдётся пара несмежных вершин.

**Доказательство.**

Допустим несмежных вершин нет. Максимальный полный планарный граф есть $K_4$. Противоречие. 
Следовательно, пятивершинный планарный граф не может быть полным и в нём найдется пара вершин, 
не соединённых ребром. $\blacksquare$

--------

Я использовал теорему {% ref theorem non-connected-pairs-in-five-graph %} при попытке 
альтернативного самостоятельного доказательства теоремы о четырёх красках.

-------

{% begin_sentence %}
**Теорема {% def theorem pythagor %} (теорема Пифагора).**

В прямоугольном треугольнике, квадрат гипотенузы равен сумме квадратов катетов.
{% end_sentence %}

Теорема Пифагора озвучена в теореме {% ref theorem pythagor %}.

# Тестирование пространства имён `figure`

![](/public/images/rxtx1.jpg)
Рисунок {% def figure cb-rxtx %} -- приёмопередатчик.

Простой СиБи-приёмопередатчик изображён на рисунке {% ref figure cb-rxtx %}.

# Тестирование ссылок, ведущих на объекты/метки, определённые позже

Самодельный вариометр показан на рисунке {% ref figure variometer %}.

![](/public/images/variometer.jpg)
Рисунок {% def figure variometer %} -- переменная катушка индуктивности.

# Нумерация формул

$$
\int x^2\mathrm{d}x=\frac13x^3+C.\eqno({% def eq integral %})
$$

Интеграл квадрата показан в $({% ref eq integral %})$.

## Нумерация с помощью штатных средств $\mbox{\LaTeX}$.

{% tex block %}
\begin{equation}
    \label{eq:trigonometry}
    \forall\alpha\ (\sin\alpha)^2+(\cos\alpha)^2=1
\end{equation}
{% endtex %}

Основное тригонометрическое тождество показано в $(\ref{eq:trigonometry})$.

-----------------

См. формулу $(\ref{eq:derivative})$ ниже.

{% tex block %}
\begin{equation}
    \label{eq:derivative}
    \frac{\mathrm{d}}{\mathrm{d}x}f(x)=
        \lim_{\triangle x\to 0}\frac{f(x+\triangle x)-f(x)}{\triangle x}
\end{equation}
{% endtex %}

Формула $(\ref{eq:derivative})$ расположена выше.

Ещё одно уравнение $(\ref{eq:other_eq})$ для режима `simple_numbering`.

$$\label{eq:other_eq}\nabla f=0.$$

Ещё упоминание: $\eqref{eq:other_eq}$.

## Возможные проблемы:

$$\label{eq:suspicious0}x\neq y.$$

$$\label{eq:suspicious1}y\neq z,
z\neq w.$$

Ссылки на $\eqref{eq:suspicious0}$ и $\eqref{eq:suspicious}$.
