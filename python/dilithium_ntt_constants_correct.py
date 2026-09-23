"""
Dilithium (ML-DSA) NTT constants -- CORRECTED generator.

Why this differs from the originally uploaded package:

1. The root's order was mislabeled. The README shipped with the original
   zip called 1753 a "primitive 256th root of unity." It is not: its
   actual multiplicative order mod q=8380417 is 512 (1753^256 = -1 mod q,
   1753^512 = 1 mod q). 1753 is the correct constant for Dilithium, but
   it is a primitive 512th (= 2N-th) root, not an N-th root.

2. Because it's a 2N-th root, Dilithium's ring Z_q[X]/(X^256+1) DOES
   fully split into 256 linear factors (unlike Kyber's ring, which only
   reaches 128 irreducible quadratics -- see the Kyber corrected
   package). q-1 = 8380416 is divisible by 512, so this full split is
   possible: X^256+1 = X^256 - zeta^256 = prod_{k}(X - zeta^(...)),
   giving a genuine 8-stage radix-2 DIT NTT all the way down to scalars.

3. The originally uploaded generator got the *stage count* right (it
   iterated 8 stages) but assigned twiddles with the plain cyclic-NTT
   formula `pow(ROOT, j*(N/m), Q)`. That formula assumes ROOT^N = 1.
   Here ROOT^256 = -1, not 1, so the assumption is violated and the
   resulting schedule does not implement negacyclic (or even cyclic)
   convolution correctly. Verified: it reproduces neither.

This generator instead builds the schedule by recursively splitting
X^n - zeta^e = (X^(n/2) - zeta^(e/2)) * (X^(n/2) + zeta^(e/2)),
tracking exponents mod 512 (zeta's true order), starting from the top
block X^256 - zeta^256 = X^256 + 1. After 8 halvings this reaches 256
singleton (fully resolved) coefficients, so multiplication in the NTT
domain is a plain element-wise multiply -- no base multiplication step
is needed (unlike Kyber).

Verified by:
  1. round-tripping forward+inverse NTT on random input, and
  2. checking that forward-NTT -> pointwise multiply -> inverse-NTT
     exactly reproduces direct O(N^2) negacyclic convolution of two
     random polynomials mod (X^256+1), for q=8380417.

Run this file directly to print the schedule and twiddle table.
"""

Q = 8380417
N = 256
ZETA = 1753        # primitive 512th (2N-th) root of unity mod q; zeta^256 = -1 mod q
LAYER_LENGTHS = [128, 64, 32, 16, 8, 4, 2, 1]   # 8 layers, full split


def generate_schedule():
    """Builds the 8-layer butterfly schedule. Final blocks are all size-1 (fully resolved)."""
    blocks = [(0, 256)]   # top block, e=256: X^256 - zeta^256 = X^256 + 1
    schedule = []
    for stage, length in enumerate(LAYER_LENGTHS, start=1):
        new_blocks = []
        for (start, e) in blocks:
            assert e % 2 == 0, f"internal error: e={e} must be even at stage {stage}"
            a_exp = (e // 2) % 512
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
            e_lo = (e // 2) % 512
            e_hi = (e // 2 + 256) % 512   # -1 = zeta^256, so -a = zeta^(e/2 + 256)
            new_blocks.append((start, e_lo))
            new_blocks.append((start + length, e_hi))
        blocks = new_blocks
    return schedule, blocks   # blocks: 256 singleton leaves (start, defining_exponent)


def generate_unique_twiddles(schedule):
    """255 distinct twiddle values, in first-use (stage) order."""
    seen = []
    seen_set = set()
    for s in schedule:
        tw = s["twiddle"]
        if tw not in seen_set:
            seen_set.add(tw)
            seen.append(tw)
    return seen


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

    print(f"q={Q}, N={N}, root={ZETA} (order 512 -- a 2N-th root, not an N-th root)")
    print(f"layers = {LAYER_LENGTHS}  (8 stages, full split)")
    print(f"total butterfly operations = {len(schedule)} (8 x 128 = 1024)")
    print(f"unique twiddle values = {len(twiddles)} (255, not 256 -- see README)")
    print()
    for k, value in enumerate(twiddles):
        print(f"W[{k}] = {value}")
