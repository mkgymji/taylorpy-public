# taylor.py -- Taylorovy rady a Newtonova iterace
# Seminar IVT, 3. rocnik gymnazia
#
# Implementace pouziva jen zakladni operace (+, -, *, /).
# import math je povolen pouze pro referencni hodnoty (spravna odpoved).

import math


# ================================================================
# Pomocne funkce
# ================================================================

def faktorial(n):
    """Vypocita n! pomoci smycky. Zadny import."""
    vysledek = 1
    for i in range(2, n + 1):
        vysledek *= i
    return vysledek


# ================================================================
# Taylorova rada pro sin(x)
#
#   sin(x) = x - x^3/3! + x^5/5! - x^7/7! + ...
#
# x musi byt v radianech.
# Pozor: pro |x| >> pi konverguje pomalu. Idealni rozsah: x v [-pi, pi].
# ================================================================

def sin_taylor(x, n_terms=10):
    """
    Aproximace sin(x) Taylorovou radou v bode 0 (Maclaurinova).
    x       -- argument v radianech
    n_terms -- pocet clenu rady
    """
    soucet = 0.0
    for k in range(n_terms):
        exponent = 2 * k + 1
        clen = ((-1) ** k) * (x ** exponent) / faktorial(exponent)
        soucet += clen
    return soucet


# ================================================================
# Taylorova rada pro cos(x)
#
#   cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + ...
#
# x musi byt v radianech.
# ================================================================

def cos_taylor(x, n_terms=10):
    """
    Aproximace cos(x) Taylorovou radou v bode 0 (Maclaurinova).
    x       -- argument v radianech
    n_terms -- pocet clenu rady
    """
    soucet = 0.0
    for k in range(n_terms):
        exponent = 2 * k
        clen = ((-1) ** k) * (x ** exponent) / faktorial(exponent)
        soucet += clen
    return soucet


# ================================================================
# Newtonova iterace pro odmocninu
#
#   x_0     = a            (pocatecni odhad)
#   x_{n+1} = (x_n + a/x_n) / 2
#
# Pouziva jen +, * a /.
# ================================================================

def sqrt_newton(a, n_iter=10):
    """
    Aproximace sqrt(a) Newtonovou iteraci (Babylonska metoda).
    a      -- cislo, ze ktereho pocitame odmocninu (a >= 0)
    n_iter -- pocet iteraci
    """
    if a < 0:
        raise ValueError("Odmocnina ze zaporne cislo je nerealna.")
    if a == 0:
        return 0.0
    x = a  # pocatecni odhad
    for _ in range(n_iter):
        x = (x + a / x) / 2
    return x


# ================================================================
# Tabulka chyb
# ================================================================

def tabulka_chyb():
    """
    Vytiskne tabulku absolutnich chyb pro ruzny pocet clenu / iteraci.
    Porovnava nase implementace s math.sin a math.sqrt jako referencemi.
    """
    print("=" * 65)
    print("TABULKA CHYB -- sin_taylor(pi/6, n)")
    print("  Spravna hodnota: sin(pi/6) = 0.5")
    print("-" * 65)
    print(f"{'n clenu':>8}  {'nase hodnota':>16}  {'chyba':>16}")
    print("-" * 65)
    x = math.pi / 6
    spravne = math.sin(x)
    for n in [1, 2, 3, 5, 7, 10, 15]:
        nase = sin_taylor(x, n)
        chyba = abs(nase - spravne)
        print(f"{n:>8}  {nase:>16.10f}  {chyba:>16.2e}")
    print("=" * 65)
    print()

    print("=" * 65)
    print("TABULKA CHYB -- sqrt_newton(2, n)")
    print(f"  Spravna hodnota: sqrt(2) = {math.sqrt(2):.10f}")
    print("-" * 65)
    print(f"{'n iter':>8}  {'nase hodnota':>16}  {'chyba':>16}")
    print("-" * 65)
    spravne = math.sqrt(2)
    for n in [1, 2, 3, 4, 5, 8, 10]:
        nase = sqrt_newton(2, n)
        chyba = abs(nase - spravne)
        print(f"{n:>8}  {nase:>16.10f}  {chyba:>16.2e}")
    print("=" * 65)
    print()

    print("=" * 65)
    print("TABULKA CHYB -- sin_taylor(x, 10) pro ruzna x")
    print("-" * 65)
    print(f"{'x [rad]':>10}  {'nase hodnota':>16}  {'math.sin':>16}  {'chyba':>12}")
    print("-" * 65)
    for stupne in [0, 30, 45, 60, 90, 120, 180]:
        x = stupne * math.pi / 180
        nase = sin_taylor(x, 10)
        spravne = math.sin(x)
        chyba = abs(nase - spravne)
        print(f"{x:>10.4f}  {nase:>16.10f}  {spravne:>16.10f}  {chyba:>12.2e}")
    print("=" * 65)


# ================================================================
# Hlavni program
# ================================================================

if __name__ == "__main__":
    print()
    print("Taylorovy rady a Newtonova iterace")
    print("Seminar IVT -- ukazka implementace")
    print()

    # Ukazka pouziti
    x = math.pi / 6  # 30 stupnu
    print(f"sin(pi/6) nase:   {sin_taylor(x, 5):.8f}")
    print(f"sin(pi/6) math:   {math.sin(x):.8f}")
    print()
    print(f"cos(pi/3) nase:   {cos_taylor(math.pi / 3, 5):.8f}")
    print(f"cos(pi/3) math:   {math.cos(math.pi / 3):.8f}")
    print()
    print(f"sqrt(2)   nase:   {sqrt_newton(2, 5):.8f}")
    print(f"sqrt(2)   math:   {math.sqrt(2):.8f}")
    print()

    tabulka_chyb()
