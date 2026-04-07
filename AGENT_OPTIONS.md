# SpecKit AI Agent Options for HafizApp

## Available AI Agents

SpecKit supports the following AI agents:

### ✅ Fully Supported (Can use directly)

**Kilo Code**
- Command: `--ai kilocode` or `--ai kiro`
- Status: Fully supported
- Integration: Available in SpecKit v0.5.1+

### ⚠️ Limited Support

**GLM-4.7**
- Status: Not in the main agent list
- Workaround: Use generic agent with custom command files
- Command: `specify init . --ai generic --ai-commands-dir .myagent/commands/ --force`

## Current Setup

Currently configured with **Claude**:
- Integration: `claude`
- Skills installed: 9 SpecKit skills
- Location: `.claude/skills/`

## Switching to Kilo Code

To switch from Claude to Kilo Code:

```bash
# 1. Backup current skills (optional)
mv .claude/skills .claude/skills.claude.backup

# 2. Initialize with Kilo Code
specify init . --ai kilocode --force

# 3. Use SpecKit skills with Kilo Code
/speckit-constitution
/speckit-specify
/speckit-plan
/speckit-tasks
/speckit-implement
```

## Switching to GLM-4.7

To use GLM-4.7 (via generic agent):

```bash
# 1. Initialize with generic agent
specify init . --ai generic --ai-commands-dir .myagent/commands/ --force

# 2. Create custom command files for GLM-4.7 in .myagent/commands/
# 3. Use skills via custom commands
```

## Recommended

**Use Kilo Code** - It's fully supported by SpecKit and specifically mentioned in the agent list. This will give you:
- Official SpecKit integration
- Pre-configured skills
- Proper templates and workflows
- Full feature support

## Files After Kilo Code Setup

After switching to Kilo Code, you'll have:
- `.claude/skills/` → `.kilo/skills/` (or updated location)
- `.specify/integrations/` → updated for kilocode
- Skills compatible with Kilo Code's API
