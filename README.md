# scheduled-tasks

Scheduled maintenance jobs for a private project. Task sources are cloned at
runtime from a private repository with a read-only deploy key; this repository
only hosts the workflow definitions.

## Census

`census.yml` follows the Bloxd player-ID frontier without a fixed final ID.

- The prepare job reads the saved census cursor from Neon (initially falling
  back to the current highest stored player ID) and plans at most 40,000 IDs.
- Four matrix runners scan contiguous, non-overlapping ranges in parallel.
  Each uses eight HTTP probe threads and writes discovered players to Neon.
- Each runner records only a small range/count receipt in Neon. Player names
  are not uploaded as public Actions artifacts.
- The finalizer advances the shared cursor only after all four receipts are
  present and valid. It keeps a 2,000-ID overlap behind the highest discovered
  ID so the moving visibility edge is checked again.
- If any runner fails, the finalizer is skipped and the cursor is not advanced.
  A later scheduled run retries the outstanding range.

The workflow runs every 30 minutes. Each run takes a fresh cursor snapshot, so
new IDs appearing while a batch is running are picked up by later batches
without needing a hard-coded maximum ID.
