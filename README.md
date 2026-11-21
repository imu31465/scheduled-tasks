# scheduled-tasks

Shared public GitHub Actions runner repository for projects whose source code
and application data remain in separate repositories. Workflows clone their
source at runtime using project-specific read-only deploy keys.

## Pandra

- `.github/workflows/pandra-ci.yml`: mirrors Pandra's Linux and Windows CI
  on public runners.
- `.github/workflows/pandra-b-budget.yml`: manual browser-budget measurements.
- These workflows use `PANDRA_DEPLOY_KEY` and their own concurrency groups.

## Bloxd Player Search

- `.github/workflows/census.yml`: moving-frontier ID discovery, split into
  four non-overlapping runner shards. Each shard writes to Neon; only the
  finalizer advances the shared cursor after all receipts validate.
- `.github/workflows/sweep.yml`: five parallel profile/rank refresh shards.
- `.github/workflows/enrich.yml`: daily changed-profile enrichment.
- `.github/workflows/name-scan.yml`: manual name-availability scan.
- These workflows use the Player Search deploy key and Neon credentials, and
  have project-specific concurrency groups.

## Player Search storage migration (prepared, not activated)

A separate change is being prepared to move Player Search from one full Neon Free project to four free projects using a stable 64-bucket map. The change adds these expected repository secrets to the census, enrich, sweep, and name-scan jobs:

- `SHARD_01_DATABASE_URL`: direct secret for the shard-01 control database; must exactly match the shard-01 value in the JSON below.
- `SHARD_DATABASE_URLS`: JSON object containing all four Neon PostgreSQL connection strings.
- `SHARD_BUCKET_MAP`: JSON array of exactly 64 shard names.

The original `DATABASE_URL` secret is left untouched. The workflows in this branch use only the new names, so missing secrets fail rather than silently writing to the old database or to one shard only.

**Do not merge this branch or add the new secrets until the private source repository has been updated on its `runner` branch, the initial data copy to all four projects has passed per-bucket verification, and the Altare reader has been deployed and tested.** Current `main` workflows and schedules are unchanged. The change is prepared on `feature/neon-free-sharding` only.

The 64 storage buckets are separate from the census workflow's four ID-range workers and the sweep workflow's five execution workers. Every writer must use the same player-ID-to-storage-bucket mapping.

## Isolation

Pandra and Player Search workflows execute independently; sharing this
orchestration repository does not serialize them. Their concurrency groups
are separate. The trade-off is that GitHub repository secrets share one
repository-level namespace, so every workflow maintainer must be trusted with
the repository's automation configuration.

Keep each project's workflows separate from the other project's files.
Do not create one repository per matrix shard: parallel workers belong inside
their project's workflow. A future split into dedicated Pandra and Player
Search runner repositories is appropriate if stronger secret/permission
isolation is needed; migrate repository secrets before disabling any of the
current workflows.
