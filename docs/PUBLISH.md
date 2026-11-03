# Publish this repo to GitHub (git + SSH only)

Git cannot create a GitHub repository by itself. Create an **empty** public repo once, then push.

1. Open: https://github.com/new
2. Repository name: `fire-tv-launcher`
3. Public, **no** README / .gitignore / license (this tree already has them)
4. Create repository
5. From this folder:

```bash
cd /path/to/FiretvHD   # or fire-tv-launcher clone path
git remote add origin git@github.com:vishnubalachandran596/Clean-Fire-TV.git   # if needed
git push -u origin main
```

SSH must already work: `ssh -T git@github.com`
