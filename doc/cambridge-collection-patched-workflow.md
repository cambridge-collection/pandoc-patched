Cambridge collection patched workflow
=====================================

Purpose
-------

The Cambridge Collection patched version of pandoc contains two significant changes:

1. The docx readers were updated to preserve manually formatted block formatting (i.e. right justification and centered). It now wraps any block-level item with manually set alignment formatting (right, center, justify, start and end) in a div with an appropriate inline style declaration (`<div style="text-align: center"><p>Lorem ipse ...</p></div>). The start and end justification does not currently take into consideration the text-direction so it will only work reliably on left-to-right flowing text.
2. A docker build process that creates a container with a compiled version of the pandoc binary. The image also contains a custom entrypoint. 

Running the container
---------------------

1) Prepare a `workspace/` directory in the repo for both source files and
   outputs (this path is ignored by the image build via `.dockerignore`).
2) Mount it into the container at `/data`, which is what the entrypoint
   script uses:
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
    -t html5 \
    --from=docx \
    -s -- "/data/sample.docx"
   ```
   
3) Override the output or format with normal pandoc flags:
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched -t html5 \
    --preserve-tabs \
    --extract-media=media \
    --mathml \
    --track-changes=accept \
    --from=docx \
    --wrap=none \
    -s -- "/data/*.docx"
   ```

4) Multiple inputs are allowed; globbing happens inside the container.
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
    -t html5 \
    --from=docx \
    -s -- "/data/sample.docx" "/data/another-sample.docx"
   ```

   Paths with spaces are fine when quoted:

   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
    -t html5 \
    --from=docx \
    -s -- "/data/EHT 016.docx" "/data/Letter_0533.docx"
   ```

Notes
-----

- The entrypoint is `pandoc-run` from `docker/pandoc-run.sh`; use `--help`
  to see the passthrough flags.
- The image ships only the built pandoc binary and data files; host
  `workspace/` content is never baked into the image.
