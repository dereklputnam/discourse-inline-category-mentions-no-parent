# Discourse - Inline Category Mentions - no Parent

A Discourse theme component that shortens inline `#category` mentions to just the category's own name. A subcategory mention that normally reads `Community > Community Feedback` shows as `Community Feedback`.

## Where it applies

- Category mentions in posts
- The live preview pane in the composer
- The `#` mention autocomplete dropdown in the composer

## What it doesn't change

This is display-only. Links, slugs, category names and permissions are untouched, and searching by slug (for example `#community:community-feedback`) works as it does in core.

## Settings

- **excluded_categories**: mentions of these categories keep their full `Parent > Child` text. It matches the mentioned category itself, so excluding a parent does not exclude its subcategories.

## Install

1. In Admin, go to **Customize → Themes → Install → From a git repository**.
2. Enter `https://github.com/dereklputnam/discourse-inline-category-mentions-no-parent`.
3. Add the component to your active theme.

## Notes

- The post mentions use Discourse's documented `decorateCookedElement` hook. The composer preview and autocomplete have no official hook, so each gets a small `MutationObserver` limited to its own container (`#reply-control` and `#d-menu-portals`), not the whole page.
- It depends on core markup (`a.hashtag-cooked`, `.hashtag-autocomplete__text`, `.d-editor-preview`). If a Discourse upgrade renames those, mentions quietly show their full "Parent > Child" text again, so check after upgrading.
