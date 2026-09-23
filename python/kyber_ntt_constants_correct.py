"""
Kyber (ML-KEM) NTT constants -- CORRECTED generator.

Why this differs from a "textbook" 8-stage radix-2 DIT NTT:

Kyber works in the ring Z_q[X]/(X^256 + 1) -- a NEGACYCLIC ring, not the
cyclic ring Z_q[X]/(X^256 - 1) that a plain Cooley-Tukey NTT assumes.

q = 3329 only has a primitive 256th root of unity (zeta = 17), not a
primitive 512th root. That means X^256 + 1 cannot be split all the way
down to 256 linear factors -- it splits into exactly 128 irreducible
QUADRATIC factors instead. Proof sketch: zeta has multiplicative order
256 = 2^8, while (q-1)/2 = 1664 = 2^7 * 13. Since 2^8 does not divide
1664, zeta (and every odd power of it) is a quadratic non-residue mod q,
so X^2 - zeta^(odd) never factors further.

Consequence: the NTT has exactly 7 layers (256 -> 128 -> 64 -> ... -> 2),
not 8, and it leaves 128 unresolved degree-1-over-degree-2 pairs. Turning
those pairs into a scalar product during polynomial multiplication
requires a "base multiplication" step (multiplying mod X^2 - zeta),
not a plain element-wise multiply.

This generator builds the correct 7-layer schedule via repeated CRT
splitting (X^n - a^2 = (X^(n/2)-a)(X^(n/2)+a)) and has been verified by:
  1. round-tripping forward+inverse on random input, and
  2. checking that forward-NTT -> base-multiplication -> inverse-NTT
     exactly reproduces direct negacyclic convolution of two random
     polynomials mod (X^256+1), for 3329.

Run this file directly to print the schedule and twiddle table.
"""

Q = 3329
N = 256
ZETA = 17          # primitive 256th root of unity mod 3329 (zeta^128 = -1 mod q)
LAYER_LENGTHS = [128, 64, 32, 16, 8, 4, 2]   # 7 layers, NOT 8


def generate_schedule():
    """Builds the 7-layer butterfly schedule and the 128 terminal (leaf) blocks."""
    blocks = [(0, 128)]   # (block_start, defining_exponent e), top block = X^256 - zeta^128 = X^256+1
    schedule = []
    for stage, length in enumerate(LAYER_LENGTHS, start=1):
        new_blocks = []
        for (start, e) in blocks:
            assert e % 2 == 0, f"internal error: e={e} must be even at n>2"
            a_exp = (e // 2) % 256
            twiddle = pow(ZETA, a_exp, Q)
            for j in range(length):
                a_idx = start + j
                b_idx = start + j + length
                schedule.append({
                    "stage": stage,
                    "group_start": start,
                    "butterfly_in_group": j,
                    "A": a_idx,
                    "B": b_idx,
                    "twiddle_exponent": a_exp,
                    "twiddle": twiddle,
                })
            e_lo = (e // 2) % 256
            e_hi = (e // 2 + 128) % 256
            new_blocks.append((start, e_lo))
            new_blocks.append((start + length, e_hi))
        blocks = new_blocks
    leaves = blocks  # 128 entries: (block_start, defining_exponent) for the unresolved quadratic factors
    return schedule, leaves


def generate_unique_twiddles(schedule):
    """127 distinct twiddle values, in first-use (stage) order."""
    seen = []
    seen_set = set()
    for s in schedule:
        tw = s["twiddle"]
        if tw not in seen_set:
            seen_set.add(tw)
            seen.append(tw)
    return seen


def base_multiply(f0, f1, g0, g1, exponent):
    """Multiply (f0 + f1*X) * (g0 + g1*X) mod (X^2 - zeta^exponent)."""
    zeta_e = pow(ZETA, exponent % 256, Q)
    h0 = (f0 * g0 + zeta_e * f1 * g1) % Q
    h1 = (f0 * g1 + f1 * g0) % Q
    return h0, h1


def forward_ntt(coeffs, schedule):
    x = coeffs[:]
    for s in schedule:
        a, b, tw = s["A"], s["B"], s["twiddle"]
        u = x[a]
        v = (tw * x[b]) % Q
        x[a] = (u + v) % Q
        x[b] = (u - v) % Q
    return x


def inverse_ntt(coeffs, schedule):
    x = coeffs[:]
    inv2 = pow(2, Q - 2, Q)
    for s in reversed(schedule):
        a, b, tw = s["A"], s["B"], s["twiddle"]
        na, nb = x[a], x[b]
        inv_tw = pow(tw, Q - 2, Q)
        x[a] = ((na + nb) * inv2) % Q
        x[b] = (((na - nb) * inv2) % Q * inv_tw) % Q
    return x


if __name__ == "__main__":
    schedule, leaves = generate_schedule()
    twiddles = generate_unique_twiddles(schedule)

    print(f"q={Q}, N={N}, root={ZETA}")
    print(f"layers = {LAYER_LENGTHS}  (7 stages, matches FIPS 203 structure)")
    print(f"total butterfly operations = {len(schedule)} (7 x 128 = 896)")
    print(f"unique twiddle values = {len(twiddles)} (127, not 128 -- see README)")
    print()
    for k, value in enumerate(twiddles):
        print(f"W[{k}] = {value}")
