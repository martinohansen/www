#!/bin/bash
set -euo pipefail

HEAD="_templates/head.html"
NAV="_templates/nav.html"
POST_METADATA_FILTER="_filters/page-metadata.lua"
# Standalone tools are built separately from the Pandoc pages below.
SITEMAP_PATHS=(fireberegner/index.html realkreditberegner/index.html)

page() {
    local src=$1 out=$2 title=$3 page=$4
    echo "$out"
    mkdir -p "$(dirname "$out")"
    pandoc "$src" \
        --from=html \
        --template="_templates/page.html" \
        --metadata title="$title" \
        --metadata page="$page" \
        --include-in-header="$HEAD" \
        --include-before-body="$NAV" \
        --output="$out"
    SITEMAP_PATHS+=("$out")
}

# Pages
page _pages/home.html index.html "Home" home
page _pages/blog.html blog/index.html "Blog" blog
page _pages/photos.html photos/index.html "Photos" photos
page _pages/tools.html tools/index.html "Tools" tools
page _pages/lightning.html lightning/index.html "Lightning node" lightning

# Posts
while IFS= read -r md; do
    out="${md%.md}.html"
    echo "$out"
    pandoc "$md" \
        --template="_templates/post.html" \
        --lua-filter="$POST_METADATA_FILTER" \
        --lua-filter="_filters/heading-links.lua" \
        --include-in-header="$HEAD" \
        --include-before-body="$NAV" \
        --output="$out"
    SITEMAP_PATHS+=("$out")
done < <(find blog -name "*.md")

# Publish the sitemap only after all pages have built successfully.
sitemap_tmp=$(mktemp sitemap.xml.XXXXXX)
trap 'rm -f "$sitemap_tmp"' EXIT
{
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    for path in "${SITEMAP_PATHS[@]}"; do
        url="https://heymartin.net/${path%index.html}"
        escaped_url=$(printf '%s' "$url" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        printf '  <url><loc>%s</loc></url>\n' "$escaped_url"
    done
    printf '</urlset>\n'
} > "$sitemap_tmp"
mv "$sitemap_tmp" sitemap.xml
