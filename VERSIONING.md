# Versioning

## Current version

**`0.1.0-alpha01`** — the first snapshot of the iOS Base. Not yet tagged; the maintainer creates
the tag deliberately once the verification in [DEVELOPMENT.md](DEVELOPMENT.md) passes.

Version numbers are independent of the Android Base — the two do not move in lockstep.

## Scheme

```
<minor-line>.<patch>-<pre-release>
0.1.0-alpha01   ← current
0.1.0-alpha02   fixes/additions on the same module set
0.1.0           first non-alpha snapshot
0.2.0-alpha01   next module set with new/changed public surface
```

A `0.x` version may change public API between tags. Tags are SemVer-compatible strings, so a
consumer that depends on the root package by URL can use `exact: "0.1.0-alpha01"`.

## When to tag

- A public API change that could break a consumer.
- A new module consumers should be able to pin.
- A defect fix consumers need without unrelated in-flight work.

## How consumers pin

Sibling checkout at a tag (`git clone --branch v0.1.0-alpha01 …`, or `ref:` in CI). **Never
`main`.** Tags are never moved once pushed; use annotated tags (`git tag -a`) whose message
names any breaking change.

## Upgrade checklist (consumer)

1. Read the tag messages / `git log <old>..<new>`.
2. Check out the new tag; run the Base verification.
3. Update the consumer's pin (CI `ref:` and local checkout).
4. Build and test the consumer; fix breakage **in the consumer**, or report a Base defect (class D).
5. Commit the pin change on its own, naming old and new versions.
