# Cloudflare Integration - Complete Guide

**Your tvOS app is now connected to Cloudflare D1 and R2!** ✅

---

## Quick Reference

### Your Configuration
- **Worker URL**: `https://reccs-movies-api.evangedrich.workers.dev/api/movies`
- **R2 Images**: `https://images.reccs.media/posters/{MOVIE_ID}.webp`
- **Database**: `reccs-media` (Cloudflare D1)
- **Toggle**: Edit `CloudflareConfig.swift` → `useCloudflare = true/false`

### Quick Commands
```bash
# Redeploy Worker
npx wrangler@latest deploy

# Test Worker
curl https://reccs-movies-api.evangedrich.workers.dev/api/movies | jq 'length'

# Test Image
curl -I https://images.reccs.media/posters/AFNOCFF.webp
```

---

## How It Works

1. **App starts** → `ReccsApp` creates `MovieStore` with Cloudflare config
2. **MovieStore** → Calls `CloudflareService.fetchMovies()`
3. **CloudflareService** → GET request to Worker
4. **Worker** → Queries D1, filters for CFF/GFF/CSF, transforms to JSON
5. **App** → Receives movies, displays with R2 images

---

## Files You Have

### Essential (Don't Delete)
- `CloudflareService.swift` - Network layer
- `CloudflareConfig.swift` - Configuration
- `R2ImageView.swift` - Image loading
- `MovieStore.swift` - Data management
- `worker.js` - Worker code
- `wrangler.toml` - Worker config

### Modified (Keep Your Changes)
- `ReccsApp.swift` - Injects Cloudflare config
- `ContentView.swift` - Uses environment
- `SubregionDetailView.swift` - Uses environment
- `GlobeView.swift` - Uses environment
- `MovieDetailView.swift` - Uses R2 images
- `MovieCard.swift` - Uses R2 images

---

## Configuration

**File**: `CloudflareConfig.swift`

```swift
struct CloudflareConfig {
    static let d1APIEndpoint = "https://reccs-movies-api.evangedrich.workers.dev/api/movies"
    static let r2BaseURL = "https://images.reccs.media"
    static let useCloudflare = true  // Toggle here
}
```

**Switch to local JSON**: Set `useCloudflare = false`, rebuild (⌘R)

---

## Troubleshooting

### Movies from local JSON instead of D1?
- Check `CloudflareConfig.swift` has `useCloudflare = true`
- Clean build: ⌘⇧K, then ⌘R
- Check console for "Successfully loaded X movies from Cloudflare D1"

### Images not loading?
- Test URL: `https://images.reccs.media/posters/AFNOCFF.webp`
- Verify images are in `/posters/` folder in R2
- Check image names match movie IDs exactly

### Worker errors?
- Test: `curl https://reccs-movies-api.evangedrich.workers.dev/api/movies`
- Check `wrangler.toml` has correct database ID
- Redeploy: `npx wrangler@latest deploy`

---

## Data Mapping

**D1 Schema → iOS JSON**

| D1 | iOS |
|----|-----|
| `title_original`, `title_transliteration`, `title_translation` | `title{}` object |
| `coord_lng`, `coord_lat`, `coord_name` | `location{x, y, name}` |
| `watch_urls` (JSON string) | `watch[]` array |
| `info` (JSON array) | `info` (joined string) |
| `genre`, `tags` (JSON) | Arrays |

See `worker.js` line 115+ for transformation code.

---

## Movie Filtering

**Worker filters by ID pattern:**
- Characters 5-7 must be `CFF`, `GFF`, or `CSF`
- `AFNOCFF` → ✅ Included
- `AMLOCSF` → ✅ Included  
- `AFNOBOO` → ❌ Excluded

**SQL**: `WHERE SUBSTR(id, 5, 3) IN ('CFF', 'GFF', 'CSF')`

---

## Redeploying the Worker

If you update `worker.js` or `wrangler.toml`:

```bash
cd /path/to/project
npx wrangler@latest deploy
```

Copy the new URL if it changes, update `CloudflareConfig.swift`.

---

## Architecture

**Single MovieStore Pattern:**
```
ReccsApp (creates MovieStore with Cloudflare config)
  ↓
All views use @Environment(MovieStore.self)
  ↓
No view creates its own MovieStore()
```

**Image Loading:**
```
R2ImageView
  ↓
Try: https://images.reccs.media/posters/{ID}.webp
  ↓
Fail? → Fallback to local asset
```

---

## Summary

✅ **Setup Complete**
- Database: Cloudflare D1
- Images: Cloudflare R2
- Worker: Deployed and working
- Filtering: CFF/GFF/CSF only
- Fallback: Local JSON if Cloudflare fails

**Everything is working!** 🎉

---

## Documentation Cleanup

You can safely delete these redundant files:
- `RUN_SETUP.md`
- `QUICK_START.md`
- `FINAL_SETUP.md`
- `DEPLOYMENT_CHECKLIST.md`
- `INFORMATION_NEEDED.md`
- `CLOUDFLARE_SETUP.md`
- `DATA_MAPPING.md`
- `ARCHITECTURE.md`
- `IMAGE_URLS.md`
- `README_CLOUDFLARE.md`
- `QUICK_REFERENCE.md`
- `START_HERE.md`
- `check-files.sh`
- `FILE_CLEANUP_GUIDE.md`

**Keep only this file** (`CLOUDFLARE_GUIDE.md`) for future reference.

---

Made with ❤️ for your tvOS app
