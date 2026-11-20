# diamondmarkdown.com

The landing page for [Diamond Markdown](https://github.com/Zollicoff/diamond-markdown),
a native Markdown notes app for macOS and Linux.

Plain static HTML and CSS. There is nothing to build.

## What is here

- `index.html`: the page
- `styles.css`: all of its styling
- `shots/`: pictures of the app, used on the page
- `favicon.svg`: the mark, two brackets holding a stone. Everything else
  that shows the mark is drawn from this file.
- `favicon-16.png`, `favicon-32.png`, `apple-touch-icon.png`: the mark as
  icons
- `og-image.png`: the card shown when the address is shared
- `tools/`: what the icons and the card are made with. Not deployed.

## Look at it

Open `index.html` in a browser. Every path in it is relative, so it works
straight from the folder.

To get a picture of the page without opening a browser:

```sh
swift tools/snapshot.swift index.html page.png 1280 0 2
```

That renders the whole page 1280 pixels wide, at two image pixels per CSS
pixel. `tools/snapshot.swift` says what the arguments mean.

## Keeping it true

The page describes the app, so it changes when the app does. Three things
come from the app's repository rather than being written here:

- **What the app does and does not do.** The page's feature list and its
  "Where it stands" section follow `README.md` and `docs/guide.md` there.
- **The pictures in `shots/`.** They are the app's own window, drawn by the
  app:

  ```sh
  # in the diamond-markdown repository
  cargo run -p diamond-app --features screenshots -- --screenshots sample-vault pictures
  ```

  Copy the ones the page uses into `shots/`.
- **The links.** They point at the `desktop-rewrite` branch, where the app
  is being developed. When that branch is merged, change them.

The icons and the card are rendered from `favicon.svg` and the pages in
`tools/`. After changing the mark, or the words on the card in
`tools/og-image.html`, make them all again:

```sh
tools/make-images.sh
```

The mark also appears once in `index.html`, as the `mark` symbol near the
top. Keep it the same as `favicon.svg`.

## Deploy

The site is a Vercel project, `diamondmarkdown-www`, deployed by hand with
the Vercel CLI from this folder. Pushing to GitHub does not publish
anything.

```sh
vercel deploy          # a preview address, to check first
vercel deploy --prod   # diamondmarkdown.com
```

`.vercelignore` keeps `tools/` and this file out of what is published.
