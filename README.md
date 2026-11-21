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


## Player Search runner split (staged)

The dedicated public runner repository is now
[`bloxd-player-search-tasks`](https://github.com/imu31465/bloxd-player-search-tasks).
Its four Player Search workflows have been copied there with a fail-closed
`PLAYER_SEARCH_SHARD_CUTOVER=ready` job gate. The new workflows are inert
until that repository variable is explicitly set.

The existing Player Search workflow files in this repository remain unchanged
as the rollback path while the Neon migration and Altare reader are being
verified. Their latest observed scheduled runs should be checked in Actions;
this note does not claim that every schedule is currently firing. Do not delete
or disable these workflows until the new repository has its secrets configured,
the shard-aware source `runner` branch is accepted, the data migration reports
`VERIFICATION PASSED`, the Altare reader is checked, and a manual run in the
new repository succeeds. After
cutover, remove only the Player Search workflows from this repository; keep
Pandra workflows and `PANDRA_DEPLOY_KEY` here.
