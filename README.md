# gptcotts Github Action

This action is designed to be places in your notes repository to automatically update the s3 bucket & pinecone index with the latest notes.
The repository should be of the form:

```
neovim.md
python.md
linear_algebra.md
...
```

The script will only look for markdown files in the root directory of the repository.

## Structure of Markdown files

The markdown files should be of the form:

```
# Title of the note

## Subtitle

any content

### Sub-subtitle

more content
...
```

It should be semi-structured with the title of the note at the top, followed by subtitles and sub-subtitles.

## Usage

To use this action, create a `.github/workflows/main.yml` file in your repository with the following content:

```yaml
name: update s3 & pinecone
on:
    push:
        branches: [ "main" ]
jobs:
    build:
        runs-on: ubuntu-latest
        steps:
        - name: checkout
          uses: actions/checkout@v4
        - name: get all changed markdown files
          id: changed-markdown-files
          uses: tj-actions/changed-files@v44
          with:
            files: |
              **.md
        - name: gptcotts action
          uses: tomcotter7/gptcotts-github-action@main
          env:
            AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
            AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
            AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            AWS_DIR: ${{ secrets.AWS_DIR }}
            PINECONE_API_KEY: ${{ secrets.PINECONE_API_KEY }}
            PINECONE_INDEX: ${{ secrets.PINECONE_INDEX }}
            PINECONE_NAMESPACE: ${{ secrets.PINECONE_NAMESPACE }}
            COHERE_API_KEY: ${{ secrets.COHERE_API_KEY }}
            CHANGED_FILES: ${{ steps.changed-markdown-files.outputs.all_changed_files }}
```

This will run the action whenever you push to the main branch. It will then update the s3 bucket and pinecone index with the latest notes.
