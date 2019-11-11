## Code Indexer

A Docker Image for code search that support:

- [Hound](https://github.com/hound-search/hound)
- [OpenGrok](https://oracle.github.io/opengrok/)

and put the search behind [nginx](https://nginx.org/)
the configuration is [repositories.jsonnet](https://github.com/dyno/code-indexer/tree/master/scripts/repositories.jsonnet)

### Run


You can create a `scripts/repos.jsonnet` which will map to `scripts/repositories.jsonnet` inside docker,
basically overwrite the repositories configuration.

```bash
make docker-run
```

- <http://localhost:8129/hound/> Hound
- <http://localhost:8129/source/> OpenGrok

### Build

```bash
make docker-build
```
