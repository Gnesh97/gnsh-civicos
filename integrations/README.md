# Integration examples

External resources should call CivicOS public exports instead of importing
server internals. Use a stable `sourceResource`, pass `externalRef` when the
provider has one, and generate one idempotency key per logical mutation.

The examples below are intentionally minimal and safe to run only in a test
resource. They demonstrate request creation, lifecycle updates, and metadata
versioning.
