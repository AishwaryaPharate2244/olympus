# Olympus

## Password strength estimator

`password.py` scores a password from 0–100 based on:

- Length
- Character-class variety (lowercase, uppercase, digits, symbols)
- Estimated entropy
- A common-password blacklist
- Simple sequences (e.g. `abcd`, `1234`) and long repeated-character runs

Run it directly to see example output:

```bash
python password.py
```

## Dependency blacklist

`dependency-blacklist.txt` lists GitHub repositories (`owner/repo`) that must not be used as dependencies in this project.
