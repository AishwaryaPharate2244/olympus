import math
import re
from collections import Counter

# Small blacklist sample; expand with a larger list in production
COMMON_PASSWORDS = {
    "password","123456","123456789","qwerty","abc123","111111","12345678",
    "iloveyou","admin","welcome","monkey","letmein","dragon"
}

SYMBOLS = r"""!@#$%^&*()-_=+[{]}\|;:'",<.>/?`~"""

def estimate_entropy(password: str) -> float:
    """Estimate entropy (bits) based on character set size and length."""
    charset = 0
    if re.search(r"[a-z]", password): charset += 26
    if re.search(r"[A-Z]", password): charset += 26
    if re.search(r"[0-9]", password): charset += 10
    if re.search(rf"[{re.escape(SYMBOLS)}]", password): charset += len(SYMBOLS)
    if charset == 0:
        return 0.0
    return len(password) * math.log2(charset)

def has_sequence(password: str, seq_len: int = 4) -> bool:
    """Detect simple increasing/decreasing sequences of letters or digits."""
    s = password.lower()
    # check for alphabetic sequences
    for i in range(len(s) - seq_len + 1):
        chunk = s[i:i+seq_len]
        if chunk.isalpha():
            # map letters to positions
            vals = [ord(c) for c in chunk]
            diffs = [vals[i+1]-vals[i] for i in range(len(vals)-1)]
            if all(d == 1 for d in diffs) or all(d == -1 for d in diffs):
                return True
        if chunk.isdigit():
            vals = [int(c) for c in chunk]
            diffs = [vals[i+1]-vals[i] for i in range(len(vals)-1)]
            if all(d == 1 for d in diffs) or all(d == -1 for d in diffs):
                return True
    return False

def repeated_chars(password: str, max_run: int = 3) -> bool:
    """Return True if there is a run of the same character longer than max_run."""
    runs = [len(list(g)) for _, g in __import__("itertools").groupby(password)]
    return any(r > max_run for r in runs)

def score_password(password: str) -> dict:
    """Return a dictionary with score, verdict, entropy, and suggestions."""
    suggestions = []
    score = 0
    length = len(password)

    # Immediate checks
    if password.lower() in COMMON_PASSWORDS:
        return {
            "score": 0,
            "verdict": "Very weak",
            "entropy_bits": estimate_entropy(password),
            "suggestions": ["Do not use common passwords; choose a unique passphrase."]
        }

    # Length scoring
    if length >= 12:
        score += 30
    elif length >= 10:
        score += 20
        suggestions.append("Increase length to 12+ characters for better security.")
    elif length >= 8:
        score += 10
        suggestions.append("Use at least 10–12 characters.")
    else:
        suggestions.append("Make the password at least 12 characters long.")
    
    # Character classes
    classes = 0
    if re.search(r"[a-z]", password): classes += 1
    if re.search(r"[A-Z]", password): classes += 1
    if re.search(r"[0-9]", password): classes += 1
    if re.search(rf"[{re.escape(SYMBOLS)}]", password): classes += 1

    score += classes * 10
    if classes < 3:
        suggestions.append("Include a mix of uppercase, lowercase, digits, and symbols.")

    # Entropy contribution (scaled)
    entropy = estimate_entropy(password)
    if entropy >= 60:
        score += 20
    elif entropy >= 40:
        score += 10
        suggestions.append("Increase unpredictability (longer or more varied characters).")
    else:
        suggestions.append("Password entropy is low; make it longer and more varied.")

    # Sequence and repetition penalties
    if has_sequence(password):
        score -= 15
        suggestions.append("Avoid simple sequences like 'abcd' or '1234'.")
    if repeated_chars(password):
        score -= 10
        suggestions.append("Avoid long runs of the same character (e.g., 'aaaa').")

    # Normalize score to 0..100
    score = max(0, min(100, score))

    # Verdict
    if score >= 80:
        verdict = "Strong"
    elif score >= 60:
        verdict = "Good"
    elif score >= 40:
        verdict = "Weak"
    else:
        verdict = "Very weak"

    return {
        "score": score,
        "verdict": verdict,
        "entropy_bits": round(entropy, 1),
        "suggestions": suggestions or ["Looks okay, but consider using a passphrase for extra safety."]
    }

# Example usage mango
if __name__ == "__main__":
    test_passwords = [
        "password", "P@ssw0rd", "correcthorsebatterystaple",
        "Tr0ub4dor&3", "abcd1234", "S0m3$tr0ng-P@ss!"
    ]
    for pw in test_passwords:
        res = score_password(pw)
        print(f"Password: {pw}")
        print(f"  Score: {res['score']}  Verdict: {res['verdict']}  Entropy: {res['entropy_bits']} bits")
        print("  Suggestions:")
        for s in res["suggestions"]:
            print(f"   - {s}")
        print()
