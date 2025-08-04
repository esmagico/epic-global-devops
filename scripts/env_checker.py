#!/usr/bin/env python3

import re
from zxcvbn import zxcvbn
import os

# Path to your .env file
ENV_PATH = ".env"

# Keys to search for (customize as needed)
SENSITIVE_KEYS = ["PASSWORD", "SECRET", "TOKEN", "KEY", "API", "ACCESS"]

# Minimum acceptable password strength (0–4). 3 = strong
MIN_SCORE = 3

def is_sensitive_key(key):
    return any(k in key.upper() for k in SENSITIVE_KEYS)

def check_password_strength(password):
    if len(password) > 72:
        return None, {"warning": "Value too long to evaluate (likely a token or API key)."}
    result = zxcvbn(password)
    return result['score'], result['feedback']

def main():
    if not os.path.isfile(ENV_PATH):
        print(f"❌ File not found: {ENV_PATH}")
        return 1

    print(f"🔍 Checking sensitive values in {ENV_PATH}...\n")
    
    weak_passwords_found = False

    with open(ENV_PATH) as f:
        for line in f:
            line = line.strip()

            # Skip empty lines or comments
            if not line or line.startswith("#") or '=' not in line:
                continue

            key, value = map(str.strip, line.split("=", 1))
            value = value.strip('"').strip("'")  # remove wrapping quotes

            if is_sensitive_key(key):
                score_feedback = check_password_strength(value)

                # Skip long values
                if score_feedback[0] is None:
                    print(f"🔷 {key} skipped (too long to check, likely secure token)")
                    continue

                score, feedback = score_feedback

                if score < MIN_SCORE:
                    print(f"⚠️ Weak {key} → Score: {score}/4")
                    if feedback.get("warning"):
                        print(f"   ⚠️ {feedback['warning']}")
                    if feedback.get("suggestions"):
                        for suggestion in feedback["suggestions"]:
                            print(f"   💡 {suggestion}")
                    weak_passwords_found = True
                else:
                    print(f"✅ {key} looks strong enough (score {score}/4)")
    
    if weak_passwords_found:
        print(f"\n❌ Deployment blocked: Weak passwords found. Please strengthen passwords before deploying.")
        return 1
    else:
        print(f"\n✅ All sensitive values meet security requirements.")
        return 0

if __name__ == "__main__":
    exit(main())
