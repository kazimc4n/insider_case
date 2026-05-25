# ADR-001: Go

**Status:** Accepted

Go compiles to one static binary, which fits `distroless/static` and keeps the image small. `net/http` and `httptest` cover this service without extra frameworks. CI builds stay fast enough for a small pipeline.

**Trade-off:** anything that needs cgo is out; for three HTTP handlers that is fine.
