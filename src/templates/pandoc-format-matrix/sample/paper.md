---
title: "A Brief Introduction to Mathematical Analysis"
author: "Sample Author"
date: 2026
abstract: |
  This paper demonstrates document transformation pipelines using pandoc.
  We cover mathematical notation, bibliographic references, and code examples
  to exercise all output format derivations in the flake.
---

# Introduction

Mathematical analysis builds on the foundations laid by [@cauchy1821cours]
and later formalized by [@rudin1976principles]. The study of convergence
is central to the field [@apostol1974mathematical].

## Basic Definitions

A sequence $(a_n)_{n \geq 0}$ **converges** to $L$ if:

$$\forall \varepsilon > 0,\ \exists N \in \mathbb{N}:\ n > N \Rightarrow |a_n - L| < \varepsilon$$

The **Gaussian integral** is a classical result:

$$\int_{-\infty}^{\infty} e^{-x^2}\, dx = \sqrt{\pi}$$

## Code Example

Numerical approximation of $\pi$ using the Leibniz formula:

```python
def leibniz_pi(n: int) -> float:
    return 4 * sum((-1)**k / (2*k + 1) for k in range(n))

print(f"pi ≈ {leibniz_pi(1_000_000):.6f}")
```

# Conclusion

Format transformations allow the same source document to reach diverse audiences.
See also [@knuth1984literate] for related ideas on literate programming.

# References
