# Sobre — Termistor NTC

Os **NTC (Negative Temperature Coefficient)** são termistores cuja resistência **diminui** com o aumento da temperatura. São amplamente usados em sensores compactos, baratos e de boa sensibilidade na faixa de **-40 °C a +150 °C**.

Este aplicativo ajusta **dois modelos** simultaneamente para o mesmo conjunto de pontos $(T_i, R_i)$ e os exibe sobrepostos no gráfico, permitindo comparar a precisão de cada um.

---

## 1. Modelo de Steinhart–Hart

A equação de **Steinhart–Hart** é a forma mais precisa de descrever a curva $R$–$T$ de um NTC numa faixa ampla:

$$
\frac{1}{T} \;=\; A \;+\; B\,\ln(R) \;+\; C\,\big[\ln(R)\big]^{3}
$$

onde:

- $T$ é a temperatura **absoluta** (Kelvin);
- $R$ é a resistência medida (Ω);
- $A, B, C$ são as constantes ajustadas a partir de **três pontos** de calibração.

Com 3 pares $(T_i, R_i)$ resolve-se o sistema linear $3\times 3$:

$$
\begin{bmatrix}
1 & \ln R_1 & (\ln R_1)^3 \\
1 & \ln R_2 & (\ln R_2)^3 \\
1 & \ln R_3 & (\ln R_3)^3
\end{bmatrix}
\begin{bmatrix} A \\ B \\ C \end{bmatrix}
\;=\;
\begin{bmatrix} 1/T_1 \\ 1/T_2 \\ 1/T_3 \end{bmatrix}
$$

A inversão $R \rightarrow T$ é direta, e $T \rightarrow R$ é obtida por **Newton–Raphson** sobre $u = \ln R$.

> Erro típico: **< 0,02 °C** dentro da faixa calibrada.

---

## 2. Modelo β (Beta) / R25

O **modelo β** é uma simplificação muito usada em datasheets:

$$
R(T) \;=\; R_{25}\,\exp\!\left[\,\beta\left(\frac{1}{T} - \frac{1}{T_{25}}\right)\right]
$$

onde:

- $R_{25}$ é a resistência a $T_{25} = 298{,}15\ \text{K}$ (25 °C);
- $\beta$ é uma constante característica do material (tipicamente **3000 – 4500 K**);
- $T$ em Kelvin.

A partir de dois pontos $(T_1, R_1)$ e $(T_2, R_2)$:

$$
\beta \;=\; \frac{\ln(R_1 / R_2)}{\dfrac{1}{T_1} - \dfrac{1}{T_2}}
$$

> Mais simples, porém menos preciso fora da vizinhança de $T_{25}$.

---

## 3. Como usar este módulo

1. Insira no painel direito **três pares** $(T_i,\ R_i)$ — temperatura em °C e resistência em Ω.
2. Clique em **Calcular**. Os coeficientes $A$, $B$, $C$, $\beta$ e $R_{25}$ aparecem no painel.
3. O gráfico exibe **as duas curvas** sobrepostas (Steinhart–Hart sólida, β tracejada) junto dos pontos medidos.
4. Use a **calculadora** para conversões pontuais $T \leftrightarrow R$.
