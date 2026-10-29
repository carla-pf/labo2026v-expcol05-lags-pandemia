#!/bin/bash
# ExpCol #05 - Sube a Kaggle los cortes elegidos de todas las semillas terminadas de un experimento.
# Uso:   bash subir_kaggle.sh 5111 "1600 1800 2000 2200 2400"
# Anota lo subido en WF<exp>/subidos.txt: si se corta (cupo diario), se vuelve a lanzar
# despues de las 21 h y sigue desde donde quedo, sin repetir envios.

EXP=$1
CORTES=$2
if [ -z "$EXP" ] || [ -z "$CORTES" ]; then
  echo 'Uso: bash subir_kaggle.sh 5111 "1600 1800 2000 2200 2400"'; exit 1
fi

COMP=labo-1-virtual-2026-analista-jr
BASE=$HOME/buckets/b1/exp/WF${EXP}
LOG=$BASE/subidos.txt
touch "$LOG"

for D in $BASE/s*/ ; do
  S=$(basename "$D"); S=${S#s}
  if [ ! -f "$D/PARAM.yml" ]; then echo "semilla $S sin terminar, la salteo"; continue; fi
  for C in $CORTES; do
    ID=KA${EXP}_${S}_${C}
    if grep -qx "$ID" "$LOG"; then continue; fi
    F=${D}kaggle/$ID.csv
    if [ ! -f "$F" ]; then echo "falta $F"; continue; fi
    SAL=$(kaggle competitions submit -c $COMP -f "$F" -m "exp=${EXP} semilla=${S} envios=${C}" 2>&1)
    if echo "$SAL" | grep -q "Successfully"; then
      echo "$ID" >> "$LOG"
      echo "$(date '+%T')  subido $ID"
    else
      echo "$SAL"
      echo "Se corto en $ID: seguramente se agoto el cupo diario. Volver a lanzar despues de las 21 h."
      exit 1
    fi
    sleep 30
  done
done
echo "Listo. Envios subidos de este experimento: $(wc -l < "$LOG")"
