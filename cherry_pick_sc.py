import subprocess
import sys
import os

commits_to_keep = [
    "ca32ecd",
    "0f40488",
    "bc7ed98",
    "815dba2",
    "6e54b15",
    "c4f2233",
    "d197ad2"
]

def run(cmd, env=None, check=True, input=None):
    res = subprocess.run(cmd, shell=True, env=env, input=input, capture_output=True, text=True)
    if check and res.returncode != 0:
        print(f"Command failed: {cmd}")
        print(res.stderr)
        sys.exit(1)
    return res

print("Sorting commits chronologically...")
# git log --reverse --format="%h" main will give all SHAs oldest to newest
all_commits_output = run('git log --reverse --format="%h" main').stdout.strip().split('\n')

sorted_commits = []
for c in all_commits_output:
    if c in commits_to_keep:
        sorted_commits.append(c)

print(f"Sorted commits to keep: {sorted_commits}")

if len(sorted_commits) != len(commits_to_keep):
    print("WARNING: Not all requested commits were found in the history!")

root_commit = sorted_commits[0]

print("Setting up orphan branch...")
run(f"git checkout {root_commit}")
run("git checkout --orphan epochsend-sc-filtered")
run("git rm -rf .", check=False)
run(f"git checkout {root_commit} -- .")

env = os.environ.copy()
env['GIT_AUTHOR_NAME'] = run(f"git log -1 --format='%an' {root_commit}").stdout.strip()
env['GIT_AUTHOR_EMAIL'] = run(f"git log -1 --format='%ae' {root_commit}").stdout.strip()
env['GIT_AUTHOR_DATE'] = run(f"git log -1 --format='%ad' {root_commit}").stdout.strip()
env['GIT_COMMITTER_NAME'] = run(f"git log -1 --format='%cn' {root_commit}").stdout.strip()
env['GIT_COMMITTER_EMAIL'] = run(f"git log -1 --format='%ce' {root_commit}").stdout.strip()
env['GIT_COMMITTER_DATE'] = run(f"git log -1 --format='%cd' {root_commit}").stdout.strip()
msg = run(f"git log -1 --format='%B' {root_commit}").stdout

run("git add -A")
run("git commit -F -", env=env, input=msg)

print("Cherry picking remaining commits...")
for sha in sorted_commits[1:]:
    print(f"Cherry picking {sha}...")
    
    env['GIT_AUTHOR_NAME'] = run(f"git log -1 --format='%an' {sha}").stdout.strip()
    env['GIT_AUTHOR_EMAIL'] = run(f"git log -1 --format='%ae' {sha}").stdout.strip()
    env['GIT_AUTHOR_DATE'] = run(f"git log -1 --format='%ad' {sha}").stdout.strip()
    env['GIT_COMMITTER_NAME'] = run(f"git log -1 --format='%cn' {sha}").stdout.strip()
    env['GIT_COMMITTER_EMAIL'] = run(f"git log -1 --format='%ce' {sha}").stdout.strip()
    env['GIT_COMMITTER_DATE'] = run(f"git log -1 --format='%cd' {sha}").stdout.strip()
    
    res = subprocess.run(f"git cherry-pick {sha}", shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Conflict on {sha}, attempting to auto-resolve...")
        
        files_changed = run(f"git diff-tree --no-commit-id --name-only -r {sha}").stdout.strip().split('\n')
        
        for file in files_changed:
            if file:
                run(f"git checkout {sha} -- {file}", check=False)
        
        run("git add -A")
        msg = run(f"git log -1 --format='%B' {sha}").stdout
        commit_res = subprocess.run("git commit -F -", shell=True, env=env, input=msg, capture_output=True, text=True)
        if commit_res.returncode != 0:
            print(f"Commit failed for {sha}. Maybe it became empty after resolution.")
            run("git cherry-pick --abort", check=False)
            continue
    else:
        run("git commit --amend --no-edit", env=env)

print("Done building history.")
