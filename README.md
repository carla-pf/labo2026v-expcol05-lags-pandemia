# labo2026v-expcol05-lags-pandemia

Experimento colaborativo #05, Grupo A: **lags y pandemia**.
Laboratorio de Implementación I, Maestría en Ciencia de Datos, Universidad Austral, 2026.

Integrantes: Ian Herrera · Carla Pérez Fernández

> Estado: diseño aprobado por el profesor el 27/10/2026. Corridas en curso.

## Hipótesis

Excluir los meses de pandemia del entrenamiento no elimina su información, porque los lags de los meses posteriores la reintroducen. Anular esos lags aumenta la ganancia respecto de solo excluir los meses.

## Diseño

Base: workflow `z620_WorkFlow_01_junior_grupoA` de la cátedra, con una corrección igual en los 10 experimentos: `param_final` se arma con `modifyList()` en vez de `c()`. Con `c()` quedaban repetidos num_leaves, min_data_in_leaf y feature_fraction, y el modelo final usaba los valores fijos (64 / 128 / 0,5) en vez de los que eligió el grid.

| Aspecto | Nombre | Qué es |
|---|---|---|
| Configuración | C1 | Base: el workflow con la corrección, sin excluir meses |
| | C2 | Excluye los meses de pandemia y deja los lags como están |
| | C3 | Excluye los meses de pandemia y pone en NA los lags y delta lags que apuntan a ellos |
| Lags | L1 | Familia 1: lags 1 y 2 (la del workflow) |
| | L2 | Familia 2: lags 1, 2, 3, 6 y 12 |
| Pandemia | R | Restringida: 202003–202007 |
| | A | Amplia: 202003–202010, ASPO en el AMBA |

Períodos, iguales en todos los experimentos: training 201901–202105, validación 202107, entrenamiento final 201901–202107, future 202109.

### Los 10 experimentos

| Prioridad | Código | Lags | Configuración | Pandemia |
|---|---|---|---|---|
| 1 | 5100 | L1 | C1 base | — |
| 1 | 5111 | L1 | C2 | R |
| 1 | 5121 | L1 | C3 | R |
| 2 | 5200 | L2 | C1 base | — |
| 2 | 5211 | L2 | C2 | R |
| 2 | 5221 | L2 | C3 | R |
| 3 | 5112 | L1 | C2 | A |
| 3 | 5122 | L1 | C3 | A |
| 3 | 5212 | L2 | C2 | A |
| 3 | 5222 | L2 | C3 | A |

Cómo se lee el código: 5 (problema) · lags 1–2 · configuración 0–2 (0 = C1, 1 = C2, 2 = C3) · pandemia 0–2 (0 = base, 1 = R, 2 = A). Por ejemplo, 5121 = L1 · C3 · R.

Las corridas piloto del 24/10 figuran en la bitácora como 5001: se hicieron con la z620 antes de la corrección de `param_final` y no entran en el análisis.

### Protocolo

1. Grid search una vez por experimento, con la semilla 629903.
2. Entrenamiento final con cada una de las 10 semillas.
3. 10 cortes de envío por semilla, de 1500 a 2400 de a 100: 100 submits por experimento.
4. Ganancia: promedio del Public Score de los cortes, por semilla.
5. Comparación principal: C3 contra C2, con test de Wilcoxon pareado por semilla. Secundarias: cada configuración contra la base.

## Estructura del repositorio

```
(raíz)            un notebook por experimento: la copia del z620 sin la z,
                  con el número de experimento adelante
                  (por ejemplo, 5100_620_WorkFlow_01_junior_grupoA.ipynb).
                  Los 10 tienen el mismo código; solo cambia PARAM$experimento,
                  y de ese número salen los lags, la configuración y la pandemia.
salidas/<código>/ salidas chicas de cada experimento: modelo.txt,
                  log del grid search y ganancia por semilla y corte
resultados/       tabla consolidada de ganancias, test de Wilcoxon y gráficos
exploracion/      exploración previa de las variables de canales
```

Las carpetas `salidas/`, `resultados/` y `exploracion/` se agregan a medida que haya resultados.

## Archivos para Kaggle

No se suben al repositorio: son 100 por experimento. Quedan en la VM de quien corrió el experimento, en `/content/buckets/b1/exp/WF<código>/kaggle/`.

Nombre de cada archivo: `KA<código>_<semilla>_<corte>.csv`, por ejemplo `KA5111_384841_1800.csv`. En Kaggle, la descripción de cada envío dice `exp=<código> semilla=<semilla> envios=<corte>`.

## Cómo replicar

[Pendiente: orden de los notebooks, parámetros y cómo partir del dataset de la competencia.]

## Enlaces

- Slides del experimento: [link pendiente]
- Bitácora: [link pendiente]
