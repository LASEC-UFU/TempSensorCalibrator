# Sobre — RTD (Pt100 / Pt1000)

Os **RTDs** (*Resistance Temperature Detectors*) são sensores cuja resistência elétrica varia de forma **quase linear** com a temperatura. Os mais comuns são os de **platina**, designados pela resistência nominal a 0 °C: **Pt100** ($R_0 = 100\ \Omega$) e **Pt1000** ($R_0 = 1000\ \Omega$).

Características:

- Excelente **estabilidade** e **repetibilidade**.
- Faixa típica: **-200 °C a +850 °C**.
- Precisão padrão: classes A ($\pm 0{,}15\ ^\circ\text{C}$) e B ($\pm 0{,}30\ ^\circ\text{C}$) a 0 °C (IEC 60751).

---

## 1. Equação de Callendar–Van Dusen

Para temperaturas **acima de 0 °C**:

$$
R(T) \;=\; R_0 \,\big(1 + A\,T + B\,T^{2} + C\,T^{3}\big)
$$

onde:

- $R_0$ é a resistência a 0 °C (parâmetro fixo do sensor);
- $A, B, C$ são os coeficientes ajustados;
- $T$ é a temperatura em °C.

Para a Pt100 padrão (IEC 60751), os valores nominais são:

$$
A \approx 3{,}9083\!\times\!10^{-3},\quad
B \approx -5{,}775\!\times\!10^{-7},\quad
C \approx 0
$$

---

## 2. Ajuste por Mínimos Quadrados

Dados $N \ge 3$ pares $(T_i,\ R_i)$, definimos $y_i = \dfrac{R_i}{R_0} - 1$ e resolvemos o sistema sobredeterminado:

$$
\underbrace{\begin{bmatrix}
T_1 & T_1^{2} & T_1^{3} \\
T_2 & T_2^{2} & T_2^{3} \\
\vdots & \vdots & \vdots \\
T_N & T_N^{2} & T_N^{3}
\end{bmatrix}}_{X}
\begin{bmatrix} A \\ B \\ C \end{bmatrix}
\;=\;
\begin{bmatrix} y_1 \\ y_2 \\ \vdots \\ y_N \end{bmatrix}
$$

via **equações normais**:

$$
\big(X^{T} X\big)\,\mathbf{c} \;=\; X^{T}\,\mathbf{y}
$$

A inversão $R \rightarrow T$ é feita por **Newton–Raphson**.

---

## 3. Como usar este módulo

1. Defina $R_0$ implicitamente pelo seu sensor (Pt100 = 100 Ω).
2. Insira **3 ou mais** pares $(T,\ R)$ — quanto mais pontos, melhor o ajuste por mínimos quadrados.
3. Clique em **Calcular**: os coeficientes $A$, $B$, $C$ aparecem ao lado.
4. O gráfico mostra a curva ajustada e os pontos medidos.
5. Use a **calculadora** para conversões $T \leftrightarrow R$.
