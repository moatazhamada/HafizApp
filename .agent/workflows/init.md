---
description: Bootstrap the HafizApp Flutter development environment
---

# /init — Project Initialization Workflow

Run this workflow to set up the HafizApp development environment from a clean state.

## Steps

// turbo-all

1. **Install Flutter dependencies**
```bash
cd /Users/mm/Main/Projects/Android/HafizApp && flutter pub get
```

2. **Run static analysis**
```bash
cd /Users/mm/Main/Projects/Android/HafizApp && flutter analyze
```

3. **Run all unit tests**
```bash
cd /Users/mm/Main/Projects/Android/HafizApp && flutter test
```

4. **Print project summary**
```bash
echo "✅ HafizApp init complete — deps installed, analysis passed, tests ran."
```
