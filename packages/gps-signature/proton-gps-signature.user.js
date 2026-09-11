// ==UserScript==
// @name         Proton Mail — GPS signature
// @namespace    local.gps-signature
// @version      1.0.0
// @description  Replace a [[GPS]] placeholder in the Proton Mail signature with the current location served by gps-signature on localhost (Cryptonomicon-style).
// @match        https://mail.proton.me/*
// @grant        GM_xmlhttpRequest
// @connect      127.0.0.1
// @run-at       document-idle
// @noframes
// ==/UserScript==

(() => {
    'use strict';

    const ENDPOINT = 'http://127.0.0.1:47121/location.txt';
    const PLACEHOLDER = /\[\[GPS\]\]/g;
    const FALLBACK = 'location unavailable';
    const CACHE_MS = 60_000;   // reuse a fetched line for a minute
    const IFRAME_SELECTOR = 'iframe[data-testid="rooster-iframe"], iframe[title="Email composer"], .composer iframe';
    const TEXTAREA_SELECTOR = 'textarea.editor-textarea, .composer textarea';

    let cached = { text: null, at: 0 };

    function fetchLocation() {
        if (cached.text && Date.now() - cached.at < CACHE_MS) {
            return Promise.resolve(cached.text);
        }

        return new Promise((resolve) => {
            GM_xmlhttpRequest({
                method: 'GET',
                url: ENDPOINT,
                timeout: 4000,
                onload: (r) => {
                    if (r.status === 200 && r.responseText.trim()) {
                        cached = { text: r.responseText.trim(), at: Date.now() };
                        resolve(cached.text);
                    } else {
                        resolve(cached.text || FALLBACK);
                    }
                },
                onerror: () => resolve(cached.text || FALLBACK),
                ontimeout: () => resolve(cached.text || FALLBACK),
            });
        });
    }

    // Replace the placeholder inside every text node under `root`.
    // Multi-line location strings become <br>-separated lines.
    function replaceInDom(root, text) {
        const doc = root.ownerDocument || root;
        const walker = doc.createTreeWalker(root, NodeFilter.SHOW_TEXT);
        const hits = [];
        for (let n = walker.nextNode(); n; n = walker.nextNode()) {
            if (PLACEHOLDER.test(n.nodeValue)) hits.push(n);
            PLACEHOLDER.lastIndex = 0;
        }
        for (const node of hits) {
            const parts = node.nodeValue.split(PLACEHOLDER);
            const frag = doc.createDocumentFragment();
            parts.forEach((part, i) => {
                frag.appendChild(doc.createTextNode(part));
                if (i < parts.length - 1) {
                    text.split('\n').forEach((line, j) => {
                        if (j > 0) frag.appendChild(doc.createElement('br'));
                        frag.appendChild(doc.createTextNode(line));
                    });
                }
            });
            node.parentNode.replaceChild(frag, node);
        }
        return hits.length;
    }

    function hasPlaceholder(root) {
        return PLACEHOLDER.test(root.textContent || '') && !(PLACEHOLDER.lastIndex = 0);
    }

    // --- Rich-text composer (Rooster editor inside a same-origin iframe) ---
    const seenFrames = new WeakSet();

    function attachFrame(iframe) {
        if (seenFrames.has(iframe)) return;
        seenFrames.add(iframe);

        const bind = () => {
            let doc;
            try { doc = iframe.contentDocument; } catch { return; }
            if (!doc || !doc.body) { setTimeout(bind, 200); return; }

            let busy = false;
            const check = () => {
                if (busy || !hasPlaceholder(doc.body)) return;
                busy = true;
                fetchLocation().then((text) => {
                    replaceInDom(doc.body, text);
                    busy = false;
                });
            };

            new MutationObserver(check).observe(doc.body, {
                childList: true,
                subtree: true,
                characterData: true
            });
            check();
        };

        if (iframe.contentDocument
            && iframe.contentDocument.readyState === 'complete'
        ) {
            bind();
        }

        iframe.addEventListener('load', bind);
        bind();
    }

    // --- Plain-text composer (a textarea) ---
    const seenAreas = new WeakSet();

    function attachTextarea(ta) {
        if (seenAreas.has(ta)) return;
        seenAreas.add(ta);
        const check = () => {
            if (!PLACEHOLDER.test(ta.value)) { PLACEHOLDER.lastIndex = 0; return; }
            PLACEHOLDER.lastIndex = 0;
            fetchLocation().then((text) => {
                const start = ta.selectionStart, end = ta.selectionEnd;
                const setter = Object
                    .getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')
                    .set;
                setter.call(ta, ta.value.replace(PLACEHOLDER, text));
                ta.setSelectionRange(start, end);
                ta.dispatchEvent(new Event('input', { bubbles: true }));
            });
        };
        check();
        setTimeout(check, 500);
        setTimeout(check, 1500);
    }

    function scan() {
        document.querySelectorAll(IFRAME_SELECTOR).forEach(attachFrame);
        document.querySelectorAll(TEXTAREA_SELECTOR).forEach(attachTextarea);
    }

    new MutationObserver(scan).observe(document.documentElement, {
        childList: true,
        subtree: true
    });
    scan();

    // Warm the cache so the first compose does not wait on the daemon.
    fetchLocation();
})();

/* <> */
