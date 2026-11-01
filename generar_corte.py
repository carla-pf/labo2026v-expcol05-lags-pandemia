# Genera cortes de envio desde prediccion.txt, igual que el notebook:
# ordena por probabilidad descendente y marca con 1 los primeros N.
# Uso:  python3 generar_corte.py 5100 1400          -> genera KA5100_<semilla>_1400.csv
#       python3 generar_corte.py --probar 5100 1500 -> regenera 1500 y compara con el original
import sys, glob, os
probar = sys.argv[1] == "--probar"
args = sys.argv[2:] if probar else sys.argv[1:]
exp, cortes = args[0], [int(x) for x in args[1:]]
for d in sorted(glob.glob(os.path.expanduser(f"~/buckets/b1/exp/WF{exp}/s*/"))):
    if not os.path.exists(d + "PARAM.yml") or not os.path.exists(d + "prediccion.txt"):
        continue
    semilla = os.path.basename(d.rstrip("/"))[1:]
    with open(d + "prediccion.txt") as f:
        next(f)
        filas = [(l.split()[0], float(l.split()[1])) for l in f if l.strip()]
    filas.sort(key=lambda r: -r[1])
    for n in cortes:
        unos = {c for c, _ in filas[:n]}
        destino = f"{d}kaggle/KA{exp}_{semilla}_{n}.csv"
        if probar:
            with open(destino) as f:
                next(f)
                orig = {l.split(",")[0] for l in f if l.strip().endswith(",1")}
            print(semilla, n, "IGUAL" if orig == unos else f"DISTINTO ({len(orig ^ unos)} clientes)")
        elif os.path.exists(destino):
            print(semilla, n, "ya existe, no lo toco")
        else:
            with open(destino, "w") as g:
                g.write("numero_de_cliente,Predicted\n")
                for c, _ in filas:
                    g.write(f"{c},{1 if c in unos else 0}\n")
            print(semilla, n, "generado")
