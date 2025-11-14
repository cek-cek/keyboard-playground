# PRD Dependency Graph

This document defines the execution order and dependencies for all PRDs. Use this to determine which PRDs can be worked on in parallel.

## Visual Dependency Graph

```
                    START
                      ↓
        ┌─────────────────────────┐
        │      PRD-001            │
        │  Technology Research    │
        │   (MUST BE FIRST)       │
        └─────────────────────────┘
                      ↓
        ┌─────────────────────────┐
        │      PRD-002            │
        │   Project Setup         │
        │  (MUST BE SECOND)       │
        └─────────────────────────┘
                      ↓
        ┌─────────────────────────┐
        │      PRD-003            │
        │   Build System & CI/CD  │
        │   (MUST BE THIRD)       │
        └─────────────────────────┘
                      ↓
     ╔════════════════════════════════════════╗
     ║     PARALLEL GROUP 1 (4 tasks)         ║
     ║   All can start after PRD-003          ║
     ╚════════════════════════════════════════╝
              ↓         ↓         ↓         ↓
     ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
     │ PRD-004  │ │ PRD-005  │ │ PRD-006  │ │ PRD-007  │
     │  Input   │ │   Exit   │ │    UI    │ │ Testing  │
     │ Capture  │ │ Mechanism│ │Framework │ │  Setup   │
     └──────────┘ └──────────┘ └──────────┘ └──────────┘
              ↓         ↓         ↓         ↓
              └─────────┴─────────┴─────────┘
                         ↓
        ┌─────────────────────────────────┐
        │         PRD-008                 │
        │  Integration & Base Application │
        │   (Needs ALL of Group 1)        │
        └─────────────────────────────────┘
                         ↓
     ╔════════════════════════════════════════╗
     ║     PARALLEL GROUP 2 (3 tasks)         ║
     ║   All can start after PRD-008          ║
     ║        (Game Implementations)          ║
     ╚════════════════════════════════════════╝
              ↓         ↓         ↓
     ┌──────────┐ ┌──────────┐ ┌──────────┐
     │ PRD-009  │ │ PRD-010  │ │ PRD-011  │
     │  Game 1  │ │ Game 2a  │ │ Game 2b  │
     │Exploding │ │ Keyboard │ │  Mouse   │
     │ Letters  │ │Visual.   │ │ Visual.  │
     └──────────┘ └──────────┘ └──────────┘

     ╔════════════════════════════════════════╗
     ║     PARALLEL GROUP 3 (3 tasks)         ║
     ║   Can start after PRD-008              ║
     ║   Independent of games (Group 2)       ║
     ╚════════════════════════════════════════╝
              ↓         ↓         ↓
     ┌──────────┐ ┌──────────┐ ┌──────────┐
     │ PRD-012  │ │ PRD-013  │ │ PRD-014  │
     │   Docs   │ │  Perf    │ │Accessib. │
     │  System  │ │   Opt    │ │ Features │
     └──────────┘ └──────────┘ └──────────┘
                         ↓
                       DONE
```

## PRD Status Table

| PRD | Title | Status | Dependencies | Can Start After | Estimated Effort |
|-----|-------|--------|--------------|-----------------|------------------|
| PRD-001 | Technology Research | ✅ Complete | None | Immediately | 2 hours |
| PRD-002 | Project Setup | ✅ Complete | PRD-001 | PRD-001 complete | 4 hours |
| PRD-003 | Build System & CI/CD | ✅ Complete | PRD-002 | PRD-002 complete | 6 hours |
| PRD-004 | Input Capture System | ✅ Complete | PRD-003 | PRD-003 complete | 16 hours |
| PRD-005 | Exit Mechanism | ✅ Complete | PRD-003 | PRD-003 complete | 4 hours |
| PRD-006 | UI Framework & Window Mgmt | ✅ Complete | PRD-003 | PRD-003 complete | 8 hours |
| PRD-007 | Testing Infrastructure | ✅ Complete | PRD-003 | PRD-003 complete | 6 hours |
| PRD-008 | Integration & Base App | ✅ Complete | PRD-004, 005, 006, 007 | All Group 1 complete | 8 hours |
| PRD-009 | Game: Exploding Letters | ⚪ Not Started | PRD-008 | PRD-008 complete | 12 hours |
| PRD-010 | Game: Keyboard Visualizer | ⚪ Not Started | PRD-008 | PRD-008 complete | 10 hours |
| PRD-011 | Game: Mouse Visualizer | ⚪ Not Started | PRD-008 | PRD-008 complete | 8 hours |
| PRD-012 | Documentation System | ⚪ Not Started | PRD-008 | PRD-008 complete | 6 hours |
| PRD-013 | Performance Optimization | ⚪ Not Started | PRD-008 | PRD-008 complete | 8 hours |
| PRD-014 | Accessibility Features | ⚪ Not Started | PRD-008 | PRD-008 complete | 6 hours |

**Status Legend:**
- ⚪ Not Started
- 🔵 In Progress
- ✅ Complete
- ⏸️ Blocked

## Execution Rules

### Rule 1: Sequential Foundation (MUST Follow Order)

These MUST be done sequentially, in exact order:

1. **PRD-001** - Technology Research & Decision
   - No dependencies
   - **START HERE**

2. **PRD-002** - Project Setup & Structure
   - Depends on: PRD-001
   - Cannot start until PRD-001 is merged

3. **PRD-003** - Build System & CI/CD
   - Depends on: PRD-002
   - Cannot start until PRD-002 is merged

### Rule 2: Parallel Group 1 (Can Work Simultaneously)

After PRD-003 is complete, these 4 can be done **in parallel** by different agents:

- **PRD-004** - Input Capture System (Platform-Specific)
  - Works on: `lib/platform/input_capture.dart`, `macos/`, `linux/`, `windows/`
  - Low conflict risk: Different files per platform
  - **Critical path**: Most complex, start first if single agent

- **PRD-005** - Exit Mechanism
  - Works on: `lib/core/exit_handler.dart`
  - Low conflict risk: New file

- **PRD-006** - UI Framework & Window Management
  - Works on: `lib/ui/`, `lib/widgets/`
  - Low conflict risk: New files

- **PRD-007** - Testing Infrastructure Setup
  - Works on: `test/`, `test_utils/`
  - Low conflict risk: New files

**Conflict Risk**: Very low - each touches different files

### Rule 3: Integration (Waits for Group 1)

- **PRD-008** - Integration & Base Application
  - Depends on: **ALL** of PRD-004, 005, 006, 007
  - **Blocker**: Cannot start until entire Group 1 is complete
  - Integrates all components into working base app

### Rule 4: Parallel Group 2 - Games (Can Work Simultaneously)

After PRD-008 is complete, these 3 can be done **in parallel**:

- **PRD-009** - Game 1: Exploding Letters
  - Works on: `lib/games/exploding_letters/`
  - Low conflict risk: New directory

- **PRD-010** - Game 2: Keyboard Visualizer
  - Works on: `lib/games/input_visualizer/keyboard/`
  - Low conflict risk: New directory

- **PRD-011** - Game 2: Mouse Visualizer
  - Works on: `lib/games/input_visualizer/mouse/`
  - Low conflict risk: New directory

**Conflict Risk**: Very low - separate directories

**Note**: PRD-010 and PRD-011 are related (both part of "Game 2") but can be developed independently. They'll share some base classes but work in separate files.

### Rule 5: Parallel Group 3 - Polish (Can Work Simultaneously)

After PRD-008 is complete, these 3 can be done **in parallel** and **independently of Group 2**:

- **PRD-012** - Documentation System
  - Works on: `docs/`, `README.md`
  - Low conflict risk: Documentation files

- **PRD-013** - Performance Optimization
  - Works on: Existing game files, optimization
  - Medium conflict risk: May touch same files as games
  - **Recommendation**: Do after games (Group 2) if conflict likely

- **PRD-014** - Accessibility Features
  - Works on: `lib/accessibility/`, UI enhancements
  - Medium conflict risk: May touch UI files
  - **Recommendation**: Coordinate with PRD-006 changes

## Recommended Execution Strategies

### Strategy 1: Single Agent (Sequential)

Best order for minimum context switching:

1. PRD-001 (2h)
2. PRD-002 (4h)
3. PRD-003 (6h)
4. PRD-004 (16h) ← Start with hardest
5. PRD-006 (8h)
6. PRD-005 (4h)
7. PRD-007 (6h)
8. PRD-008 (8h)
9. PRD-009 (12h)
10. PRD-010 (10h)
11. PRD-011 (8h)
12. PRD-012 (6h)
13. PRD-013 (8h)
14. PRD-014 (6h)

**Total**: ~104 hours (~2.6 weeks full-time)

### Strategy 2: Two Agents (Parallel)

**Agent A (Critical Path):**
1. PRD-001 → PRD-002 → PRD-003
2. PRD-004 (complex, platform-specific)
3. PRD-008 (integration)
4. PRD-009 (first game)
5. PRD-013 (performance)

**Agent B (Supporting Path):**
1. Wait for PRD-003
2. PRD-005, PRD-006, PRD-007 (in sequence or parallel)
3. PRD-010, PRD-011 (games)
4. PRD-012, PRD-014 (docs, accessibility)

**Total**: ~60 hours (~1.5 weeks full-time with 2 agents)

### Strategy 3: Four Agents (Maximum Parallelism)

**Agent A (Critical Path):**
- PRD-001 → PRD-002 → PRD-003 → PRD-004 → PRD-008

**Agent B (UI Path):**
- Wait for PRD-003 → PRD-006 → PRD-009

**Agent C (Testing Path):**
- Wait for PRD-003 → PRD-007 → PRD-010

**Agent D (Exit & Docs Path):**
- Wait for PRD-003 → PRD-005 → PRD-011 → PRD-012

Then all agents can pick up Group 3 tasks (PRD-013, PRD-014) as available.

**Total**: ~40 hours (~1 week full-time with 4 agents)

## Quick Reference: Can I Start This PRD?

### Checklist Before Starting Any PRD

```bash
# 1. Check if dependencies are met
git log --all --oneline --grep="PRD-XXX" # Check if dependency PRDs merged

# 2. Check if someone is already working on it
git branch -a | grep "feature/prd-XXX"

# 3. Check current status
cat DEPENDENCIES.md | grep "PRD-XXX"

# 4. If all clear, claim it
git checkout -b feature/prd-XXX-short-name
git push -u origin feature/prd-XXX-short-name  # Signal you're working on it
```

### Decision Tree

```
Can I start PRD-XXX?
  │
  ├─ Are ALL dependencies complete? ──NO──> ⏸️ Wait
  │   │
  │   YES
  │   ↓
  ├─ Is there a branch for PRD-XXX? ──YES──> ⏸️ Someone else working
  │   │
  │   NO
  │   ↓
  └─ Is PRD-XXX in "Not Started" status? ──YES──> ✅ START WORKING
      │
      NO (In Progress/Complete)
      ↓
      ⏸️ Pick a different PRD
```

## Critical Path Analysis

The **critical path** (longest sequence of dependent tasks) is:

```
PRD-001 (2h) → PRD-002 (4h) → PRD-003 (6h) → PRD-004 (16h) → PRD-008 (8h) → PRD-009 (12h)

Total critical path: 48 hours
```

**Key Insight**: PRD-004 (Input Capture) is the bottleneck. This is the most complex and takes longest. If single agent, start this immediately after PRD-003.

## Merge Order Requirements

### Strict Merge Order

1. PRD-001 must merge before PRD-002 starts
2. PRD-002 must merge before PRD-003 starts
3. PRD-003 must merge before Group 1 (004-007) starts
4. All Group 1 (004-007) must merge before PRD-008 starts
5. PRD-008 must merge before Group 2 (009-011) and Group 3 (012-014) start

### Within Parallel Groups

Within a parallel group, merge order doesn't matter:
- Group 1: PRDs 004-007 can merge in any order
- Group 2: PRDs 009-011 can merge in any order
- Group 3: PRDs 012-014 can merge in any order

## Updating This Document

When a PRD is completed:

1. Update the status table (⚪ → ✅)
2. Check if any blocked PRDs can now start
3. Update the "Can Start After" for unblocked PRDs
4. Commit changes: `git commit -m "docs: Update PRD-XXX status to complete"`

## Risk Mitigation

### High-Risk Dependencies

**PRD-004 (Input Capture)**: If this is significantly delayed or blocked:
- **Mitigation**: Can proceed with mocked input for PRD-008, 009, 010, 011
- **Fallback**: Implement keyboard capture only (defer mouse)
- **Note**: PRD-005 (Exit Mechanism) also depends on input capture behavior

**PRD-008 (Integration)**: If integration reveals architectural issues:
- **Mitigation**: May need to refactor some Group 1 PRDs
- **Prevention**: Thorough review of Group 1 PRDs before merging

### Conflict Scenarios

If multiple agents try to work on interdependent PRDs:

1. **Communicate via branches**: Push branches early to signal work in progress
2. **Coordinate in shared files**: If both need to modify `main.dart`, discuss approach
3. **Use feature flags**: If needed, wrap new features in flags to merge partially complete work

## FAQ

**Q: Can I work on PRD-009 while PRD-004 is still in progress?**
A: No. PRD-009 depends on PRD-008, which depends on PRD-004.

**Q: Can I work on PRD-010 and PRD-011 simultaneously?**
A: Yes, but only if you're doing them yourself. Otherwise, two different agents can work on them in parallel after PRD-008 is complete.

**Q: PRD-004 is taking longer than estimated. Can I help?**
A: Yes! PRD-004 has platform-specific code. You could take one platform (e.g., Linux) while another agent does macOS.

**Q: I finished PRD-007 but PRD-004 is still in progress. What should I do?**
A: You can start on documentation (PRD-012) prep work, or help with PRD-004 if you have platform expertise. Don't wait idle.

**Q: Can I start PRD-013 (Performance Optimization) before games are done?**
A: Technically yes after PRD-008, but it's better to wait for at least PRD-009 so you have a game to optimize.

---

**Remember**: When in doubt, check this document. If you're blocked, pick a different PRD from the available list. There's always work to be done!
