# =============================================================================
# ExpCol #05 - lags y pandemia (Grupo A)
# Analisis final: ganancia por semilla, Wilcoxon, chequeo de sensibilidad y
# chequeo de reproducibilidad.
#
# Entrada: la hoja "Corridas" de la bitacora descargada como CSV
#          (Archivo > Descargar > Valores separados por comas, con la hoja
#          Corridas abierta). Se guarda como corridas.csv al lado de este script.
# Uso:     Rscript analisis_expcol05.R            (lee corridas.csv)
#          Rscript analisis_expcol05.R otro.csv
# Salida:  se imprime en pantalla y se guardan dos tablas en resultados/
#          (ganancia_por_semilla.csv y comparaciones.csv).
# Solo usa R base.
# =============================================================================

options(width = 200)
args    <- commandArgs(trailingOnly = TRUE)
archivo <- if (length(args) > 0) args[1] else "corridas.csv"

CORTES   <- c(1500, 1600, 1700, 2000, 2200)   # los 5 cortes de la metrica
SEMILLAS <- c(629903, 333331, 121229, 983209, 100169,
              384841, 612511, 693809, 761681, 981653)

# ---------------------------------------------------------------- lectura ---
crudo <- read.csv(archivo, check.names = FALSE, colClasses = "character",
                  encoding = "UTF-8")
crudo <- crudo[, 1:8]
names(crudo) <- c("fecha", "experimento", "notebook", "semilla", "quien",
                  "corte", "ganancia", "notas")
crudo <- crudo[crudo$experimento != "", ]

a_numero <- function(x) as.numeric(gsub(",", ".", trimws(x)))   # 89,968 o 89.968
crudo$experimento <- a_numero(crudo$experimento)
crudo$semilla     <- a_numero(crudo$semilla)
crudo$corte       <- a_numero(crudo$corte)
crudo$ganancia    <- a_numero(crudo$ganancia)

# fuera: pilotos, protocolo anterior y cortes de prueba (la nota dice "no entra")
corridas <- crudo[!grepl("no entra", crudo$notas, ignore.case = TRUE), ]
# solo los 5 cortes de la metrica (afuera quedan los cortes de control)
corridas <- corridas[corridas$corte %in% CORTES, ]

cat("Filas leidas:", nrow(crudo), "| filas que entran en la metrica:",
    nrow(corridas), "\n\n")

# ------------------------------------------------- chequeo de reproducibilidad
# Mismo experimento, semilla y corte cargado por dos personas distintas
# (por ejemplo, la 5211 de Ian y la de Carla). Con el mismo codigo y la misma
# semilla, el score tendria que ser identico.
cat("=== Chequeo de reproducibilidad (mismo experimento, semilla y corte,",
    "corrido por distintas personas) ===\n")
clave  <- paste(corridas$experimento, corridas$semilla, corridas$corte)
quienes <- tapply(corridas$quien, clave, function(q) length(unique(q)))
dobles <- names(quienes)[quienes > 1]
if (length(dobles) == 0) {
  cat("No hay corridas repetidas por distintas personas.\n\n")
} else {
  rep <- corridas[clave %in% dobles, c("experimento", "semilla", "corte",
                                       "quien", "ganancia")]
  ancho <- reshape(rep, idvar = c("experimento", "semilla", "corte"),
                   timevar = "quien", direction = "wide")
  cols  <- grep("^ganancia", names(ancho))
  ancho$diferencia <- apply(ancho[, cols], 1, function(v) max(v) - min(v))
  ancho$igual <- ifelse(ancho$diferencia == 0, "SI", "NO")
  ancho <- ancho[order(ancho$experimento, ancho$semilla, ancho$corte), ]
  print(ancho, row.names = FALSE)
  cat("\nIguales:", sum(ancho$igual == "SI"), "de", nrow(ancho), "\n\n")
}

# ------------------------------------------------------ ganancia por semilla
# Si una combinacion esta cargada dos veces (reproducibilidad), se promedia:
# si son iguales, da el mismo valor.
g <- aggregate(ganancia ~ experimento + semilla + corte, data = corridas,
               FUN = mean)
n_cortes <- aggregate(corte ~ experimento + semilla, data = g, FUN = length)
gps      <- aggregate(ganancia ~ experimento + semilla, data = g, FUN = max)
gps      <- merge(gps, n_cortes)
names(gps)[names(gps) == "corte"] <- "cortes"
incompletas <- gps[gps$cortes < length(CORTES), ]
if (nrow(incompletas) > 0) {
  cat("ATENCION: semillas sin los 5 cortes (no entran en las comparaciones):\n")
  print(incompletas, row.names = FALSE)
  cat("\n")
}
gps <- gps[gps$cortes == length(CORTES), c("experimento", "semilla", "ganancia")]

resumen <- do.call(rbind, lapply(split(gps, gps$experimento), function(d)
  data.frame(experimento = d$experimento[1], semillas = nrow(d),
             media = round(mean(d$ganancia), 2),
             desvio = round(sd(d$ganancia), 2),
             minimo = min(d$ganancia), maximo = max(d$ganancia))))
cat("=== Ganancia por experimento (maximo de los 5 cortes, en millones) ===\n")
print(resumen, row.names = FALSE)
cat("\n")

# ---------------------------------------------------------------- Wilcoxon
# Wilcoxon de rangos con signo, pareado, con p exacto aunque haya empates.
# wilcox.test() de R pasa a la aproximacion normal cuando hay diferencias
# empatadas en valor absoluto (y avisa con un warning). Con 10 pares se puede
# enumerar las 2^10 = 1024 asignaciones de signo y calcular el p exacto.
# Las diferencias iguales a cero se descartan, igual que en wilcox.test().
wilcoxon_exacto <- function(d) {
  d <- d[d != 0]
  n <- length(d)
  if (n == 0) return(NA)
  r <- rank(abs(d))                          # rangos promedio si hay empates
  W <- sum(r[d > 0])                         # suma de rangos positivos
  signos <- as.matrix(expand.grid(rep(list(c(0, 1)), n)))
  Ws <- as.vector(signos %*% r)              # W bajo todas las asignaciones
  eps <- 1e-9
  min(1, 2 * min(mean(Ws >= W - eps), mean(Ws <= W + eps)))   # bilateral
}

comparar <- function(a, b, familia, etiqueta) {
  x <- gps[gps$experimento == a, c("semilla", "ganancia")]
  y <- gps[gps$experimento == b, c("semilla", "ganancia")]
  p <- merge(x, y, by = "semilla", suffixes = c("_a", "_b"))
  if (nrow(p) == 0) {
    return(data.frame(familia, comparacion = etiqueta, a, b, pares = 0,
                      dif_media = NA, dif_mediana = NA, gana_a = NA,
                      empates = NA, p_wilcoxon = NA))
  }
  d  <- p$ganancia_a - p$ganancia_b
  pv <- wilcoxon_exacto(d)
  data.frame(familia, comparacion = etiqueta, a, b, pares = nrow(p),
             dif_media = round(mean(d), 3), dif_mediana = round(median(d), 3),
             gana_a = sum(d > 0), empates = sum(d == 0),
             p_wilcoxon = round(pv, 4))
}

pares <- rbind(
  # comparacion principal: C3 contra C2
  c("principal",  "L1 R: C3 vs C2", 5121, 5111),
  c("principal",  "L1 A: C3 vs C2", 5122, 5112),
  c("principal",  "L2 R: C3 vs C2", 5221, 5211),
  c("principal",  "L2 A: C3 vs C2", 5222, 5212),
  # secundarias: cada configuracion contra la base
  c("secundaria", "L1 R: C2 vs base", 5111, 5100),
  c("secundaria", "L1 R: C3 vs base", 5121, 5100),
  c("secundaria", "L1 A: C2 vs base", 5112, 5100),
  c("secundaria", "L1 A: C3 vs base", 5122, 5100),
  c("secundaria", "L2 R: C2 vs base", 5211, 5200),
  c("secundaria", "L2 R: C3 vs base", 5221, 5200),
  c("secundaria", "L2 A: C2 vs base", 5212, 5200),
  c("secundaria", "L2 A: C3 vs base", 5222, 5200),
  # familias de lags: L1 contra L2 con la misma configuracion (exploratoria,
  # no estaba en la hipotesis)
  c("lags", "Base: L1 vs L2",  5100, 5200),
  c("lags", "C2 R: L1 vs L2",  5111, 5211),
  c("lags", "C3 R: L1 vs L2",  5121, 5221),
  c("lags", "C2 A: L1 vs L2",  5112, 5212),
  c("lags", "C3 A: L1 vs L2",  5122, 5222),
  # chequeo de sensibilidad de la grilla
  c("sensibilidad", "L1 A: C3 vs C2, grilla v3",       5122,  5112),
  c("sensibilidad", "L1 A: C3 vs C2, grilla ampliada", 45122, 45112),
  c("sensibilidad", "C2: ampliada vs v3",              45112, 5112),
  c("sensibilidad", "C3: ampliada vs v3",              45122, 5122)
)

tabla <- do.call(rbind, lapply(seq_len(nrow(pares)), function(i)
  comparar(as.numeric(pares[i, 3]), as.numeric(pares[i, 4]),
           pares[i, 1], pares[i, 2])))

# correccion de Holm dentro de cada familia (por comparaciones multiples)
tabla$p_holm <- NA
for (f in c("principal", "secundaria", "lags")) {
  i <- tabla$familia == f & !is.na(tabla$p_wilcoxon)
  tabla$p_holm[i] <- round(p.adjust(tabla$p_wilcoxon[i], method = "holm"), 4)
}

mostrar <- function(f, titulo) {
  cat("===", titulo, "===\n")
  t <- tabla[tabla$familia == f, -1]
  print(t, row.names = FALSE)
  if (any(t$pares < length(SEMILLAS)))
    cat("ATENCION: hay comparaciones con menos de 10 pares de semillas.\n")
  cat("\n")
}
mostrar("principal",    "Comparacion principal: C3 contra C2 (Wilcoxon pareado por semilla)")
mostrar("secundaria",   "Comparaciones secundarias: contra la base")
mostrar("lags",         "Exploratoria: familia L1 contra familia L2")
mostrar("sensibilidad", "Chequeo de sensibilidad de la grilla")
cat("dif_media y dif_mediana: a - b, en millones. gana_a: semillas en las que",
    "a supera a b.\n",
    "p_holm: p ajustado por Holm dentro de cada familia de comparaciones.\n",
    "En 'ampliada vs v3', los empates son semillas en las que el grid eligio",
    "los mismos hiperparametros y el modelo es identico.\n")

# ------------------------------------------------------------------ salida
dir.create("resultados", showWarnings = FALSE)
write.csv(gps[order(gps$experimento, gps$semilla), ],
          "resultados/ganancia_por_semilla.csv", row.names = FALSE)
write.csv(tabla, "resultados/comparaciones.csv", row.names = FALSE)
cat("\nGuardado: resultados/ganancia_por_semilla.csv y resultados/comparaciones.csv\n")
