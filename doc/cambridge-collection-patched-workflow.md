Cambridge collection patched workflow
=====================================

Purpose
-------

The Cambridge Collection patched version of pandoc contains two changes:

1. The docx readers were updated to preserve manual block alignment formatting (i.e. right justification and centered). It now wraps any block-level item with manually set alignment formatting (right, center, justify, start and end) in a div with an appropriate inline style declaration (`<div style="text-align: center"><p>Lorem ipse ...</p></div>). **Note:** The start and end justification does not currently take into consideration the text-direction so it will only work reliably on left-to-right flowing text.
2. A docker build process that creates a container with a compiled version of the pandoc binary. The image also contains a custom entrypoint. 

Running the container
---------------------

1) Create a `workspace/` directory in the repo to hold both source files and
   outputs.
2) Mount it into the container at `/data`, which is what the entrypoint
   script uses:
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
   -t html5 \
   --from=docx \
   -s -- "/data/sample.docx"
   ```
   
3) Accepts all pandoc flags:
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched -t html5 \
    --extract-media=media \
    --mathml \
    --track-changes=accept \
    --from=docx \
    --wrap=none \
    -s -- "/data/sample.docx"
   ```

4) Multiple inputs are allowed; globbing happens inside the container.
   
   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
    -t html5 \
    --from=docx \
    -s -- "/data/sample.docx" "/data/another-sample.docx"
   ```

   It also supports wildcards

   ```
   docker run --rm -v "$PWD/workspace:/data" ghcr.io/cambridge-collection/pandoc-patched \
    -t html5 \
    --from=docx \
    -s -- "/data/*sample*.docx"
    ```

Notes
-----

- The entrypoint is `pandoc-run` from `docker/pandoc-run.sh`; use `--help`
  to see the passthrough flags.
- The image ships only the built pandoc binary and data files; host
  `workspace/` content is never baked into the image.
