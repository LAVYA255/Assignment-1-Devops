# Git / GitHub

Both tasks were run in throwaway repositories so the demonstration commits stay out of this repository's own history. Every output block below is real terminal output.

---

## Task 1 - `git commit -a -m` vs `git commit -m`

### The difference

Git has three areas: the **working directory** (your files), the **staging area / index** (what will go into the next commit), and the **repository** (committed history).

| | `git commit -m "msg"` | `git commit -a -m "msg"` |
|---|---|---|
| What it commits | Only what is **already staged** with `git add` | Automatically stages **all modified tracked files**, then commits |
| Modified tracked files | Ignored unless staged | **Included** |
| New (untracked) files | Ignored | **Still ignored** |
| Deleted tracked files | Ignored unless staged | **Included** |
| Steps | `git add` then `git commit` | One step |

The critical point, and the usual interview follow-up: **`-a` does not add untracked files.** It only picks up files Git is already tracking. A brand-new file must always be `git add`-ed first.

`-a` is a convenience for the common "I edited a few files that Git already knows about" case. It is worth being deliberate about, because it stages *every* modified tracked file - including changes you may not have meant to commit. Staging explicitly with `git add` gives you control over what goes into each commit.

### Commands

```bash
git commit -m "message"       # commits only what is staged
git add file.txt              # stage a specific file
git commit -a -m "message"    # auto-stage modified TRACKED files, then commit
git status --short            # M = modified, ?? = untracked
```

### Practical demonstration and output

```console
########## SETUP: one tracked file, already committed ##########
f2f2782 Initial commit: add file.txt

==================================================================
 PART A: 'git commit -m'  (WITHOUT -a)
==================================================================
Modify the TRACKED file, and also create a NEW untracked file:

$ git status --short
 M file.txt
?? newfile.txt
   M = modified but NOT staged   |   ?? = untracked

$ git commit -m 'try to commit without staging'
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   file.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

no changes added to commit (use "git add" and/or "git commit -a")

>>> RESULT: the commit FAILED. 'git commit -m' only commits what is
>>> already in the staging area, and nothing was staged.

$ git log --oneline   (still just the one commit)
f2f2782 Initial commit: add file.txt

==================================================================
 PART B: 'git commit -a -m'
==================================================================
$ git commit -a -m 'commit tracked changes automatically'
[main 976571d] commit tracked changes automatically
 1 file changed, 1 insertion(+)

$ git log --oneline
976571d commit tracked changes automatically
f2f2782 Initial commit: add file.txt

$ git status --short
?? newfile.txt

>>> RESULT: -a auto-staged the MODIFIED TRACKED file (file.txt) and
>>> committed it in one step.
>>> BUT newfile.txt is STILL untracked (?? above) -- -a does NOT add new files.

==================================================================
 PART C: proving -a ignores UNTRACKED files
==================================================================
$ git commit -a -m 'does this pick up newfile.txt?'
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	newfile.txt

nothing added to commit but untracked files present (use "git add" to track)

>>> Nothing to commit: newfile.txt is invisible to -a.

The only way to commit a NEW file is to 'git add' it first:
$ git add newfile.txt && git commit -m 'add newfile.txt explicitly'
63bdbae add newfile.txt explicitly
976571d commit tracked changes automatically
f2f2782 Initial commit: add file.txt

$ git status
(clean)
```

### What the output proves

1. **Part A** - with `file.txt` modified and `newfile.txt` untracked, `git commit -m` **refused to commit**: `no changes added to commit (use "git add" and/or "git commit -a")`. The log still shows only the initial commit.
2. **Part B** - `git commit -a -m` succeeded immediately: `[main 976571d] ... 1 file changed, 1 insertion(+)`. It auto-staged the modified tracked file.
3. **Part C** - running `git commit -a -m` again reports `nothing added to commit but untracked files present`. This is the proof that **`-a` never picks up new files**; `newfile.txt` had to be `git add`-ed explicitly.

---

## Task 2 - Git Cherry-Pick

### What cherry-pick does

`git cherry-pick <hash>` takes the **change introduced by one specific commit** and replays it onto the current branch. It is how you pull a single fix out of a feature branch - for example a hotfix that must ship now, while the rest of that branch is not ready to merge.

Merge and cherry-pick are different tools: **merge** brings across the entire history of a branch, whereas **cherry-pick** copies one commit's diff. The copy is a *new* commit with a **new hash**, because its parent is different.

### Commands

```bash
git log --oneline                # find the commit
git log --oneline --grep="TEXT"  # search commit messages
git show <hash> --stat           # inspect what a commit changed
git checkout main                # switch to the target branch
git cherry-pick <hash>           # replay that one commit here
git cherry-pick --abort          # bail out if it conflicts
git log --oneline --all --graph  # see the result across branches
```

### Practical demonstration and output

```console
==================================================================
 STEP 1: Create 4 commits on the main branch
==================================================================
$ git log --oneline
be91e10 C4: add gitignore
6595cf4 C3: add config.txt
aa674bc C2: add app.py
bee27d3 C1: add README

$ ls   (files on main)
.git
.gitignore
README.md
app.py
config.txt

==================================================================
 STEP 2: Create a new branch and switch to it
==================================================================
$ git checkout -b feature
wsl : Switched to a new branch 'feature'
At line:1 char:581
+ ... chpad\out'; wsl -d Ubuntu -u lavya -- bash "$sp/git_task2.sh" > "$o\g ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Switched to a new branch 'feature':String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 

==================================================================
 STEP 3: Make 3 commits on the feature branch
==================================================================
$ git log --oneline
099896d F3: add documentation
333ba94 F2: HOTFIX - the commit we will cherry-pick
e780694 F1: add auth module
be91e10 C4: add gitignore
6595cf4 C3: add config.txt
aa674bc C2: add app.py
bee27d3 C1: add README

$ ls   (files on feature)
.git
.gitignore
README.md
app.py
auth.py
config.txt
docs.md
hotfix.txt

==================================================================
 STEP 4: Use git log to identify the SPECIFIC commit to pick
==================================================================
$ git log --oneline --grep=HOTFIX
333ba94 F2: HOTFIX - the commit we will cherry-pick

The commit we want is: 333ba94

$ git show 333ba94 --stat
commit 333ba945649e5be5e507772bf9b1ee70828fbdb9
Author: Lavya <lavtanotra@gmail.com>
Date:   Thu Sep 3 18:37:28 2026 +0000

    F2: HOTFIX - the commit we will cherry-pick

 hotfix.txt | 1 +
 1 file changed, 1 insertion(+)

==================================================================
 STEP 5: Switch back to main
==================================================================
Switched to branch 'main'

$ git log --oneline   (main is still at C4 - no feature work here)
be91e10 C4: add gitignore
6595cf4 C3: add config.txt
aa674bc C2: add app.py
bee27d3 C1: add README

$ ls   (hotfix.txt is NOT here yet)
.git
.gitignore
README.md
app.py
config.txt

==================================================================
 STEP 6: CHERRY-PICK that one commit into main
==================================================================
$ git cherry-pick 333ba94
[main c530656] F2: HOTFIX - the commit we will cherry-pick
 Date: Thu Sep 3 18:37:28 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.txt

==================================================================
 STEP 7: VERIFY the change is now on main
==================================================================
$ git log --oneline
c530656 F2: HOTFIX - the commit we will cherry-pick
be91e10 C4: add gitignore
6595cf4 C3: add config.txt
aa674bc C2: add app.py
bee27d3 C1: add README

$ ls   (hotfix.txt has arrived)
.git
.gitignore
README.md
app.py
config.txt
hotfix.txt

$ cat hotfix.txt
CRITICAL BUGFIX applied

>>> Note: F1 (auth.py) and F3 (docs.md) did NOT come across --
>>> only the single commit we selected.
auth.py absent  <-- correct
docs.md absent  <-- correct

$ git log --oneline --all --graph   (the cherry-picked commit has a NEW hash)
* 099896d F3: add documentation
* 333ba94 F2: HOTFIX - the commit we will cherry-pick
* e780694 F1: add auth module
| * c530656 F2: HOTFIX - the commit we will cherry-pick
|/  
* be91e10 C4: add gitignore
* 6595cf4 C3: add config.txt
* aa674bc C2: add app.py
* bee27d3 C1: add README
```

### What the output proves

Following the required steps exactly:

1. **4 commits created on `main`** - C1 through C4, listed with `git log --oneline`.
2. **A new branch created** - `git checkout -b feature`.
3. **3 commits made on `feature`** - F1, F2 (the hotfix) and F3.
4. **`git log` used to identify one specific commit** - `git log --oneline --grep="HOTFIX"` found `333ba94`, and `git show 333ba94 --stat` confirmed it adds `hotfix.txt`.
5. **Cherry-picked into `main`** - `git cherry-pick 333ba94` reported `[main c530656] ... create mode 100644 hotfix.txt`.
6. **Verified** - after the cherry-pick, `main` contains `hotfix.txt` with the correct content, while `auth.py` (F1) and `docs.md` (F3) are **absent**. Only the selected commit came across.

The final graph shows the mechanism clearly:

```
* 099896d F3: add documentation
* 333ba94 F2: HOTFIX - the commit we will cherry-pick     <-- original, on feature
* e780694 F1: add auth module
| * c530656 F2: HOTFIX - the commit we will cherry-pick   <-- the COPY, on main
|/
* be91e10 C4: add gitignore
```

The same change now exists on both branches under **two different hashes** (`333ba94` on `feature`, `c530656` on `main`). That is the defining characteristic of a cherry-pick: it copies the *change*, not the commit object itself.
