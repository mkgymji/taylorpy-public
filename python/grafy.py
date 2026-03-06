# grafy.py -- Vizualizace Taylorovych rad pro dokument a prezentaci
# Generuje PNG do python/output/
#
# Toto studenti nemusi cist -- je to nastroj sestaveni.
# Vyzaduje: numpy, matplotlib

import math
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# ----------------------------------------------------------------
# Vystupni adresar
# ----------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(SCRIPT_DIR, "output")
os.makedirs(OUT_DIR, exist_ok=True)


# ----------------------------------------------------------------
# Pomocne funkce (stejne jako taylor.py, bez importu toho souboru)
# ----------------------------------------------------------------

def faktorial(n):
    v = 1
    for i in range(2, n + 1):
        v *= i
    return v


def sin_taylor(x, n_terms):
    s = 0.0
    for k in range(n_terms):
        exp = 2 * k + 1
        s += ((-1) ** k) * (x ** exp) / faktorial(exp)
    return s


def cos_taylor(x, n_terms):
    s = 0.0
    for k in range(n_terms):
        exp = 2 * k
        s += ((-1) ** k) * (x ** exp) / faktorial(exp)
    return s


def sqrt_newton(a, n_iter):
    if a == 0:
        return 0.0
    x = a
    for _ in range(n_iter):
        x = (x + a / x) / 2
    return x


# ================================================================
# Graf 1: Aproximace sin(x) polynomy ruzneho stupne
# ================================================================

def graf_aproximace_sin():
    x = np.linspace(-np.pi, np.pi, 500)
    y_sin = np.sin(x)

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(x, y_sin, "k-", linewidth=2, label=r"$\sin(x)$ (presne)")

    barvy = ["#e41a1c", "#ff7f00", "#4daf4a", "#377eb8"]
    n_terms_list = [1, 2, 3, 4]
    for n, barva in zip(n_terms_list, barvy):
        stupen = 2 * n - 1
        y = np.array([sin_taylor(xi, n) for xi in x])
        ax.plot(x, y, color=barva, linewidth=1.5,
                label=f"polynom stupne {stupen} ({n} clen{'' if n == 1 else 'y' if n < 5 else 'u'})")

    ax.set_xlim(-np.pi, np.pi)
    ax.set_ylim(-2, 2)
    ax.axhline(0, color="gray", linewidth=0.5)
    ax.axvline(0, color="gray", linewidth=0.5)
    ax.set_xlabel(r"$x$ [rad]")
    ax.set_ylabel(r"$f(x)$")
    ax.set_title("Aproximace sin(x) Taylorovymi polynomy")
    ax.legend(loc="upper right", fontsize=9)
    ax.set_xticks([-np.pi, -np.pi/2, 0, np.pi/2, np.pi])
    ax.set_xticklabels([r"$-\pi$", r"$-\pi/2$", r"$0$", r"$\pi/2$", r"$\pi$"])
    ax.grid(True, alpha=0.3)

    fig.tight_layout()
    out = os.path.join(OUT_DIR, "sin_aproximace.png")
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  [OK] {out}")


# ================================================================
# Graf 2: Konvergence sin(pi/6) pro rostouci pocet clenu
# ================================================================

def graf_konvergence_sin():
    x = math.pi / 6
    spravne = math.sin(x)
    n_rozsah = list(range(1, 16))
    hodnoty = [sin_taylor(x, n) for n in n_rozsah]
    chyby = [abs(v - spravne) for v in hodnoty]

    fig, axes = plt.subplots(1, 2, figsize=(10, 4))

    # Levy panel: hodnota aproximace
    ax = axes[0]
    ax.plot(n_rozsah, hodnoty, "o-", color="#377eb8", linewidth=1.5)
    ax.axhline(spravne, color="black", linewidth=1.5, linestyle="--",
               label=f"presna hodnota = {spravne:.6f}")
    ax.set_xlabel("Pocet clenu")
    ax.set_ylabel("Hodnota")
    ax.set_title(r"Aproximace $\sin(\pi/6)$")
    ax.legend(fontsize=9)
    ax.grid(True, alpha=0.3)

    # Pravy panel: absolutni chyba (log)
    ax = axes[1]
    ax.semilogy(n_rozsah, [max(e, 1e-16) for e in chyby],
                "s-", color="#e41a1c", linewidth=1.5)
    ax.set_xlabel("Pocet clenu")
    ax.set_ylabel("Absolutni chyba")
    ax.set_title(r"Chyba $|\mathrm{nase} - \sin(\pi/6)|$")
    ax.grid(True, alpha=0.3, which="both")

    fig.tight_layout()
    out = os.path.join(OUT_DIR, "sin_konvergence.png")
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  [OK] {out}")


# ================================================================
# Graf 3: Konvergence cos(pi/3) pro rostouci pocet clenu
# ================================================================

def graf_konvergence_cos():
    x = math.pi / 3
    spravne = math.cos(x)
    n_rozsah = list(range(1, 16))
    hodnoty = [cos_taylor(x, n) for n in n_rozsah]
    chyby = [abs(v - spravne) for v in hodnoty]

    fig, axes = plt.subplots(1, 2, figsize=(10, 4))

    ax = axes[0]
    ax.plot(n_rozsah, hodnoty, "o-", color="#984ea3", linewidth=1.5)
    ax.axhline(spravne, color="black", linewidth=1.5, linestyle="--",
               label=f"presna hodnota = {spravne:.6f}")
    ax.set_xlabel("Pocet clenu")
    ax.set_ylabel("Hodnota")
    ax.set_title(r"Aproximace $\cos(\pi/3)$")
    ax.legend(fontsize=9)
    ax.grid(True, alpha=0.3)

    ax = axes[1]
    ax.semilogy(n_rozsah, [max(e, 1e-16) for e in chyby],
                "s-", color="#984ea3", linewidth=1.5)
    ax.set_xlabel("Pocet clenu")
    ax.set_ylabel("Absolutni chyba")
    ax.set_title(r"Chyba $|\mathrm{nase} - \cos(\pi/3)|$")
    ax.grid(True, alpha=0.3, which="both")

    fig.tight_layout()
    out = os.path.join(OUT_DIR, "cos_konvergence.png")
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  [OK] {out}")


# ================================================================
# Graf 4: Konvergence sqrt(2) Newtonovou iteraci
# ================================================================

def graf_konvergence_sqrt():
    spravne = math.sqrt(2)
    n_rozsah = list(range(1, 11))
    hodnoty = [sqrt_newton(2, n) for n in n_rozsah]
    chyby = [abs(v - spravne) for v in hodnoty]

    fig, ax = plt.subplots(figsize=(7, 4))
    ax.semilogy(n_rozsah, [max(e, 1e-16) for e in chyby],
                "o-", color="#4daf4a", linewidth=2, markersize=8)
    ax.set_xlabel("Pocet iteraci")
    ax.set_ylabel("Absolutni chyba")
    ax.set_title(r"Konvergence $\sqrt{2}$ -- Newtonova iterace")
    ax.grid(True, alpha=0.3, which="both")
    ax.set_xticks(n_rozsah)

    fig.tight_layout()
    out = os.path.join(OUT_DIR, "sqrt_konvergence.png")
    fig.savefig(out, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  [OK] {out}")


# ================================================================
# Hlavni program
# ================================================================

if __name__ == "__main__":
    print()
    print("Generuji obrazky do python/output/ ...")
    print()
    graf_aproximace_sin()
    graf_konvergence_sin()
    graf_konvergence_cos()
    graf_konvergence_sqrt()
    print()
    print("Hotovo.")
