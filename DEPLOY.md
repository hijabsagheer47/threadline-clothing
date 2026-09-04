# CI/CD — GitHub se IONOS par auto deploy

Jaise hi `main` branch par push hoti hai, GitHub Actions tests chalata hai aur phir
saari site files IONOS webspace par SFTP se upload kar deta hai.

Workflow file: [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)

---

## 1. IONOS se SFTP credentials lein

IONOS panel → **Hosting → SFTP & SSH** (ya *Webspace / FTP Access*) par ye 4 cheezein milengi:

| Cheez | Value |
|---|---|
| Server / Host | `access-5020843190.webspace-host.com` |
| Port | `22` (SFTP) |
| Username | `a1667790` |
| Password | jo aapne SFTP user `a1667790` ke liye set kiya |

Ye account `/mytechrcm` directory tak restricted hai (IONOS panel -> **Manage secure FTP accounts**).

> Agar password yaad nahi, IONOS panel se **naya password set** kar lein — GitHub ko wahi dena hai.

---

## 2. GitHub par Secrets add karein

Repo → **Settings → Secrets and variables → Actions → Secrets → New repository secret**

| Secret name | Value |
|---|---|
| `SFTP_HOST` | `access-5020843190.webspace-host.com` |
| `SFTP_USERNAME` | `a1667790` |
| `SFTP_PASSWORD` | us user ka password |
| `SFTP_PORT` | `22` *(optional — na dein to 22 use hoga)* |

Direct link: https://github.com/hijabsagheer47/threadline-clothing/settings/secrets/actions

---

## 3. Remote path set karein (optional)

Usi page par **Variables** tab → **New repository variable**:

| Variable | Value |
|---|---|
| `REMOTE_DIR` | `/mytechrcm/tayyabacollective` |

Ye variable na banayein to bhi default yahi path use hota hai.

**Confirmed:** SFTP account `a1667790` `/mytechrcm` par chroot hai, is liye login ke
baad asli path **`/tayyabacollective`** banta hai. Workflow ye khud detect kar leti hai —
aapko `REMOTE_DIR` chhedne ki zaroorat nahi.

---

## 4. Test karein

```bash
git add .github/workflows/deploy.yml DEPLOY.md
git commit -m "Add CI/CD pipeline for IONOS deployment"
git push origin main
```

Phir dekhein: https://github.com/hijabsagheer47/threadline-clothing/actions

---

## Pipeline kya karti hai

1. **test** job — `node --test tests/*.test.js` chalata hai. Test fail ho to deploy **nahi** hota.
2. **deploy** job — pehle remote path resolve karta hai (SFTP account `/mytechrcm` par
   scoped hai, is liye `/mytechrcm/tayyabacollective` aur `/tayyabacollective` dono try
   hote hain), phir `lftp` se SFTP mirror. Sirf badli hui files upload hoti hain (fast).

Server par **upload nahi** hone wali cheezein:
`.git/`, `.github/`, `.gitignore`, `node_modules/`, `tests/`, `images/sources/`, `README.md`, `DEPLOY.md`

## Purani files delete karna

Normally deploy sirf files **add/update** karta hai, kuch delete nahi karta (safe default —
server par manually upload ki hui cheezein bachi rehti hain).

Agar server ko repo ka exact copy banana ho:
Actions → **Deploy to IONOS** → **Run workflow** → *"Server par woh files bhi delete karein…"*
ko tick karke chalayein.

## Server par purani files

Deploy se pehle manually upload ki gayi `README.md` aur `tests/` folder server par
mojood hain. Workflow inhein exclude karti hai, is liye ye kabhi update nahi hongi.
Chahein to IONOS Webspace Explorer se delete kar dein.

## Manually deploy

Actions → **Deploy to IONOS** → **Run workflow** → branch `main` → Run.
