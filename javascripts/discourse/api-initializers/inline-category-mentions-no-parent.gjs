import { apiInitializer } from "discourse/lib/api";

const SEPARATOR = " > ";

// Category hashtag mentions (#category) are cooked as a single text node
// like "Parent > Child" — there's no separate element boundary between the
// parent and child names to hide with CSS, so this strips the parent
// segment client-side wherever that markup renders.
function shortenHashtagLink(link) {
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

function shortenAutocompleteOptions() {
  document.querySelectorAll(".hashtag-autocomplete__text").forEach((span) => {
    const index = span.textContent.lastIndexOf(SEPARATOR);
    if (index !== -1) {
      span.textContent = span.textContent.slice(index + SEPARATOR.length);
    }
  });
}

// Two surfaces render this same markup outside the post stream and aren't
// reached by decorateCookedElement: the composer's live preview pane (which
// re-cooks on every keystroke) and the #category autocomplete dropdown (a
// floating-menu portal created on demand). Neither has a core value
// transformer, so a MutationObserver on document.body (always present at
// init time) covers both. The re-check-before-write guard (lastIndexOf
// returns -1 once already shortened) prevents an infinite loop from our own
// edits re-triggering the observer.
function observeLiveSurfaces() {
  const observer = new MutationObserver(() => {
    const preview = document.querySelector(".d-editor-preview");
    if (preview) {
      shortenCategoryHashtagsIn(preview);
    }
    if (document.querySelector(".hashtag-autocomplete")) {
      shortenAutocompleteOptions();
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
    characterData: true,
  });
}

export default apiInitializer((api) => {
  api.decorateCookedElement(shortenCategoryHashtagsIn, {
    id: "discourse-inline-category-mentions-no-parent",
  });

  observeLiveSurfaces();
});
