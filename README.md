# labo2026v-expcol05-lags-pandemia

Experimento colaborativo #05, Grupo A: **lags y pandemia**.
Laboratorio de Implementación I, Maestría en Ciencia de Datos, Universidad Austral, 2026.

Integrantes: Ian Herrera · Carla Pérez Fernández

> Estado (8/11/2026): **terminado**. Los 10 experimentos tienen sus 10 semillas corridas y subidas a Kaggle, más el chequeo de sensibilidad de la grilla (45112 y 45122): 120 corridas y 820 envíos a Kaggle. El análisis está en `analisis_expcol05.R` y sus salidas, en `resultados/`.

## Hipótesis

Excluir los meses de pandemia del entrenamiento no elimina su información, porque los lags de los meses posteriores la reintroducen. Anular esos lags aumenta la ganancia respecto de solo excluir los meses.

## Diseño

Base: workflow `z620_WorkFlow_01_junior_grupoA` de la cátedra, con una corrección igual en todos los experimentos: `param_final` se arma con `modifyList()` en vez de `c()`. Con `c()` quedaban repetidos num_leaves, min_data_in_leaf y feature_fraction, y el modelo final usaba los valores fijos (64 / 128 / 0,5) en vez de los que eligió el grid.

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

### Los experimentos

| Prioridad | Código | Lags | Configuración | Pandemia | Semillas | Envíos a Kaggle | Corrió |
|---|---|---|---|---|---|---|---|
| 1 | 5100 | L1 | C1 base | — | 10 | 100 (10 cortes) | Carla |
| 1 | 5111 | L1 | C2 | R | 10 | 100 (10 cortes) | Ian |
| 1 | 5121 | L1 | C3 | R | 10 | 50 | Ian |
| 2 | 5200 | L2 | C1 base | — | 10 | 80 | Carla |
| 2 | 5211 | L2 | C2 | R | 10 | 80 | Carla (Ian había corrido 4 semillas; ver Reproducibilidad) |
| 2 | 5221 | L2 | C3 | R | 10 | 80 | Carla |
| 3 | 5112 | L1 | C2 | A | 10 | 50 | Gustavo Denicolay (subió Carla) |
| 3 | 5122 | L1 | C3 | A | 10 | 50 | Gustavo Denicolay (subió Carla) |
| 3 | 5212 | L2 | C2 | A | 10 | 50 | Gustavo Denicolay (subió Carla) |
| 3 | 5222 | L2 | C3 | A | 10 | 80 | Gustavo Denicolay (subió Carla) |
| Sensibilidad | 45112 | L1 | C2 | A | 10 | 50 | Carla |
| Sensibilidad | 45122 | L1 | C3 | A | 10 | 50 | Carla |

Cómo se lee el código: 5 (problema) · lags 1–2 · configuración 0–2 (0 = C1, 1 = C2, 2 = C3) · pandemia 0–2 (0 = base, 1 = R, 2 = A). Por ejemplo, 5121 = L1 · C3 · R. El notebook lee la configuración de las tres últimas cifras. El 4 adelante (45112, 45122) marca el chequeo de sensibilidad: el mismo experimento con la grilla ampliada.

Las corridas piloto del 24/10 figuran en la bitácora como 5001, y la 5100 del 27/10 se hizo con el protocolo anterior: ninguna de las dos entra en el análisis. Además, para las 10 semillas de la 5100 se subió un corte de prueba de 1400 envíos (`generar_corte.py`), que tampoco entra en la métrica.

### Protocolo

1. El notebook se corre entero una vez por semilla (`correr_experimento.sh`): grid search con esa semilla y entrenamiento final con la misma semilla.
2. Grilla (v3): num_leaves {32, 64, 128, 256, 384, 512, 768, 1024} × min_data_in_leaf {64, 256, 512, 1024, 2048} × feature_fraction {0,5, 0,8} = 80 combinaciones. El notebook registra si el mejor valor quedó en el borde de la grilla.
3. Las mismas 10 semillas en todos los experimentos: 629903, 333331, 121229, 983209, 100169, 384841, 612511, 693809, 761681, 981653.
4. El notebook genera 10 cortes de envío por semilla (1500 a 2400 de a 100). A Kaggle se suben 5: **1500, 1600, 1700, 2000 y 2200**, elegidos con las 20 corridas de 5100 y 5111 subidas completas (tienen el máximo en 17 de 20). En L2 se suben además 1800, 2100 y 2400 como cortes de control, que no entran en la métrica.
5. Ganancia de cada corrida: el máximo del Public Score entre los 5 cortes (indicación de la cátedra, 27/10).
6. Comparación principal: C3 contra C2, con test de Wilcoxon pareado por semilla. Secundarias: cada configuración contra la base. Ajuste de Holm por comparaciones múltiples dentro de cada familia. El p del Wilcoxon es exacto: se enumeran las 1024 asignaciones de signo, porque con diferencias empatadas `wilcox.test()` de R pasa a la aproximación normal.

Los cambios al protocolo durante el experimento (con fecha, quién y para qué) están en la hoja Cambios de la bitácora, exportada como `resultados/cambios_protocolo.csv`.

## Resultados

Ganancia de cada experimento: media de las 10 semillas (desvío entre semillas), en millones; cada semilla aporta el máximo del Public entre los 5 cortes.

| Lags | Base | C2 · R | C3 · R | C2 · A | C3 · A |
|---|---|---|---|---|---|
| L1 (1, 2) | 87,93 (2,3) | 88,41 (2,3) | 88,37 (3,4) | 87,28 (2,9) | 89,55 (2,5) |
| L2 (1, 2, 3, 6, 12) | 82,33 (2,7) | 85,26 (2,7) | 84,59 (2,9) | 83,86 (2,8) | 85,35 (4,0) |

**Comparación principal, C3 contra C2** (diferencia media C3 − C2, semillas en que gana C3, p exacto, p ajustado por Holm):

| | Diferencia (M) | Gana C3 | p | p Holm |
|---|---|---|---|---|
| L1 · R (5121 − 5111) | −0,05 | 4 de 10 | 0,77 | 1 |
| L1 · A (5122 − 5112) | +2,28 | 7 de 10 | 0,064 | 0,26 |
| L2 · R (5221 − 5211) | −0,67 | 4 de 10 | 0,63 | 1 |
| L2 · A (5222 − 5212) | +1,49 | 7 de 10 | 0,16 | 0,48 |

Ninguna comparación principal es significativa. Con la pandemia amplia, C3 supera a C2 en 7 de 10 semillas en las dos familias de lags; con la restringida, no.

**Secundarias, contra la base:** las únicas con p < 0,05 son en L2: C2 · R (5211 − 5200: +2,93 M, 9 de 10, p = 0,037) y C3 · A (5222 − 5200: +3,02 M, 8 de 10, p = 0,037). Ninguna sobrevive al ajuste de Holm (p = 0,30).

**Exploratoria, familia L1 contra L2** (no estaba en la hipótesis): con la misma configuración, L1 gana más que L2 en las cinco columnas, entre 3,2 y 5,6 M. En la base, L1 gana en 10 de 10 semillas (p = 0,002). Con Holm sobre las cinco comparaciones, quedan por debajo de 0,05 cuatro de cinco (todas menos C3 · R, p = 0,084).

La tabla completa, con medianas y empates, está en `resultados/comparaciones.csv`; la salida del script, en `resultados/salida_analisis.txt`.

### Chequeo de sensibilidad de la grilla

En 28 de las 100 corridas con la grilla v3, algún hiperparámetro quedó en el borde (sobre todo min_data_in_leaf en 2048). Para ver si eso cambia la conclusión, 45112 y 45122 repiten 5112 y 5122 (L1 · C2 y C3 · pandemia amplia) con la grilla ampliada para los dos lados: num_leaves {16, …, 1536} y min_data_in_leaf {32, …, 4096}, 140 combinaciones, mismas 10 semillas y mismos 5 cortes. Se eligió ese par porque es donde aparece la diferencia entre C3 y C2 y donde los bordes caían sobre C2.

Resultado: en 45122 las 10 semillas eligieron los mismos hiperparámetros que en 5122; en 45112, 9 de 10. De las 4 semillas de 5112 que estaban en el borde, 3 eligieron el mismo valor aun pudiendo ir más lejos. La diferencia C3 − C2 queda igual: +2,28 M con la grilla v3 y +2,22 M con la ampliada, C3 gana en 7 de 10 semillas en los dos casos, Wilcoxon p = 0,064 en los dos. El borde de la grilla no cambia la conclusión en ese par; los bordes de L2 no se probaron.

### Reproducibilidad

- Las 4 semillas de la 5211 que había corrido Ian (629903, 333331, 121229 y 983209) dan exactamente los mismos scores en la corrida completa de Carla: 32 de 32 envíos idénticos, incluidos los cortes de control.
- 45122 reproduce exactamente la 5122 que corrió Gustavo en su hardware (las 10 semillas eligieron los mismos hiperparámetros y dan los mismos 50 scores).

Con el mismo notebook y la misma semilla, el resultado es el mismo en máquinas y personas distintas.

## Estructura del repositorio

```
(raíz)                   un notebook por experimento: la copia del z620 sin la z,
                         con el número de experimento adelante
                         (por ejemplo, 5100_620_WorkFlow_01_junior_grupoA.ipynb).
                         Los 10 tienen el mismo código; solo cambia PARAM$experimento.
                         45112 y 45122: chequeo de sensibilidad (solo cambia la grilla).
correr_experimento.sh    corre un experimento con las 10 semillas (o con las que se le pasen);
                         si se corta, retoma
subir_kaggle.sh          sube a Kaggle los cortes elegidos, sin repetir envíos
generar_corte.py         arma cortes nuevos desde prediccion.txt sin volver a correr
extraer_grid.py          saca de los PARAM.yml los hiperparámetros que eligió el grid
analisis_expcol05.R      ganancia por semilla, Wilcoxon exacto, sensibilidad y reproducibilidad
resultados/
  corridas.csv           hoja Corridas de la bitácora: un renglón por envío a Kaggle
  grid.csv               hoja Grid: hiperparámetros que eligió el grid en cada semilla
  experimentos.csv       hoja Experimentos: qué es cada código
  cambios_protocolo.csv  hoja Cambios: cambios al notebook y al protocolo, con fecha
  ganancia_por_semilla.csv   salida del análisis: un número por experimento y semilla
  comparaciones.csv      salida del análisis: todas las comparaciones de Wilcoxon
  salida_analisis.txt    lo que imprime el script
```

## Cómo correr

En la VM, con los notebooks y los scripts en `~/buckets/b1/labo2026v/ExpColaborativos/`:

```bash
# un experimento entero
nohup bash correr_experimento.sh 5111 > ~/log_5111.txt 2>&1 &

# o repartido entre dos VMs (cada una con sus semillas)
nohup bash correr_experimento.sh 5211 "629903 333331 121229 983209 100169" > ~/log_5211_a.txt 2>&1 &
nohup bash correr_experimento.sh 5211 "384841 612511 693809 761681 981653" > ~/log_5211_b.txt 2>&1 &

# subir a Kaggle los cortes de la métrica (en L2, agregar 1800 2100 2400)
bash subir_kaggle.sh 5111 "1500 1600 1700 2000 2200"

# hiperparámetros elegidos por el grid
~/.venv/bin/python extraer_grid.py 5111
```

Cada semilla escribe en `~/buckets/b1/exp/WF<código>/s<semilla>/`: `PARAM.yml` (hiperparámetros elegidos y bordes), `tb_grid_search_01.txt`, `modelo.txt`, `impo.txt`, `prediccion.txt` y la carpeta `kaggle/`.

Para el análisis (solo usa R base), desde la raíz del repositorio:

```bash
Rscript analisis_expcol05.R resultados/corridas.csv
```

Vuelve a escribir `resultados/ganancia_por_semilla.csv` y `resultados/comparaciones.csv`.

## Archivos para Kaggle

No se suben al repositorio. Quedan en `~/buckets/b1/exp/WF<código>/s<semilla>/kaggle/`.

Nombre de cada archivo: `KA<código>_<semilla>_<corte>.csv`, por ejemplo `KA5111_384841_1800.csv`. En Kaggle, la descripción de cada envío dice `exp=<código> semilla=<semilla> envios=<corte>`.

Para agregar un corte que no generó el notebook (por ejemplo 1400) sin volver a correr, `generar_corte.py` lo arma desde `prediccion.txt`, igual que el notebook: `python3 generar_corte.py --probar 5100 1500` regenera un corte existente y lo compara con el original; `python3 generar_corte.py 5100 1400` genera el nuevo en la carpeta `kaggle/` de cada semilla.

## Cómo replicar

1. **Dataset.** Cada notebook descarga solo el dataset de la competencia, `analistajr_competencia_2026.csv.gz`, desde `https://storage.googleapis.com/open-courses/austral2026-5da5/labo1/`, si no está en `/content/datasets/`.
2. **Corridas.** Para cada experimento, `correr_experimento.sh <código>` corre el notebook completo con las 10 semillas. Cada semilla deja su `PARAM.yml`, el grid y los 10 cortes en `~/buckets/b1/exp/WF<código>/s<semilla>/`.
3. **Kaggle.** `subir_kaggle.sh <código> "1500 1600 1700 2000 2200"` sube los 5 cortes de la métrica (en L2, además 1800, 2100 y 2400) a la competencia `labo-1-virtual-2026-analista-jr`. Cada Public Score se anota en la hoja Corridas de la bitácora.
4. **Análisis.** `Rscript analisis_expcol05.R resultados/corridas.csv`.

Salidas esperadas: con la misma semilla, el mismo notebook da los mismos hiperparámetros y los mismos scores (ver Reproducibilidad). Los resultados de este experimento están en `resultados/`.

## Enlaces

- Bitácora: https://docs.google.com/spreadsheets/d/1ZHsmXmayEYXfLRdt0v0EbGCLv3adXTMK9p7MZ2rgPKM

- Video (Lags en Debate): https://www.youtube.com/watch?v=0LJtRD2K4mg

