---
layout: post
title: "Инопланетный календарь. :)"
xdate: "ноябрь, 2021"
sig: false
toc: false
test: true
tags: календарь
---

$d$ -- день недели
$y$ -- год
$x$ -- продолжительность невисокосного года
каждый $v$ год -- високосный
недели имеют стандартную продолжительность в 7 дней.

Если все годы имеют одинаковую продолжительность, то, очевидно, до года $y$ с начала времён, 
т.е. с нулевого года, пройдёт $xy$ дней. Но, т.к. каждый $v$ год добавляется 1 лишний день, то 
всего дополнительных дней до года $y$ будет $\lfrac y/v\rfrac$, а всего дней пройдёт 
$xy+\lfrac y/v\rfrac$. Тогда день недели, на который будет приходится 1 января года $y$ равен 
остатку от деления общего количества дней на продолжительность недели; другими словами, день 
недели, --- т.е. число $d$, --- удовлетворяет сравнению $$d\equiv xy+\lfloor y/v\rfloor\pmod 
7.\label{eq-day-of-week}$$

Попытка найти распределение "первых январёв" по дням недели для некоторых частных случаев (т.е. 
для некоторых значений $v$, $x$ и $y$) приводит к следующему предположению, подлежащему 
последующему доказательству.

Гипотеза: $n=14=\operatorname{const}$.

Набросок доказательства:

I.

- База индукции: если $x\equiv 0\pmod 7$, то $d\equiv xy+\lfloor y/v\rfloor\pmod 7$ пробегает 
все значения для произвольного $z$, такого, что $y\equiv z\pmod 7$.

если $x\equiv 0\pmod 7$, то первое слагаемое ($xy$) в правой части сравнения 
$\eqref{eq-day-of-week}$ может быть исключено и получается $d\equiv\lfloor y/v\rfloor\pmod 7$.

Для произвольного $z$, такого, что $y\equiv z\pmod v$, выражение $\lfloor y/v\rfloor$ пробегает 
все значения из $\mathbb{N}$ (но не биективно), поэтому $\forall d \exist y\ d\equiv\lfloor 
y/v\rfloor\pmod 7$.

$y\equiv v-1\pmod v$ -- признак високосности года $y$.

(Т.к. для любого високосного года ($z=v-1$), $d$ пробегает все 7 значений, и для каждого 
невисокосного года ($z\neq v-1$), $d$ тоже пробегает все 7 значений, то $n=14$.)

- Предположение индукции: $x\equiv m\pmod 7$ и $d\equiv xy+\lfloor y/v\rfloor\pmod 7$ пробегает 
все значения при произвольном $z$, таком, что $y\equiv z\pmod v$. (FIXME.)

- Шаг индукции: Требуется показать, что если $x\equiv m+1 \pmod 7$, то $d\equiv xy+\lfloor 
y/v\rfloor$ пробегает все значения при произвольном $z$.

$x\equiv m+1\pmod 7$

$d\equiv xy+\lfloor y/v\rfloor\pmod 7$

$x=7w+m+1$

$d\equiv 7wy+my+y+\lfloor y/v\rfloor\pmod 7$

(слагаемое $7wy$ можно выбросить из-за кратности модулю)

$d\equiv my+y+\lfloor y/v\rfloor\pmod 7$

$d\equiv (m+1)y+\lfloor y/v\rfloor\pmod 7$

$y\equiv y'\pmod 7$

$y'\equiv y\pmod 7$

$$d-y'\equiv my+\lfloor y/v\rfloor\pmod 7.\label{eq-from-inductive-step}$$

II.

(вспомогательное утверждение: $$\left\{\begin{aligned}d\equiv xy\pmod 
7\\x\equiv m\pmod 7\end{aligned}\right.\Rightarrow d\equiv my\pmod 7.$$ Действительно, 
$d=7d'+xy$ и $x=7x'+m$ подстановка выражения для $x$ даёт $d=7d'+(7x'+m)y = 
7d'+7x'y+my=7(d'+x'y)+my$, но это итоговое выражение, будучи переписанным в терминах сравнений, 
как раз и будет выглядеть как $d\equiv my\pmod 7$.)

$d\equiv xy+\lfloor y/v\rfloor\pmod 7$

$$x\equiv m\pmod z
\Rightarrow d\equiv\lfloor y/v\rfloor\pmod 7.\label{eq-inductive-hypothesis-consequence}$$

по предположению индукции $d$ в $\eqref{eq-inductive-hypothesis-consequence}$ пробегает все 
значения.

Сопоставление $\eqref{eq-from-inductive-hypothesis}$ с 
$\eqref{eq-inductive-hypothesis-consequence}$ приводит к выводу о том, что $d$ в 
$\eqref{eq-from-inductive-hypothesis}$ тоже пробегает все значения.

III.

$d-z\equiv\lfloor y/v\rfloor\pmod 7$

утверждается, что если $d-z$ пробегает все значения, то и $d$ пробегает все значения (из $[0; 
7[$).

$d_i-z\equiv i\pmod 7$

$d_i-z=7w_i+i, где i, z\in[0; 7[$.

Т.к. $\forall u \exists i\ u\equiv i\pmod 7$, то $\forall d' \exists i\ d'-z\equiv i\pmod 7$.
