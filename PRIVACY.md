# Privacy Policy

**Effective Date:** January 20, 2026

## Data Collection

**INVI Ledger does not collect, transmit, or store any data about you or your usage.**

## What This Means

- **No telemetry**: The software does not send usage statistics, analytics, or diagnostic data
- **No tracking**: We do not track how you use the software
- **No phone home**: The software does not communicate with any external servers operated by us
- **No user accounts**: INVI Ledger does not require or maintain user accounts with us

## Your Data

All data you enter into INVI Ledger:
- Remains entirely on your infrastructure
- Is stored in your PostgreSQL database under your control
- Is never transmitted to us or any third party
- Is your property and responsibility

## Network Communication

INVI Ledger only communicates with:
- Your PostgreSQL database (on your infrastructure)
- Docker registries when pulling updates (standard Docker behavior)
- Any external systems **you** configure it to integrate with via its API

## Updates and Support

- Software updates are distributed via Docker images from public container registries
- Pulling images follows standard Docker registry protocols and is subject to the registry provider's policies (GitHub, Docker Hub, etc.)
- We do not track who downloads or uses INVI Ledger

## Changes to This Policy

If we ever change our data collection practices, we will update this policy and the effective date above.

---

**In summary: We don't collect your data. Period.**
