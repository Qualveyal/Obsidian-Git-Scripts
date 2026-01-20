main - sat-1 - sat-2


Step 1:
- **Setup**
```shell
# Configurations
VAULT_PATH="/home/qual/Code/Vault-Test-Git"

# Code
cd "$VAULT_PATH" 

git init
git add .; git commit; # Initial Commit.
git remote add origin https://github.com/Qualveyal/Vault-Test-Git.git
git branch -M main # master to main
git push -u origin main

# Create Satellites and push them
git switch -c sat-1; git push origin sat-1;
git switch -c sat-2; git push origin sat-2;

# On other devices
git clone https://github.com/Qualveyal/Vault-Test-Git.git
```

- **Helpers**
```shell
# add and commit
git switch main; git add .; git commit; git push origin main;
git switch sat-1; git add .; git commit; git push origin sat-1;
git switch sat-2; git add .; git commit; git push origin sat-2;


git fetch --all

# From sat-1 Device
git switch sat-2; git merge origin/sat-2; git switch sat-1;

git merge sat-2
## fix conflicts

# Make the main equal to sat-1
git switch main; git reset --hard sat-1; git switch sat-1;
## Make Sat-2 equal to main (and sat-1, ALL EQUAL)
git switch sat-2; git reset --hard main; git switch sat-1;

## Use merge
git switch main; git merge sat-1; git switch sat-1;
# Make Sat-2 equal to main (and sat-1, ALL EQUAL)
git switch sat-2; git merge main; git switch sat-1;

git push --all


# From sat-1 Device
git switch sat-1; git merge origin/sat-1; git switch sat-2;
git switch sat-2; git merge origin/sat-2; git switch sat-1;
```
