# ExpCol #05 - Extrae de cada PARAM.yml los hiperparametros que eligio el grid.
# Uso (en la VM):
#   ~/.venv/bin/python extraer_grid.py 5211
#   ~/.venv/bin/python extraer_grid.py 45112 45122
# Imprime una linea por semilla, separada por ";":
#   experimento;semilla;num_leaves;min_data_in_leaf;feature_fraction;num_iterations;en_borde
import sys, glob, os, yaml

def buscar(d, k):
    # busca la clave k en cualquier nivel del yaml
    if isinstance(d, dict):
        if k in d:
            return d[k]
        for v in d.values():
            r = buscar(v, k)
            if r is not None:
                return r
    return None

def num(x):
    # 384.0 -> 384 ; 0.5 queda 0.5
    return int(x) if isinstance(x, float) and x.is_integer() else x

if len(sys.argv) < 2:
    sys.exit("Falta el numero de experimento. Ej: python extraer_grid.py 5211")

print("experimento;semilla;num_leaves;min_data_in_leaf;feature_fraction;num_iterations;en_borde")
for exp in sys.argv[1:]:
    archivos = sorted(glob.glob(os.path.expanduser(f"~/buckets/b1/exp/WF{exp}/s*/PARAM.yml")))
    if not archivos:
        print(f"# {exp}: no hay semillas terminadas")
        continue
    for f in archivos:
        semilla = os.path.basename(os.path.dirname(f))[1:]
        p = yaml.safe_load(open(f))
        h = buscar(p, "mejores_hiperparametros") or {}
        b = buscar(p, "en_borde")
        b = "+".join(b) if isinstance(b, list) else (b or "ninguno")
        print(exp, semilla, num(h.get("num_leaves")), num(h.get("min_data_in_leaf")),
              num(h.get("feature_fraction")), num(h.get("num_iterations")), b, sep=";")
    print(f"# {exp}: {len(archivos)} semillas")
