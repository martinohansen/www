#!/bin/bash
set -euo pipefail

HEAD="_templates/head.html"
NAV="_templates/nav.html"
POST_METADATA_FILTER="_filters/page-metadata.lua"
# Standalone tools are built separately from the Pandoc pages below.
SITEMAP_PATHS=(fireberegner/index.html realkreditberegner/index.html)

page() {
    local src=$1 out=$2 title=$3 page=$4 description=$5
    echo "$out"
    mkdir -p "$(dirname "$out")"
    pandoc "$src" \
        --from=html \
        --template="_templates/page.html" \
        --metadata title="$title" \
        --metadata page="$page" \
        --metadata description="$description" \
        --include-in-header="$HEAD" \
        --include-before-body="$NAV" \
        --output="$out"
    SITEMAP_PATHS+=("$out")
}

# Pages
page _pages/home.html index.html "Home" home \
    "Martin Hansen's personal website with a blog, photos and free Danish calculators for FIRE planning and mortgages."
page _pages/blog.html blog/index.html "Blog" blog \
    "Blog posts by Martin Hansen, writing about life as it happens."
page _pages/photos.html photos/index.html "Photos" photos \
    "Travel photos by Martin Hansen."
page _pages/tools.html tools/index.html "Tools" tools \
    "Free tools by Martin Hansen: a Danish FIRE calculator, a Danish mortgage calculator, a Firefox add-on and a YNAB bank sync."
page _pages/lightning.html lightning/index.html "Lightning node" lightning \
    "Connection addresses for thunderf, a Bitcoin Lightning routing node run by Martin Hansen."

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
sitemap_tmp=sitemap.xml.tmp
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
