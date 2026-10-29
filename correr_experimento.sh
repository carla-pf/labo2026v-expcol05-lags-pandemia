#!/bin/bash
# ExpCol #05 - Corre el notebook COMPLETO una vez por semilla (grid search incluido).
# Uso:   bash correr_experimento.sh 5111
# Si la VM se apaga a mitad de camino, se vuelve a lanzar igual:
# saltea las semillas que ya terminaron (las que tienen PARAM.yml).

EXP=$1
if [ -z "$EXP" ]; then echo "Falta el numero de experimento. Ej: bash correr_experimento.sh 5111"; exit 1; fi

NB=$HOME/buckets/b1/labo2026v/ExpColaborativos/${EXP}_620_WorkFlow_01_junior_grupoA.ipynb
if [ ! -f "$NB" ]; then echo "No encuentro $NB"; exit 1; fi

SEMILLAS="629903 333331 121229 983209 100169 384841 612511 693809 761681 981653"

for S in $SEMILLAS; do
  OUT=$HOME/buckets/b1/exp/WF${EXP}/s${S}
  if [ -f "$OUT/PARAM.yml" ]; then
    echo "$(date '+%F %T')  semilla $S ya terminada, la salteo"
    continue
  fi
  mkdir -p "$OUT"
  echo "$(date '+%F %T')  ARRANCA exp $EXP semilla $S"
  if SEMILLA=$S jupyter nbconvert --to notebook --execute \
       --ExecutePreprocessor.kernel_name=ir \
       --ExecutePreprocessor.timeout=-1 \
       --output-dir="$OUT" --output="corrida_${EXP}_${S}.ipynb" "$NB" ; then
    echo "$(date '+%F %T')  TERMINO semilla $S"
  else
    echo "$(date '+%F %T')  ERROR en semilla $S (ver el mensaje de arriba)"
  fi
done

echo "$(date '+%F %T')  FIN experimento $EXP"
echo "Semillas terminadas: $(ls $HOME/buckets/b1/exp/WF${EXP}/s*/PARAM.yml 2>/dev/null | wc -l) de 10"
