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
