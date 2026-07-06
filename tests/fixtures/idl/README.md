# IDL Parity Fixtures

Generate LASCO IDL parity outputs with:

```bash
scripts/idl/run_lasco_parity.sh tests/fixtures/idl/lasco_parity.json
```

The command assumes that IDL can start with SolarSoft/LASCO on its path. Commit
the resulting JSON when available so Python tests can compare against exact IDL
outputs.
