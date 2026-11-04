# PersonaOS Release-Gate Execution Plan

> Planning document for PersonaOS. The containing repository, kalmahdy326-lang/consent-first-creator-desk, is a separate Flutter application. This plan does not claim that its code is PersonaOS; Gate 1 must confirm the intended implementation source and integration boundary.

## Execution rules

- Work gates in order. Do not start a downstream gate while an upstream exit criterion is open.
- In Gate 1, inventory each test row and mark it Verified Correct, Defect Confirmed, or Requires Investigation, with evidence.
- Keep Android, voice, social posting, and multi-user features out of MVP scope.
- Treat local data, workspace isolation, immutable persona versions, and explicit provider consent as release requirements.

## Ten-week plan

| Week | Gate | Work and exit criteria |
|---|---|---|
| 1 | Source reconciliation | Identify the canonical PersonaOS checkout, branch, and owner; document architecture, migration inventory, command/event surface, and existing tests. Populate every matrix row with a status and evidence. Exit: source is confirmed and no matrix row is unclassified. No feature work this week. |
| 2 | A — Database | Verify WAL, foreign keys, busy timeout, migration transaction behavior, fresh migration, reopen, and repeat safety. Exit: DB-001–006 pass on fresh and reopened databases, including pooled connections. |
| 3 | A — Job engine | Verify enqueue/idempotency, lease ownership, heartbeat, expiry, retries, cancellation, and persisted state. Exit: JOB-001–016 pass. |
| 4 | A — Concurrency and recovery | Exercise simultaneous enqueue/claim, worker crash, stale lease reclaim, and isolation. Exit: CON-001–004 pass; one live lease owner and automatic recovery are demonstrated. Gate A closes. |
| 5 | B — Tauri shell | Validate Tauri v2 configuration, command permissions, event transport, and startup/shutdown. Exit: TAURI-001–008 pass; frontend communicates only through the intended command and event surface. |
| 6 | C — Import | Persist queued imports, process supported formats, retain errors/progress/retry state, restore history after restart, and define duplicate/re-import behavior. Exit: IMP-001–008 pass. |
| 7 | D — Memory | Implement bounded chunking, memory/source relationships, FTS or selected retrieval index, ranking, citations, and workspace filtering. Exit: MEM-001–007 pass with no cross-workspace result. |
| 8 | E — Personality | Implement persona/version/active/archive states, append-only updates, activation, and rollback. Exit: PERS-001–004 pass; active versions cannot be mutated. |
| 9 | F — AI twin | Build workspace-filtered retrieval, active-persona context, model adapter, response provenance, and explicit provider behavior. Exit: responses use the selected workspace and active version and return citations. |
| 10 | G — Vertical slice and release candidate | Run the complete flow on a clean profile and after restart; run regression, frontend, Rust, formatting, and release-build checks. Exit: all MVP criteria below pass and no release blocker remains. |

A failed exit criterion returns the work to its owning gate; later weeks move accordingly rather than skipping the gate.

## Vertical-slice test checklist

### Database — Gate A

- [ ] DB-001 WAL is active on every pooled connection.
- [ ] DB-002 Foreign-key enforcement is active on every pooled connection.
- [ ] DB-003 Busy timeout is configured and lock contention is bounded.
- [ ] DB-004 Failed migrations roll back without partial schema changes.
- [ ] DB-005 Fresh migrations apply successfully.
- [ ] DB-006 Reopen/reapply behavior is safe and leaves no schema drift.

### Job engine — Gate A

- [ ] JOB-001 Enqueue without an idempotency key creates one job.
- [ ] JOB-002 Repeated workspace/key enqueue returns the same job.
- [ ] JOB-003 The same key is isolated across workspaces.
- [ ] JOB-004 Failed retry preserves job identity and resets retry state as specified.
- [ ] JOB-005 Re-enqueue of active work does not replace its lease or progress.
- [ ] JOB-006 Invalid workspace and retry settings fail safely.
- [ ] JOB-007 A job is claimed atomically.
- [ ] JOB-008 Claim order is deterministic.
- [ ] JOB-009 Claim records worker, lease token, expiry, and attempt.
- [ ] JOB-010 A valid heartbeat extends the lease.
- [ ] JOB-011 Wrong worker or stale token cannot heartbeat.
- [ ] JOB-012 Expired leases cannot complete.
- [ ] JOB-013 Only the current lease owner can complete.
- [ ] JOB-014 Failures retry until the configured limit.
- [ ] JOB-015 Queued and running cancellation reach the documented terminal state.
- [ ] JOB-016 Expired work is reclaimed or failed after exhaustion.
- [ ] CON-001 Concurrent same-key enqueue creates one logical job.
- [ ] CON-002 Concurrent workers cannot own the same live lease.
- [ ] CON-003 Reclaimed work rejects completion by its former worker.
- [ ] CON-004 Concurrent work stays isolated by workspace and handler.

### Tauri shell — Gate B

- [ ] TAURI-001 Tauri v2 config and production asset paths validate.
- [ ] TAURI-002 Exposed commands and permissions are explicitly reviewed.
- [ ] TAURI-003 Commands validate inputs and enforce import limits.
- [ ] TAURI-004 No command grants unintended arbitrary filesystem access.
- [ ] TAURI-005 Queued, progress, success, and failure events reach the frontend.
- [ ] TAURI-006 Worker starts once and shuts down cleanly.
- [ ] TAURI-007 Startup recovers queued and expired work.
- [ ] TAURI-008 Production app launches and communicates with its backend.

### Import — Gate C

- [ ] IMP-001 TXT, Markdown, and JSON extraction is deterministic.
- [ ] IMP-002 Exactly 5 MiB is accepted; oversized, invalid UTF-8, malformed JSON, and unsupported files fail clearly.
- [ ] IMP-003 Submission and job status persist before processing starts.
- [ ] IMP-004 Restart restores queued, recoverable, and terminal import history.
- [ ] IMP-005 History queries return only the requested workspace.
- [ ] IMP-006 Error details, progress, and retry state are visible and durable.
- [ ] IMP-007 Normalized content deduplicates within a workspace and remains separate across workspaces.
- [ ] IMP-008 Duplicate and explicit re-import behavior is documented and tested.

### Memory — Gate D

- [ ] MEM-001 Chunk bounds hold for long, short, Unicode, and unbroken text.
- [ ] MEM-002 Each memory stores workspace, source, content, creation time, and metadata.
- [ ] MEM-003 Source changes/deletion keep memory and index state consistent.
- [ ] MEM-004 Results include source citation and chunk lineage.
- [ ] MEM-005 Every retrieval is workspace-filtered.
- [ ] MEM-006 Relevance ordering is deterministic for equivalent inputs.
- [ ] MEM-007 Cross-workspace references and retrieval are rejected.

### Personality — Gate E

- [ ] PERS-001 New persona state appends version N+1.
- [ ] PERS-002 Active versions cannot be edited or deleted.
- [ ] PERS-003 Activation validates workspace ownership.
- [ ] PERS-004 Rollback selects a prior version without rewriting history.

### End-to-end — Gate G

- [ ] Create two workspaces and verify isolation.
- [ ] Import supported content and observe queued/progress/terminal status.
- [ ] Restart during queued or running work and verify recovery.
- [ ] Restart after completion and verify import history and memory remain searchable.
- [ ] Retry a failed import and verify stable job identity and final outcome.
- [ ] Cancel queued and running work and verify persisted state.
- [ ] Import duplicate content and verify the documented dedup/re-import policy.
- [ ] Create and activate a persona version, then roll back.
- [ ] Ask the twin a question grounded in imported content and verify its citations and persona version.
- [ ] Confirm no result, source, or context crosses workspaces.

## MVP release criteria

Release only when all are true:

1. Gates A–G are closed with recorded evidence for every checklist row.
2. The end-to-end flow works on a clean install and after application restart.
3. WAL, foreign keys, migrations, retries, cancellation, stale-lease recovery, deduplication, and workspace isolation pass.
4. Import history and errors persist and remain accurate after restart.
5. Every memory and twin citation traces to a source in the selected workspace.
6. Active persona versions are immutable and rollback is tested.
7. Local data stays on-device by default; any remote model provider is opt-in before personal context is sent.
8. No unresolved high-severity data-loss, privacy, or cross-workspace defect remains.
9. Frontend production build, Rust tests, formatting, and release build pass on the canonical source.
10. Android, voice, social posting, and multi-user features remain out of MVP.

## Release evidence

For each gate, record the source commit/ref, commands run, test IDs passed/failed, environment, defects, and approved exceptions. A green build alone does not close a behavioral test row.