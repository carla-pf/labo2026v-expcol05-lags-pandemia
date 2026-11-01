# labo2026v-expcol05-lags-pandemia

Experimento colaborativo #05, Grupo A: **lags y pandemia**.
Laboratorio de Implementación I, Maestría en Ciencia de Datos, Universidad Austral, 2026.

Integrantes: Ian Herrera · Carla Pérez Fernández

> Estado (1/11/2026): diseño aprobado el 27/10 y protocolo corregido el mismo día a pedido del profesor. Corridas terminadas en 9 de los 10 experimentos (la 5211 termina el 1/11). Chequeo de sensibilidad de la grilla en curso.

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

### Los 10 experimentos

| Prioridad | Código | Lags | Configuración | Pandemia | Corrió |
|---|---|---|---|---|---|
| 1 | 5100 | L1 | C1 base | — | Carla |
| 1 | 5111 | L1 | C2 | R | Ian |
| 1 | 5121 | L1 | C3 | R | Ian |
| 2 | 5200 | L2 | C1 base | — | Carla |
| 2 | 5211 | L2 | C2 | R | Ian |
| 2 | 5221 | L2 | C3 | R | Carla |
| 3 | 5112 | L1 | C2 | A | Gustavo Denicolay |
| 3 | 5122 | L1 | C3 | A | Gustavo Denicolay |
| 3 | 5212 | L2 | C2 | A | Gustavo Denicolay |
| 3 | 5222 | L2 | C3 | A | Gustavo Denicolay |

Cómo se lee el código: 5 (problema) · lags 1–2 · configuración 0–2 (0 = C1, 1 = C2, 2 = C3) · pandemia 0–2 (0 = base, 1 = R, 2 = A). Por ejemplo, 5121 = L1 · C3 · R. El notebook lee la configuración de las tres últimas cifras.

Las corridas piloto del 24/10 figuran en la bitácora como 5001, y la 5100 del 27/10 se hizo con el protocolo anterior: ninguna de las dos entra en el análisis.

### Protocolo

1. El notebook se corre entero una vez por semilla (`correr_experimento.sh`): grid search con esa semilla y entrenamiento final con la misma semilla.
2. Grilla (v3): num_leaves {32, 64, 128, 256, 384, 512, 768, 1024} × min_data_in_leaf {64, 256, 512, 1024, 2048} × feature_fraction {0,5, 0,8} = 80 combinaciones. El notebook registra si el mejor valor quedó en el borde de la grilla.
3. Las mismas 10 semillas en todos los experimentos: 629903, 333331, 121229, 983209, 100169, 384841, 612511, 693809, 761681, 981653.
4. El notebook genera 10 cortes de envío por semilla (1500 a 2400 de a 100). A Kaggle se suben 5: **1500, 1600, 1700, 2000 y 2200**, elegidos con las 20 corridas de 5100 y 5111 subidas completas (tienen el máximo en 17 de 20). En L2 se suben además 1800, 2100 y 2400 como cortes de control, que no entran en la métrica.
5. Ganancia de cada corrida: el máximo del Public Score entre los 5 cortes.
6. Comparación principal: C3 contra C2, con test de Wilcoxon pareado por semilla. Secundarias: cada configuración contra la base.

### Chequeo de sensibilidad de la grilla

En 24 de las 90 corridas con la grilla v3, algún hiperparámetro quedó en el borde (sobre todo min_data_in_leaf en 2048). Para ver si eso cambia la conclusión, 45112 y 45122 repiten 5112 y 5122 (L1 · C2 y C3 · pandemia amplia) con la grilla ampliada para los dos lados: num_leaves {16, …, 1536} y min_data_in_leaf {32, …, 4096}, 140 combinaciones, mismas 10 semillas y mismos 5 cortes. Se eligió ese par porque es donde aparece la diferencia entre C3 y C2 y donde los bordes caían sobre C2. Si la diferencia entre C3 y C2 mantiene el sentido, el orden de magnitud y el resultado del Wilcoxon, el borde de la grilla no cambia la conclusión.

## Estructura del repositorio

```
(raíz)                   un notebook por experimento: la copia del z620 sin la z,
                         con el número de experimento adelante
                         (por ejemplo, 5100_620_WorkFlow_01_junior_grupoA.ipynb).
                         Los 10 tienen el mismo código; solo cambia PARAM$experimento.
                         45112 y 45122: chequeo de sensibilidad (solo cambia la grilla).
correr_experimento.sh    corre un experimento con las 10 semillas; si se corta, retoma
subir_kaggle.sh          sube a Kaggle los cortes elegidos, sin repetir envíos
generar_corte.py         arma cortes nuevos desde prediccion.txt sin volver a correr
salidas/<código>/        salidas chicas de cada experimento (a agregar)
resultados/              tabla consolidada de ganancias, Wilcoxon y gráficos (a agregar)
exploracion/             exploración previa de las variables de canales (a agregar)
```

## Cómo correr

En la VM, con los notebooks y los scripts en `~/buckets/b1/labo2026v/ExpColaborativos/`:

```bash
nohup bash correr_experimento.sh 5111 > ~/log_5111.txt 2>&1 &
bash subir_kaggle.sh 5111 "1500 1600 1700 2000 2200"
```

Cada semilla escribe en `~/buckets/b1/exp/WF<código>/s<semilla>/`: `PARAM.yml` (hiperparámetros elegidos y bordes), `tb_grid_search_01.txt`, `modelo.txt`, `impo.txt`, `prediccion.txt` y la carpeta `kaggle/`.

## Archivos para Kaggle

No se suben al repositorio. Quedan en `~/buckets/b1/exp/WF<código>/s<semilla>/kaggle/`.

Nombre de cada archivo: `KA<código>_<semilla>_<corte>.csv`, por ejemplo `KA5111_384841_1800.csv`. En Kaggle, la descripción de cada envío dice `exp=<código> semilla=<semilla> envios=<corte>`.

Para agregar un corte que no generó el notebook (por ejemplo 1400) sin volver a correr, `generar_corte.py` lo arma desde `prediccion.txt`, igual que el notebook: `python3 generar_corte.py --probar 5100 1500` regenera un corte existente y lo compara con el original; `python3 generar_corte.py 5100 1400` genera el nuevo en la carpeta `kaggle/` de cada semilla.

## Cómo replicar

[Pendiente: orden de los notebooks, parámetros y cómo partir del dataset de la competencia.]

## Enlaces

- Slides del experimento: [link pendiente]
- Bitácora: [link pendiente]
