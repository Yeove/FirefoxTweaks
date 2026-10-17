// Sidebery Drop-Down controller
// Loaded into each browser window by yeovefirefox.cfg. Pairs with userChrome.css.
//
//  - Swipe the mouse to the very top edge of the window -> panel drops open ("sb-hover-open")
//  - Swipe to the top edge again                         -> panel closes
//  - Mouse enters the close strip at the bottom          -> panel closes
//  - Ctrl+Space: if closed, pins it open ("sb-pinned-open"); if open (either way), closes it.
//    A pinned panel ignores the close strip (and top swipes, unless SWIPE_CLOSES_PINNED).

(function () {
    const HOVER  = "sb-hover-open";
    const PINNED = "sb-pinned-open";
    const XHTML  = "http://www.w3.org/1999/xhtml";

    // After the top edge opens or closes the panel, the mouse must come back down
    // at least this far (px from the top of the window) before the edge works again.
    // Stops small wiggles at the edge from flickering the panel open/closed.
    const REARM_DISTANCE = 16;

    // true = swiping to the top edge also closes a panel pinned with Ctrl+Space.
    const SWIPE_CLOSES_PINNED = false;

    const box         = document.getElementById("sidebar-box");
    const browserArea = document.getElementById("browser");
    if (!box || !browserArea) return;

    const isOpen   = () => box.hasAttribute(HOVER) || box.hasAttribute(PINNED);
    const closeAll = () => { box.removeAttribute(HOVER); box.removeAttribute(PINNED); };

    // ---------- Top edge: toggle ----------
    let edgeArmed = true;

    const topZone = document.createElementNS(XHTML, "div");
    topZone.id = "sb-top-hotzone";
    (document.body || document.documentElement).appendChild(topZone);

    topZone.addEventListener("mouseenter", () => {
        if (!edgeArmed) return;
        if (!isOpen()) {
            box.setAttribute(HOVER, "");
        } else if (box.hasAttribute(PINNED) && !SWIPE_CLOSES_PINNED) {
            return; // pinned: leave it alone, and stay armed
        } else {
            closeAll();
        }
        edgeArmed = false;
    });

    // Re-arm once the mouse has come back down from the edge.
    // mouseleave covers fast flicks that jump straight down past the toolbar;
    // mousemove covers slower movement through the toolbar.
    topZone.addEventListener("mouseleave", (e) => {
        if (e.clientY > REARM_DISTANCE) edgeArmed = true;
    });
    window.addEventListener("mousemove", (e) => {
        if (!edgeArmed && e.clientY > REARM_DISTANCE) edgeArmed = true;
    }, true);

    // ---------- Bottom close strip ----------
    const closeZone = document.createElementNS(XHTML, "div");
    closeZone.id = "sb-close-zone";
    browserArea.appendChild(closeZone); // after #sidebar-box, so CSS can target it with ~
    closeZone.addEventListener("mouseenter", () => box.removeAttribute(HOVER));

    // ---------- Ctrl+Space ----------
    // Owns the key entirely; Sidebery never sees it.
    window.addEventListener("keydown", (e) => {
        if (e.code !== "Space" || !e.ctrlKey || e.shiftKey || e.altKey || e.metaKey) return;
        e.preventDefault();
        e.stopImmediatePropagation();
        if (e.repeat) return;
        if (isOpen()) closeAll();
        else box.setAttribute(PINNED, "");
    }, true); // capture phase: runs before page content / other shortcuts
})();
