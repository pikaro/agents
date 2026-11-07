# Kubernetes Work

## Default Boundary

- Treat this repository as the desired-state source of truth.
- Prefer GitOps changes over imperative cluster changes.
- Do not mutate the live cluster unless the user explicitly asks for a live
    cluster change.
- A request to change configuration means edit repo manifests/values and
    validate them; it does not imply kubectl apply.

## Evidence Order

Use this order when investigating or validating:

1. Read the checked-in repo files.
2. Render locally with helm template, kubectl kustomize, yq, and available
    schema tools.
3. Inspect live state through the read-only Kubernetes MCP server.
4. Use kubectl apply --dry-run=server only when live API validation is needed.
5. Perform real cluster mutations only on explicit user instruction.

## Structure

- All Kubernetes manifests, Helm charts, and Kustomize overlays are stored in
    the repo.
- ArgoCD uses ApplicationSets to deploy the repo contents to the live cluster.
- The ApplicationSets are configured from a catalog; any set of resources must
    have *both* a catalog entry and a corresponding service directory.
- Where applications publish Helm charts, prefer using them unmodified with
    values.yaml in the service directory.
- You may use `requirements` and `resources` directories with
    `kustomization.yaml` configuring `sync-wave` in the service directory to add
    resources that must exist before and after the main application manifests.
- `requirements` and `resources` *must* only be used for *exceptions* to the
    rule. If you find yourself adding a specific resource or pattern to
    `requirements` or `resources` for all or many services, pause to consider
    whether there is a more suitable location, and otherwise require permission
    from the user.
- For custom sets of resources that are not Helm charts, such as service
    accounts or RBAC, prefer using `kustomization.yaml` with the associated
    manifests directly in the service directory.

## DNS

### Cluster domain

- The external cluster domain is `k8s.d-reis.com`.
- `external-dns` and `cert-manager` have full access to this zone.
- Use this zone to create public DNS records that are not expected to be typed
    into a browser and relate to cluster operation itself.
- For example, the public OIDC metadata endpoint for the cluster is
    `https://oidc.k8s.d-reis.com/.well-known/openid-configuration`.

### Service domain

- The external service domain is `d-reis.com`.
- `external-dns` may create CNAMEs in this zone, but *not* its subdomains except
    for `k8s.d-reis.com`. Specific high-criticality CNAMEs may also be blocked
    by Route53 IAM policies.
- `cert-manager` may create ACME validation records in this zone, but *not* its
    subdomains except for `k8s.d-reis.com`.
- Use this domain for public services that are expected to be typed into a
    browser or otherwise accessed by end users. You should in general create at
    most one public DNS record per service, and only if the service exposes a
    web interface, API or similar public service to end users. Admin-only
    services, such as the Traefik dashboard, should not be exposed in this
    domain.
- The subdomain for each service should be short and memorable. It may include
    the service name or a shortened version of it, such as `argo` for ArgoCD, or
    use a common mnemonic like `sso` for `Authentik`.
- For example, the public Vaultwarden login page is `https://pwd.d-reis.com`.

## Application types

- `platform` services are foundational to the cluster and are expected to be
    present in all environments. Examples: ArgoCD, external-secrets,
    cert-manager. `platform` applications may typically have cluster-wide scope.
- `base` services are shared across multiple environments and are expected to be
    present in all environments. Examples: PostgreSQL, Authentik. `base`
    applications should typically have namespace scope.
- `app` services are individual workloads. They make use of `platform` and
    `base` services. `app` applications should have namespace scope.

## Isolation boundaries

- Each service directory is a self-contained unit of configuration and
    deployment.
- Each service directory should typically contain a single Helm chart or
    Kustomize overlay that deploys into a single namespace. Rarely, sibling
    applications may deploy into the same namespace from two or more service
    directories.
- Each service directory should have a single `kustomization.yaml` or
    `values.yaml` file that is the entry point for rendering the service.
- `external-secrets` should be used as a targeted synchronization mechanism for
    single secrets that must be shared across namespaces, such as auto-generated
    PostgreSQL passwords.

## Kubernetes MCP

- Use the Kubernetes MCP server only as a read-only inspection surface.
- Use MCP, not kubectl, for live read-only inspection unless the user explicitly
    authorizes kubectl access.
- Allowed MCP operations: list/get resources, inspect object state, read pod
    logs.
- Do not use MCP tools for create/update/delete, pod exec, pod run, or other
    mutation paths, even if tools appear in discovery.
- Do not read Kubernetes Secret objects through MCP.
- Treat MCP output as live-state evidence, not as a replacement for repo review.

## Client-Side Validation

Before asking for live API access, run local checks where applicable:

- yq eval '.' ... for YAML syntax.
- kubectl kustomize <path> for Kustomize resources.
- helm template ... -f values.yaml for Helm charts.
- git diff --check for whitespace/conflict markers.
- Prefer repo-local validation scripts if present.

## Server-Side Dry Run

- Use `kubectl apply --dry-run=server` for API-schema/defaulting/admission
    validation when local rendering is insufficient.
- Server-side dry-run may require administrative credentials and sandbox
    escalation.
- Dry-run is validation only; it must not be described as deploying or applying
    the change.
- If a dry-run fails because a namespace is created in the same manifest,
    validate cluster-scoped/existing-namespace objects separately and state the
    limitation.

## Live Mutations

- Do not run real kubectl apply, delete, patch, annotate, label, rollout
    restart, scale, Helm install/upgrade, or similar mutation commands unless
    the user explicitly requested a live cluster change.
- If the user requested only a repo/configuration change, stop at repo edits
    plus validation.
- If a live mutation is requested, state what will be changed before running it
    and keep the command narrowly scoped.
- Never use live mutation as a shortcut for testing a manifest that can be
    rendered or dry-run first.
- Treat removing a manifest, catalog entry, chart value, or Kustomize reference
    as a potentially destructive change because ArgoCD may prune the live
    resource. Clearly identify deletions and likely prune effects in the summary
    and specify them to the user.

## Secrets

- *Never* store plain secrets in the repo or in any checked-in files.
- Do not inspect secret values unless the user explicitly requests it.
- Use generated secrets through `external-secrets` where possible.
- Use AWS SSM Parameter Store for secrets that should have off-cluster
    durability.
- Prefer validating secret references, names, namespaces, and ownership without
    reading data.
- If generated secrets are used, distinguish Kubernetes-local durability from
    off-cluster durability such as SSM or backups.
