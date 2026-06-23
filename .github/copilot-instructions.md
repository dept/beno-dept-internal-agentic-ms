# DEPT Agentic Managed Services – Repository Instructions

## Purpose of this Repository

This repository defines the standards, agents, templates, and workflows for building AI-ready Managed Services projects at DEPT.

It is the foundation for an Agentic Managed Services Operating Model where:

- Projects are structured for AI understanding by default
- Repositories contain explicit operational and architectural context
- AI agents can analyze, maintain, and evolve production systems
- Managed Services delivery becomes partially autonomous and standardized

This repository is not product code.

It is a system of operational intelligence for software maintenance and evolution.

---

## Core Principle

Always prioritize:

1. Correctness over assumptions
2. Evidence over speculation
3. Structure over narrative
4. Operational value over theoretical completeness

If something is unknown, explicitly mark it as unknown.

Never hallucinate project-specific facts.

---

## Primary Use Cases

This repository supports:

- Discovery Agent (generating .ai folders in client projects)
- Maintainer Agent (keeping documentation in sync with reality)
- Agent definition and orchestration
- Managed Services standardization
- Cross-project operational consistency

---

## Key Concept: .ai Folder Standard

Every Managed Services project should contain an .ai folder generated from these standards.

The .ai folder is the single source of truth for project intelligence and includes:

- project-context.md
- architecture.md
- runbooks.md
- dependencies.md
- cms.md
- operational-context.md
- coding-standards.md
- agent-registry.md
- onboarding.md

These files describe how the system works, how it is operated, and how it is maintained.

---

## AI Behavior Rules

When working in this repository:

### 1. Be evidence-driven
Only infer architecture or behavior from:
- Source code
- Config files
- CI/CD pipelines
- Documentation present in repo

If not found, explicitly mark:

> Unknown or Not Found in Repository

---

### 2. Be structured
Always prefer:

- Sections
- Tables
- Bullet points
- Clear hierarchies

Avoid vague explanations.

---

### 3. Be operationally focused
Every output should answer:

- How is this system built?
- How is it operated?
- How is it maintained?
- What breaks, and how is it fixed?

---

### 4. Be agent-aware
Assume outputs will be consumed by AI agents.

Therefore:

- Avoid ambiguity
- Avoid conversational filler
- Use explicit naming
- Use deterministic structure

---

## Primary Workflows Supported

### 1. Project Discovery Workflow

Input:
- Existing repository

Output:
- Complete .ai folder
- Fully populated operational and architectural context

---

### 2. Project Maintenance Workflow

Input:
- Existing .ai folder + updated codebase

Output:
- Updated .ai files reflecting real system state

---

### 3. Agent Definition Workflow

Input:
- Required capability (e.g. security, CMS upgrade, accessibility)

Output:
- Structured agent definition that can operate across projects

---

## Repository Structure Meaning

- /standards → Defines system-wide rules
- /agents → Defines AI agent behaviors and capabilities
- /templates → Reusable structures for .ai generation
- /prompts → Executable instructions for AI systems
- /docs → Strategic vision and roadmap

---

## Non-Goals

This repository does NOT:

- Contain application business logic
- Replace project-specific documentation
- Define runtime systems for production apps
- Store client-specific information

---

## Output Quality Expectations

All generated artifacts must:

- Be production usable
- Be deterministic in structure
- Be grounded in real repository data
- Include missing information sections
- Include validation questions for humans

---

## North Star

Transform Managed Services from:

> reactive ticket-based delivery

into:

> AI-augmented, continuously maintained, self-documenting engineering systems

Where:

- Humans handle decision making and edge cases
- AI handles analysis, synthesis, and maintenance work
- Documentation never becomes stale
- Every system is continuously understandable

---

## Final Rule

If unsure how to proceed:

Do not guess.

Instead:

- State assumptions explicitly
- Ask for clarification via structured questions
- Prefer completeness over speed only when evidence exists