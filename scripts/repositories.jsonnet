local all_repositories = [
  {
    branch: 'master',
    name: 'code-indexer',
    url: 'https://github.com/dyno/code-indexer.git',
  },
];

local repositories = all_repositories;
// DEBUG: fast startup ...
// local repositories = [repo for repo in all_repositories if repo.name == 'devops' || repo.name == 'dev-tools'];

// https://github.com/hound-search/hound/blob/master/config-example.json
local hound_config(repositories) = {
  'max-concurrent-indexers': 8,
  dbpath: 'hound_data',
  repos: {
    [if repo.branch == 'master' then repo.name else repo.name + '-' + repo.branch]: {
      local dirname = if repo.branch == 'master' then repo.name else repo.name + '-' + repo.branch,
      url: repo.url,
      'exclude-dot-files': true,
      'url-pattern': {
        'base-url': 'http://localhost:8129/source/xref/%s/{path}{anchor}' % dirname,
        anchor: '#{line}',
      },
      // https://github.com/hound-search/hound/pull/275, Add ability to use custom branch from vcs config for git
      'vcs-config': {
        ref: repo.branch,
      },
    }
    for repo in repositories
  },
};

{
  'repositories.json': std.manifestJson(repositories),
  'hound_config.json': std.manifestJson(hound_config(repositories)),
}
