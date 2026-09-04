# Git and GitHub

I did both tasks in a throwaway repo so I wasn't experimenting on real work.

---

## Task 1: `git commit -m` vs `git commit -a -m`

Short version: `-a` automatically stages files git is **already tracking**, so you can skip `git add`. It does nothing for brand new files.

To show the difference I modified a tracked file (`file.txt`) and created a new untracked one (`newfile.txt`), then tried to commit without staging anything:

```console
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

The commit **refused to happen**. `git commit -m` only commits what's already staged, and I'd staged nothing.

Then `git commit -a -m` worked immediately, picking up the modified `file.txt` in one step. But `newfile.txt` was still sitting there untracked afterwards. Running `-a` again said "nothing added to commit but untracked files present". The only way to get a new file in is `git add` first.

So:

- `git commit -m` = commit what I already staged
- `git commit -a -m` = stage tracked changes and commit, in one step
- Neither one picks up new files. `-a` is a shortcut for `add` on *modified* files, not a catch-all.

That last part is the bit worth remembering, and it's why `git add .` is still a habit.

<details>
<summary>Full walkthrough</summary>

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

</details>

---

## Task 2: Cherry-pick

The setup: 4 commits on `main`, then a `feature` branch with 3 more. I wanted just the hotfix from `feature` on `main`, without dragging the other two commits along.

```
main:     C1 -- C2 -- C3 -- C4
feature:                     \-- F1 -- F2 (the hotfix) -- F3
```

I found the commit I wanted with `git log --oneline --grep=HOTFIX`, switched back to `main`, and picked it:

```console
 STEP 6: CHERRY-PICK that one commit into main
==================================================================
$ git cherry-pick 333ba94
[main c530656] F2: HOTFIX - the commit we will cherry-pick
 Date: Thu Sep 3 18:37:28 2026 +0000
 1 file changed, 1 insertion(+)
 create mode 100644 hotfix.txt


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

What this shows:

- `hotfix.txt` arrived on `main`, and `auth.py` and `docs.md` (F1 and F3) **did not**. Only the one commit came across.
- In the graph, the hotfix appears twice with **different hashes**: `333ba94` on `feature`, `c530656` on `main`.

That second point is the thing I actually took away. Cherry-pick doesn't move a commit, it replays the *change* as a brand new commit with a new hash and a new parent. Same diff, different identity. Which is also why cherry-picking a commit and later merging that branch can produce a conflict, since git sees two separate commits making the same edit.

<details>
<summary>Full walkthrough (all 7 steps)</summary>

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
Switched to a new branch 'feature'
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 

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

</details>
