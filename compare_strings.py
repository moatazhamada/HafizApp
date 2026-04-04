
json_string = "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ"
code_string = "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ"

def print_hex(s, label):
    print(f"{label}: {' '.join(hex(ord(c)) for c in s)}")

print_hex(json_string, "JSON")
print_hex(code_string, "CODE")
