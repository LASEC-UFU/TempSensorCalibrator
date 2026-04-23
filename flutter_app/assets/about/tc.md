# Sobre — Termopares

Um **termopar** é um sensor formado pela junção de **dois metais distintos**. A diferença de temperatura entre a **junção quente** (medida) e a **junção fria** (referência) gera uma **força eletromotriz (FEM)** proporcional à diferença de temperatura — o **efeito Seebeck**.

$$
E \;=\; \int_{T_{\text{fria}}}^{T_{\text{quente}}} \!\!\big(S_A(T) - S_B(T)\big)\,dT
$$

onde $S_A$ e $S_B$ são os coeficientes de Seebeck dos dois metais.

---

## 1. Tipos suportados

| Tipo | Composição                | Faixa típica         | Sensibilidade |
|:----:|---------------------------|----------------------|--------------:|
| **K** | Chromel / Alumel          | -200 a +1372 °C      | ~41 µV/°C     |
| **J** | Ferro / Constantan        | -210 a +1200 °C      | ~52 µV/°C     |
| **T** | Cobre / Constantan        | -270 a +400 °C       | ~43 µV/°C     |
| **E** | Chromel / Constantan      | -270 a +1000 °C      | ~68 µV/°C     |
| **N** | Nicrosil / Nisil          | -270 a +1300 °C      | ~39 µV/°C     |
| **S** | Pt-10%Rh / Pt             | -50 a +1768 °C       | ~10 µV/°C     |
| **R** | Pt-13%Rh / Pt             | -50 a +1768 °C       | ~12 µV/°C     |
| **B** | Pt-30%Rh / Pt-6%Rh        | +50 a +1820 °C       | ~10 µV/°C     |

---

## 2. Modelo polinomial (NIST ITS-90)

A norma **NIST ITS-90** descreve a relação $E(T)$ de cada tipo por um polinômio:

$$
E(T) \;=\; \sum_{i=0}^{n} c_i\,T^{i}
\;=\; c_0 + c_1 T + c_2 T^{2} + \dots + c_n T^{n}
$$

Neste aplicativo o ajuste é de **grau 4**:

$$
E(T) \;=\; c_0 + c_1 T + c_2 T^{2} + c_3 T^{3} + c_4 T^{4}
$$

com **mínimos quadrados** sobre $N \ge 5$ pontos:

$$
\big(X^{T} X\big)\,\mathbf{c} \;=\; X^{T}\,\mathbf{E},
\qquad
X_{ij} = T_i^{\,j}
$$

A conversão inversa $E \rightarrow T$ é feita por **Newton–Raphson**.

> Os pontos default carregados em cada tipo provêm das **tabelas oficiais NIST** para a faixa típica de uso.

---

## 3. Compensação da junção fria

Em uma medida real, é necessário **compensar a junção fria** (CJC). A FEM medida é:

$$
E_{\text{med}} \;=\; E(T_{\text{quente}}) - E(T_{\text{fria}})
$$

Conhecendo $T_{\text{fria}}$ (sensor auxiliar), recupera-se $E(T_{\text{quente}})$ e a temperatura é obtida invertendo o polinômio.

---

## 4. Como usar este módulo

1. Selecione o **tipo** de termopar no menu lateral (K, J, T, E, N, S, R, B).
2. Os pontos default já estão carregados — edite-os com seus dados de calibração ou adicione novos.
3. Clique em **Calcular**: os coeficientes $c_0 \dots c_4$ são exibidos.
4. O gráfico mostra a curva ajustada e os pontos medidos.
5. A **calculadora** faz $T \rightarrow E\,(\text{mV})$ e $E\,(\text{mV}) \rightarrow T$.
