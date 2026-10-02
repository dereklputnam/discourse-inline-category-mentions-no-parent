import { apiInitializer } from "discourse/lib/api";

const SEPARATOR = " > ";

// The category picker setting arrives as a pipe-separated string of IDs.
const EXCLUDED_CATEGORY_IDS = new Set(
  String(settings.excluded_categories || "")
    .split("|")
    .filter(Boolean)
    .map(Number)
);

// Cooked mention links carry the category ID in data-id. The autocomplete
// dropdown items have no ID attribute, so the only place it appears is the
// icon's hashtag-color--category-<id> class.
function autocompleteCategoryId(textSpan) {
  const icon = textSpan
    .closest(".hashtag-autocomplete__option")
    ?.querySelector(".hashtag-category-icon");
  const match = icon?.className.match(/hashtag-color--category-(\d+)/);
  return match ? Number(match[1]) : null;
}

// Category hashtag mentions (#category) are cooked as a single text node
// like "Parent > Child" — there's no separate element boundary between the
// parent and child names to hide with CSS, so this strips the parent
// segment client-side wherever that markup renders.
function shortenHashtagLink(link) {
  if (EXCLUDED_CATEGORY_IDS.has(Number(link.dataset.id))) {
    return;
  }

  const textSpan = link.querySelector("span:not(.hashtag-category-icon)");
  if (textSpan) {
    const index = textSpan.textContent.lastIndexOf(SEPARATOR);
    if (index !== -1) {
      textSpan.textContent = textSpan.textContent.slice(
        index + SEPARATOR.length
      );
    }
  }

  const label = link.getAttribute("aria-label");
  if (label) {
    const labelIndex = label.lastIndexOf(SEPARATOR);
    if (labelIndex !== -1) {
      link.setAttribute(
        "aria-label",
        label.slice(labelIndex + SEPARATOR.length)
      );
    }
  }
}

function shortenCategoryHashtagsIn(root) {
  root
    .querySelectorAll('a.hashtag-cooked[data-type="category"]')
    .forEach(shortenHashtagLink);
}

function shortenAutocompleteOptions(root) {
  root.querySelectorAll(".hashtag-autocomplete__text").forEach((span) => {
    if (EXCLUDED_CATEGORY_IDS.has(autocompleteCategoryId(span))) {
      return;
    }

    const index = span.textContent.lastIndexOf(SEPARATOR);
    if (index !== -1) {
      span.textContent = span.textContent.slice(index + SEPARATOR.length);
    }
  });
}

// The composer's live preview and the # autocomplete dropdown render this
// same markup outside the post stream, so decorateCookedElement never sees
// them, and core has no hook for either. Each gets its own observer, limited
// to its own container and coalesced to one run per frame. The
// re-check-before-write guard (lastIndexOf returns -1 once already
// shortened) keeps our own edits from re-triggering the work.
const observed = new WeakSet();

function observeOnce(selector, callback) {
  const element = document.querySelector(selector);
  if (!element || observed.has(element)) {
    return;
  }
  observed.add(element);

  let queued = false;
  new MutationObserver(() => {
    if (queued) {
      return;
    }
    queued = true;
    requestAnimationFrame(() => {
      queued = false;
      callback(element);
    });
  }).observe(element, { childList: true, subtree: true, characterData: true });
}

function observeComposerSurfaces() {
  observeOnce("#d-menu-portals", shortenAutocompleteOptions);
  observeOnce("#reply-control", (composer) => {
    const preview = composer.querySelector(".d-editor-preview");
    if (preview) {
      shortenCategoryHashtagsIn(preview);
    }
  });
}

export default apiInitializer((api) => {
  api.decorateCookedElement(shortenCategoryHashtagsIn, {
    id: "discourse-inline-category-mentions-no-parent",
  });

  observeComposerSurfaces();

  // Fires for the initial page load as well. The containers above may not
  // exist yet when this initializer runs, so they are (re)attached here.
  api.onPageChange(observeComposerSurfaces);
});
